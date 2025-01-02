//
//  DeviceListViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import "DeviceListViewController.h"
#import "BPViewController.h"
#import "TemperatureRecordingViewController.h"
#import "OmronLogger.h"
#import "SupportDevicesViewController.h"
#import "DevicePairingViewController.h"
#import "AppDelegate.h"
#import "WheezeViewController.h"
#import "PersonalInfoSettingsViewController.h"
#import "BodyCompositionViewController.h"
@interface DeviceListViewController () {
    
    NSMutableArray *deviceList;
    NSMutableArray *connectedDeviceList;
    NSMutableDictionary *deviceConfig;
    
    NSMutableDictionary *omronCommonDevice;
    
    BOOL isLoading;
    BOOL isCancelButtonStatus;
    BOOL okButtonCheck;
    BOOL partnerKeyCheck;
    
    NSString *partnerKey;
    NSString *protocolSelect;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoBtn;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addNewDeviceButton;
@property (strong, nonatomic) UIButton *btnBLEDevice;
@property (strong, nonatomic) UIButton *btnSoundWaveDevice;
@property (nonatomic, strong) UIAlertController *alert;

- (IBAction)infoBtnPressed:(id)sender;

@end

@implementation DeviceListViewController

NSString * const ACOmronAPIKeyNorthAmerica = @"614A3E02-42FA-40AB-A49E-649B3A239B36";
NSString * const ACOmronAPIKeyEurope = @"A71BCE3A-7563-4409-8D9D-8F2430E7777D";
NSString * const ACOmronAPIKeyAsia = @"9DA8CCE1-4077-4BEB-9977-3722EBF49AA5";

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.addNewDeviceButton.layer.cornerRadius = 5.0; // 5.0 indicates the radius to round
    self.addNewDeviceButton.layer.masksToBounds = YES;

    self.addNewDeviceButton.enabled = NO;
    okButtonCheck = FALSE;
    partnerKeyCheck = FALSE;
    isCancelButtonStatus = FALSE;
    // Customize Navigation Bar
    [self customNavigationBarTitle:@"OMRON Connected Devices" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    if(![[NSUserDefaults standardUserDefaults] valueForKey:LibraryKey]) {
        
        [self showPromptForPartnerKey : isCancelButtonStatus];
        
    }else {
        
        [self reloadConfiguration];
    }
    connectedDeviceList = [self deviceConnectedList];
    if(connectedDeviceList.count > 0){
        isLoading = NO;
    }
    [self.addNewDeviceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}


// Start Omron Peripheral Manager
- (void)startOmronPeripheralManagerWithHistoricRead:(BOOL)isHistoric withPairing:(BOOL)pairing {
    
    OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
    
    peripheralConfig.enableiBeaconWithTransfer = true;
    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
    // Set Configuration to New Configuration (mandatory to set configuration)
    [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:peripheralConfig];
    [[OmronPeripheralManager sharedManager] startManager];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Remove Notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OMRONBLEConfigDeviceAvailabilityNotification object:nil];
}

- (void)configAvailabilityNotification:(NSNotification *)aNotification {
    
    // Remove Notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OMRONBLEConfigDeviceAvailabilityNotification object:nil];
    
    OMRONConfigurationStatus configFileStatus = (OMRONConfigurationStatus)[aNotification.object unsignedIntegerValue] ;
    
    isLoading = NO;
    
    if(configFileStatus == OMRONConfigurationFileSuccess) {
        
        ILogMethodLine(@"%@",  @"Config File Extract Success");
        
        [self loadDeviceList];
        // Check if the device list is not empty
        if (deviceList.count > 0) {
            self.addNewDeviceButton.enabled = YES;
            partnerKeyCheck = YES;
            isCancelButtonStatus = YES;
            partnerKey = [[NSUserDefaults standardUserDefaults] valueForKey:LibraryKey];
        } else {
            // If device list is empty and partner key is set
            if (partnerKey) {
                okButtonCheck = NO;
                partnerKeyCheck = NO;
                [[NSUserDefaults standardUserDefaults] setValue:partnerKey forKey:LibraryKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self messageDialog :@"Invalid Library API key configured" isCancleButton : isCancelButtonStatus];
                [self reloadConfiguration];
            } else {
                if (isCancelButtonStatus) {
                    [self showPromptForPartnerKey:isCancelButtonStatus];
                } else if (okButtonCheck) {
                    [self messageDialog:@"Invalid Library API key configured" isCancleButton:isCancelButtonStatus];
                } else if (!partnerKey) {
                    [self showPromptForPartnerKey:isCancelButtonStatus];
                }
            }
        }

        //Display the list of supported devices only when the OK button is pressed and the partner key is valid.
        //When switching partner keys, clear all pairing information.
        if(okButtonCheck && partnerKeyCheck){
            self.addNewDeviceButton.enabled = YES;
            self.addNewDeviceButton.backgroundColor = [self getCustomColor];
            [self showInfoAlertWithScrollView:deviceList];
            connectedDeviceList = [[NSMutableArray alloc] init];
            [self.tableView reloadData];
            [self deleteAllData];
        }
        
    }else if(configFileStatus == OMRONConfigurationFileError) {
        
        ILogMethodLine(@"%@",  @"Config File Extract Failure");
        
        [self showAlertWithMessage:@"Configuration File Error!" withAction:NO];
        
    }else if(configFileStatus == OMRONConfigurationFileUpdateError) {
        
        ILogMethodLine(@"%@",  @"Config File Update Failure");
        
        [self loadDeviceList];
        
        [self showAlertWithMessage:@"Configuration Update Error!" withAction:NO];
    }
    
}

- (void)loadDeviceList {
    
    // Get Devices List from Configuration File in Framework
    NSDictionary *configDictionary = [[NSDictionary alloc] initWithDictionary:[[OmronPeripheralManager sharedManager] retrieveManagerConfiguration]];
    
    deviceList = [NSMutableArray arrayWithArray:[configDictionary objectForKey:OMRONBLEConfigDeviceKey]];
    
    [self.tableView reloadData];
}

#pragma mark - Table View Data Source and Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(isLoading)
        return 1;
    
