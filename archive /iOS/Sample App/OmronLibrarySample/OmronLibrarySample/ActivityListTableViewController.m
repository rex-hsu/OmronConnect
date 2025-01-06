//
//  ActivityListTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/28/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "ActivityListTableViewController.h"
#import "AppDelegate.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface ActivityListTableViewController () {
    
    NSMutableArray *listDays;
}

@end

@implementation ActivityListTableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSString *activityType = @"";
    
    if([[self.selectedDevice valueForKey:@"type"] isEqualToString:OMRONActivityWalkingCaloriesPerDay]) {
        activityType = @"Calories";
    }else if([[self.selectedDevice valueForKey:@"type"] isEqualToString:OMRONActivityStepsPerDay]) {
        activityType = @"Steps";
    }else if([[self.selectedDevice valueForKey:@"type"] isEqualToString:OMRONActivityDistancePerDay]) {
        activityType = @"Distance";
    }else if([[self.selectedDevice valueForKey:@"type"] isEqualToString:OMRONActivityAerobicStepsPerDay]) {
        activityType = @"Aerobic Steps";
    }
    
    [self customNavigationBarTitle:activityType withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    [self loadDaysData];
}

- (void)loadDaysData {
    
    listDays = [[NSMutableArray alloc] init];
    listDays = [self retrieveActivityDaysFromDB];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return listDays.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSMutableArray *dividedItems = [[listDays objectAtIndex:section] objectForKey:@"dividedData"];
    
    return dividedItems.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger) section{
    
    NSMutableDictionary *currentItem = [listDays objectAtIndex:section];
    NSString *localDateString = [self dateFromRecordDate:[currentItem valueForKey:@"startDate"]];
    return localDateString;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityItemCell" forIndexPath:indexPath];
    
    NSMutableArray *dividedItems = [[listDays objectAtIndex:indexPath.section] objectForKey:@"dividedData"];
    
    NSMutableDictionary *currentItem = [dividedItems objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:18];
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.text = [NSString stringWithFormat:@"Measurement : %@\n", [currentItem valueForKey:@"measurement"]];
    
    cell.detailTextLabel.text = [self dateFromRecordDate:[currentItem valueForKey:@"startDate"]];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:14];
    
    if([[currentItem valueForKey:@"measurement"] intValue] > 0) {
        cell.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}


- (NSMutableArray *)retrieveActivityDaysFromDB {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"ActivityData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ActivityData"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@ AND type == %@", [self.selectedDevice valueForKey:@"localName"], [self.selectedDevice valueForKey:@"type"]];
    
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *recordDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *vitalData = [[NSMutableDictionary alloc] init];
        [vitalData setValue:[info valueForKey:@"localName"] forKey:@"localName"];
        [vitalData setValue:[info valueForKey:@"startDate"] forKey:@"startDate"];
        [vitalData setValue:[info valueForKey:@"endDate"] forKey:@"endDate"];
        [vitalData setValue:[info valueForKey:@"measurement"] forKey:@"measurement"];
        [vitalData setValue:[info valueForKey:@"type"] forKey:@"type"];
        [vitalData setValue:[info valueForKey:@"sequence"] forKey:@"sequence"];
        
        
        
        NSManagedObjectContext *newManagedContext = [appDel managedObjectContext];
        
        NSEntityDescription *newEntity = [NSEntityDescription
                                          entityForName:@"ActivityDividedData" inManagedObjectContext:managedContext];
        
        NSFetchRequest *newFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ActivityDividedData"];
        
        newFetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@ AND sequence == %@ AND type == %@", [self.selectedDevice valueForKey:@"localName"], [info valueForKey:@"sequence"], [info valueForKey:@"type"]];
        
        
        [newFetchRequest setEntity:newEntity];
        
        NSError *newError;
        NSArray *newFetchedObjects = [newManagedContext executeFetchRequest:newFetchRequest error:&newError];
        
        NSMutableArray *newRecordDataList = [[NSMutableArray alloc] init];
        for (NSManagedObject *newInfo in newFetchedObjects) {
            
            NSMutableDictionary *newVitalData = [[NSMutableDictionary alloc] init];
            
            [newVitalData setValue:[newInfo valueForKey:@"startDate"] forKey:@"startDate"];
            [newVitalData setValue:[newInfo valueForKey:@"measurement"] forKey:@"measurement"];
            [newVitalData setValue:[newInfo valueForKey:@"type"] forKey:@"type"];
            [newVitalData setValue:[newInfo valueForKey:@"sequence"] forKey:@"sequence"];
            
            [newRecordDataList addObject:newVitalData];
        }
        
        
        [vitalData setObject:newRecordDataList forKey:@"dividedData"];
        
        [recordDataList addObject:vitalData];
    }
    
    recordDataList = [[[recordDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    return recordDataList;
    
}

@end
