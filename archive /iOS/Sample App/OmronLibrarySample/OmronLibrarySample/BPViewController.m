//
//  BPViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import  "QuartzCore/QuartzCore.h"
#import "BPViewController.h"
#import "AppDelegate.h"
#import "BPReadingsViewController.h"
#import "VitalOptionsTableViewController.h"
#import "ReminderListTableViewController.h"
#import "OmronLogger.h"
#import <UserNotifications/UserNotifications.h>
@interface BPViewController (){
    
    // Tracks Connected Omron Peripheral
    OmronPeripheral *localPeripheral;
    bool isTransfer;
    bool isConnect;
    int counter;
}

@property (weak, nonatomic) IBOutlet UILabel *lblTimeStamp;
@property (weak, nonatomic) IBOutlet UILabel *lblSystolic;
@property (weak, nonatomic) IBOutlet UILabel *lblDiastolic;
@property (weak, nonatomic) IBOutlet UILabel *lblPulseRate;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblSysUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblDiaUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblPulseUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblLocalName;
@property (weak, nonatomic) IBOutlet UILabel *lblUserSelected;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralErrorCode;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralError;
@property (weak, nonatomic) IBOutlet UILabel *lbldeviceModel;
@property (weak, nonatomic) IBOutlet UILabel *lbldateOfBirth;
@property (weak, nonatomic) IBOutlet UILabel *lblsequenceNumber;
@property (weak, nonatomic) IBOutlet UILabel *lbltruReadEnable;
@property (weak, nonatomic) IBOutlet UILabel *lbltruReadInterval;
@property (weak, nonatomic) IBOutlet UILabel *lblTruReadEnable;
@property (weak, nonatomic) IBOutlet UILabel *lblTruReadInterval;
@property (weak, nonatomic) IBOutlet UILabel *lblBatteryRemaining;
@property (weak, nonatomic) IBOutlet UIView *devicesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searching;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *transferButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnReadingList;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *lblSequenceNumberTitle;

- (IBAction)settingsButtonPressed:(id)sender;
- (IBAction)readingListButtonPressed:(id)sender;

@end

@interface NSDictionary (ContainsKey)
- (BOOL)containsKey:(id)key;
@end

@implementation NSDictionary (ContainsKey)
- (BOOL)containsKey:(id)key {
    return [self objectForKey:key] != nil;
}
@end

@implementation BPViewController

#pragma mark - View Controller Life cycles

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.transferButton.layer.cornerRadius = 5.0; // 5.0 indicates the radius to round
    self.transferButton.layer.masksToBounds = YES;
    isTransfer = NO;
    isConnect = NO;
    
    //Showing and hiding labels
    [self configureLabelVisibilyty];
    
    [self updateLocalPeripheral: self.omronLocalPeripheral];
    
    counter = 0;
    
    self.searching.hidden = YES;
    
    self.scrollView.backgroundColor = self.devicesView.backgroundColor;
    
    self.lbldeviceModel.text = [NSString stringWithFormat:@"%@ - Connection Status", [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelNameKey]];
    self.lblLocalName.text = [NSString stringWithFormat:@"%@\n\n%@", self.omronLocalPeripheral.localName,  self.omronLocalPeripheral.UUID];
    [self customNavigationBarTitle:@"Data Transfer" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    // Default to 1 for single user device
    if(self.users.count == 0) {
        self.users = [[NSMutableArray alloc] initWithArray:@[@(1)]];
    }
    
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
        
        self.settingsButton.hidden = YES;
        
    }else {
        
        self.settingsButton.hidden = YES;
    }
    
    // Start OmronPeripheralManager
    [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:YES];
}

// Start Omron Peripheral Manager
- (void)startOmronPeripheralManagerWithHistoricRead:(BOOL)isHistoric withPairing:(BOOL)pairing {
    
    OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
    
    // Filter device to scan and connect (optional)
    if([self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIDKey] && [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]) {
        
        NSMutableArray *filterDevices = [[NSMutableArray alloc] init];
        
        // New Supported Format - Add entire data model to filter list
        [filterDevices addObject:self.filterDeviceModel];
        
        peripheralConfig.deviceFilters = filterDevices;// Filter Devices
    }
    
    // Set Scan timeout interval (optional)
    peripheralConfig.timeoutInterval = 30; // Seconds
    
    // Holds settings
    NSMutableArray *deviceSettings = [[NSMutableArray alloc] init];
    
    // Disclaimer: Read definition before usage
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] != OMRONBLEDeviceCategoryActivity) {
        peripheralConfig.enableAllDataRead = isHistoric;
    }
    
    peripheralConfig.enableiBeaconWithTransfer = true;
    
    // Activity device settings (optional)
    [self getActivitySettings:&deviceSettings];
    
    [self getPersonalSettings:&deviceSettings];

    // Scan settings (optional)
    [self getScanSettings:&deviceSettings withPairing:pairing];
    
    // Set settings
    peripheralConfig.deviceSettings = deviceSettings;
    
    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
    // Pass the last sequence number of reading  tracked by app - "SequenceKey" for each vital data (user number and sequence number mapping)
    // peripheralConfig.sequenceNumbersForTransfer = @{@1 : @42, @2 : @8};
    
    // Set Configuration to New Configuration (mandatory to set configuration)
    [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:peripheralConfig];
    
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
        
        [self requestPushNotificationPermission];

    }else{
        // Start OmronPeripheralManager (mandatory)
        [[OmronPeripheralManager sharedManager] startManager];
    }
    
    // Notification Listener for BLE State Change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(centralManagerDidUpdateStateNotification:)
                                                 name:OMRONBLECentralManagerDidUpdateStateNotification
                                               object:nil];
}
- (void)requestPushNotificationPermission {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // Start OmronPeripheralManager (mandatory)
        [[OmronPeripheralManager sharedManager] startManager];

    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Remove Notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OMRONBLECentralManagerDidUpdateStateNotification object:nil];
    
    if(isTransfer){
        isTransfer = NO;
        // Stop Scanning for devices if scanning
        [[OmronPeripheralManager sharedManager] stopScanPeripherals];
    }
    if(isConnect){
        isConnect = NO;
        // Disconnects Omron Peripherals
        [[OmronPeripheralManager sharedManager] disconnectPeripheral:localPeripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {}];
    }
}