    return [connectedDeviceList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 100.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    // Add UILongPressGestureRecognizer to the cell
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [cell addGestureRecognizer:longPressGesture];
    
    if(isLoading) {
        
        cell.textLabel.font = [UIFont fontWithName:@"Courier" size:16];
        cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
        cell.textLabel.text = @"Loading Devices";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = @"Please wait...";
        cell.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        
    }else {
        
        if(connectedDeviceList.count != 0) {
            NSDictionary *currentItem = [connectedDeviceList objectAtIndex:indexPath.row];
            NSString *localName = [currentItem valueForKey:LocalNameKey];
            NSString *uuid = [NSString stringWithFormat:@"%@",[currentItem valueForKey:UuidKey]];
            
            cell.textLabel.font = [UIFont fontWithName:@"Courier" size:11];
            cell.textLabel.numberOfLines = 3 ;
            cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:11];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            if(localName){
                OmronPeripheral *peripheral = [[OmronPeripheral alloc] initWithLocalName:localName andUUID:uuid];
                OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
                deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
                
                NSString *modelName = [deviceConfig valueForKey:OMRONBLEConfigDeviceModelNameKey];
                NSString *identifier = [deviceConfig valueForKey:OMRONBLEConfigDeviceIdentifierKey];
                
                NSString *userNumber = [NSString stringWithFormat:@"User %@", [[currentItem valueForKey:UserNumberKey] stringValue]];
                NSString *textLabel = [NSString stringWithFormat:@"%@(%@)\n%@", modelName, identifier,localName];
                if([localName isEqualToString:OMRONThermometerMC280B]){
                    textLabel = [NSString stringWithFormat:@"%@(%@)", modelName, identifier];
                    cell.textLabel.text = textLabel;
                }else{
                    cell.textLabel.text = textLabel;
                    cell.detailTextLabel.text = userNumber;
                }
                cell.imageView.image = [UIImage imageNamed:[deviceConfig valueForKey:OMRONBLEConfigDeviceThumbnailKey]];
            }
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(isLoading) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableDictionary *currentDevice = [NSMutableDictionary dictionaryWithDictionary:[connectedDeviceList objectAtIndex:indexPath.row]];
        OmronPeripheral *peripheral = [[OmronPeripheral alloc] initWithLocalName:[currentDevice valueForKey:LocalNameKey] andUUID:[currentDevice valueForKey:UuidKey]];
            OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
            deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
        
        if([[deviceConfig valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
                
            BPViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPViewController"];
            controller.filterDeviceModel = deviceConfig;
            controller.omronLocalPeripheral = peripheral;
            controller.localName = [currentDevice valueForKey:LocalNameKey];;
            controller.users = [NSMutableArray array];
            NSNumber * number = [currentDevice valueForKey:UserNumberKey];
            [controller.users addObject: number];
            [self.navigationController pushViewController:controller animated:YES];
            
        }else if([[deviceConfig valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
            
            BPViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPViewController"];
            controller.filterDeviceModel = deviceConfig;
            controller.settingsModel = [[NSMutableDictionary alloc] initWithDictionary:[self getPersonalSettings]];
            [self.navigationController pushViewController:controller animated:YES];
            
        }else if([[deviceConfig valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBodyComposition) {
            AppDelegate *appDel = [AppDelegate sharedAppDelegate];
            NSManagedObjectContext *context = [appDel managedObjectContext];
            NSMutableArray *deviceSettings = [[NSMutableArray alloc] init];
            // Get existing data
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonalData"];
            NSError *error = nil;
            NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
            
            if (results && results.count > 0) {
                [deviceSettings addObject:[self getPersonalSettings]];
                [deviceSettings addObject:[self getWeightSettings]];
                [deviceSettings addObject:[self getTimeFormat]];
            }
            BodyCompositionViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BodyCompositionViewController"];
            controller.filterDeviceModel = deviceConfig;
            controller.localName = [currentDevice valueForKey:LocalNameKey];;
            controller.deviceSettings = deviceSettings;
            controller.omronLocalPeripheral = peripheral;
            controller.users = [NSMutableArray array];
            NSNumber * number = [currentDevice valueForKey:UserNumberKey];
            [controller.users addObject: number];
            [self.navigationController pushViewController:controller animated:YES];
        
        }else if([[deviceConfig valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryWheeze) {
            
            // TODO: Temporary setting for BP screen
            WheezeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WheezeViewController"];
            controller.filterDeviceModel = deviceConfig;
            controller.localName = [currentDevice valueForKey:LocalNameKey];;
            controller.omronLocalPeripheral = peripheral;
            controller.users = [NSMutableArray array];
            NSNumber * number = [currentDevice valueForKey:UserNumberKey];
            [controller.users addObject: number];
            [self.navigationController pushViewController:controller animated:YES];
            
        }else if([[deviceConfig valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryTemperature) {
            
            TemperatureRecordingViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"TemperatureRecordingViewController"];
            controller.filterDeviceModel = deviceConfig;
            [self.navigationController pushViewController:controller animated:YES];
        
        }else if([[deviceConfig valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryPulseOximeter) {

            BPViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PulseOxymeterViewController"];
            controller.localName = [currentDevice valueForKey:LocalNameKey];;
            controller.filterDeviceModel = deviceConfig;
            controller.omronLocalPeripheral = peripheral;
            
            [self.navigationController pushViewController:controller animated:YES];
        
        }
        
    });
}

- (IBAction)infoBtnPressed:(id)sender {
    [self showPromptForPartnerKey : TRUE];
}

- (void)showPromptForPartnerKey : (BOOL) isCancelButtonStatus {

    NSString *message = [NSString stringWithFormat:@"OMRON SDK version: %@",  [OmronPeripheralManager.sharedManager libVersion]];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Select the Region of the Device" message:message preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *northAmericaAction = [UIAlertAction actionWithTitle:@"North America" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] setValue:ACOmronAPIKeyNorthAmerica forKey:LibraryKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reloadConfiguration];
    }];
    UIAlertAction *europeAction = [UIAlertAction actionWithTitle:@"Europe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] setValue:ACOmronAPIKeyEurope forKey:LibraryKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reloadConfiguration];
    }];
    UIAlertAction *asiaAction = [UIAlertAction actionWithTitle:@"Asia" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] setValue:ACOmronAPIKeyAsia forKey:LibraryKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reloadConfiguration];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [actionSheet addAction:northAmericaAction];
    [actionSheet addAction:europeAction];
    [actionSheet addAction:asiaAction];
    [actionSheet addAction:cancelAction];
    
    UIPopoverPresentationController *popoverController = actionSheet.popoverPresentationController;
    if (popoverController) {
        popoverController.sourceView = self.view;
        CGSize size = self.view.bounds.size;
        popoverController.sourceRect = CGRectMake(size.width/2, size.height/2, 1, 1);
    }
    
    [self presentViewController:actionSheet animated:YES completion:nil];
    
    
    /*
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *details = [NSString stringWithFormat:@"Sample App Version : %@\nLibrary Version : %@\n\nTap ⓘ to configure later", version, [[OmronPeripheralManager sharedManager] libVersion]];
    
    self.alert = [UIAlertController alertControllerWithTitle:@"Configure OMRON Library Key" message:details preferredStyle:UIAlertControllerStyleAlert];
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Configure OMRON Library Key" attributes:titleAttributes];
    [self.alert setValue:attributedTitle forKey:@"attributedTitle"];
    // Create attributes for message strings
    NSDictionary *messageAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0]
    };
    NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:details attributes:messageAttributes];
    // Apply attributes to messages
    [self.alert setValue:attributedMessage forKey:@"attributedMessage"];
    [self.alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        {
            textField.placeholder = @"Enter API Key";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        }
    }];
    
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
        
        self.addNewDeviceButton.enabled = NO;
        self.addNewDeviceButton.backgroundColor = [UIColor grayColor];
        okButtonCheck = true;
        NSString *apiKey = self.alert.textFields[0].text;
        
        if(![apiKey isEqualToString:@""]) {
            [[NSUserDefaults standardUserDefaults] setValue:apiKey forKey:LibraryKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self reloadConfiguration];
        }else{
            [self messageDialog :@"Invalid Library API key configured" isCancleButton : isCancelButtonStatus];
        }
    }];
    
    if(isCancelButtonStatus){
        
        UIAlertAction *cancelButton = [UIAlertAction
                                       actionWithTitle:@"CANCEL"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction * action) {
            
            [self loadDeviceList];
            self.addNewDeviceButton.enabled = YES;
            self.addNewDeviceButton.backgroundColor = [self getCustomColor];
        }];
        [self.alert addAction:cancelButton];
        [self.alert addAction:cancelButton];
        
        [self.alert addAction:okButton];
        [self presentViewController:self.alert animated:YES completion:^{
            self.alert.view.superview.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAlert)];
            [self.alert.view.superview addGestureRecognizer:tapGesture];
        }];
    }else{
        [self.alert addAction:okButton];
        [self presentViewController:self.alert animated:YES completion:nil];
    }
    */
}

- (void)reloadConfiguration {
    
    [[OmronPeripheralManager sharedManager] setAPIKey:[[NSUserDefaults standardUserDefaults] valueForKey:LibraryKey] options:nil];
    
    if(![[NSUserDefaults standardUserDefaults] valueForKey:LibraryKey]) {
        
        [self showPromptForPartnerKey : FALSE];
        
    }else {
        
        isLoading = YES;
        // Notification Listener for Configuration Availability
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configAvailabilityNotification:)
                                                     name:OMRONBLEConfigDeviceAvailabilityNotification
                                                   object:nil];
    }
    
    [self updateInfoBtn];
}


- (void)updateInfoBtn {
    NSString *title = @"N/A";
    NSString *selectedAPIKey = (NSString *)[[NSUserDefaults standardUserDefaults] valueForKey:LibraryKey];
    if ([selectedAPIKey isEqualToString:ACOmronAPIKeyEurope]) {
        title = @"EU";;
    } else if ([selectedAPIKey isEqualToString:ACOmronAPIKeyAsia]) {
        title = @"Asia";
    } else if ([selectedAPIKey isEqualToString:ACOmronAPIKeyNorthAmerica]) {
        title = @"N. America";
    }
    self.infoBtn.title = title;
}

- (void)showInfoAlertWithScrollView : (NSMutableArray *)deviceList {
    // create custom view
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 350)];
    
    // Create the first UILabel
    UILabel *APIKeyRegistrationSuccessfulLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, customView.frame.size.width - 10, 120)];
    APIKeyRegistrationSuccessfulLabel.text = @"\n\nAPI Key registration successful!\n\nSupport devices";
    APIKeyRegistrationSuccessfulLabel.numberOfLines = 6;
    APIKeyRegistrationSuccessfulLabel.textAlignment = NSTextAlignmentLeft;
    APIKeyRegistrationSuccessfulLabel.font = [UIFont systemFontOfSize:15.0f];
    // Add APIKeyRegistrationSuccessfulLabel to custom view
    [customView addSubview:APIKeyRegistrationSuccessfulLabel];
    
    // Create scrollViewWrapper (scrollView border)
    UIView *scrollViewWrapper = [[UIView alloc] initWithFrame:CGRectMake(10, APIKeyRegistrationSuccessfulLabel.frame.origin.y + APIKeyRegistrationSuccessfulLabel.frame.size.height-10, customView.frame.size.width - 20 , customView.frame.size.height - 130)];
    scrollViewWrapper.layer.borderWidth = 1.0; // Set border width
    scrollViewWrapper.layer.borderColor = [UIColor grayColor].CGColor; // Set border color
    
    // Create UIScrollView
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, scrollViewWrapper.frame.size.width , scrollViewWrapper.frame.size.height)]; // Adjust scroll view size
    
    // Add content (labels, etc.) to be displayed in the scroll view
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, scrollView.frame.size.width - 20, 0)];
    NSString *deviceNameInfo = [self getDeviceNameInfo : deviceList];
    textLabel.text = deviceNameInfo;
    textLabel.numberOfLines = 0; // Supports multiple lines of text
    textLabel.font = [UIFont systemFontOfSize:12.0]; // set font size
    [textLabel sizeToFit]; // Automatically adjust label size
    
    // Add label to scrollview
    [scrollView addSubview:textLabel];
    
    // Set contentSize of scroll view
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, textLabel.frame.size.height);
    // Show slider from the beginning
    [scrollView flashScrollIndicators];
    
    // Add UIScrollView to scrollViewWrapper
    [scrollViewWrapper addSubview:scrollView];
    
    // Add scroll view to custom view
    [customView addSubview:scrollViewWrapper];
    // Create UIAlertController
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Info"
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    // Create a constraint on the UIAlertController's view height
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:alertController.view
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:385];
    [alertController.view addConstraint:heightConstraint];
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Info" attributes:titleAttributes];
    [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    
    // Add custom view to alert controller
    [alertController.view addSubview:customView];
    
    // Add OK button
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        // bluetooth permission request
        [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:YES];
    }];
    [alertController addAction:okAction];
    if(![deviceNameInfo  isEqual: @""]){
        // Show UIAlertController
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (NSString *)getDeviceNameInfo : (NSMutableArray *)deviceList{
    NSMutableString *combinedString = [NSMutableString string];

    // Loop through each element in deviceList
    for (NSDictionary *deviceInfo in deviceList) {
        // Get the modelName and identifier values
        NSString *modelName = deviceInfo[ModelNameKey];
        NSString *identifier = deviceInfo[OMRONBLEConfigDeviceIdentifierKey];
        
        // Add the modelName and identifier values ​​to the string and insert a newline
        NSString *infoString = [NSString stringWithFormat:@"%@(%@)\n", modelName, identifier];
        
        // join strings
        [combinedString appendString:infoString];
    }
    
    // combinedString contains a string with each device information separated by newlines
    return combinedString;
}
- (void) messageDialog : (NSString *) message  isCancleButton : (BOOL) cancleButton{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Info" message:message preferredStyle:UIAlertControllerStyleAlert];
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Info" attributes:titleAttributes];
    [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    // Create attributes for message strings
    NSDictionary *messageAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0]
    };
    NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:message attributes:messageAttributes];
    // Apply attributes to messages
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    // Add OK button
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self showPromptForPartnerKey:cancleButton];
    }];
    [alertController addAction:okAction];
    // Show UIAlertController
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showMenuList {
   
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Personal SettingsItem
    UIAlertAction *personalSettingsMenuItem = [UIAlertAction actionWithTitle:@"Personal Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Describe the process when Personal SettingsItem is selected
        NSLog(@"Personal Settings selected");
        // Get the destination view controller using UIStoryboard
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *PersonalSettingsVC = [storyboard instantiateViewControllerWithIdentifier:@"PersonalInfoSettingsViewController"]; // "PersonalInfoSettingsViewController" is the Storyboard ID of the view controller to transition to

        // Execute transition processing
        [self.navigationController pushViewController:PersonalSettingsVC animated:YES];
        
    }];
    if (@available(iOS 13.0, *)) {
        NSString *imageName = @"personal";
        UIImage *personalIcon = [UIImage imageNamed:imageName];
        [personalSettingsMenuItem setValue:[personalIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    } else {
        // Fallback on earlier versions
    }

    // Device Data History Item
    UIAlertAction *deviceDataHistoryMenuItem = [UIAlertAction actionWithTitle:@"Device Data History" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Describe the process when a Device Data History item is selected
        NSLog(@"Device Data History selected");
        // Get the destination view controller using UIStoryboard
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *deviceDataHistoryVC = [storyboard instantiateViewControllerWithIdentifier:@"PairedDeviceListTableViewController"]; // "PairedDeviceListTableViewController" is the Storyboard ID of the destination view controller

        // Execute transition processing
        [self.navigationController pushViewController:deviceDataHistoryVC animated:YES];
    }];
    if (@available(iOS 13.0, *)) {
        
        // "folder.fill" Load system icon
        UIImage *folderIcon = [UIImage systemImageNamed:@"folder.fill"];

        // set new color
        UIColor *newColor = [UIColor colorWithRed:0.0/255.0 green:114.0/255.0 blue:187.0/255.0 alpha:1.0];

        // Create an icon with new colors
        UIImage *coloredIcon = [folderIcon imageWithTintColor:newColor renderingMode:UIImageRenderingModeAlwaysOriginal];

        // Set new icon on deviceDataHistoryMenuItem
        [deviceDataHistoryMenuItem setValue:coloredIcon forKey:@"image"];
        
    } else {
        // Fallback on earlier versions
    }
    // Support DeviceItem
    UIAlertAction *supportDeviceMenuItem = [UIAlertAction actionWithTitle:@"Support Devices" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Describe the process when Support DeviceItem is selected
        NSLog(@"Support Device selected");
        
        SupportDevicesViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SupportDevicesViewController"];// "SupportDevicesViewController" is the Storyboard ID of the view controller to transition to
        controller.filterDeviceModel = deviceList;

        // Execute transition processing
        [self.navigationController pushViewController:controller animated:YES];
        
    }];
    if (@available(iOS 13.0, *)) {
        NSString *imageName = @"support_device";
        UIImage *supportIcon = [UIImage imageNamed:imageName];
        [supportDeviceMenuItem setValue:[supportIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    } else {
        // Fallback on earlier versions
    }
    
    // cancel action
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleCancel handler:nil];
    
    // Add menu item to alert controller
    [alertController addAction:personalSettingsMenuItem];
    [alertController addAction:deviceDataHistoryMenuItem];
    [alertController addAction:supportDeviceMenuItem];
    [alertController addAction:cancelAction];
    
    UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
    if (popoverController) {
        popoverController.sourceView = self.view;
        CGSize size = self.view.bounds.size;
        popoverController.sourceRect = CGRectMake(size.width/2, size.height/2, 1, 1);
    }
    // Show alert controller
    [self presentViewController:alertController animated:YES completion:nil];
}
- (IBAction)addNewDeviceAction:(id)sender {
    [self checkPersonalSettingData];
}
- (IBAction)showMenu:(id)sender {
    [self showMenuList];
}

