//
//  ReminderListTableViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/29/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseTableViewController.h"
#import "BPViewController.h"
#import "ReminderAddTableViewController.h"

@interface ReminderListTableViewController : BaseTableViewController

@property (nonatomic, strong) OmronPeripheral *selectedPeripheral;

@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;

@property (nonatomic, strong) NSMutableDictionary *settingsModel;

@end
