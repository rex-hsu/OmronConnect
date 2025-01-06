//
//  TemperatureRecordingViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/17/21.
//  Copyright © 2021 Omron HealthCare Inc. All rights reserved.
//

#import "BaseViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

NS_ASSUME_NONNULL_BEGIN

@interface TemperatureRecordingViewController : BaseViewController

@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;


@end

NS_ASSUME_NONNULL_END