- (NSMutableArray *) deviceConnectedList{
    NSMutableArray *deviceDataList = [[NSMutableArray alloc] init];
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PairingDeviceData" inManagedObjectContext:managedContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PairingDeviceData"];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    if(!fetchedObjects){
        
    }else{
        for (NSManagedObject *info in fetchedObjects) {
            NSMutableDictionary *deviceData = [[NSMutableDictionary alloc] init];
            [deviceData setValue:[info valueForKey:LocalNameKey]  forKey:LocalNameKey];
            [deviceData setValue:[info valueForKey:UserNumberKey] forKey:UserNumberKey];
            [deviceData setValue:[info valueForKey:UuidKey] forKey:UuidKey];
            [deviceData setValue:[info valueForKey:SequenceNumber] forKey:SequenceNumber];
            
            if(![deviceDataList containsObject:deviceData]){
                [deviceDataList addObject:deviceData];
            }
        }
    }
    
    NSMutableArray *reversedArray = [NSMutableArray array];
    for (NSInteger i = [deviceDataList count] - 1; i >= 0; i--) {
        [reversedArray addObject:deviceDataList[i]];
    }
    
    return reversedArray;
}
// Handler for long press gesture
- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if (indexPath) {
            // Get the position of the long-pressed cell and perform the delete action
            [self showDeleteConfirmationForIndexPath:indexPath];
        }
    }
}
// Display action sheet to confirm deletion
- (void)showDeleteConfirmationForIndexPath:(NSIndexPath *)indexPath {
    self.alert = [UIAlertController alertControllerWithTitle:@"Delete device" message:@"Are you sure you want to delete this device？" preferredStyle:UIAlertControllerStyleAlert];
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Delete device" attributes:titleAttributes];
    [self.alert setValue:attributedTitle forKey:@"attributedTitle"];
    // Create attributes for message strings
    NSDictionary *messageAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0]
    };
    NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:@"Are you sure you want to delete this device？" attributes:messageAttributes];
    // Apply attributes to messages
    [self.alert setValue:attributedMessage forKey:@"attributedMessage"];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"CANCEL"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
        
        if (indexPath) {
            
            [self deleteReadingAtIndex : indexPath.row];
            
            [self.tableView reloadData];
        }
    }];
    
    [self.alert addAction:cancelAction];
    [self.alert addAction:deleteAction];

    [self presentViewController:self.alert animated:YES completion:^{
        self.alert.view.superview.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAlert)];
        [self.alert.view.superview addGestureRecognizer:tapGesture];
    }];
}
- (void)deleteReadingAtIndex:(NSInteger) index {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];

    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PairingDeviceData" inManagedObjectContext:managedContext];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PairingDeviceData"];
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    connectedDeviceList = [self deviceConnectedList];
    for (NSManagedObject *info in fetchedObjects) {
        NSMutableDictionary *currentDevice = [connectedDeviceList  objectAtIndex:index];
        if([[currentDevice valueForKey:LocalNameKey] isEqualToString:[info valueForKey:LocalNameKey]]) {
            [managedContext deleteObject:info];
            break;
        }
    }
    error = nil;
    if (![managedContext save:&error]) {
        NSLog(@"Failed to delete from Core Data: %@", error);
        // Perform error handling
        return;
    }
    connectedDeviceList = [self deviceConnectedList];
}

