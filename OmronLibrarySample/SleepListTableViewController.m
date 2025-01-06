//
//  SleepListTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/6/18.
//  Copyright © 2018 Omron HealthCare Inc. All rights reserved.
//

#import "SleepListTableViewController.h"
#import "SleepMovementListTableViewController.h"
#import "AppDelegate.h"


@interface SleepListTableViewController () {
    
    NSMutableArray *readingsList;
}

@end

@implementation SleepListTableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self loadReadings];
    
    [self customNavigationBarTitle:[NSString stringWithFormat:@"%@ - Sleep Data", [self.selectedDevice valueForKey:@"displayName"]] withFont:[UIFont fontWithName:@"Courier" size:16]];
}

- (void)loadReadings {
    
    readingsList = [[NSMutableArray alloc] init];
    readingsList = [self retrieveReadingsFromDB];
    
    [self.tableView reloadData];
    
    [self.tableView setRowHeight:130.0f];
}

- (NSMutableArray *)retrieveReadingsFromDB {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"SleepData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"SleepData"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@", [self.selectedDevice valueForKey:@"localName"]];
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *vitalDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *vitalData = [[NSMutableDictionary alloc] init];
        [vitalData setValue:[info valueForKey:@"startDate"]  forKey:@"startDate"];
        [vitalData setValue:[info valueForKey:@"endDate"] forKey:@"endDate"];
        [vitalData setValue:[info valueForKey:@"timeInBed"] forKey:@"timeInBed"];
        [vitalData setValue:[info valueForKey:@"wakeTime"] forKey:@"wakeTime"];
        [vitalData setValue:[info valueForKey:@"onSetTime"] forKey:@"onSetTime"];
        [vitalData setValue:[info valueForKey:@"totalSleepTime"] forKey:@"totalSleepTime"];
        [vitalData setValue:[info valueForKey:@"efficiency"] forKey:@"efficiency"];
        [vitalData setValue:[info valueForKey:@"arousalDuringSleepTime"] forKey:@"arousalDuringSleepTime"];
        [vitalData setValue:[info valueForKey:@"bodyMotionLevel"] forKey:@"bodyMotionLevel"];
        
        [vitalDataList addObject:vitalData];
    }
    
    vitalDataList = [[[vitalDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    return vitalDataList;
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return readingsList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 280.0f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *currentItem = [readingsList objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:14];
    
    NSString *startTime = [self dateFromRecordDate:[currentItem valueForKey:@"startDate"]];
    NSString *endTime = [self dateFromRecordDate:[currentItem valueForKey:@"endDate"]];
    NSString *timeInBed = [self dateFromRecordDate:[currentItem valueForKey:@"timeInBed"]];
    NSString *onSetTime = [self dateFromRecordDate:[currentItem valueForKey:@"onSetTime"]];
    NSString *wakeTime = [self dateFromRecordDate:[currentItem valueForKey:@"wakeTime"]];
    
    
    NSData* data = [[currentItem valueForKey:@"bodyMotionLevel"] dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *values = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    NSString *tapForMovement = @"";
    if(values.count > 0) {
        tapForMovement = @"Tap for know details on Movement";
    }
    
    NSString *readingsString = [NSString stringWithFormat:@"\nStart Time : %@\nEnd Time : %@\nTime In Bed: %@\nSleep Time: %@\nWake Time : %@\nTotal Sleep Time (min): %@\nEfficiency (percentage) : %@\nArousal Time during Sleep (min) : %@\n\n%@",
                                startTime,
                                endTime,
                                timeInBed,
                                onSetTime,
                                wakeTime,
                                [currentItem valueForKey:@"totalSleepTime"],
                                [currentItem valueForKey:@"efficiency"],
                                [currentItem valueForKey:@"arousalDuringSleepTime"],
                                tapForMovement
                                ];
    
    
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:readingsString];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:10];
    [attrString addAttribute:NSParagraphStyleAttributeName
                       value:style
                       range:NSMakeRange(0, readingsString.length)];
    cell.textLabel.numberOfLines = 15;
    cell.textLabel.attributedText = attrString;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *currentItem = [readingsList objectAtIndex:indexPath.row];
    
    NSData* data = [[currentItem valueForKey:@"bodyMotionLevel"] dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *values = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    if(values.count > 0) {
        
        SleepMovementListTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SleepMovementListTableViewController"];
        controller.movementList = values;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

@end
