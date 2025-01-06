//
//  BaseTableViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 9/13/20.
//  Copyright © 2020 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseTableViewController : UITableViewController

- (void)customNavigationBarTitle:(NSString *)title withFont:(UIFont *)font;

- (void)showAlertWithMessage:(NSString *)message withAction:(BOOL)userAction;

- (NSString *)dateFromRecordDate:(NSString *)dateString;

@end

NS_ASSUME_NONNULL_END