#pragma mark - OmronPeripheralManager Disconnect Function

- (void)disconnectDeviceWithMessage:(NSString *)message {
    
    self.lblStatus.text = @"Disconnecting...";
    
    // Disconnects Omron Peripherals
    [[OmronPeripheralManager sharedManager] disconnectPeripheral:localPeripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        if(error == nil) {
            
            self.lblStatus.text = @"Disconnected";
            self.lblPeripheralError.text = message;
            
        }else {
            
            [self resetLabels];
            
            self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
            self.lblPeripheralError.text = [error localizedDescription];
            
            ILogMethodLine(@"Error - %@", error);
        }
    }];
}

#pragma mark - OmronPeripheralManager Transfer Function

- (IBAction)TransferClick:(id)sender {
    
    counter++;
    
    [self resetLabels];
    
    self.btnReadingList.enabled = NO;
    self.transferButton.enabled = NO;
    self.transferButton.backgroundColor = [UIColor grayColor];
    self.searching.hidden = NO;
    
    if(localPeripheral) {
        
        if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
            [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:NO];
            [self performDataTransfer];
        }else {
            UIAlertController *transferType = [UIAlertController
                                              alertControllerWithTitle:@"Transfer"
                                              message:@"Do you want to transfer all historic readings from device?"
                                              preferredStyle:UIAlertControllerStyleAlert];
            // Create an attribute for the title string
            NSDictionary *titleAttributes = @{
                NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
            };
            NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Transfer" attributes:titleAttributes];
            [transferType setValue:attributedTitle forKey:@"attributedTitle"];
            // Create attributes for message strings
            NSDictionary *messageAttributes = @{
                NSFontAttributeName: [UIFont systemFontOfSize:12.0]
            };
            NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:@"Do you want to transfer all historic readings from device?" attributes:messageAttributes];

            // Apply attributes to messages
            [transferType setValue:attributedMessage forKey:@"attributedMessage"];
            UIAlertAction *okButton = [UIAlertAction
                                       actionWithTitle:@"Yes"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                
                [self startOmronPeripheralManagerWithHistoricRead:YES withPairing:NO];
                [self performDataTransfer];
                
            }];
            UIAlertAction *cancelButton = [UIAlertAction
                                       actionWithTitle:@"No"
                                       style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction * action) {
                
                [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:NO];
                [self performDataTransfer];
            }];
            [transferType addAction:cancelButton];
            [transferType addAction:okButton];
            [self presentViewController:transferType animated:YES completion:nil];
        }

    }else {
        
        self.lblPeripheralError.text = @"No device paired";
    }
}

- (void)performDataTransfer {
    
    // Connection State
    [self setConnectionStateNotifications];
    
    // Only Activity Device - HeartGuide
    [self onPeriodicNotifications];
    
    OmronPeripheral *peripheralLocal = [[OmronPeripheral alloc] initWithLocalName:localPeripheral.localName andUUID:localPeripheral.UUID];
    
    if([self.users count] > 1) {
        // Use param different to check function availability
    }else {
        // Use regular function with one user type
        [self transferUserDataWithPeripheral:peripheralLocal];
    }
}

// Single User data transfer
- (void)transferUserDataWithPeripheral:(OmronPeripheral *)peripheral {
    
    OMRONVitalDataTransferCategory category = OMRONVitalDataTransferCategoryAll;
    
    // Activity
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
        if(counter %2 != 0) {
            category = OMRONVitalDataTransferCategoryBloodPressure;
        }
    }
    
    /*
     * Starts Data Transfer from Omron Peripherals.
     * endDataTransferFromPeripheralWithCompletionBlock of OmronConnectivityLibrary need to be called once data retrieved is saved
     * For single user device, selected user will be passed as 1
     * withWait : Only YES is supported now
     */
    isTransfer = YES;
    [[OmronPeripheralManager sharedManager] startDataTransferFromPeripheral:peripheral withUser:[[self.users firstObject] intValue] withWait:YES withType:category withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil) {
                
                localPeripheral = peripheral;
                
                ILogMethodLine(@"Device Information - %@", [peripheral getDeviceInformation]);
                ILogMethodLine(@"Device Settings - %@", [peripheral getDeviceSettings]);
                
                // Retrieves Vital data for required user (should be same as value passed in function startDataTransferFromPeripheral:withUser:withWait:withCompletionBlock
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        [self uploadData:vitalData withPeripheral:peripheral withWait:YES];
                        
                    }else {
                        
                        // Error retrieving Peripheral vital data
                        ILogMethodLine(@"Error retrieving Peripheral Vital data - %@", error.description);
                        
                        [self disconnectDeviceWithMessage:error.localizedDescription];
                    }
                }];
                
            }else {
                
                [self resetLabels];
                
                self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                self.lblPeripheralError.text = [error localizedDescription];
                
                ILogMethodLine(@"Error - %@", error);
            }
        });
    }];
}

#pragma mark - Vital Data Save

