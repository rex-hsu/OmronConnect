//
//  ReminderListTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/29/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "ReminderListTableViewController.h"
#import "OmronLogger.h"
@interface ReminderListTableViewController () {
    
    NSMutableArray *reminderList;
    UISwitch *timeFormatSwitch;
    UIButton *updateButton;
    UILabel *statusLabel;
}

- (IBAction)addReminderButtonPressed:(id)sender;
- (IBAction)updateDeviceSettingsButtonPressed:(id)sender;

@end

@implementation ReminderListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Customize Navigation Bar
    [self customNavigationBarTitle:@"Settings" withFont:[UIFont fontWithName:@"Courier" size:16]];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    statusLabel.text = @"";
    
    reminderList = [[NSMutableArray alloc] init];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"RemindersSaved"]) {
        
        reminderList = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"RemindersSaved"]];
        
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section == 1)
        return reminderList.count;
    else
        return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0) {
        return 65;
    }else if(indexPath.section == 1) {
        return 56;
    }else if(indexPath.section == 2) {
        return 130;
    }
    
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if(section == 0) {
        return @"Time Format";
    }else if(section == 1) {
        return @"Reminders";
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if(indexPath.section == 0) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FormatCell" forIndexPath:indexPath];
        
        timeFormatSwitch = (UISwitch *) [cell viewWithTag:1000];
        [timeFormatSwitch setOn:NO];
        [timeFormatSwitch addTarget:self action:@selector(timeFormatTogglePressed:) forControlEvents:UIControlEventValueChanged];

        return cell;
        
    }else if(indexPath.section == 1) {
        
        NSMutableDictionary *currentItem = [reminderList objectAtIndex:indexPath.row];
        
        NSMutableDictionary *timeItem = [currentItem objectForKey:OMRONDeviceAlarmSettingsTimeKey];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReminderCell" forIndexPath:indexPath];
        cell.textLabel.font = [UIFont fontWithName:@"Courier" size:18];
        cell.textLabel.text = [NSString stringWithFormat:@"%@:%@", [timeItem valueForKey:OMRONDeviceAlarmSettingsHourKey], [timeItem valueForKey:OMRONDeviceAlarmSettingsMinuteKey]];
        
        
        NSMutableDictionary *daysList = [currentItem objectForKey:OMRONDeviceAlarmSettingsDaysKey];
        NSMutableArray *daysNameList = [[NSMutableArray alloc] init];
        
        if([[daysList valueForKey:OMRONDeviceAlarmSettingsDaySundayKey] intValue] == 1) {
            [daysNameList addObject:@"SUN"];
        }
        
        if([[daysList valueForKey:OMRONDeviceAlarmSettingsDayMondayKey] intValue] == 1) {
            [daysNameList addObject:@"MON"];
        }
        
        if([[daysList valueForKey:OMRONDeviceAlarmSettingsDayTuesdayKey] intValue] == 1) {
            [daysNameList addObject:@"TUE"];
        }
        
        if([[daysList valueForKey:OMRONDeviceAlarmSettingsDayWednesdayKey] intValue] == 1) {
            [daysNameList addObject:@"WED"];
        }
        
        if([[daysList valueForKey:OMRONDeviceAlarmSettingsDayThursdayKey] intValue] == 1) {
            [daysNameList addObject:@"THU"];
        }
        
        if([[daysList valueForKey:OMRONDeviceAlarmSettingsDayFridayKey] intValue] == 1) {
            [daysNameList addObject:@"FRI"];
        }
        
        if([[daysList valueForKey:OMRONDeviceAlarmSettingsDaySaturdayKey] intValue] == 1) {
            [daysNameList addObject:@"SAT"];
        }
        
        cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
        cell.detailTextLabel.text = [daysNameList componentsJoinedByString:@", "];
        
        return cell;
        
    }else {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UpdateCell" forIndexPath:indexPath];
        
        updateButton = (UIButton *)[cell viewWithTag:2000];
        statusLabel = (UILabel *) [cell viewWithTag:3000];
        
        return cell;
    }
    
    return nil;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        NSMutableDictionary *currentItem = [reminderList objectAtIndex:indexPath.row];
        [reminderList removeObject:currentItem];
        
        [[NSUserDefaults standardUserDefaults] setObject:reminderList forKey:@"RemindersSaved"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.tableView reloadData];
    }
}

