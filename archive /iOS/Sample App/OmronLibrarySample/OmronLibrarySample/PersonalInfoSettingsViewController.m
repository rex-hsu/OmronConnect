//
//  PersonalInfoSettingsViewController.m
//  OmronLibrarySample
//
//  Created by Tran Thanh Tuan on 2023/09/19.
//  Copyright © 2023 Omron HealthCare Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PersonalInfoSettingsViewController.h"
#import "DeviceListViewController.h"
#import "AppDelegate.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface PersonalInfoSettingsViewController () <UITextFieldDelegate>{
    
    UIDatePicker *datePickerView;
    
    int selectedFieldForPicker;
    int keyboardHeight;
    
    NSArray *genderArray;
    NSArray *weightUnitArray;
    
    NSNumber *selectWeightUnit;
    NSNumber *selectGender;
    
    NSString *originalString;
    NSString *dateOfBirthString;
    
    BOOL textFieldCheck;
    
}
@property (weak, nonatomic) IBOutlet UIButton *kgRadioButton;
@property (weak, nonatomic) IBOutlet UIButton *lbsRadioButton;
@property (weak, nonatomic) IBOutlet UIButton *maleRadioButton;
@property (weak, nonatomic) IBOutlet UIButton *femaleRadioButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *lblKg;
@property (weak, nonatomic) IBOutlet UILabel *lblLbs;
@property (weak, nonatomic) IBOutlet UILabel *lblMale;
@property (weak, nonatomic) IBOutlet UILabel *lblFemale;
@property (weak, nonatomic) IBOutlet UIView *saveButtonView;
@property (weak, nonatomic) IBOutlet UIView *viewFemale;
@property (weak, nonatomic) IBOutlet UIView *viewMale;
@property (weak, nonatomic) IBOutlet UIView *viewKg;
@property (weak, nonatomic) IBOutlet UIView *viewLbs;
@property (weak, nonatomic) IBOutlet UIView *viewStride;
@property (strong, nonatomic) IBOutlet UIView *mainView;

@end
@implementation PersonalInfoSettingsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self initRadioButton];
    
    [self getPersonalInformationData];
    
    [self setupUI];
    
    // Register notification when keyboard is displayed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
       
    // Register notification when keyboard is hidden
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    self.saveButton.layer.cornerRadius = 5.0; // 5.0 indicates the radius to round
    self.saveButton.layer.masksToBounds = YES;
    
    [self customNavigationBarTitle:@"Personal Settings" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    [self HideKeyboardWhenTouchingScreen];
    
    self.strideField.delegate = self;
    
    [self createTapGesture];
}

- (void)setupUI{
    
    textFieldCheck = true;
    // keyboardHeight initialization
    keyboardHeight = 0;
    
    // tag settings
    self.heightField.tag = 1;
    self.weightField.tag = 2;
    self.strideField.tag = 3;
    
    // Preparation to automatically delete units during input
    self.heightField.delegate = self;
    self.weightField.delegate = self;
    self.strideField.delegate = self;

    self.heightField.keyboardType = UIKeyboardTypeDecimalPad;
    self.weightField.keyboardType = UIKeyboardTypeDecimalPad;
    self.strideField.keyboardType = UIKeyboardTypeDecimalPad;
    
    // UITextField settings with bottom border
    [self setTextFieldBorder:self.dateOfBirthField];
    [self setTextFieldBorder:self.heightField];
    [self setTextFieldBorder:self.weightField];
    [self setTextFieldBorder:self.strideField];
    
    // date picker for date of birth
    datePickerView = [[UIDatePicker alloc] init];
    datePickerView.datePickerMode = UIDatePickerModeDate;
    if (@available(iOS 13.4, *)) {
        datePickerView.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    self.dateOfBirthField.inputView = datePickerView;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *currentDate = [NSDate date];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:0];
    NSDate *maxDate = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
    [comps setYear:-119];
    NSDate *minDate = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
    
    // Set maximum and minimum value ranges
    [datePickerView setMaximumDate:maxDate];
    [datePickerView setMinimumDate:minDate];
    if(![self checkPersonalSettingData]){
        selectWeightUnit = @(OMRONDeviceWeightUnitKg);
        selectGender = @(OMRONDevicePersonalSettingsUserGenderTypeFemale);
        [self setDateOfBirth:@"2000/01/01"];
    }
    NSDate *initialDate = [self getDateOfBirthNSDateType:dateOfBirthString Format:@"yyyy/MM/dd"];
    self.dateOfBirthField.text = [self getDate:initialDate];
    [datePickerView setDate:initialDate animated:NO];
    [datePickerView addTarget:self action:@selector(handleDatePicker:) forControlEvents:UIControlEventValueChanged];
}