- (void)uploadData:(NSMutableDictionary *)vitalData withPeripheral:(OmronPeripheral *)peripheral withWait:(BOOL)isWait {
    
    NSMutableDictionary *deviceInfo = peripheral.getDeviceInformation;
    NSMutableDictionary *deviceSettings = peripheral.getDeviceSettings;
    
    if(vitalData.allKeys.count > 0) {
        
        for (NSString *key in vitalData.allKeys) {
            
            // Blood Pressure Data
            if([key isEqualToString:OMRONVitalDataBloodPressureKey]) {
                
                NSMutableArray *uploadData = [vitalData objectForKey:key];
                
                // Save to DB
                if([uploadData count] > 0) {
                    
                    ILogMethodLine(@"BP Data - %@", uploadData);
                    
                    [self saveBPReadingsToDB:uploadData withDeviceInfo:deviceInfo];
                    [self saveDeviceDataHistory:deviceInfo];
                }
                
                // Update UI with last element in Blood Pressure
                NSMutableDictionary *latestData = [uploadData lastObject];
                
                if(latestData) {
                    
                    [self updateUIWithVitalData:latestData];
                    [self updateUIWithVitalDeviceInfomation:deviceSettings];
                    
                }else {
                    [self updateUIWithVitalDeviceInfomation:deviceSettings];
                    self.lblPeripheralError.text = @"No new blood pressure readings";
                }
            }
            
            // Activity Data
            else if([key isEqualToString:OMRONVitalDataActivityKey]) {
                
                NSMutableArray *activityData = vitalData[key];
                
                for (NSMutableDictionary *data in activityData) {
                    
                    for (NSString *activityKey in data.allKeys) {
                        
                        ILogMethodLine(@"Activity Data With Key : %@ \n %@ \n", activityKey, data[activityKey]);
                        
                        if([activityKey isEqualToString:OMRONActivityAerobicStepsPerDay] || [activityKey isEqualToString:OMRONActivityStepsPerDay] || [activityKey isEqualToString:OMRONActivityDistancePerDay] || [activityKey isEqualToString:OMRONActivityWalkingCaloriesPerDay]) {
                            
                            NSMutableDictionary *typeActivityData = data[activityKey];
                            
                            // Save to DB
                            [self saveActivityDataToDB:typeActivityData withDeviceInfo:deviceInfo withMainTable:@"ActivityData" withSubTable:@"ActivityDividedData" withType:activityKey];
                            [self saveDeviceDataHistory:deviceInfo];
                        }
                    }
                }
            }
            
            // Sleep Data
            else if([key isEqualToString:OMRONVitalDataSleepKey]) {
                
                NSMutableArray *sleepData = vitalData[key];
                
                for (NSMutableDictionary *data in sleepData) {
                    
                    ILogMethodLine(@"Sleep Data : %@", data);
                }
                
                // Save to DB
                [self saveSleepDataToDB:sleepData withDeviceInfo:deviceInfo withMainTable:@"SleepData"];
                [self saveDeviceDataHistory:deviceInfo];
                
            }
            
            // Records Data
            else if([key isEqualToString:OMRONVitalDataRecordKey]) {
                
                ILogMethodLine(@"Record Data With Key : %@ \n %@ \n", key, vitalData[key]);
                
                NSMutableArray *recordsData = [vitalData objectForKey:key];
                
                // Save to DB
                [self saveRecordsDataToDB:recordsData withDeviceInfo:deviceInfo];
                [self saveDeviceDataHistory:deviceInfo];
            }
        }
        
    }else {
        
        self.lblPeripheralError.text = @"No new readings transferred";
    }
    
    // To showcase delay and end data transfer - required when doing operations in app in between data transfer
    if(isWait)
        [self performSelector:@selector(continueDataTransfer) withObject:nil afterDelay:1.0];
    else
        [self continueDataTransfer];
    
}

- (void)continueDataTransfer {
    
    // End Data Transfer and update device
    [[OmronPeripheralManager sharedManager] endDataTransferFromPeripheralWithCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil) {
                
                ILogMethodLine(@"Device Information - %@", [peripheral getDeviceInformation]);
                ILogMethodLine(@"Device Settings - %@", [peripheral getDeviceSettings]);
                NSMutableDictionary *deviceSettings = peripheral.getDeviceSettings;
                
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        if(vitalData.allKeys.count > 0) {
                            
                            ILogMethodLine(@"Vital Data - %@", vitalData);
                            
                            for (NSString *key in vitalData.allKeys) {
                                
                                if([key isEqualToString:OMRONVitalDataBloodPressureKey]) {
                                    
                                    NSMutableArray *uploadData = [vitalData objectForKey:key];
                                    NSMutableDictionary *latestData = [uploadData lastObject];
                                    
                                    if(latestData) {
                                        
                                        [self updateUIWithVitalData:latestData];
                                        [self updateUIWithVitalDeviceInfomation:deviceSettings];
                                    }
                                }
                            }
                        }else {
                            [self updateUIWithVitalDeviceInfomation:deviceSettings];
                            self.lblPeripheralError.text = @"No new readings transferred";
                        }
                    }
                }];
            }else {
                
                [self resetLabels];
                
                self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                self.lblPeripheralError.text = [error localizedDescription];
                
                ILogMethodLine(@"Error - %@", error);
            }
        });
    }];
    
}

#pragma mark - Data Save

- (void)saveBPReadingsToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *bpItem in dataList) {
        
        NSManagedObject *bpInfo = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"BPData"
                                   inManagedObjectContext:context];
        
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataUserIdKey]                                                   forKey:@"user"];
        [bpInfo setValue:[NSString stringWithFormat:@"%@", [bpItem valueForKey:OMRONVitalDataMeasurementStartDateKey]]  forKey:@"startDate"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataSystolicKey]                                                 forKey:@"systolic"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataDiastolicKey]                                                forKey:@"diastolic"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataPulseKey]                                                    forKey:@"pulse"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataPositioningIndicatorKey]                                     forKey:@"positionIndicator"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataIrregularFlagKey]                                            forKey:@"irregularFlag"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataMovementFlagKey]                                             forKey:@"movementFlag"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataCuffFlagKey]                                                 forKey:@"cuffFlag"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataConsecutiveMeasurementKey]                                   forKey:@"consecutiveMeasurement"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataAtrialFibrillationDetectionFlagKey]                          forKey:@"afib"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataIrregularHeartBeatCountKey]                                  forKey:@"irregularHBCount"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataMeasurementModeKey]                                          forKey:@"measurementMode"];
        
        // Set Device Information
        [bpInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [bpInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]]   forKey:@"displayName"];
        [bpInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]]  forKey:@"deviceIdentity"];
        [bpInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey]                               forKey:@"category"];
        
        NSError *error;
        if (![context save:&error]) {
            
        }
    }
}

