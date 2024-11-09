//
//  BaseViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 9/12/20.
//  Copyright © 2020 Omron HealthCare Inc. All rights reserved.
//

#import "BaseViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

#pragma mark - Utility Data Functions

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

- (NSString *)getDate:(NSDate *)date{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale currentLocale];
    formatter.dateStyle = NSDateFormatterShortStyle;
    NSString *dateString = [formatter stringFromDate:date];

    return dateString;
}


- (NSNumber *)roundDoubleNumber:(double)number
                      exponent:(double)exponent {
    double fractionDigitBase = powf(10.0, exponent);
    double roundValue = (roundf(number * fractionDigitBase) / fractionDigitBase) * 100;
    return [[NSNumber alloc] initWithFloat:roundValue];
}



- (NSNumber *)getNumberFromString:(NSString *)numberString {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [formatter numberFromString:numberString];
}




#pragma mark - Audio Permission functions

- (void)requestMicrophonePermission {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (status != AVAuthorizationStatusAuthorized) {
        __weak typeof(self) weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (!granted) {
                [weakSelf showGoToSettingsAlert];
            }
        }];
    }
}

- (void)showGoToSettingsAlert {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Audio Permission is Required", nil)
                                                                        message:NSLocalizedString(@"Please give permissions on the setting screen.", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        // Create an attribute for the title string
        NSDictionary *titleAttributes = @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
        };
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Audio Permission is Required", nil) attributes:titleAttributes];
        [alert setValue:attributedTitle forKey:@"attributedTitle"];
        // Create attributes for message strings
        NSDictionary *messageAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:12.0]
        };
        NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Please give permissions on the setting screen.", nil) attributes:messageAttributes];
        // Apply attributes to messages
        [alert setValue:attributedMessage forKey:@"attributedMessage"];
        UIAlertAction * actionOk = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }];
        
        [alert addAction:actionOk];
        
        UIAlertAction *cancelButton = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction * action) {
        }];
        
        [alert addAction:cancelButton];
        
        [weakSelf presentViewController:alert animated:YES completion:nil];
    });
}

- (NSString *)convertFromNumberToString:(NSNumber *)number {
    // Create a number formatter
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    
    // Automatic locale detection based on the device's current locale
    [formatter setLocale:[NSLocale autoupdatingCurrentLocale]];
    
    // Divide the NSNumber value by 100
    double result = [number doubleValue] / 100;
    
    // Set the maximum fraction digits based on the current locale
    NSInteger maxFractionDigits = [formatter maximumFractionDigits];
    [formatter setMaximumFractionDigits:maxFractionDigits];
    
    // Check if the result is an integer
    if (floor(result) == result) {
        // Show the result as an integer
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        return [formatter stringFromNumber:@(result)];
    } else {
        // Show the result as a decimal with trailing zeros removed
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatter setUsesSignificantDigits:YES];
        [formatter setMinimumFractionDigits:0];
        [formatter setMaximumFractionDigits:maxFractionDigits];
        return [formatter stringFromNumber:@(result)];
    }
}

- (NSNumber *)convertFromStringToNumber:(NSString *)textFieldValue {
    // Create a number formatter
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    
    // Automatic locale detection based on the device's current locale
    [formatter setLocale:[NSLocale autoupdatingCurrentLocale]];
    
    // Convert the string to a NSNumber using the formatter
    NSNumber *number = [formatter numberFromString:textFieldValue];
    
    return number;
}

- (NSString *)limitValueWithDecimal:(NSString *)inputValue minimum:(int)minValue maximum:(int)maxValue {
    
    // Remove spaces, "kg" and "cm"
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s|kg|cm" options:NSRegularExpressionCaseInsensitive error:nil];
    inputValue = [regex stringByReplacingMatchesInString:inputValue options:0 range:NSMakeRange(0, [inputValue length]) withTemplate:@""];
    
    double doubleValue = [inputValue doubleValue];
    if (doubleValue <= (double)minValue) {
        
        return [NSString stringWithFormat:@"%d", minValue];
        
    }
    
    // If doubleValue exceeds the maximum value, set it to the maximum value
    if (doubleValue >= (double)maxValue) {
        
        return [NSString stringWithFormat:@"%d", maxValue];
        
    }
    
    return [self convertFromNumberToString:@(doubleValue * 100)];
    
}

- (UIColor *)getCustomColor {
    UIColor *newColor = [UIColor colorWithRed:0.0/255.0 green:114.0/255.0 blue:187.0/255.0 alpha:1.0];
    return newColor;
}

- (NSDate *)getDateOfBirthNSDateType:(NSString *)dateOfBirth Format:(NSString *)stringDateFormat{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:stringDateFormat];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDate *date = [dateFormatter dateFromString:dateOfBirth];
    return date;
}
@end
