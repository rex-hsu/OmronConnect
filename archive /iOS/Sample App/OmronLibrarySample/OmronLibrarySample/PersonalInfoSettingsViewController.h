//
//  PersonalInfoSettingsViewController.h
//  OmronLibrarySample
//
//  Created by Tran Thanh Tuan on 2023/09/19.
//  Copyright © 2023 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

#define HEIGHT_MIN_VALUE 100
#define HEIGHT_MAX_VALUE 220
#define WEIGHT_MIN_VALUE 10
#define WEIGHT_MAX_VALUE 250
#define STRIDE_MIN_VALUE 30
#define STRIDE_MAX_VALUE 120

@interface PersonalInfoSettingsViewController : BaseViewController
@property (weak, nonatomic) IBOutlet UITextField *dateOfBirthField;
@property (weak, nonatomic) IBOutlet UITextField *heightField;
@property (weak, nonatomic) IBOutlet UITextField *weightField;
@property (weak, nonatomic) IBOutlet UITextField *strideField;

@end