- (void)saveDeviceDataHistory:(NSMutableDictionary *)deviceInfo {
    if (!deviceInfo) {
        // If device information is invalid, do nothing or perform error handling
        return;
    }
    
    NSString *localName = [self localName];
    NSString *displayName = [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey];
    NSString *category = [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey];
    NSString *identifier = [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceIdentifierKey];
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *context = [appDel managedObjectContext];
    // 1. Create a fetch request to retrieve device information
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DeviceDataHistory"];
    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (results.count == 0) {
        // Add initial value if data does not exist
        NSManagedObject *initialData = [NSEntityDescription insertNewObjectForEntityForName:@"DeviceDataHistory" inManagedObjectContext:context];
        
        [initialData setValue:localName forKey:@"localName"];
        [initialData setValue:displayName forKey:@"displayName"];
        [initialData setValue:category forKey:@"category"];
        [initialData setValue:identifier forKey:IdentifierKey];
        
        // keep
        if (![context save:&error]) {
            NSLog(@"Failed to save initial value: %@", [error localizedDescription]);
        }
    }else{
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName ==[c] %@", localName];
        
        // 2. Check for duplicates
        
        NSError *fetchError;
        NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&fetchError];
        
        if (fetchError) {
            // You can do error handling
            return;
        }
        
        if (fetchedObjects.count == 0) {
            // 3. Save only if there are no duplicates
            NSManagedObject *poInfo = [NSEntityDescription insertNewObjectForEntityForName:@"DeviceDataHistory" inManagedObjectContext:context];
            [poInfo setValue:localName forKey:@"localName"];
            [poInfo setValue:displayName forKey:@"displayName"];
            [poInfo setValue:category forKey:@"category"];
            [poInfo setValue:identifier forKey:IdentifierKey];
            
            
            NSError *saveError;
            if (![context save:&saveError]) {
                // You can do error handling
            }
        }
    }
}

- (void)saveActivityDataToDB:(NSMutableDictionary *)data withDeviceInfo:(NSMutableDictionary *)deviceInfo withMainTable:(NSString *)mainTable withSubTable:(NSString *)subTable withType:(NSString *)type {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    NSManagedObject *stepInfo = [NSEntityDescription
                                 insertNewObjectForEntityForName:mainTable
                                 inManagedObjectContext:context];
    
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataStartDateKey]] forKey:@"startDate"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataMeasurementKey]] forKey:@"measurement"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataSequenceKey]] forKey:@"sequence"];
    [stepInfo setValue:type forKey:@"type"];
    
    
    // Set Device Information
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
    [stepInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
    
    NSError *error;
    if ([context save:&error]) {
        
        NSManagedObjectContext *dividedContext = [appDel managedObjectContext];
        
        for (NSMutableDictionary *dividedData in [data objectForKey:OMRONActivityDataDividedDataKey]) {
            
            NSManagedObject *stepDividedInfo = [NSEntityDescription
                                                insertNewObjectForEntityForName:subTable
                                                inManagedObjectContext:dividedContext];
            
            [stepDividedInfo setValue:[NSString stringWithFormat:@"%@", [dividedData valueForKey:OMRONActivityDividedDataMeasurementKey]] forKey:@"measurement"];
            [stepDividedInfo setValue:[NSString stringWithFormat:@"%@", [dividedData valueForKey:OMRONActivityDividedDataStartDateKey]] forKey:@"startDate"];
            [stepDividedInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataSequenceKey]] forKey:@"sequence"];
            [stepDividedInfo setValue:type forKey:@"type"];
            
            [stepDividedInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
            
            NSError *errorDivided;
            if (![dividedContext save:&errorDivided]) {
                
                ILogMethodLine(@"Error Saving Divided Data");
            }
        }
    }else {
        
        ILogMethodLine(@"Error Saving Activity Data");
    }
}

- (void)saveSleepDataToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo withMainTable:(NSString *)mainTable {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *sleepData in dataList) {
        
        NSManagedObject *sleepInfo = [NSEntityDescription
                                      insertNewObjectForEntityForName:mainTable
                                      inManagedObjectContext:context];
        
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepDataStartDateKey]] forKey:@"startDate"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepDataEndDateKey]] forKey:@"endDate"];
        
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepTimeInBedKey]] forKey:@"timeInBed"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepSleepOnsetTimeKey]] forKey:@"onSetTime"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepWakeTimeKey]] forKey:@"wakeTime"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepTotalSleepTimeKey]] forKey:@"totalSleepTime"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepSleepEfficiencyKey]] forKey:@"efficiency"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepArousalDuringSleepTimeKey]] forKey:@"arousalDuringSleepTime"];
        
        NSError *error1;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[sleepData valueForKey:OMRONSleepBodyMotionLevelKey] options:NSJSONWritingPrettyPrinted error:&error1];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", jsonString] forKey:@"bodyMotionLevel"];
        
        // Set Device Information
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [sleepInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        
        NSError *error;
        if ([context save:&error]) {
            
            
        }else {
            
            ILogMethodLine(@"Error Saving Sleep Data");
        }
    }
}

- (void)saveRecordsDataToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *recordData in dataList) {
        
        NSManagedObject *recordInfo = [NSEntityDescription
                                       insertNewObjectForEntityForName:@"RecordData"
                                       inManagedObjectContext:context];
        
        [recordInfo setValue:[NSString stringWithFormat:@"%@", [recordData valueForKey:OMRONRecordDataDateKey]] forKey:@"startDate"];
        
        // Set Device Information
        [recordInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [recordInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [recordInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [recordInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        
        NSError *error;
        if ([context save:&error]) {
            
        }else {
            
            ILogMethodLine(@"Error Saving Activity Records Data");
        }
    }
}

#pragma mark - CoreBluetooth Notifications

- (void)centralManagerDidUpdateStateNotification:(NSNotification *)aNotification {
    
    OMRONBLEBluetoothState bluetoothState = (OMRONBLEBluetoothState)[aNotification.object unsignedIntegerValue] ;
    
    if(bluetoothState == OMRONBLEBluetoothStateOn) {
        ILogMethodLine(@"%@",  @"Bluetooth is currently powered on.");
    }else if(bluetoothState == OMRONBLEBluetoothStateOff) {
        ILogMethodLine(@"%@",  @"Bluetooth is currently powered off.");
    }else if(bluetoothState == OMRONBLEBluetoothStateUnknown) {
        ILogMethodLine(@"%@",  @"Bluetooth is in unknown state");
    }
}

- (void)peripheralDisconnected {
    
    ILogMethodLine(@"Omron Peripheral Disconnected");
}

- (void)setConnectionStateNotifications {
    
    [[OmronPeripheralManager sharedManager] onConnectStateChangeWithCompletionBlock:^(int state) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *status = @"-";
            
            if (state == OMRONBLEConnectionStateConnecting) {
                isConnect = YES;
                status = @"Connecting...";
            } else if (state == OMRONBLEConnectionStateConnected) {
                status = @"Connected";
            } else if (state == OMRONBLEConnectionStateDisconnecting) {
                isConnect = NO;
                status = @"Disconnecting...";
            } else if (state == OMRONBLEConnectionStateDisconnect) {
                status = @"Disconnected";
                self.searching.hidden = YES;
                self.transferButton.enabled = YES;
                self.transferButton.backgroundColor = [self getCustomColor];
                self.btnReadingList.enabled = YES;
            }
            
            self.lblStatus.text = status;
        });
    }];
}