- (void) deleteAllData{
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    // Create NSFetchRequest from entity name ("PairingDeviceData") and managedContext
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PairingDeviceData"];

    // Get data to delete
    NSArray *itemsToDelete = [managedContext executeFetchRequest:fetchRequest error:nil];

    // Delete acquired data
    for (NSManagedObject *item in itemsToDelete) {
        [managedContext deleteObject:item];
    }

    // save changes
    NSError *error = nil;
    if (![managedContext save:&error]) {
        NSLog(@"Failed to delete data. error: %@", error);
    } else {
        NSLog(@"Data has been deleted.");
    }
}

-(void) checkPersonalSettingData{
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    // Get existing data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonalData"];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (results.count < 1) {
        [self showDialogtWithMessage : @"Please set personal setting" title : @"Info" withAction : @"NoPersonalSettingData"  localPeripheral:nil];
    }else{
        [self checkSoundSupport];
    }
}

- (void)showDialogtWithMessage:(NSString *)message title : (NSString *)title withAction:(NSString *)userAction localPeripheral :(OmronPeripheral *)localPeripheral {
    
    UIAlertController *configError = [UIAlertController
                                      alertControllerWithTitle:title
                                      message:message
                                      preferredStyle:UIAlertControllerStyleAlert];
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:titleAttributes];
    [configError setValue:attributedTitle forKey:@"attributedTitle"];
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
        
        if([userAction isEqualToString:@"NoPersonalSettingData"]) {
            
            PersonalInfoSettingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PersonalInfoSettingsViewController"];            [self.navigationController pushViewController:controller animated:YES];
            
        }
    }];
    
    [configError addAction:okButton];
    [self presentViewController:configError animated:YES completion:nil];
}

