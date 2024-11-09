//
//  ReminderAddTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/29/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "ReminderAddTableViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>
#import "OmronLogger.h"
@interface ReminderAddTableViewController () {
    
    NSMutableArray *daysSelectedArray;
}

@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;

- (IBAction)saveButtonPressed:(id)sender;

@end

@implementation ReminderAddTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    daysSelectedArray = [[NSMutableArray alloc] init];
    
    // Customize Navigation Bar
    [self customNavigationBarTitle:@"Add Reminder" withFont:[UIFont fontWithName:@"Courier" size:16]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.row == 2) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDaySundayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDaySundayKey];
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDaySundayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:100];
            prefCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
    }else if(indexPath.row == 3) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayMondayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayMondayKey];
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayMondayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:101];
            prefCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
    }else if(indexPath.row == 4) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayTuesdayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayTuesdayKey];
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayTuesdayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:102];
            prefCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
    }else if(indexPath.row == 5) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayWednesdayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayWednesdayKey];
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayWednesdayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:103];
            prefCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
    }else if(indexPath.row == 6) {
       
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayThursdayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayThursdayKey];
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayThursdayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:104];
            prefCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
    }else if(indexPath.row == 7) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayFridayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayFridayKey];
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayFridayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:105];
            prefCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
    }else if(indexPath.row == 8) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDaySaturdayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDaySaturdayKey];
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDaySaturdayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:106];
            prefCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.row == 2) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDaySundayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDaySundayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:100];
            prefCell.accessoryType = UITableViewCellAccessoryNone;
            
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDaySundayKey];
        }
        
    }else if(indexPath.row == 3) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayMondayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayMondayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:101];
            prefCell.accessoryType = UITableViewCellAccessoryNone;
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayMondayKey];
        }
        
    }else if(indexPath.row == 4) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayTuesdayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayTuesdayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:102];
            prefCell.accessoryType = UITableViewCellAccessoryNone;
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayTuesdayKey];
        }
        
    }else if(indexPath.row == 5) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayWednesdayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayWednesdayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:103];
            prefCell.accessoryType = UITableViewCellAccessoryNone;
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayWednesdayKey];
        }
        
    }else if(indexPath.row == 6) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayThursdayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayThursdayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:104];
            prefCell.accessoryType = UITableViewCellAccessoryNone;
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayThursdayKey];
        }
        
    }else if(indexPath.row == 7) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDayFridayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDayFridayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:105];
            prefCell.accessoryType = UITableViewCellAccessoryNone;
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDayFridayKey];
        }
        
    }else if(indexPath.row == 8) {
        
        if([daysSelectedArray containsObject:OMRONDeviceAlarmSettingsDaySaturdayKey]) {
            [daysSelectedArray removeObject:OMRONDeviceAlarmSettingsDaySaturdayKey];
            
            UITableViewCell *prefCell = [tableView viewWithTag:106];
            prefCell.accessoryType = UITableViewCellAccessoryNone;
        }else {
            [daysSelectedArray addObject:OMRONDeviceAlarmSettingsDaySaturdayKey];
        }
    }
}

- (IBAction)saveButtonPressed:(id)sender {
    
    if([daysSelectedArray count] == 0) {
        return;
    }
    
    NSMutableDictionary *daysEnabled = [[NSMutableDictionary alloc] init];
    for (NSString *day in daysSelectedArray) {
        
        [daysEnabled setValue:[NSNumber numberWithInt:1] forKey:day];
    }
    
    NSArray *allDays = @[
                         OMRONDeviceAlarmSettingsDaySundayKey,
                         OMRONDeviceAlarmSettingsDayMondayKey,
                         OMRONDeviceAlarmSettingsDayTuesdayKey,
                         OMRONDeviceAlarmSettingsDayWednesdayKey,
                         OMRONDeviceAlarmSettingsDayThursdayKey,
                         OMRONDeviceAlarmSettingsDayFridayKey,
                         OMRONDeviceAlarmSettingsDaySaturdayKey
                         ];
    
    for (NSString *eachDay in allDays) {
        
        if(![daysSelectedArray containsObject:eachDay]) {
           [daysEnabled setValue:[NSNumber numberWithInt:0] forKey:eachDay];
        }
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH"];
    NSString *currentReminderTimeHour = [formatter stringFromDate:self.timePicker.date];
    [formatter setDateFormat:@"mm"];
    NSString *currentReminderTimeMin = [formatter stringFromDate:self.timePicker.date];
    
    NSMutableDictionary *timeDict = [[NSMutableDictionary alloc] init];
    [timeDict setValue:currentReminderTimeHour forKey:OMRONDeviceAlarmSettingsHourKey];  // Add Hour in 24 Hr format
    [timeDict setValue:currentReminderTimeMin forKey:OMRONDeviceAlarmSettingsMinuteKey]; // Add Minute
    
    NSMutableDictionary *savedReminder = [[NSMutableDictionary alloc] init];
    [savedReminder setObject:daysEnabled forKey:OMRONDeviceAlarmSettingsDaysKey];        // Add Days enabled
    [savedReminder setObject:timeDict forKey:OMRONDeviceAlarmSettingsTimeKey];           // Add Time HH/mm
    
    NSMutableArray *allList = [[NSMutableArray alloc] init];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"RemindersSaved"]) {
        
        allList = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"RemindersSaved"]];
        
    }
    
    [allList addObject:savedReminder];
    
    [[NSUserDefaults standardUserDefaults] setObject:allList forKey:@"RemindersSaved"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    ILogMethodLine(@"Complete savedReminder - %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"RemindersSaved"]);
    
    UIAlertController *configError = [UIAlertController
                                      alertControllerWithTitle:@""
                                      message:@"Reminder Added Successfully."
                                      preferredStyle:UIAlertControllerStyleAlert];
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"" attributes:titleAttributes];
    [configError setValue:attributedTitle forKey:@"attributedTitle"];
    // Create attributes for message strings
    NSDictionary *messageAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0]
    };
    NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:@"Reminder Added Successfully." attributes:messageAttributes];
    // Apply attributes to messages
    [configError setValue:attributedMessage forKey:@"attributedMessage"];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
        
        [self.navigationController popViewControllerAnimated:YES];
    }];
    
    [configError addAction:okButton];
    [self presentViewController:configError animated:YES completion:nil];
}

@end