- (void)onPeriodicNotifications {
    
    [[OmronPeripheralManager sharedManager] onPeriodicWithCompletionBlock:^{
        
        ILogMethodLine(@"Periodic call from device");
    }];
}

#pragma mark - Navigations and actions

- (IBAction)readingListButtonPressed:(id)sender {
    
    if(localPeripheral) {
        
        [localPeripheral getDeviceInformationWithCompletionBlock:^(NSMutableDictionary *deviceInfo, NSError *error) {
            
            ILogMethodLine(@"Device Information - %@", deviceInfo);
            
            NSMutableDictionary *currentDevice = [[NSMutableDictionary alloc] init];
            [currentDevice setValue:[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] forKey:LocalNameKey];
            [currentDevice setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelNameKey] forKey:OMRONBLEConfigDeviceModelNameKey];
            [currentDevice setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:OMRONBLEConfigDeviceCategoryKey];
            [currentDevice setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceIdentifierKey] forKey:OMRONBLEConfigDeviceIdentifierKey];
            
            if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
                
                // Blood Pressure Device
                BPReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPReadingsViewController"];
                controller.selectedDevice = currentDevice;
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }else if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
                
                // Blood Pressure Device
                VitalOptionsTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"VitalOptionsTableViewController"];
                controller.selectedDevice = currentDevice;
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }
            
        }];
    }
}

