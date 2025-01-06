//
//  BPViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface BPViewController : BaseViewController

@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;

@property (nonatomic, strong) NSMutableDictionary *settingsModel;

@property (nonatomic, strong) NSMutableArray *users;

@property (nonatomic, strong) NSString *localName;

@property (nonatomic, strong) OmronPeripheral *omronLocalPeripheral;

- (IBAction)TransferClick:(id)sender;

@end
