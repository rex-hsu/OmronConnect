//
//  BaseViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 9/12/20.
//  Copyright © 2020 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
NSString * const LocalNameKey = @"localName";
NSString * const ModelNameKey = @"modelName";
NSString * const DateOfBirthKey = @"dateOfBirth";
NSString * const HeightKey = @"height";
NSString * const GenderKey = @"gender";
NSString * const WeightUnitKey = @"weightUnit";
NSString * const WeightKey = @"weight";
NSString * const StrideKey = @"stride";
NSString * const SequenceNumber = @"sequenceNumber";
NSString * const UserNumberKey = @"userNumber";
NSString * const UuidKey = @"uuid";
NSString * const BLEDeviceKey = @"BLE device";
NSString * const SoundWaveDeviceKey = @"Sound wave device";
NSString * const LibraryKey = @"LibraryKey";
NSString * const IdentifierKey = @"identifier";
NSString * const ThumbnailKey = @"thumbnail";

@interface BaseViewController : UIViewController

- (void)showAlertWithMessage:(NSString *)message withAction:(BOOL)action;

- (void)customNavigationBarTitle:(NSString *)title withFont:(UIFont *)font;

- (NSString *)getDateTime:(NSDate *)date;

- (NSString *)getDate:(NSDate *)date;

- (NSNumber *)roundDoubleNumber:(double)number
                      exponent:(double)exponent;

- (NSNumber *)getNumberFromString:(NSString *)numberString;

- (void)requestMicrophonePermission;

- (NSNumber *)convertFromStringToNumber:(NSString *)numberString;

- (NSString *)convertFromNumberToString:(NSNumber *)number;

- (NSString *)limitValueWithDecimal:(NSString *)inputValue minimum:(int)minValue maximum:(int)maxValue;

- (UIColor *)getCustomColor;

- (NSDate *)getDateOfBirthNSDateType:(NSString *)dateOfBirthValue Format:(NSString *) stringDateFormat;
@end

NS_ASSUME_NONNULL_END
