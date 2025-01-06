//
//  WheezeReadingsViewController.h
//  OmronLibrarySample
//
//  Created by TranThanh Tuan on 2023/03/03.
//  Copyright © 2023 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface WheezeReadingsViewController : BaseViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableDictionary *selectedDevice;

@end