- (void)handleDatePicker:(UIDatePicker *)sender {
    // Format date to string using default timezone
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *localDateString = [dateFormatter stringFromDate:[sender date]];
    [self setDateOfBirth:localDateString];
    NSDate *date = [sender date];
    self.dateOfBirthField.text = [self getDate:date];
    
}
- (void)savePersonalInformationDataFirst{
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    NSManagedObject *personalData = [NSEntityDescription
                                     insertNewObjectForEntityForName:@"PersonalData"
                                     inManagedObjectContext:context];
    
    // clear text units
    NSString *originalString = self.heightField.text;
    NSString *targetString = @" cm";
    NSNumber *resultString = [self getNumberFromString:[originalString stringByReplacingOccurrencesOfString:targetString withString:@""]];
    NSNumber *heightNumber = [self roundDoubleNumber:[resultString doubleValue] exponent:2.0];
    
    originalString = self.strideField.text;
    resultString = [self convertFromStringToNumber:[originalString stringByReplacingOccurrencesOfString:targetString withString:@""]];
    NSNumber *strideNumber = [self roundDoubleNumber:[resultString doubleValue] exponent:2.0];
    
    originalString = self.weightField.text;
    targetString = @" kg";
    resultString = [self convertFromStringToNumber:[originalString stringByReplacingOccurrencesOfString:targetString withString:@""]];
    NSNumber *weighNumber = [self roundDoubleNumber:[resultString doubleValue] exponent:2.0];
    // set value
    NSNumber *weightUnitNumber = selectWeightUnit;
    NSNumber *genderNumber = selectGender;
    
    targetString = @"/";

    originalString = [dateOfBirthString stringByReplacingOccurrencesOfString:targetString withString:@""];

    NSString *dateOfBirth = originalString;
    // If conversion to numeric value is successful, save to Core Data
    [personalData setValue:dateOfBirth forKey:DateOfBirthKey];
    [personalData setValue:heightNumber forKey:HeightKey];
    [personalData setValue:weighNumber forKey:WeightKey];
    [personalData setValue:weightUnitNumber forKey:WeightUnitKey];
    [personalData setValue:genderNumber forKey:GenderKey];
    [personalData setValue:strideNumber forKey:StrideKey];
    
    
    // keep
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Unable to save data. error: %@", error);
        
    }
}
#pragma mark - Save Personal Data
- (void)savePersonalInformationData {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *context = [appDel managedObjectContext];
    // Get existing data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonalData"];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (results && results.count > 0) {
        NSString *targetString = @" cm";

        NSManagedObject *existingData = results[0];
        
        NSString *originalString = self.heightField.text;
        NSNumber *resultString = [self convertFromStringToNumber:[originalString stringByReplacingOccurrencesOfString:targetString withString:@""]];
        NSNumber *heightNumber = [self roundDoubleNumber:[resultString doubleValue] exponent:2.0];
        
        originalString = self.strideField.text;
        resultString = [self convertFromStringToNumber:[originalString stringByReplacingOccurrencesOfString:targetString withString:@""]];
        NSNumber *strideNumber = [self roundDoubleNumber:[resultString doubleValue] exponent:2.0];
        
        targetString = @" kg";
        originalString = self.weightField.text;
        resultString = [self convertFromStringToNumber:[originalString stringByReplacingOccurrencesOfString:targetString withString:@""]];
        NSNumber *weighNumber = [self roundDoubleNumber:[resultString doubleValue] exponent:2.0];
        
        targetString = @"/";

        originalString = [dateOfBirthString stringByReplacingOccurrencesOfString:targetString withString:@""];
                
        NSString *dateOfBirth = originalString;
        // Update existing data if conversion to number is successful
        [existingData setValue:dateOfBirth forKey:@"dateOfBirth"];
        [existingData setValue:heightNumber forKey:@"height"];
        [existingData setValue:weighNumber forKey:@"weight"];
        [existingData setValue:selectWeightUnit forKey:@"weightUnit"];
        [existingData setValue:selectGender forKey:@"gender"];
        [existingData setValue:strideNumber forKey:@"stride"];
        
        // keep
        if (![context save:&error]) {
            
            NSLog(@"Unable to update data. error: %@", error);
        }
    } else {
        
        [self savePersonalInformationDataFirst];
        
    }
}
#pragma mark - Display personal information
- (void) getPersonalInformationData{
    
    // Get data
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PersonalData" inManagedObjectContext:managedContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PersonalData"];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects) {
        
        NSString * dateOfBirth = [object valueForKey:@"dateOfBirth"];
        dateOfBirth = [self stringDateString:dateOfBirth];
        dateOfBirthString = dateOfBirth;
        
        self.heightField.text = [NSString stringWithFormat:@"%@ cm",[self convertFromNumberToString : [object valueForKey:@"height"]]];
        
        self.weightField.text = [NSString stringWithFormat:@"%@ kg",[self convertFromNumberToString : [object valueForKey:@"weight"]]];
        
        selectWeightUnit = [object valueForKey:@"weightUnit"];
        [self weightUnitRadioButtonSetting : selectWeightUnit];
        
        selectGender = [object valueForKey:@"gender"];
        [self genderRadioButtonSetting : selectGender];
        
        self.strideField.text = [NSString stringWithFormat:@"%@ cm",[self convertFromNumberToString : [object valueForKey:@"stride"]]];
        
    }
}

