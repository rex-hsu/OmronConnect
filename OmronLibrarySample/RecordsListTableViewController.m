//
//  RecordsListTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/28/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "RecordsListTableViewController.h"
#import "AppDelegate.h"

@interface RecordsListTableViewController () {
    
    NSMutableArray *recordsList;
}

@end

@implementation RecordsListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadRecordings];
    
    // Customize Navigation Bar
    [self customNavigationBarTitle:[NSString stringWithFormat:@"%@ - Records", [self.selectedDevice valueForKey:@"displayName"]] withFont:[UIFont fontWithName:@"Courier" size:16]];
}

- (void)loadRecordings {
    
    recordsList = [[NSMutableArray alloc] init];
    recordsList = [self retrieveRecordingsFromDB];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [recordsList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecordCell" forIndexPath:indexPath];
    
    NSDictionary *currentItem = [recordsList objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:16];
    
    cell.textLabel.text = [self dateFromRecordDate:[currentItem valueForKey:@"startDate"]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - Utility

- (NSMutableArray *)retrieveRecordingsFromDB {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"RecordData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RecordData"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@", [[self.selectedDevice valueForKey:@"localName"] lowercaseString]];
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *recordDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *vitalData = [[NSMutableDictionary alloc] init];
        [vitalData setValue:[info valueForKey:@"startDate"] forKey:@"startDate"];
        [recordDataList addObject:vitalData];
    }
    
    recordDataList = [[[recordDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    return recordDataList;
}

@end
