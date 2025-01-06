//
//  PulseOxymeterViewController.h
//  OmronLibrarySample
//
//  Created by Shohei Tomoe on 2022/10/27.
//  Copyright © 2022 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface PulseOxymeterViewController : BaseViewController

@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;

@property (nonatomic, strong) NSMutableArray *users;

@property (nonatomic, strong) NSString *localName;

@property (nonatomic, strong) OmronPeripheral *omronLocalPeripheral;

- (IBAction)TransferClick:(id)sender;

@end
