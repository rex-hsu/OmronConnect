//
//  VitalOptionsTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/28/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "VitalOptionsTableViewController.h"
#import "AppDelegate.h"
#import "BPViewController.h"
#import "BPReadingsViewController.h"
#import "RecordsListTableViewController.h"
#import "ActivityTypesTableViewController.h"
#import "SleepListTableViewController.h"

@interface VitalOptionsTableViewController ()

@end

@implementation VitalOptionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Customize Navigation Bar
    [self customNavigationBarTitle:@"Vital Data" withFont:[UIFont fontWithName:@"Courier" size:16]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.row == 0) {
        
        ActivityTypesTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ActivityTypesTableViewController"];
        controller.selectedDevice = self.selectedDevice;
        [self.navigationController pushViewController:controller animated:YES];
        
        
    }else if(indexPath.row == 1) {
        
        // Blood Pressure Device
        BPReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPReadingsViewController"];
        controller.selectedDevice = self.selectedDevice;
        
        [self.navigationController pushViewController:controller animated:YES];
        
    }else if(indexPath.row == 2) {
        
        SleepListTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SleepListTableViewController"];
        controller.selectedDevice = self.selectedDevice;
        [self.navigationController pushViewController:controller animated:YES];
        
    }else if(indexPath.row == 3) {
        
        RecordsListTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"RecordsListTableViewController"];
        controller.selectedDevice = self.selectedDevice;
        
        [self.navigationController pushViewController:controller animated:YES];        
    }
    
}

@end