- (NSMutableDictionary *)getWeightSettings{
    NSMutableDictionary *weightSettings = [[NSMutableDictionary alloc] init];
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
        // Common Settings
        NSNumber *weightUnit = [object valueForKey:WeightUnitKey];
        
        NSDictionary *weightCommonSettings;
        
        weightCommonSettings = @{ OMRONDeviceWeightSettingsUnitKey : weightUnit};
        [weightSettings setObject:weightCommonSettings forKey:OMRONDeviceWeightSettingsKey];
    }
    return weightSettings ;
}

- (NSMutableDictionary *)getPersonalSettings{
    NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
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
        
        NSString *originalString = [object valueForKey:DateOfBirthKey];
        
        NSNumber *height = [object valueForKey:HeightKey];
        
        NSString *dateOfBirth = originalString;
        
        NSNumber *gender = [object valueForKey:GenderKey];
        
        NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : height,
                                    OMRONDevicePersonalSettingsUserDateOfBirthKey : dateOfBirth,
                                    OMRONDevicePersonalSettingsUserGenderKey : gender};
        [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
        
    }
    
    return personalSettings ;
}

- (NSMutableDictionary *)getTimeFormat{
    
    // Time Format
    NSDictionary *timeFormatSettings = @{ OMRONDeviceTimeSettingsFormatKey : @(OMRONDeviceTimeFormat24Hour) };
    NSMutableDictionary *timeSettings = [[NSMutableDictionary alloc] init];
    [timeSettings setObject:timeFormatSettings forKey:OMRONDeviceTimeSettingsKey];
    return timeSettings ;
}