- (IBAction)saveData:(id)sender {
    
    [self savePersonalInformationData];
    DeviceListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DeviceListViewController"];
    [self.navigationController pushViewController:controller animated:YES];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder]; // hide keyboard
    return YES;
    
}

#pragma mark - Textfield Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    // Create new string by restricting textField to range
    NSString *limitedValue = @"";
    
    selectedFieldForPicker = (int)textField.tag;
    
    NSString *targetString = @" cm";
    // clear text
    NSString *originalString =@"";
    NSString *resultString =@"";
    
    
    if(selectedFieldForPicker == 1){
        
        limitedValue = [self limitValueWithDecimal:self.weightField.text minimum:WEIGHT_MIN_VALUE maximum:WEIGHT_MAX_VALUE];
        // Set a restricted value to a text field
        self.weightField.text = [NSString stringWithFormat:@"%@ kg",limitedValue];
        
        limitedValue = [self limitValueWithDecimal:self.strideField.text minimum:STRIDE_MIN_VALUE maximum:STRIDE_MAX_VALUE];
        // Set a restricted value to a text field
        self.strideField.text = [NSString stringWithFormat:@"%@ cm",limitedValue];
        
        // clear text
        originalString = self.heightField.text;
        resultString = [originalString stringByReplacingOccurrencesOfString:targetString withString:@""];
        self.heightField.text = resultString;
        
        //add unit
        if ([self.weightField.text rangeOfString:@" kg"].location == NSNotFound) {
            // If "self.weightField.text" does not contain " kg"
            self.weightField.text = [self.weightField.text stringByAppendingString:@" kg"];
        }if ([self.strideField.text rangeOfString:@" cm"].location == NSNotFound) {
            // If "self.strideField.text" does not contain " cm"
            self.strideField.text = [self.strideField.text stringByAppendingString:@" cm"];
        }
    }
    if(selectedFieldForPicker == 2){
        // Create new string by restricting textField to range
        limitedValue = [self limitValueWithDecimal:self.heightField.text minimum:HEIGHT_MIN_VALUE maximum:HEIGHT_MAX_VALUE];
        // Set a restricted value to a text field
        self.heightField.text = [NSString stringWithFormat:@"%@ cm",limitedValue];
        limitedValue = [self limitValueWithDecimal:self.strideField.text minimum:STRIDE_MIN_VALUE maximum:STRIDE_MAX_VALUE];
        // Set a restricted value to a text field
        self.strideField.text = [NSString stringWithFormat:@"%@ cm",limitedValue];
    
        
        originalString = self.weightField.text;
        targetString = @" kg";
        resultString = [originalString stringByReplacingOccurrencesOfString:targetString withString:@""];
        self.weightField.text = resultString;
        //add unit
        if ([self.heightField.text rangeOfString:@" cm"].location == NSNotFound) {
            // If "self.heightField.text" does not contain " cm"
            self.heightField.text = [self.heightField.text stringByAppendingString:@" cm"];
        }if ([self.strideField.text rangeOfString:@" cm"].location == NSNotFound) {
            // If "self.strideField.text" does not contain " cm"
            self.strideField.text = [self.strideField.text stringByAppendingString:@" cm"];
        }
    }
    if(selectedFieldForPicker == 3){
        // Create new string by restricting textField to range
        limitedValue = [self limitValueWithDecimal:self.heightField.text minimum:HEIGHT_MIN_VALUE maximum:HEIGHT_MAX_VALUE];
        // Set a restricted value to a text field
        self.heightField.text = [NSString stringWithFormat:@"%@ cm",limitedValue];
        
        limitedValue = [self limitValueWithDecimal:self.weightField.text minimum:WEIGHT_MIN_VALUE maximum:WEIGHT_MAX_VALUE];
        // Set a restricted value to a text field
        self.weightField.text = [NSString stringWithFormat:@"%@ kg",limitedValue];
        
        
        targetString = @" cm";
        originalString = self.strideField.text;
        resultString = [originalString stringByReplacingOccurrencesOfString:targetString withString:@""];
        self.strideField.text = resultString;
        //add unit
        
        if ([self.heightField.text rangeOfString:@" cm"].location == NSNotFound) {
            // If "self.heightField.text" does not contain " cm"
            self.heightField.text = [self.heightField.text stringByAppendingString:@" cm"];
        }if ([self.weightField.text rangeOfString:@" kg"].location == NSNotFound) {
            // If "self.weightField.text" does not contain " kg"
            self.weightField.text = [self.weightField.text stringByAppendingString:@" kg"];
        }
    }
    
    return true;
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *inputText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString *decimalSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
    if ([inputText isEqualToString:decimalSeparator]) {
        return NO;
    }
    NSArray *components = [inputText componentsSeparatedByString:decimalSeparator];
    if (components.count > 2) {
        return NO;
    }
    if ([components[0] length] > 3) {
        return NO;
    }
    if (components.count == 2) {
        if ([components[1] length] > 2) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Picker View Data Source and Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;  // Or return whatever as you intend
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView
numberOfRowsInComponent:(NSInteger)component {
    return 0;
}

#pragma mark - Radio Button Settings Related

- (IBAction)kgRadioButtonAction:(id)sender {
    self.kgRadioButton.selected = YES;
    self.lbsRadioButton.selected = NO;
    selectWeightUnit = @(OMRONDeviceWeightUnitKg);
}

- (IBAction)lbsRadioButtonAction:(id)sender {
    self.kgRadioButton.selected = NO;
    self.lbsRadioButton.selected = YES;
    selectWeightUnit = @(OMRONDeviceWeightUnitLbs);
}

- (IBAction)maleRadioButtonAction:(id)sender {
    self.maleRadioButton.selected = YES;
    self.femaleRadioButton.selected = NO;
    selectGender = @(OMRONDevicePersonalSettingsUserGenderTypeMale);
}

- (IBAction)femaleRadioButtonAction:(id)sender {
    self.maleRadioButton.selected = NO;
    self.femaleRadioButton.selected = YES;
    selectGender = @(OMRONDevicePersonalSettingsUserGenderTypeFemale);
}

- (void) initRadioButton{
    self.kgRadioButton.selected = YES;
    self.lbsRadioButton.selected = NO;
    self.maleRadioButton.selected = NO;
    self.femaleRadioButton.selected = YES;
}

- (void) weightUnitRadioButtonSetting : (NSNumber*) weightUnitValue{
    if ([weightUnitValue intValue] == OMRONDeviceWeightUnitKg) {
        self.kgRadioButton.selected = YES;
        self.lbsRadioButton.selected = NO;
    } else if ([weightUnitValue intValue] == OMRONDeviceWeightUnitLbs) {
        self.kgRadioButton.selected = NO;
        self.lbsRadioButton.selected = YES;
    } else {
        self.kgRadioButton.selected = YES;
        self.lbsRadioButton.selected = NO;
    }
}

- (void) genderRadioButtonSetting : (NSNumber*) genderUnitValue{
    if ([genderUnitValue intValue] == OMRONDevicePersonalSettingsUserGenderTypeMale) {
        self.maleRadioButton.selected = YES;
        self.femaleRadioButton.selected = NO;
        selectGender = @(OMRONDevicePersonalSettingsUserGenderTypeMale);
    } else if ([genderUnitValue intValue] == OMRONDevicePersonalSettingsUserGenderTypeFemale) {
        self.maleRadioButton.selected = NO;
        self.femaleRadioButton.selected = YES;
        selectGender = @(OMRONDevicePersonalSettingsUserGenderTypeFemale);
    } else {
        self.maleRadioButton.selected = NO;
        self.femaleRadioButton.selected = YES;
        selectGender = @(OMRONDevicePersonalSettingsUserGenderTypeFemale);
    }
}

#pragma mark - Text Field Border Setting

-(void)setTextFieldBorder :(UITextField *)textField{
    
    CALayer *border = [CALayer layer];
    CGFloat borderWidth = 2;
    border.borderColor = [UIColor grayColor].CGColor;
    border.frame = CGRectMake(0, textField.frame.size.height - borderWidth, textField.frame.size.width, textField.frame.size.height);
    border.borderWidth = borderWidth;
    [textField.layer addSublayer:border];
    textField.layer.masksToBounds = YES;
    
}

#pragma mark - Hide Keyboard When Touching Screen

// tap gesture handler
- (void)handleTap:(UITapGestureRecognizer *)sender {
    [self inputValueRangeSetting];
    [self unitInput];
    textFieldCheck = true;
    // Hide keyboard when screen is tapped
    [self.view endEditing:YES];
}

- (void)HideKeyboardWhenTouchingScreen{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (NSString *)stringDateString:(NSString *)string {
    NSString *inputDateString = string; // original date string
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
    [inputDateFormatter setDateFormat:@"yyyyMMdd"];
    [inputDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSDate *date = [inputDateFormatter dateFromString:inputDateString];

    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc] init];
    [outputDateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *outputDateString = [outputDateFormatter stringFromDate:date];

    return outputDateString;
}

- (void) inputValueRangeSetting{
    NSString *textField = @"";
    // Create new string by restricting textField to range
    NSString *limitedValue = @"";
    if(selectedFieldForPicker == 1){
        
        textField = self.heightField.text;
        // Create new string by restricting textField to range
        limitedValue = [self limitValueWithDecimal:textField minimum:HEIGHT_MIN_VALUE maximum:HEIGHT_MAX_VALUE];
        // Set a restricted value to a text field
        self.heightField.text = [NSString stringWithFormat:@"%@ cm",limitedValue];
        
    }if(selectedFieldForPicker == 2){
        
        textField = self.weightField.text;
        // Create new string by restricting textField to range
        limitedValue = [self limitValueWithDecimal:textField minimum:WEIGHT_MIN_VALUE maximum:WEIGHT_MAX_VALUE];
        // Set a restricted value to a text field
        self.weightField.text = [NSString stringWithFormat:@"%@ kg",limitedValue];
        
    }if(selectedFieldForPicker == 3){
        
        textField = self.strideField.text;
        // Create new string by restricting textField to range
        limitedValue = [self limitValueWithDecimal:textField minimum:STRIDE_MIN_VALUE maximum:STRIDE_MAX_VALUE];
        // Set a restricted value to a text field
        self.strideField.text = [NSString stringWithFormat:@"%@ cm",limitedValue];
    }
}

- (void)unitInput{
    if ([self.heightField.text rangeOfString:@" cm"].location == NSNotFound) {
        // If "self.heightField.text" does not contain "cm"
        self.heightField.text = [self.heightField.text stringByAppendingString:@" cm"];
    }if ([self.weightField.text rangeOfString:@" kg"].location == NSNotFound) {
        // If "self.weightField.text" does not contain "kg"
        self.weightField.text = [self.weightField.text stringByAppendingString:@" kg"];
    }if ([self.strideField.text rangeOfString:@" cm"].location == NSNotFound) {
        // If "self.strideField.text" does not contain "cm"
        self.strideField.text = [self.strideField.text stringByAppendingString:@" cm"];
    }
}

- (void)animateTextField:(UITextField *)textField up:(BOOL)up {
    int movementDistance = 0; // Initialize scroll distance

    if (up) {
        CGRect textFieldFrame = self.viewStride.frame;
        CGFloat textFieldBottomY = textFieldFrame.origin.y + textFieldFrame.size.height;
        CGFloat screenHeight = self.view.frame.size.height;
        CGFloat offset = textFieldBottomY - (screenHeight - keyboardHeight);
        // Check if UITextField is located below the keyboard
        if (offset > 0) {
            movementDistance = offset;
        }
    }

    // Animate UITextField to appropriate position
    [UIView animateWithDuration:0.3 animations:^{
        CGRect viewFrame = self.view.frame;
        if (up) {
            viewFrame.origin.y -= movementDistance;
        } else {
            viewFrame.origin.y = 0;
        }
        self.view.frame = viewFrame;
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSValue *keyboardFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [keyboardFrameValue CGRectValue];
    keyboardHeight = keyboardFrame.size.height;
    if (self.strideField.isFirstResponder) {
        if(textFieldCheck){
            [self animateTextField:self.strideField up:YES];
            textFieldCheck = false;
        }
    }else{
        [self animateTextField:self.strideField up:NO];
        textFieldCheck = true;
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (self.strideField.isFirstResponder) {
        [self animateTextField:self.strideField up:NO];
    }
}

- (void) createTapGesture{
    // create tap gesture
    UITapGestureRecognizer *femaleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.viewFemale addGestureRecognizer:femaleTapGesture];
    UITapGestureRecognizer *maleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.viewMale addGestureRecognizer:maleTapGesture];
    UITapGestureRecognizer *kgTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.viewKg addGestureRecognizer:kgTapGesture];
    UITapGestureRecognizer *lbsTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.viewLbs addGestureRecognizer:lbsTapGesture];
}

- (void)tapped:(UITapGestureRecognizer *)gesture {
    // Describe the process when the UILabel is tapped here
    NSLog(@"UILabel tapped");
    if(self.viewFemale == gesture.view){
        self.maleRadioButton.selected = NO;
        self.femaleRadioButton.selected = YES;
        selectGender = @(OMRONDevicePersonalSettingsUserGenderTypeFemale);
    }
    
    if(self.viewMale == gesture.view){
        self.maleRadioButton.selected = YES;
        self.femaleRadioButton.selected = NO;
        selectGender = @(OMRONDevicePersonalSettingsUserGenderTypeMale);
    }
    
    if(self.viewKg == gesture.view){
        self.kgRadioButton.selected = YES;
        self.lbsRadioButton.selected = NO;
        selectWeightUnit = @(OMRONDeviceWeightUnitKg);
    }
    
    if(self.viewLbs == gesture.view){
        self.kgRadioButton.selected = NO;
        self.lbsRadioButton.selected = YES;
        selectWeightUnit = @(OMRONDeviceWeightUnitLbs);
    }
}

-(BOOL) checkPersonalSettingData{
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    // Get existing data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonalData"];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (results.count < 1) {
        return false;
    }else{
        return true;
    }
}

- (void) setDateOfBirth:(NSString *)dateOfBirth{
    dateOfBirthString = dateOfBirth;
}
@end
