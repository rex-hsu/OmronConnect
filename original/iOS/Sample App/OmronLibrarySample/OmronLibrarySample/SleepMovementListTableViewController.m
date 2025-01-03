//
//  SleepMovementListTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/6/18.
//  Copyright © 2018 Omron HealthCare Inc. All rights reserved.
//

#import "SleepMovementListTableViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface SleepMovementListTableViewController ()

@end

@implementation SleepMovementListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customNavigationBarTitle:@"Sleep Movement" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.movementList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *currentItem = (NSMutableArray *) [self.movementList objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SleepMovementCell" forIndexPath:indexPath];
    
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:15];
    cell.textLabel.text = [NSString stringWithFormat:@"%@, %@, %@", [currentItem objectAtIndex:OMRONSleepBodyMotionLevelDetailItemOffset], [currentItem objectAtIndex:OMRONSleepBodyMotionLevelDetailItemPeriodTime], [currentItem objectAtIndex:OMRONSleepBodyMotionLevelDetailItemMeasurement]];
    
    return cell;
}

@end