- (void)protocolSelectionDialog {
    // Create an instance of the dialog controller
    self.alert = [UIAlertController alertControllerWithTitle:@"Protocol selection" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Protocol selection" attributes:titleAttributes];
    [self.alert setValue:attributedTitle forKey:@"attributedTitle"];
    // Create a constraint on the UIAlertController's view height
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.alert.view
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:200];
    [self.alert.view addConstraint:heightConstraint];
    // Create custom view
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 270, 100)];
    
    UIView *BLEDeviceView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 50)];
    // create tap gesture
    UITapGestureRecognizer *BLEDeviceViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(BLEDeviceViewTapped:)];
    [BLEDeviceView addGestureRecognizer:BLEDeviceViewTapGesture];
    [customView addSubview:BLEDeviceView];
    
    // Create SoundDeviceView and set background color
    UIView *SoundDeviceView = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 270, 50)];

    // create tap gesture
    UITapGestureRecognizer *soundDeviceViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(soundDeviceViewTapped:)];
    [SoundDeviceView addGestureRecognizer:soundDeviceViewTapGesture]; // Add tap gesture to SoundDeviceView

    [customView addSubview:SoundDeviceView]; // Add SoundDeviceView to customView

    // Create UIButton
    self.btnBLEDevice = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnBLEDevice setFrame:CGRectMake(20, 20, 20, 20)];
    [self.btnBLEDevice setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
    [self.btnBLEDevice setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
    self.btnBLEDevice.selected = YES;
    protocolSelect = BLEDeviceKey;
    [self.btnBLEDevice addTarget:self action:@selector(BLEDeviceViewTapped:) forControlEvents:UIControlEventTouchUpInside];
    [customView addSubview:self.btnBLEDevice];
    
    // Create UIButton
    self.btnSoundWaveDevice = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnSoundWaveDevice setFrame:CGRectMake(20, 60, 20, 20)];
    [self.btnSoundWaveDevice setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
    [self.btnSoundWaveDevice setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
    [self.btnSoundWaveDevice addTarget:self action:@selector(soundDeviceViewTapped:) forControlEvents:UIControlEventTouchUpInside];
    [customView addSubview:self.btnSoundWaveDevice];

    // Create UILabel
    UILabel *lblBLEDevice = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 200, 20)];
    lblBLEDevice.text = @"BLE device";
    lblBLEDevice.font = [UIFont systemFontOfSize:14];
    [customView addSubview:lblBLEDevice];
    
    // Create UILabel
    UILabel *lblSoundWaveDevice = [[UILabel alloc] initWithFrame:CGRectMake(50, 60, 200, 20)];
    lblSoundWaveDevice.text = @"Sound wave device";
    lblSoundWaveDevice.font = [UIFont systemFontOfSize:14];
    [customView addSubview:lblSoundWaveDevice];
    
    // Add custom view to alert controller
    [self.alert.view addSubview:customView];
    
    // Add OK button
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //Write here the process when the OK button is tapped
        DevicePairingViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DevicePairingViewController"];
        controller.deviceList = deviceList;
        controller.protocolSelect = protocolSelect;
        [self.navigationController pushViewController:controller animated:YES];
    }];
    // Add cancel button
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // Write here what happens when the cancel button is tapped
    }];
    // show dialog
    [self.alert addAction:okAction];
    [self.alert addAction:cancelAction];

    [self presentViewController:self.alert animated:YES completion:^{
        self.alert.view.superview.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAlert)];
        [self.alert.view.superview addGestureRecognizer:tapGesture];
    }];

}

