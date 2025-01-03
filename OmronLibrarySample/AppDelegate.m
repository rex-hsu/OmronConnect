//
//  AppDelegate.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>
#import <UserNotifications/UserNotifications.h>
#import <Foundation/Foundation.h>
#import "OmronLogger.h"

// constant definition
#define LOG_FILE_PREFIX @"log_"
#define MAX_LOG_SIZE 5242880 // 5MB

@interface AppDelegate ()
@property (strong, nonatomic) NSTimer *logCheckTimer;
@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Start log output
    [self startLogging];

    // Timer settings. Call checkAndManageLogFiles function every 600 seconds
    self.logCheckTimer = [NSTimer scheduledTimerWithTimeInterval:600.0 target:self selector:@selector(checkAndManageLogFiles) userInfo:nil repeats:YES];

    sleep(1);

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    // Stop timer when app goes to background
    [self.logCheckTimer invalidate];
    self.logCheckTimer = nil;
    [self stopLogging];
    #ifdef DEBUG
        [self testNotifications];
    #endif
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // Resume timer when app becomes active
    if (!self.logCheckTimer || ![self.logCheckTimer isValid]) {
        [self startLogging];
        self.logCheckTimer = [NSTimer scheduledTimerWithTimeInterval:600.0 target:self selector:@selector(checkAndManageLogFiles) userInfo:nil repeats:YES];
    }
    // Clear all notifications
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

+ (AppDelegate *)sharedAppDelegate{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [self.managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BPDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OmronLibrarySample.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
       
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Notification Test

- (void)testNotifications {
    
    // Trigger test notification for HeartGuide
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString localizedUserNotificationStringForKey:@"Notification" arguments:nil];
    content.body = [NSString localizedUserNotificationStringForKey:@"Test Notification for HeartGuide" arguments:nil];
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5 repeats:NO];
    // Create the request object.
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"HeartGuideNotification" content:content trigger:trigger];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            ILogMethodLine(@"%@", error.localizedDescription);
        }
    }];
}

- (void)startLogging {
    setLoggable(LogLevelInfo);
    // Get current date and time
    NSDate *now = [NSDate date];
    // Set date format
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    // Convert date to string
    NSString *strNow = [formatter stringFromDate:now]; 
    // Create log file name
    NSString *logFileName = [NSString stringWithFormat:@"log_%@.txt", strNow];

    //document folder/log.txt
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES );
    NSString* dir = [paths objectAtIndex:0];
    NSString* path = [dir stringByAppendingPathComponent:logFileName];

    // Redirect standard output to file
    freopen([path UTF8String], "a+", stdout);
    // Redirect standard error output to file
    freopen([path UTF8String], "a+", stderr);
}

- (void)stopLogging {
    // Restore standard output
    freopen("/dev/stdout", "a", stdout);
    // Restore standard error output
    freopen("/dev/stderr", "a", stderr);
}

- (void)checkAndManageLogFiles {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    NSMutableArray *logFiles = [[NSMutableArray alloc] init];
    unsigned long long totalSize = 0;

    // Extract only log files and calculate total size
    for (NSString *fileName in allFiles) {
        if ([fileName hasPrefix:LOG_FILE_PREFIX]) {
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            unsigned long long fileSize = [[fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
            totalSize += fileSize;
            NSDictionary *fileAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                            filePath, @"path",
                                            [NSNumber numberWithUnsignedLongLong:fileSize], @"size",
                                            nil];
            [logFiles addObject:fileAttributes];
        }
    }

    // If the total size exceeds 1MB, delete the oldest files first.
    if (totalSize > MAX_LOG_SIZE) {
        // Sort files by creation date and time
        NSArray *sortedLogFiles = [logFiles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSDictionary *file1 = (NSDictionary *)obj1;
            NSDictionary *file2 = (NSDictionary *)obj2;
            return [[fileManager attributesOfItemAtPath:[file1 objectForKey:@"path"] error:nil][NSFileCreationDate] compare:[fileManager attributesOfItemAtPath:[file2 objectForKey:@"path"] error:nil][NSFileCreationDate]];
        }];

        // Delete old files
        for (NSDictionary *fileAttributes in sortedLogFiles) {
            if (totalSize <= MAX_LOG_SIZE) {
                break;
            }
            NSString *filePath = [fileAttributes objectForKey:@"path"];
            unsigned long long fileSize = [[fileAttributes objectForKey:@"size"] unsignedLongLongValue];
            if ([fileManager removeItemAtPath:filePath error:nil]) {
                totalSize -= fileSize;
            }
        }
    }
}
@end
