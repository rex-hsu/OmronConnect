//
//  BPReadingsViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/1/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface BPReadingsViewController : BaseViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableDictionary *selectedDevice;

@end