- (void)BLEDeviceViewTapped:(UITapGestureRecognizer *)gesture {
    self.btnBLEDevice.selected = YES;
    self.btnSoundWaveDevice.selected = NO;
    protocolSelect = BLEDeviceKey;
}

- (void)soundDeviceViewTapped:(UITapGestureRecognizer *)gesture {
    self.btnSoundWaveDevice.selected = YES;
    self.btnBLEDevice.selected = NO;
    protocolSelect = SoundWaveDeviceKey;
}

- (void)checkSoundSupport {
    BOOL hasAudioProtocol = NO;
    BOOL hasBLEProtocol = NO;

    for (NSDictionary *deviceInfo in deviceList) {
        NSString *deviceProtocol = deviceInfo[OMRONBLEConfigDeviceProtocolKey];
        NSString *deviceGroupID = deviceInfo[OMRONBLEConfigDeviceGroupIDKey];
        NSString *deviceIncludedGroupID = deviceInfo[OMRONBLEConfigDeviceGroupIncludedGroupIDKey];

        if (deviceGroupID && deviceIncludedGroupID) {
            if ([deviceProtocol isEqualToString:@"OMRONAudioProtocol"]) {
                hasAudioProtocol = YES;
            } else {
                hasBLEProtocol = YES;
            }
        }
    }

    if (hasAudioProtocol && hasBLEProtocol) {
        [self protocolSelectionDialog];
    } else {
        NSString *protocolSelect = nil;

        if (hasAudioProtocol) {
            protocolSelect = SoundWaveDeviceKey;
        }

        if (hasBLEProtocol) {
            protocolSelect = BLEDeviceKey;
        }

        DevicePairingViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DevicePairingViewController"];
        controller.deviceList = deviceList;
        controller.protocolSelect = protocolSelect;

        [self.navigationController pushViewController:controller animated:YES];
    }
}


- (void)closeAlert {
    [self.alert dismissViewControllerAnimated:YES completion:nil];
    self.alert = nil;
    self.addNewDeviceButton.backgroundColor = [self getCustomColor];
    self.addNewDeviceButton.enabled = YES;
    
}
@end

