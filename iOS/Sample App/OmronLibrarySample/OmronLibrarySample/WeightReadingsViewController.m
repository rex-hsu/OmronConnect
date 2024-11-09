//
//  WeightReadingsViewController.m
//  OmronLibrarySample
//
//  Created by Hitesh Bhardwaj on 12/04/19.
//  Copyright © 2019 Omron HealthCare Inc. All rights reserved.
//

#import "WeightReadingsViewController.h"
#import "AppDelegate.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface WeightReadingsViewController () {
    
    NSMutableArray *readingsList;
}
@property (weak, nonatomic) IBOutlet UILabel *lblDataCount;



@end

@implementation WeightReadingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadReadings];
    
    [self customNavigationBarTitle:[NSString stringWithFormat:@"History - %@", self.selectedDevice[OMRONBLEConfigDeviceIdentifierKey]] withFont:[UIFont fontWithName:@"Courier" size:16]];
    
}

- (void)loadReadings {
    
    readingsList = [[NSMutableArray alloc] init];
    readingsList = [self retrieveReadingsFromDB];
    
    [self.tableView reloadData];
    
}

#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [readingsList count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 300.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *currentItem = [readingsList objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:14];
    
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[currentItem valueForKey:@"startDate"] doubleValue]];
    NSString *localDateString = [self getDateTime:date];
    
    
    NSString *readingsString =
    [NSString stringWithFormat:@"User : %@\nStart Date : %@\nWeight(Kg) : %@\nBody Fat Level : %@\nBody Fat Percentage : %@\nResting Metabolism : %@\nSkeletal Muscle Percentage : %@\nBMI : %@\nBody Age : %@\nVisceral Fat Level : %@\nVisceral Fat Level Classification: %@\nSkeletal Muscle Level Classification : %@\nBMI Level Classification : %@",
                                [currentItem valueForKey:@"user"],
                                localDateString,
    [self convertDoubleToString:[currentItem valueForKey:@"weight"]],
                                [currentItem valueForKey:@"bodyFatLevelClassification"],
    [self convertDoubleToString:[currentItem valueForKey:@"bodyFatPercentage"]],
                                [currentItem valueForKey:@"restingMetabolism"],
    [self convertDoubleToString:[currentItem valueForKey:@"skeletalMusclePercentage"]],
    [self convertDoubleToString:[currentItem valueForKey:@"bMI"]],
                                [currentItem valueForKey:@"bodyAge"],
                                [currentItem valueForKey:@"visceralFatLevel"],
                                [currentItem valueForKey:@"visceralFatLevelClassification"],
                                [currentItem valueForKey:@"skeletalMuscleLevelClassification"],
                                [currentItem valueForKey:@"bMIMuscleLevelClassification"]];
    
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:readingsString];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:10];
    [attrString addAttribute:NSParagraphStyleAttributeName
                       value:style
                       range:NSMakeRange(0, readingsString.length)];
    cell.textLabel.numberOfLines = 26;
    cell.textLabel.attributedText = attrString;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
    
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteReadingAtIndex:indexPath.row];
    }
}

#pragma mark - Utility

- (void)deleteReadingAtIndex:(NSInteger) index {
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"WeightData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WeightData"];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        
        NSDictionary *currentItem = [readingsList objectAtIndex:index];
        
        if([currentItem[@"startDate"] isEqualToString:[info valueForKey:@"startDate"]]) {
            [managedContext deleteObject:info];
            
            [self loadReadings];
            break;
        }
    }
}

- (NSMutableArray *)retrieveReadingsFromDB {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"WeightData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WeightData"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@", [[self.selectedDevice valueForKey:@"localName"] lowercaseString]];
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *vitalDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *vitalData = [[NSMutableDictionary alloc] init];
        [vitalData setValue:[info valueForKey:@"displayName"]                           forKey:@"displayName"];
        [vitalData setValue:[info valueForKey:@"deviceIdentity"]                        forKey:@"deviceIdentity"];
        [vitalData setValue:[info valueForKey:@"weight"]                                forKey:@"weight"];
        [vitalData setValue:[info valueForKey:@"bodyFatLevelClassification"]            forKey:@"bodyFatLevelClassification"];
        [vitalData setValue:[info valueForKey:@"bodyFatPercentage"]                     forKey:@"bodyFatPercentage"];
        [vitalData setValue:[info valueForKey:@"restingMetabolism"]                     forKey:@"restingMetabolism"];
        [vitalData setValue:[info valueForKey:@"skeletalMusclePercentage"]              forKey:@"skeletalMusclePercentage"];
        [vitalData setValue:[info valueForKey:@"bMI"]                                   forKey:@"bMI"];
        [vitalData setValue:[info valueForKey:@"bodyAge"]                               forKey:@"bodyAge"];
        [vitalData setValue:[info valueForKey:@"visceralFatLevel"]                      forKey:@"visceralFatLevel"];
        [vitalData setValue:[info valueForKey:@"user"]                                  forKey:@"user"];
        [vitalData setValue:[info valueForKey:@"startDate"]                             forKey:@"startDate"];
        [vitalData setValue:[info valueForKey:@"skeletalMuscleLevelClassification"]     forKey:@"skeletalMuscleLevelClassification"];
        [vitalData setValue:[info valueForKey:@"bMIMuscleLevelClassification"]          forKey:@"bMIMuscleLevelClassification"];
        [vitalData setValue:[info valueForKey:@"visceralFatLevelClassification"]        forKey:@"visceralFatLevelClassification"];
        
        [vitalDataList addObject:vitalData];
    }
    
    vitalDataList = [[[vitalDataList reverseObjectEnumerator] allObjects] mutableCopy];
    self.lblDataCount.text = [NSString stringWithFormat:@"Data Count :  %lu",(unsigned long)vitalDataList.count];
    return vitalDataList;
    
}

- (NSString *)convertDoubleToString:(NSNumber *)value withMaximumFractionDigits:(NSUInteger)maxFractionDigits {
    if ([value isKindOfClass:[NSNull class]]) {
        return @"(null)";
    }
    double doubleValue = [value doubleValue];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    numberFormatter.minimumFractionDigits = 0;
    numberFormatter.maximumFractionDigits = maxFractionDigits;
    return [numberFormatter stringFromNumber:@(doubleValue)];
}

- (NSString *)convertDoubleToString:(NSNumber *)value {
    return [self convertDoubleToString:value withMaximumFractionDigits:2];
}

@end
