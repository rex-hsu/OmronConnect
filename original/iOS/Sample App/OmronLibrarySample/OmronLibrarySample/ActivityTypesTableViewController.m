//
//  ActivityTypesTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/28/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "ActivityTypesTableViewController.h"
#import "AppDelegate.h"
#import "ActivityListTableViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface ActivityTypesTableViewController () {
    
    NSMutableArray *activitySleepTypeList;
}

@end

@implementation ActivityTypesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadTypes];
    
    [self customNavigationBarTitle:[NSString stringWithFormat:@"%@ - Activity Types", [self.selectedDevice valueForKey:@"displayName"]] withFont:[UIFont fontWithName:@"Courier" size:16]];
}

- (void)loadTypes {
    
    activitySleepTypeList = [[NSMutableArray alloc] init];
    activitySleepTypeList = [self retrieveActivityTypeFromDB];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return activitySleepTypeList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *currentItem = [activitySleepTypeList objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityTypeCell" forIndexPath:indexPath];
    
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:15];
    NSString *activityType = @"";
    
    if([[currentItem valueForKey:@"type"] isEqualToString:OMRONActivityWalkingCaloriesPerDay]) {
        activityType = @"Calories";
    }else if([[currentItem valueForKey:@"type"] isEqualToString:OMRONActivityStepsPerDay]) {
        activityType = @"Steps";
    }else if([[currentItem valueForKey:@"type"] isEqualToString:OMRONActivityDistancePerDay]) {
        activityType = @"Distance";
    }else if([[currentItem valueForKey:@"type"] isEqualToString:OMRONActivityAerobicStepsPerDay]) {
        activityType = @"Aerobic Steps";
    }
    cell.textLabel.text = activityType;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *currentItem = [activitySleepTypeList objectAtIndex:indexPath.row];
    NSMutableDictionary *updatedDevice = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)self.selectedDevice];
    [updatedDevice setValue:[currentItem valueForKey:@"type"] forKey:@"type"];
    
    ActivityListTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ActivityListTableViewController"];
    controller.selectedDevice = updatedDevice;
    [self.navigationController pushViewController:controller animated:YES];
    
}

- (NSMutableArray *)retrieveActivityTypeFromDB {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"ActivityData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ActivityData"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@", [[self.selectedDevice valueForKey:@"localName"] lowercaseString]];
    fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:[[entity propertiesByName] objectForKey:@"localName"], [[entity propertiesByName] objectForKey:@"type"], nil];
    fetchRequest.returnsDistinctResults = YES;
    fetchRequest.resultType = NSDictionaryResultType;
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *recordDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *vitalData = [[NSMutableDictionary alloc] init];
        [vitalData setValue:[[info valueForKey:@"localName"] lowercaseString] forKey:@"localName"];
        [vitalData setValue:[info valueForKey:@"type"] forKey:@"type"];
        [recordDataList addObject:vitalData];
    }
    
    recordDataList = [[[recordDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    return recordDataList;
}

@end