- (IBAction)settingsButtonPressed:(id)sender {
    
    ReminderListTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ReminderListTableViewController"];
    controller.selectedPeripheral = localPeripheral;
    controller.filterDeviceModel = self.filterDeviceModel;
    controller.settingsModel = self.settingsModel;
    
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Settings update for Connectivity library

- (void)updateSettings {
    
    OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
    
    // Filter device to scan and connect (optional)
    if([self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIDKey] && [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]) {
        
        NSMutableArray *filterDevices = [[NSMutableArray alloc] init];
        
        // New Supported Format - Add entire data model to filter list
        [filterDevices addObject:self.filterDeviceModel];
        
        peripheralConfig.deviceFilters = filterDevices;// Filter Devices
    }
    
    // Set Scan timeout interval (optional)
    peripheralConfig.timeoutInterval = 30; // Seconds
    
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] != OMRONBLEDeviceCategoryActivity) {
        peripheralConfig.enableAllDataRead = YES;
    }
    
    NSMutableArray *deviceSettigs = [[NSMutableArray alloc] init];
    
    // Set Personal Settings in Configuration (mandatory for Activity devices)
    if([[self.settingsModel allKeys] count] > 1 ) {
        
        ILogMethodLine(@"Settings Model - %@", self.settingsModel);
        
        NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : self.settingsModel[@"personalHeight"],
                                    OMRONDevicePersonalSettingsUserWeightKey : self.settingsModel[@"personalWeight"],
                                    OMRONDevicePersonalSettingsUserStrideKey : self.settingsModel[@"personalStride"],
                                    OMRONDevicePersonalSettingsTargetStepsKey : @"1000",
                                    OMRONDevicePersonalSettingsTargetSleepKey : @"600"
        };
        
        NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
        [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
        
        
        // Test Functions
        // Time Format
        NSDictionary *timeFormatSettings = @{ OMRONDeviceTimeSettingsFormatKey : @(OMRONDeviceTimeFormat24Hour) };
        NSMutableDictionary *timeSettings = [[NSMutableDictionary alloc] init];
        [timeSettings setObject:timeFormatSettings forKey:OMRONDeviceTimeSettingsKey];
        
        // Date Format
        NSDictionary *dateFormatSettings = @{ OMRONDeviceDateSettingsFormatKey : @(OMRONDeviceDateFormatMonthDay) };
        NSMutableDictionary *dateSettings = [[NSMutableDictionary alloc] init];
        [dateSettings setObject:dateFormatSettings forKey:OMRONDeviceDateSettingsKey];
        
        // Distance Format
        NSDictionary *distanceFormatSettings = @{ OMRONDeviceDistanceSettingsUnitKey : @(OMRONDeviceDistanceUnitKilometer) };
        NSMutableDictionary *distanceSettings = [[NSMutableDictionary alloc] init];
        [distanceSettings setObject:distanceFormatSettings forKey:OMRONDeviceDistanceSettingsKey];
        
        // Sleep Settings
        // TODO: Values to test
        NSDictionary *sleepTimeSettings = @{ OMRONDeviceSleepSettingsAutomaticKey: @(OMRONDeviceSleepAutomaticOff),
                                             OMRONDeviceSleepSettingsAutomaticStartTimeKey : @"4",
                                             OMRONDeviceSleepSettingsAutomaticStopTimeKey : @"9"
        };
        NSMutableDictionary *sleepSettings = [[NSMutableDictionary alloc] init];
        [sleepSettings setObject:sleepTimeSettings forKey:OMRONDeviceSleepSettingsKey];
        
        // Alarm Settings
        
        // Alarm1 Time
        NSMutableDictionary *alarmTime1 = [[NSMutableDictionary alloc] init];
        [alarmTime1 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime1 setValue:@"54" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm1 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays1 = [[NSMutableDictionary alloc] init];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm1 = [[NSMutableDictionary alloc] init];
        [alarm1 setObject: alarmDays1 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm1 setObject: alarmTime1 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm1 setValue:@(OMRONDeviceAlarmTypeMeasure) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        // Alarm2 Time
        NSMutableDictionary *alarmTime2 = [[NSMutableDictionary alloc] init];
        [alarmTime2 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime2 setValue:@"56" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm2 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays2 = [[NSMutableDictionary alloc] init];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm2 = [[NSMutableDictionary alloc] init];
        [alarm2 setObject: alarmDays2 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm2 setObject: alarmTime2 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm2 setValue:@(OMRONDeviceAlarmTypeNormal) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        
        // Alarm3 Time
        NSMutableDictionary *alarmTime3 = [[NSMutableDictionary alloc] init];
        [alarmTime3 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime3 setValue:@"58" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm3 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays3 = [[NSMutableDictionary alloc] init];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm3 = [[NSMutableDictionary alloc] init];
        [alarm3 setObject: alarmDays3 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm3 setObject: alarmTime3 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm3 setValue:@(OMRONDeviceAlarmTypeMedication) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        // Add Alarm1, Alarm2, Alarm3 to List
        NSMutableArray *alarms = [[NSMutableArray alloc] init];
        [alarms addObject: alarm1];
        [alarms addObject: alarm2];
        [alarms addObject: alarm3];
        
        NSMutableDictionary *alarmSettings = [[NSMutableDictionary alloc] init];
        [alarmSettings setObject:alarms forKey:OMRONDeviceAlarmSettingsKey];
        
        NSMutableArray *notificationEnabledList = [[NSMutableArray alloc] init];
        [notificationEnabledList addObject:@"com.google.Gmail"];
        [notificationEnabledList addObject:@"com.apple.mobilemail"];
        [notificationEnabledList addObject:@"com.apple.mobilephone"];
        [notificationEnabledList addObject:@"com.apple.MobileSMS"];
        
        NSMutableDictionary *notificationSettings = [[NSMutableDictionary alloc] init];
        [notificationSettings setObject:notificationEnabledList forKey:OMRONDeviceNotificationSettingsKey];
        
        // Notification enable settings
        NSDictionary *notificationEnableSettings = @{ OMRONDeviceNotificationStatusKey : @(OMRONDeviceNotificationStatusOff) };
        NSMutableDictionary *notificationSettingsEnable = [[NSMutableDictionary alloc] init];
        [notificationSettingsEnable setObject:notificationEnableSettings forKey:OMRONDeviceNotificationEnableSettingsKey];
        
        
        [deviceSettigs addObject:personalSettings];
        [deviceSettigs addObject:notificationSettingsEnable];
        [deviceSettigs addObject:timeSettings];
        [deviceSettigs addObject:dateSettings];
        [deviceSettigs addObject:distanceSettings];
        [deviceSettigs addObject:sleepSettings];
        [deviceSettigs addObject:alarmSettings];
        [deviceSettigs addObject:notificationSettings];
        
        peripheralConfig.deviceSettings = deviceSettigs;
    }
    
    peripheralConfig.deviceSettings = deviceSettigs;
    
    
    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
    // Set Configuration to New Configuration (mandatory to set configuration)
    [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:peripheralConfig];
}

- (void)getActivitySettings:(NSMutableArray **)deviceSettings {
    
    // Activity
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
        
        // Set Personal Settings in Configuration (mandatory for Activity devices)
        if([[self.settingsModel allKeys] count] > 1 ) {
            
            ILogMethodLine(@"Settings Model - %@", self.settingsModel);
            
            NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : self.settingsModel[@"personalHeight"],
                                        OMRONDevicePersonalSettingsUserWeightKey : self.settingsModel[@"personalWeight"],
                                        OMRONDevicePersonalSettingsUserStrideKey : self.settingsModel[@"personalStride"],
                                        OMRONDevicePersonalSettingsTargetStepsKey : @"1000",
                                        OMRONDevicePersonalSettingsTargetSleepKey : @"420"
            };
            
            NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
            [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
            
            
            // Test Functions
            // Time Format
            NSDictionary *timeFormatSettings = @{ OMRONDeviceTimeSettingsFormatKey : @(OMRONDeviceTimeFormat12Hour) };
            NSMutableDictionary *timeSettings = [[NSMutableDictionary alloc] init];
            [timeSettings setObject:timeFormatSettings forKey:OMRONDeviceTimeSettingsKey];
            
            // Date Format
            NSDictionary *dateFormatSettings = @{ OMRONDeviceDateSettingsFormatKey : @(OMRONDeviceDateFormatDayMonth) };
            NSMutableDictionary *dateSettings = [[NSMutableDictionary alloc] init];
            [dateSettings setObject:dateFormatSettings forKey:OMRONDeviceDateSettingsKey];
            
            // Distance Format
            NSDictionary *distanceFormatSettings = @{ OMRONDeviceDistanceSettingsUnitKey : @(OMRONDeviceDistanceUnitMile) };
            NSMutableDictionary *distanceSettings = [[NSMutableDictionary alloc] init];
            [distanceSettings setObject:distanceFormatSettings forKey:OMRONDeviceDistanceSettingsKey];
            
            // Sleep Settings
            // TODO: Values to test
            NSDictionary *sleepTimeSettings = @{ OMRONDeviceSleepSettingsAutomaticKey: @(OMRONDeviceSleepAutomaticOff),
                                                 OMRONDeviceSleepSettingsAutomaticStartTimeKey : @"3",
                                                 OMRONDeviceSleepSettingsAutomaticStopTimeKey : @"20"
            };
            NSMutableDictionary *sleepSettings = [[NSMutableDictionary alloc] init];
            [sleepSettings setObject:sleepTimeSettings forKey:OMRONDeviceSleepSettingsKey];
            
            // Alarm Settings
            
            // Alarm1 Time
            NSMutableDictionary *alarmTime1 = [[NSMutableDictionary alloc] init];
            [alarmTime1 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
            [alarmTime1 setValue:@"54" forKey:OMRONDeviceAlarmSettingsMinuteKey];
            // Alarm1 Days (SUN-SAT)
            // Enable – 1, Disable - 0
            NSMutableDictionary *alarmDays1 = [[NSMutableDictionary alloc] init];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
            // Set Alarm and Time Settings
            NSMutableDictionary *alarm1 = [[NSMutableDictionary alloc] init];
            [alarm1 setObject: alarmDays1 forKey: OMRONDeviceAlarmSettingsDaysKey];
            [alarm1 setObject: alarmTime1 forKey: OMRONDeviceAlarmSettingsTimeKey];
            [alarm1 setValue:@(OMRONDeviceAlarmTypeMeasure) forKey: OMRONDeviceAlarmSettingsTypeKey];
            
            // Alarm2 Time
            NSMutableDictionary *alarmTime2 = [[NSMutableDictionary alloc] init];
            [alarmTime2 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
            [alarmTime2 setValue:@"56" forKey:OMRONDeviceAlarmSettingsMinuteKey];
            // Alarm2 Days (SUN-SAT)
            // Enable – 1, Disable - 0
            NSMutableDictionary *alarmDays2 = [[NSMutableDictionary alloc] init];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
            // Set Alarm and Time Settings
            NSMutableDictionary *alarm2 = [[NSMutableDictionary alloc] init];
            [alarm2 setObject: alarmDays2 forKey: OMRONDeviceAlarmSettingsDaysKey];
            [alarm2 setObject: alarmTime2 forKey: OMRONDeviceAlarmSettingsTimeKey];
            [alarm2 setValue:@(OMRONDeviceAlarmTypeNormal) forKey: OMRONDeviceAlarmSettingsTypeKey];
            
            
            // Alarm3 Time
            NSMutableDictionary *alarmTime3 = [[NSMutableDictionary alloc] init];
            [alarmTime3 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
            [alarmTime3 setValue:@"58" forKey:OMRONDeviceAlarmSettingsMinuteKey];
            // Alarm3 Days (SUN-SAT)
            // Enable – 1, Disable - 0
            NSMutableDictionary *alarmDays3 = [[NSMutableDictionary alloc] init];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
            // Set Alarm and Time Settings
            NSMutableDictionary *alarm3 = [[NSMutableDictionary alloc] init];
            [alarm3 setObject: alarmDays3 forKey: OMRONDeviceAlarmSettingsDaysKey];
            [alarm3 setObject: alarmTime3 forKey: OMRONDeviceAlarmSettingsTimeKey];
            [alarm3 setValue:@(OMRONDeviceAlarmTypeMedication) forKey: OMRONDeviceAlarmSettingsTypeKey];
            
            // Add Alarm1, Alarm2, Alarm3 to List
            NSMutableArray *alarms = [[NSMutableArray alloc] init];
            [alarms addObject: alarm1];
            [alarms addObject: alarm2];
            [alarms addObject: alarm3];
            
            NSMutableDictionary *alarmSettings = [[NSMutableDictionary alloc] init];
            [alarmSettings setObject:alarms forKey:OMRONDeviceAlarmSettingsKey];
            
            NSMutableArray *notificationEnabledList = [[NSMutableArray alloc] init];
            [notificationEnabledList addObject:@"com.google.Gmail"];
            [notificationEnabledList addObject:@"com.apple.mobilemail"];
            [notificationEnabledList addObject:@"com.apple.mobilephone"];
            [notificationEnabledList addObject:@"com.apple.MobileSMS"];
            [notificationEnabledList addObject:@"com.omronhealthcare.connectivitylibrary"];
            
            NSMutableDictionary *notificationSettings = [[NSMutableDictionary alloc] init];
            [notificationSettings setObject:notificationEnabledList forKey:OMRONDeviceNotificationSettingsKey];
            
            // Notification enable settings
            NSDictionary *notificationEnableSettings = @{ OMRONDeviceNotificationStatusKey : @(OMRONDeviceNotificationStatusOn) };
            NSMutableDictionary *notificationSettingsEnable = [[NSMutableDictionary alloc] init];
            [notificationSettingsEnable setObject:notificationEnableSettings forKey:OMRONDeviceNotificationEnableSettingsKey];
            
            [*deviceSettings addObject:personalSettings];
            [*deviceSettings addObject:notificationSettingsEnable];
            [*deviceSettings addObject:notificationSettings];
            
            [*deviceSettings addObject:timeSettings];
            [*deviceSettings addObject:dateSettings];
            [*deviceSettings addObject:distanceSettings];
            [*deviceSettings addObject:sleepSettings];
            [*deviceSettings addObject:alarmSettings];
        }
    }
}

- (void)getScanSettings:(NSMutableArray **)deviceSettings withPairing:(BOOL)pairing{
    NSDictionary *scanModeSettings =
    @{ OMRONDeviceScanSettingsModeKey : pairing ? @(OMRONDeviceScanSettingsModePairing) : @(OMRONDeviceScanSettingsModeMismatchSequence)};
    BOOL addFlag = YES;
    for (NSDictionary *settings in *deviceSettings) {
        if ([settings objectForKey:OMRONDeviceScanSettingsKey]) {
            [settings setValue:scanModeSettings forKey:OMRONDeviceScanSettingsKey];
            addFlag = NO;
            break;
        }
    }
    if (addFlag) {
        NSMutableDictionary *scanSettings = [[NSMutableDictionary alloc] init];
        [scanSettings setObject:scanModeSettings forKey:OMRONDeviceScanSettingsKey];
        [*deviceSettings addObject:scanSettings];
    }
}

#pragma mark - Utility UI Functions

- (void)updateUIWithVitalData:(NSMutableDictionary *)vitalData{
    
    self.lblSysUnit.text = @"mmHg";
    self.lblDiaUnit.text = @"mmHg";
    self.lblPulseUnit.text = @"bpm";
    
    // Set display unit
    self.lblSysUnit.hidden = NO;
    self.lblDiaUnit.hidden = NO;
    self.lblPulseUnit.hidden = NO;
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[vitalData valueForKey:OMRONVitalDataMeasurementStartDateKey] doubleValue]];
    self.lblTimeStamp.text = [self getDateTime:date];
    self.lblSystolic.text =  [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONVitalDataSystolicKey]];
    self.lblDiastolic.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONVitalDataDiastolicKey]];
    self.lblPulseRate.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONVitalDataPulseKey]];
    
    self.lblUserSelected.text =  [NSString stringWithFormat:@"User %@", [vitalData valueForKey:OMRONVitalDataUserIdKey]];
    self.lblsequenceNumber.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONVitalDataSequenceKey]];
    
}

