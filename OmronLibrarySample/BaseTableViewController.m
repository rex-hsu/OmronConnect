//
//  BaseTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 9/13/20.
//  Copyright © 2020 Omron HealthCare Inc. All rights reserved.
//

#import "BaseTableViewController.h"

@interface BaseTableViewController ()

@end

@implementation BaseTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Customize Navigation Bar

- (void)customNavigationBarTitle:(NSString *)title withFont:(UIFont *)font{
    
    // Creates Title
    UILabel *labelTop = [[UILabel alloc] initWithFrame:CGRectZero];
    labelTop.text = title;
    labelTop.font = font;
    labelTop.textColor = [UIColor colorWithRed:0/255.0 green:114.0/255.0 blue:188.0/255.0 alpha:1.0];
    [labelTop sizeToFit];
    self.navigationItem.titleView = labelTop;
}

- (void)showAlertWithMessage:(NSString *)message withAction:(BOOL)userAction {
    
    UIAlertController *configError = [UIAlertController
                                      alertControllerWithTitle:@"Info"
                                      message:message
                                      preferredStyle:UIAlertControllerStyleAlert];
    // Create attributes for message strings
    NSDictionary *messageAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0]
    };
    NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:message attributes:messageAttributes];
    // Apply attributes to messages
    [configError setValue:attributedMessage forKey:@"attributedMessage"];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
        
        if(userAction) {
            exit(0);
        }
    }];
    
    [configError addAction:okButton];
    [self presentViewController:configError animated:YES completion:nil];
}

- (NSString *)dateFromRecordDate:(NSString *)dateString {
    NSDate *measurementDate = [NSDate dateWithTimeIntervalSince1970:[dateString doubleValue]];
//    NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setTimeZone:timeZone];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss a"];
//    NSString *localDateString = [dateFormatter stringFromDate:measurementDate];
    NSString *localDateString = [self getDateTime:measurementDate];
    return localDateString;
}

- (NSString *)getDateTime:(NSDate *)date{

    NSDateFormatter *formatter;

    formatter = [[NSDateFormatter alloc] init];

    formatter.locale = [NSLocale currentLocale];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;

    NSString *dateString = [formatter stringFromDate:date];

    formatter = [[NSDateFormatter alloc] init];

    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;

    NSString *timeString = [formatter stringFromDate:date];

    return [NSString stringWithFormat:@"%@ %@",dateString,timeString];
}

@end
