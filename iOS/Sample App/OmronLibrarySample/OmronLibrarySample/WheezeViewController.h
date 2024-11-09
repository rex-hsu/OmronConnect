//
//  WheezeViewController.h
//  OmronLibrarySample
//
//  Created by TranThanh Tuan on 2023/03/03.
//  Copyright © 2023 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface WheezeViewController : BaseViewController

@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;
@property (nonatomic, strong) NSString *localName;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) OmronPeripheral *omronLocalPeripheral;
- (IBAction)TransferClick:(id)sender;

@end
