//
//  WeightReadingsViewController.h
//  OmronLibrarySample
//
//  Created by Hitesh Bhardwaj on 12/04/19.
//  Copyright © 2019 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface WeightReadingsViewController : BaseViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableDictionary *selectedDevice;

@end
