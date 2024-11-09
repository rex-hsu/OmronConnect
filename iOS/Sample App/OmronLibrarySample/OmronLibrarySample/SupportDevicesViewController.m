//
//  Support Devices View Controller.m
//  OmronLibrarySample
//
//  Created by チャンタン on 2023/09/19.
//  Copyright © 2023 Omron HealthCare Inc. All rights reserved.
//

#import "SupportDevicesViewController.h"

@interface SupportDevicesViewController () {
    // Tracks Connected Omron Peripheral
    NSMutableArray *deviceList;
}
@end

@implementation SupportDevicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    deviceList = self.filterDeviceModel;
    [self customNavigationBarTitle:@"Support Devices" withFont:[UIFont fontWithName:@"Courier" size:16]];

}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return deviceList.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return 100.0f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        
    NSMutableDictionary *currentItem = [deviceList objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:12];
    cell.textLabel.text = [currentItem valueForKey:ModelNameKey];

    cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
    cell.detailTextLabel.text = [currentItem valueForKey:IdentifierKey];;

    cell.imageView.image = [UIImage imageNamed:[currentItem valueForKey:ThumbnailKey]];
    
    return cell;
}

@end