- (void)resetLabels {
    
    self.btnReadingList.enabled = YES;
    self.transferButton.enabled = YES;
    self.transferButton.backgroundColor = [self getCustomColor];
    self.searching.hidden = YES;
    self.lblSysUnit.hidden = YES;
    self.lblDiaUnit.hidden = YES;
    self.lblPulseUnit.hidden = YES;
    self.lblSystolic.text =  @"-";
    self.lblDiastolic.text = @"-";
    self.lblPulseRate.text = @"-";
    self.lblUserSelected.text = @"-";
    self.lblTimeStamp.text = @"-";
    self.lblStatus.text = @"-";
    self.lblPeripheralError.text = @"-";
    self.lblPeripheralErrorCode.text = @"-";
    self.lbldateOfBirth.text = @"-";
    self.lblsequenceNumber.text = @"-";
    self.lbltruReadEnable.text = @"-";
    self.lbltruReadInterval.text = @"-";
    self.lblBatteryRemaining.text = @"-";
    
}

- (void)updateLocalPeripheral:(OmronPeripheral *)peripheral {
    localPeripheral = peripheral;
}

- (void)configureLabelVisibilyty {
#ifdef OMRON_DEVTEST
    self.lbltruReadEnable.hidden = NO;
    self.lbltruReadInterval.hidden = NO;
    self.lblTruReadEnable.hidden = NO;
    self.lblTruReadInterval.hidden = NO;
    self.lblsequenceNumber.hidden = NO;
    self.lblSequenceNumberTitle.hidden = NO;
#else
    self.lbltruReadEnable.hidden = YES;
    self.lbltruReadInterval.hidden = YES;
    self.lblTruReadEnable.hidden = YES;
    self.lblTruReadInterval.hidden = YES;
    self.lblsequenceNumber.hidden = YES;
    self.lblSequenceNumberTitle.hidden = YES;
#endif
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.scrollView flashScrollIndicators];
}