- (IBAction)addReminderButtonPressed:(id)sender {
    
    // Blood Pressure Device
    ReminderAddTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ReminderAddTableViewController"];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)updateDeviceSettingsButtonPressed:(id)sender {
    
    OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
    
    // Filter device to scan and connect (optional)
    if([self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIDKey] && [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]) {
        
        NSMutableArray *filterDevices = [[NSMutableArray alloc] init];
        
        // New Supported Format - Add entire data model to filter list
        [filterDevices addObject:self.filterDeviceModel];
        
        peripheralConfig.deviceFilters = filterDevices;// Filter Devices
    }
    
    // Set Scan timeout interval (optional)
    peripheralConfig.timeoutInterval = 60; // Seconds
    // Holds settings
    NSMutableArray *deviceSettings = [[NSMutableArray alloc] init];
    // Activity device settings (optional)
    [self getActivitySettings:&deviceSettings];
    
    // Update Reminders in Configuration
    peripheralConfig.deviceSettings = deviceSettings;
    peripheralConfig.enableAllDataRead = NO;
    
    [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:peripheralConfig];
    
    updateButton.enabled = NO;
    statusLabel.text = @"Updating Settings...";

    // Create an OmronPeripheral object for updating device
    OmronPeripheral *peripheral = [[OmronPeripheral alloc] initWithLocalName:self.selectedPeripheral.localName andUUID:self.selectedPeripheral.UUID];

    // Start Updating Device
    [[OmronPeripheralManager sharedManager] updatePeripheral:peripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{

            updateButton.enabled = YES;
            statusLabel.text = @"";

            if(error == nil) {

                [self showAlertWithMessage:@"Device Settings Updated Successfully" withAction:NO];
                
            }else {
                
                [self showAlertWithMessage:error.localizedDescription withAction:NO];
            }
        });
    }];
    
}

- (void)timeFormatTogglePressed:(UISwitch *)sender {
    
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
            NSDictionary *sleepTimeSettings = @{ OMRONDeviceSleepSettingsAutomaticKey: @(OMRONDeviceSleepAutomaticOn),
                                                 OMRONDeviceSleepSettingsAutomaticStartTimeKey : @"3",
                                                 OMRONDeviceSleepSettingsAutomaticStopTimeKey : @"9"
            };
            NSMutableDictionary *sleepSettings = [[NSMutableDictionary alloc] init];
            [sleepSettings setObject:sleepTimeSettings forKey:OMRONDeviceSleepSettingsKey];
            
            
            // Add Reminders
            NSMutableDictionary *alarmSettings = [[NSMutableDictionary alloc] init];
            [alarmSettings setObject:reminderList forKey:OMRONDeviceAlarmSettingsKey];
            ILogMethodLine(@"Alarms Settings - %@", alarmSettings);
            
            // Add Time Format
            NSNumber *format = [NSNumber numberWithInt:OMRONDeviceTimeFormat12Hour];
            if(timeFormatSwitch.isOn) {
                format = [NSNumber numberWithInt:OMRONDeviceTimeFormat24Hour];
            }
            // Time Settings
            NSMutableDictionary *timeFormatSettings = [[NSMutableDictionary alloc] initWithDictionary:@{ OMRONDeviceTimeSettingsFormatKey : format}];
            NSMutableDictionary *timeSettings = [[NSMutableDictionary alloc] init];
            [timeSettings setObject:timeFormatSettings forKey:OMRONDeviceTimeSettingsKey];
            ILogMethodLine(@"Display Settings - %@", timeSettings);
             
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

@end