- (void)getPersonalSettings:(NSMutableArray **)deviceSettings {
    NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
    // Get data
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PersonalData" inManagedObjectContext:managedContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PersonalData"];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects) {
        
        NSString *originalString = [object valueForKey:DateOfBirthKey];
        
        NSString *dateOfBirth = originalString;
        
        NSDictionary *bloodPressurePersonalSettings = @{};
        NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserDateOfBirthKey : dateOfBirth,
                                    OMRONDevicePersonalSettingsBloodPressureKey : bloodPressurePersonalSettings
        };
        [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
        
    }
    
    [*deviceSettings addObject:personalSettings];
}

- (void) updateUIWithVitalDeviceInfomation:(NSMutableDictionary *)DeviceSettingsData{
    NSString *dateOfBirthValue = @"-";
    NSString *batteryRemaining = @"-";
    NSString *truReadEnable = @"-";
    NSString *truReadInterval = @"-";
    for (NSDictionary *settings in DeviceSettingsData) {
        for (NSString* mainKey in settings.allKeys) {
            // Personal Information for device settings
            if([mainKey isEqualToString:OMRONDevicePersonalSettingsKey]) {
                NSMutableDictionary *personalSettings = settings[mainKey];
                for (NSString* userNumberKey in personalSettings) {
                    NSMutableDictionary *userNumberPersonalSettings = personalSettings[userNumberKey];
                    if([userNumberPersonalSettings containsKey:OMRONDevicePersonalSettingsBloodPressureKey]){
                        NSMutableDictionary *deviceBloodPressureTruReadEnable = userNumberPersonalSettings[OMRONDevicePersonalSettingsBloodPressureKey];
                        if([userNumberPersonalSettings containsKey:OMRONDevicePersonalSettingsBloodPressureKey]){
                            NSMutableDictionary *devicePersonalSettingsBloodPressure = userNumberPersonalSettings[OMRONDevicePersonalSettingsBloodPressureKey];
                            if([devicePersonalSettingsBloodPressure containsKey:OMRONDevicePersonalSettingsBloodPressureTruReadEnableKey]){
                                truReadEnable = deviceBloodPressureTruReadEnable[OMRONDevicePersonalSettingsBloodPressureTruReadEnableKey];
                            }
                            if([devicePersonalSettingsBloodPressure containsKey:OMRONDevicePersonalSettingsBloodPressureTruReadIntervalKey]){
                                truReadInterval = deviceBloodPressureTruReadEnable[OMRONDevicePersonalSettingsBloodPressureTruReadIntervalKey];
                            }
                        }
                    }
                    if([userNumberPersonalSettings containsKey:OMRONDevicePersonalSettingsUserDateOfBirthKey]){
                        dateOfBirthValue = userNumberPersonalSettings[OMRONDevicePersonalSettingsUserDateOfBirthKey];
                    }
                }
            }
        }
    }
    
    NSMutableDictionary *deviceInformation = [localPeripheral getDeviceInformation];
    if([deviceInformation containsKey:OMRONDeviceInformationBatteryRemainingKey]){
        batteryRemaining = [NSString stringWithFormat:@"%@%%", deviceInformation[OMRONDeviceInformationBatteryRemainingKey]];
    }
    NSDate *date = [self getDateOfBirthNSDateType:dateOfBirthValue Format:@"yyyyMMdd"];
    dateOfBirthValue = [self getDate:date];
    self.lbldateOfBirth.text = [NSString stringWithFormat:@"%@", dateOfBirthValue];
    self.lbltruReadEnable.text = [NSString stringWithFormat:@"%@", truReadEnable];
    self.lbltruReadInterval.text = [NSString stringWithFormat:@"%@", truReadInterval];
    self.lblBatteryRemaining.text = batteryRemaining;
}
@end
