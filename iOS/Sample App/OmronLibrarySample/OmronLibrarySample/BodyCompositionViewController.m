//
//  BodyCompositionViewController.m
//  OmronLibrarySample
//
//  Created by Hitesh Bhardwaj on 09/04/19.
//  Copyright © 2019 Omron HealthCare Inc. All rights reserved.
//

#import  "QuartzCore/QuartzCore.h"
#import "BodyCompositionViewController.h"
#import "AppDelegate.h"
#import "WeightReadingsViewController.h"
#import "OmronLogger.h"
@interface BodyCompositionViewController (){
    
    // Tracks Connected Omron Peripheral
    OmronPeripheral *localPeripheral;
    bool isTransfer;
    bool isConnect;
}
@property (weak, nonatomic) IBOutlet UILabel *lblTimeStamp;
@property (weak, nonatomic) IBOutlet UILabel *lblWeight;
@property (weak, nonatomic) IBOutlet UILabel *lblWeightUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblBodyFat;
@property (weak, nonatomic) IBOutlet UILabel *lblRestingMetabolism;
@property (weak, nonatomic) IBOutlet UILabel *lblSkeletalMuscle;
@property (weak, nonatomic) IBOutlet UILabel *lblBMI;
@property (weak, nonatomic) IBOutlet UILabel *lblVisceralFat;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblLocalName;
@property (weak, nonatomic) IBOutlet UILabel *lblUserSelected;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralErrorCode;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralError;
@property (weak, nonatomic) IBOutlet UILabel *lbldeviceModel;
@property (weak, nonatomic) IBOutlet UILabel *lblDateOfBirth;
@property (weak, nonatomic) IBOutlet UILabel *lblGender;
@property (weak, nonatomic) IBOutlet UILabel *lblHeight;
@property (weak, nonatomic) IBOutlet UILabel *lblSequenceNumber;
@property (weak, nonatomic) IBOutlet UILabel *lblsequenceNumberTitle;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayPriorityVisceralFatLv;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayPriorityVisceralFatLv;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayPrioritySkeletalMuscleLv;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayPrioritySkeletalMuscleLv;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayPriorityRestingMetabolism;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayPriorityRestingMetabolism;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayPriorityBMI;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayPriorityBMI;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayPriorityBodyAge;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayPriorityBodyAge;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayPriorityBodyFat;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayPriorityBodyFat;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayEnableVisceralFatLv;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayEnableVisceralFatLv;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayEnableSkeletalMuscleLv;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayEnableSkeletalMuscleLv;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayEnableRestingMetabolism;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayEnableRestingMetabolism;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayEnableBMI;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayEnableBMI;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayEnableBodyAge;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayEnableBodyAge;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayEnableBodyFat;
@property (weak, nonatomic) IBOutlet UILabel *lbldisplayEnableBodyFat;

@property (weak, nonatomic) IBOutlet UILabel *lblTimeFormat;
@property (weak, nonatomic) IBOutlet UILabel *lbltimeFormat;

@property (weak, nonatomic) IBOutlet UILabel *lblDateFormat;
@property (weak, nonatomic) IBOutlet UILabel *lbldateFormat;

@property (weak, nonatomic) IBOutlet UILabel *lblweightUnitDevice;
@property (weak, nonatomic) IBOutlet UILabel *lblWeightUnitDevice;

@property (weak, nonatomic) IBOutlet UILabel *lblBodyAge;

@property (weak, nonatomic) IBOutlet UILabel *lblBatteryRemaining;

@property (weak, nonatomic) IBOutlet UIView *devicesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searching;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *omronDevicesScrollView;
@property (weak, nonatomic) IBOutlet UIButton *transferButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnReadingList;
@property (weak, nonatomic) IBOutlet UIView *bodyCompositionDevicesInfomationView;
- (IBAction)readingListButtonPressed:(id)sender;

@end

@interface NSDictionary (ContainsKey)
- (BOOL)containsKey:(id)key;
@end

@implementation NSDictionary (ContainsKey)
- (BOOL)containsKey:(id)key {
    return [self objectForKey:key] != nil;
}
@end

@implementation BodyCompositionViewController

#pragma mark - View Controller Life cycles

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.transferButton.layer.cornerRadius = 5.0; // 5.0 indicates the radius to round
    self.transferButton.layer.masksToBounds = YES;
    isTransfer = NO;
    isConnect = NO;
    
    //Showing and hiding labels
    [self configureLabelVisibilyty];
    
    self.devicesView.hidden = NO;
    self.searching.hidden = YES;
    
    self.scrollView.backgroundColor = self.devicesView.backgroundColor;
    
    [self updateLocalPeripheral: self.omronLocalPeripheral];
    self.lbldeviceModel.text = [NSString stringWithFormat:@"%@ - Connection Status", [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelDisplayNameKey]];
    self.lblLocalName.text = [NSString stringWithFormat:@"%@\n\n%@", self.omronLocalPeripheral.localName,  self.omronLocalPeripheral.UUID];
    [self customNavigationBarTitle:@"Data Transfer" withFont:[UIFont fontWithName:@"Courier" size:16]];
    // Default to 1 for single user device
    if(self.users.count == 0) {
        self.users = [[NSMutableArray alloc] initWithArray:@[@(1)]];
    }
        
    // Start OmronPeripheralManager
    [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:NO];
}

// Start Omron Peripheral Manager
- (void)startOmronPeripheralManagerWithHistoricRead:(BOOL)isHistoric withPairing:(BOOL)pairing {
    
    OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
    
    // Filter device to scan and connect (optional)
    if([self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIDKey] && [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]) {
        
        NSMutableArray *filterDevices = [[NSMutableArray alloc] init];
        
        // New Supported Format - Add entire data model to filter list
        [filterDevices addObject:self.filterDeviceModel];
        
        peripheralConfig.deviceFilters = filterDevices;// Filter Devices
    }
    
    // Set Scan timeout interval (optional)
    peripheralConfig.timeoutInterval = 30; // Seconds
    
    // Holds settings
    NSMutableArray *deviceSettings = [[NSMutableArray alloc] init];
//    deviceSettings = self.deviceSettings;
    // Get existing data
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *context = [appDel managedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonalData"];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (results && results.count > 0) {
        
        [self getPersonalSettings:&deviceSettings];
    }
    [self getWeightSettings:&deviceSettings];
    
    [self getTimeFormat:&deviceSettings];

    // Scan settings (optional)
    [self getScanSettings:&deviceSettings withPairing:pairing];

    // Set Device settings to the peripheral
    peripheralConfig.deviceSettings = deviceSettings;
    
    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
    // Disclaimer: Read definition before usage
    peripheralConfig.enableAllDataRead = isHistoric;
    
    // Set Configuration to New Configuration (mandatory to set configuration)
    [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:peripheralConfig];
    
    // Start OmronPeripheralManager (mandatory)
    [[OmronPeripheralManager sharedManager] startManager];
    
    // Notification Listener for BLE State Change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(centralManagerDidUpdateStateNotification:)
                                                 name:OMRONBLECentralManagerDidUpdateStateNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Remove Notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OMRONBLECentralManagerDidUpdateStateNotification object:nil];
    
    if(isTransfer){
        isTransfer = NO;
        // Stop Scanning for devices if scanning
        [[OmronPeripheralManager sharedManager] stopScanPeripherals];
    }
    if(isConnect){
        isConnect = NO;
        // Disconnects Omron Peripherals
        [[OmronPeripheralManager sharedManager] disconnectPeripheral:localPeripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {}];
    }
}

#pragma mark - OmronPeripheralManager Disconnect Function

- (void)disconnectDeviceWithMessage:(NSString *)message {
    
    self.lblStatus.text = @"Disconnecting...";
    
    // Disconnects Omron Peripherals
    [[OmronPeripheralManager sharedManager] disconnectPeripheral:localPeripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        if(error == nil) {
            
            self.lblStatus.text = @"Disconnected";
            self.lblPeripheralError.text = message;
        }else {
            
            [self resetLabels];
            
            self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
            self.lblPeripheralError.text = [error localizedDescription];
            ILogMethodLine(@"Error - %@", error);
        }
    }];
}

#pragma mark - OmronPeripheralManager Transfer Function

- (IBAction)TransferClick:(id)sender {
    
    [self resetLabels];
    
    self.btnReadingList.enabled = NO;
    self.transferButton.enabled = NO;
    self.transferButton.backgroundColor = [UIColor grayColor];
    self.searching.hidden = NO;
    if(localPeripheral) {
        
        UIAlertController *transferType = [UIAlertController
                                          alertControllerWithTitle:@"Transfer"
                                          message:@"Do you want to transfer all historic readings from device?"
                                          preferredStyle:UIAlertControllerStyleAlert];
        // Create an attribute for the title string
        NSDictionary *titleAttributes = @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
        };
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Transfer" attributes:titleAttributes];
        [transferType setValue:attributedTitle forKey:@"attributedTitle"];
        // Create attributes for message strings
        NSDictionary *messageAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:12.0]
        };
        NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:@"Do you want to transfer all historic readings from device?" attributes:messageAttributes];
        // Apply attributes to messages
        [transferType setValue:attributedMessage forKey:@"attributedMessage"];
        
        UIAlertAction *okButton = [UIAlertAction
                                   actionWithTitle:@"Yes"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
            
            [self startOmronPeripheralManagerWithHistoricRead:YES withPairing:NO];
            [self performDataTransfer];
            
        }];
        UIAlertAction *cancelButton = [UIAlertAction
                                   actionWithTitle:@"No"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction * action) {
            
            [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:NO];
            [self performDataTransfer];
        }];
        
        [transferType addAction:cancelButton];
        [transferType addAction:okButton];
        [self presentViewController:transferType animated:YES completion:nil];
    
    }else {
        
        self.lblPeripheralError.text = @"No device paired";
    }
}

- (void)performDataTransfer {
    
    // Connection State
    [self setConnectionStateNotifications];
    
    OmronPeripheral *peripheralLocal = [[OmronPeripheral alloc] initWithLocalName:localPeripheral.localName andUUID:localPeripheral.UUID];
    
    self.lblStatus.text = @"Connecting...";
    
    if([self.users count] > 1) {
        // Use param different to check function availability
//        [self transferUsersDataWithPeripheral:peripheralLocal];
    }else {
        // Use regular function with one user type
        [self transferUserDataWithPeripheral:peripheralLocal];
    }
}

// Single User data transfer
- (void)transferUserDataWithPeripheral:(OmronPeripheral *)peripheral {
    
    /*
     * Starts Data Transfer from Omron Peripherals.
     * endDataTransferFromPeripheralWithCompletionBlock of OmronConnectivityLibrary need to be called once data retrieved is saved
     * For single user device, selected user will be passed as 1
     * withWait : Only YES is supported now
     */
    isTransfer = YES;
    [[OmronPeripheralManager sharedManager] startDataTransferFromPeripheral:peripheral withUser:[[self.users firstObject] intValue] withWait:YES withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil) {
                
                localPeripheral = peripheral;
                
                ILogMethodLine(@"Device Information - %@", [peripheral getDeviceInformation]);
                ILogMethodLine(@"Device Settings - %@", [peripheral getDeviceSettings]);
                
                // Retrieves Vital data for required user (should be same as value passed in function startDataTransferFromPeripheral:withUser:withWait:withCompletionBlock
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        [self uploadData:vitalData withPeripheral:peripheral withWait:YES];
                        
                    }else {
                        
                        // Error retrieving Peripheral vital data
                        ILogMethodLine(@"Error retrieving Peripheral Vital data - %@", error.description);
                        
                        [self disconnectDeviceWithMessage:error.localizedDescription];
                    }
                }];
                
            }else {
                
                [self resetLabels];
                
                self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                self.lblPeripheralError.text = [error localizedDescription];
                
                ILogMethodLine(@"Error - %@", error);
            }
        });
    }];
}

#pragma mark - Vital Data Save

- (void)uploadData:(NSMutableDictionary *)vitalData withPeripheral:(OmronPeripheral *)peripheral withWait:(BOOL)isWait {
    
    NSMutableDictionary *deviceInfo = peripheral.getDeviceInformation;
    NSMutableDictionary *deviceSettings = peripheral.getDeviceSettings;
    ILogMethodLine(@"Device Information - %@", deviceInfo);
    ILogMethodLine(@"Device Settings - %@", deviceSettings);
    
    if(vitalData.allKeys.count > 0) {
        
        for (NSString *key in vitalData.allKeys) {
            
            // Blood Pressure Data
            if([key isEqualToString:OMRONVitalDataWeightKey]) {
                
                NSMutableArray *uploadData = [vitalData objectForKey:key];
                
                // Save to DB
                if([uploadData count] > 0) {
                    
                    ILogMethodLine(@"Weight Data - %@", uploadData);
                    
                    [self saveWeightReadingsToDB:uploadData withDeviceInfo:deviceInfo];
                    [self saveDeviceDataHistory:deviceInfo];
                }
                
                // Update UI with last element in Blood Pressure
                NSMutableDictionary *latestData = [uploadData lastObject];
                
                if(latestData) {
                    
                }else {
                    
                    self.lblPeripheralError.text = @"No new weight readings";
                }
                
            }
        }
        
    }else {
        
        self.lblPeripheralError.text = @"No new readings transferred";
    }
    
    // To showcase delay and end data transfer - required when doing operations in app in between data transfer
    if(isWait)
        [self performSelector:@selector(continueDataTransfer) withObject:nil afterDelay:1.0];
    else
        [self continueDataTransfer];
    
}

- (void)continueDataTransfer {
    
    // End Data Transfer and update device
    [[OmronPeripheralManager sharedManager] endDataTransferFromPeripheralWithCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil) {
                
                ILogMethodLine(@"Device Information - %@", [peripheral getDeviceInformation]);
                ILogMethodLine(@"Device Settings - %@", [peripheral getDeviceSettings]);
                
                NSMutableDictionary *deviceSettings = peripheral.getDeviceSettings;
                
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                                                
                        [self updateUIWithVitalDeviceInfomation:deviceSettings];
                        if(vitalData.allKeys.count > 0) {
                            
                            for (NSString *key in vitalData.allKeys) {
                                
                                if([key isEqualToString:OMRONVitalDataWeightKey]) {
                                    
                                    NSMutableArray *uploadData = [vitalData objectForKey:key];
                                    NSMutableDictionary *latestData = [uploadData lastObject];
                                                                        
                                    if(latestData) {
                                        
                                        [self updateUIWithVitalData:latestData];
                                    }
                                }
                            }
                        }else {
                            
                            self.lblPeripheralError.text = @"No new readings transferred";
                        }
                    }
                }];
            }else {
                [self resetLabels];
                
                self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                self.lblPeripheralError.text = [error localizedDescription];
                
                ILogMethodLine(@"Error - %@", error);
            }
        });
    }];
    
}

#pragma mark - Data Save

- (void)saveWeightReadingsToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *weightItem in dataList) {
        
        NSManagedObject *weightinfo = [NSEntityDescription
                                       insertNewObjectForEntityForName:@"WeightData"
                                       inManagedObjectContext:context];
        
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [weightItem valueForKey:OMRONWeightDataStartDateKey]] forKey:@"startDate"];
        
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightKey] forKey:@"weight"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightBodyFatLevelClassificationKey] forKey:@"bodyFatLevelClassification"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightBodyFatPercentageKey] forKey:@"bodyFatPercentage"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightRestingMetabolismKey] forKey:@"restingMetabolism"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightSkeletalMusclePercentageKey] forKey:@"skeletalMusclePercentage"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightBMIKey] forKey:@"bMI"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightBodyAgeKey] forKey:@"bodyAge"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightVisceralFatLevelKey] forKey:@"visceralFatLevel"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightVisceralFatLevelClassificationKey] forKey:@"visceralFatLevelClassification"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightSkeletalMuscleLevelClassificationKey] forKey:@"skeletalMuscleLevelClassification"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightBMILevelClassificationKey] forKey:@"bMIMuscleLevelClassification"];
        
        // Set Device Information
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [weightinfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightDataUserIdKey] forKey:@"user"];
        
        NSError *error;
        if (![context save:&error]) {
            
        }
    }
}

- (void)saveDeviceDataHistory:(NSMutableDictionary *)deviceInfo {
    if (!deviceInfo) {
        // If device information is invalid, do nothing or perform error handling
        return;
    }

    NSString *localName = [self localName];
    NSString *displayName = [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey];
    NSString *category = [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey];
    NSString *identifier = [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceIdentifierKey];

    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *context = [appDel managedObjectContext];
    // 1. Create a fetch request to retrieve device information
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DeviceDataHistory"];
    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (results.count == 0) {
        // Add initial value if data does not exist
        NSManagedObject *initialData = [NSEntityDescription insertNewObjectForEntityForName:@"DeviceDataHistory" inManagedObjectContext:context];
        
        [initialData setValue:localName forKey:@"localName"];
        [initialData setValue:displayName forKey:@"displayName"];
        [initialData setValue:category forKey:@"category"];
        [initialData setValue:identifier forKey:IdentifierKey];
        
        // keep
        if (![context save:&error]) {
            NSLog(@"Failed to save initial value: %@", [error localizedDescription]);
        }
    }else{
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName ==[c] %@", localName];

        // 2. Check for duplicates
        NSError *fetchError;
        NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&fetchError];

        if (fetchError) {
            // You can do error handling
            return;
        }

        if (fetchedObjects.count == 0) {
            // 3. Save only if there are no duplicates
            NSManagedObject *poInfo = [NSEntityDescription insertNewObjectForEntityForName:@"DeviceDataHistory" inManagedObjectContext:context];
            [poInfo setValue:localName forKey:@"localName"];
            [poInfo setValue:displayName forKey:@"displayName"];
            [poInfo setValue:category forKey:@"category"];
            [poInfo setValue:identifier forKey:IdentifierKey];
            

            NSError *saveError;
            if (![context save:&saveError]) {
                // You can do error handling
            }
        }
    }
}

#pragma mark - CoreBluetooth Notifications

- (void)centralManagerDidUpdateStateNotification:(NSNotification *)aNotification {
    
    OMRONBLEBluetoothState bluetoothState = (OMRONBLEBluetoothState)[aNotification.object unsignedIntegerValue] ;
    
    if(bluetoothState == OMRONBLEBluetoothStateOn) {
        ILogMethodLine(@"%@",  @"Bluetooth is currently powered on.");
    }else if(bluetoothState == OMRONBLEBluetoothStateOff) {
        ILogMethodLine(@"%@",  @"Bluetooth is currently powered off.");
    }else if(bluetoothState == OMRONBLEBluetoothStateUnknown) {
        ILogMethodLine(@"%@",  @"Bluetooth is in unknown state");
    }
}

- (void)peripheralDisconnected {
    
    ILogMethodLine(@"Omron Peripheral Disconnected");
}

- (void)setConnectionStateNotifications {
    
    [[OmronPeripheralManager sharedManager] onConnectStateChangeWithCompletionBlock:^(int state) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *status = @"-";
            
            if (state == OMRONBLEConnectionStateConnecting) {
                isConnect = YES;
                status = @"Connecting...";
            } else if (state == OMRONBLEConnectionStateConnected) {
                status = @"Connected";
            } else if (state == OMRONBLEConnectionStateDisconnecting) {
                isConnect = NO;
                status = @"Disconnecting...";
            } else if (state == OMRONBLEConnectionStateDisconnect) {
                status = @"Disconnected";
                self.searching.hidden = YES;
                self.transferButton.enabled = YES;
                self.transferButton.backgroundColor = [self getCustomColor];
                self.btnReadingList.enabled = YES;
            }
            
            self.lblStatus.text = status;
        });
    }];
}

#pragma mark - Navigations and actions

- (IBAction)readingListButtonPressed:(id)sender {
    
    if(localPeripheral) {

        [localPeripheral getDeviceInformationWithCompletionBlock:^(NSMutableDictionary *deviceInfo, NSError *error) {
            
            ILogMethodLine(@"Device Information - %@", deviceInfo);
            
            NSMutableDictionary *currentDevice = [[NSMutableDictionary alloc] init];
            [currentDevice setValue:[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] forKey:LocalNameKey];
            [currentDevice setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelNameKey] forKey:ModelNameKey];
            [currentDevice setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:OMRONBLEConfigDeviceCategoryKey];
            [currentDevice setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceIdentifierKey] forKey:OMRONBLEConfigDeviceIdentifierKey];
            
            // Weight Scale Device
            WeightReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WeightReadingsViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
            
        }];
    }
}

#pragma mark - Settings update for Connectivity library

- (void)getScanSettings:(NSMutableArray **)deviceSettings withPairing:(BOOL)pairing{
    NSDictionary *scanModeSettings =
        @{ OMRONDeviceScanSettingsModeKey : pairing ? @(OMRONDeviceScanSettingsModePairing) : @(OMRONDeviceScanSettingsModeMismatchSequence)};
    BOOL addFlag = YES;
    for (NSDictionary *settings in *deviceSettings) {
        if ([settings objectForKey:OMRONDeviceScanSettingsKey]) {
            [settings setValue:scanModeSettings forKey:OMRONDeviceScanSettingsKey];
            addFlag = NO;
            break;
        }
    }
    if (addFlag) {
         NSMutableDictionary *scanSettings = [[NSMutableDictionary alloc] init];
        [scanSettings setObject:scanModeSettings forKey:OMRONDeviceScanSettingsKey];
        [*deviceSettings addObject:scanSettings];
    }
}
#pragma mark - Utility UI Functions

- (void)updateUIWithVitalData:(NSMutableDictionary *)vitalData{
    
    self.lblWeightUnit.text = @"Kg";
    
    // Set display unit
    self.lblWeightUnit.hidden = NO;
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[vitalData valueForKey:OMRONWeightDataStartDateKey] doubleValue]];
    self.lblTimeStamp.text = [self getDateTime:date];
    
    self.lblWeight.text = [self convertDoubleToString:[vitalData valueForKey:OMRONWeightKey]];
    NSString *weightKg = [self convertDoubleToString:[vitalData valueForKey:OMRONWeightKey]];
    if([vitalData containsKey:OMRONWeightLbsKey]){
        
        self.lblWeightUnit.hidden = YES;
        NSString *weightLbs = [self convertDoubleToString:[vitalData valueForKey:OMRONWeightLbsKey]];
        self.lblWeight.text = [NSString stringWithFormat:@"%@ Kg　/　%@ Lbs", weightKg, weightLbs];
    }

    self.lblBodyFat.text = [self convertDoubleToString:[vitalData valueForKey:OMRONWeightBodyFatPercentageKey]];
    self.lblRestingMetabolism.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWeightRestingMetabolismKey]];
    self.lblSkeletalMuscle.text = [self convertDoubleToString:[vitalData valueForKey:OMRONWeightSkeletalMusclePercentageKey]];
    self.lblBMI.text = [self convertDoubleToString:[vitalData valueForKey:OMRONWeightBMIKey]];
    self.lblBodyAge.text = [self convertDoubleToString:[vitalData valueForKey:OMRONWeightBodyAgeKey]];
    self.lblVisceralFat.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWeightVisceralFatLevelKey]];
    self.lblUserSelected.text =  [NSString stringWithFormat:@"User %@", [vitalData valueForKey:OMRONWeightDataUserIdKey]];
    self.lblSequenceNumber.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWeightDataSequenceKey]];
    
    
}

- (void)resetLabels {
    
    self.btnReadingList.enabled = YES;
    self.transferButton.enabled = YES;
    self.transferButton.backgroundColor = [self getCustomColor];
    self.searching.hidden = YES;
    self.lblStatus.text = @"-";
    self.lblPeripheralError.text = @"-";
    self.lblPeripheralErrorCode.text = @"-";
    self.lblTimeStamp.text = @"-";
    self.lblWeight.text = @"-";
    self.lblBodyFat.text = @"-";
    self.lblRestingMetabolism.text = @"-";
    self.lblSkeletalMuscle.text = @"-";
    self.lblBMI.text = @"-";
    self.lblVisceralFat.text = @"-";
    self.lblUserSelected.text = @"-";
    self.lblDateOfBirth.text = @"-";
    self.lblGender.text = @"-";
    self.lblHeight.text = @"-";
    self.lblSequenceNumber.text = @"-";
    self.lblDisplayPriorityBodyFat.text = @"-";
    self.lblDisplayPriorityVisceralFatLv.text = @"-";
    self.lblDisplayPrioritySkeletalMuscleLv.text = @"-";
    self.lblDisplayPriorityRestingMetabolism.text = @"-";
    self.lblDisplayPriorityBMI.text = @"-";
    self.lblDisplayPriorityBodyAge.text = @"-";
    self.lblDisplayEnableBodyFat.text = @"-";
    self.lblDisplayEnableVisceralFatLv.text = @"-";
    self.lblDisplayEnableSkeletalMuscleLv.text = @"-";
    self.lblDisplayEnableRestingMetabolism.text = @"-";
    self.lblDisplayEnableBMI.text = @"-";
    self.lblDisplayEnableBodyAge.text = @"-";
    self.lblTimeFormat.text = @"-";
    self.lblDateFormat.text = @"-";
    self.lblWeightUnitDevice.text = @"-";
    self.lblBatteryRemaining.text = @"-";
    self.lblBodyAge.text = @"-";
    self.lblWeightUnit.text = @"-";
    
}

- (void)updateLocalPeripheral:(OmronPeripheral *)peripheral {
    localPeripheral = peripheral;
}

- (NSString *)convertDoubleToString:(NSNumber *)value withMaximumFractionDigits:(NSUInteger)maxFractionDigits {
    if ([value isKindOfClass:[NSNull class]]) {
        return @"(null)";
    }
    double doubleValue = [value doubleValue];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    numberFormatter.minimumFractionDigits = 0;
    numberFormatter.maximumFractionDigits = maxFractionDigits;
    return [numberFormatter stringFromNumber:@(doubleValue)];
}

- (NSString *)convertDoubleToString:(NSNumber *)value {
    return [self convertDoubleToString:value withMaximumFractionDigits:2];
}

- (void)configureLabelVisibilyty {
#ifdef OMRON_DEVTEST
    CGFloat newHeight = 470.0;
    [self updateBodyCompositionViewHeight:newHeight];
    self.lblDisplayPriorityVisceralFatLv.hidden = NO;
    self.lbldisplayPriorityVisceralFatLv.hidden = NO;
    
    self.lblDisplayPrioritySkeletalMuscleLv.hidden = NO;
    self.lbldisplayPrioritySkeletalMuscleLv.hidden = NO;
    
    self.lblDisplayPriorityRestingMetabolism.hidden = NO;
    self.lbldisplayPriorityRestingMetabolism.hidden = NO;
    
    self.lblDisplayPriorityBMI.hidden = NO;
    self.lbldisplayPriorityBMI.hidden = NO;
    
    self.lblDisplayPriorityBodyAge.hidden = NO;
    self.lbldisplayPriorityBodyAge.hidden = NO;
    
    self.lblDisplayPriorityBodyFat.hidden = NO;
    self.lbldisplayPriorityBodyFat.hidden = NO;
    
    self.lblDisplayEnableVisceralFatLv.hidden = NO;
    self.lbldisplayEnableVisceralFatLv.hidden = NO;
    
    self.lblDisplayEnableSkeletalMuscleLv.hidden = NO;
    self.lbldisplayEnableSkeletalMuscleLv.hidden = NO;
    
    self.lblDisplayEnableRestingMetabolism.hidden = NO;
    self.lbldisplayEnableRestingMetabolism.hidden = NO;
    
    self.lblDisplayEnableBMI.hidden = NO;
    self.lbldisplayEnableBMI.hidden = NO;
    
    self.lblDisplayEnableBodyAge.hidden = NO;
    self.lbldisplayEnableBodyAge.hidden = NO;
    
    self.lblDisplayEnableBodyFat.hidden = NO;
    self.lbldisplayEnableBodyFat.hidden = NO;
    
    self.lblTimeFormat.hidden = NO;
    self.lbltimeFormat.hidden = NO;
    
    self.lblDateFormat.hidden = NO;
    self.lbldateFormat.hidden = NO;
    
    self.lblweightUnitDevice.hidden = NO;
    self.lblWeightUnitDevice.hidden = NO;

    self.lblsequenceNumberTitle.hidden = NO;
    self.lblSequenceNumber.hidden = NO;
#else
    CGFloat newHeight = 150.0;
    [self updateBodyCompositionViewHeight:newHeight];
    self.lblDisplayPriorityVisceralFatLv.hidden = YES;
    self.lbldisplayPriorityVisceralFatLv.hidden = YES;
    
    self.lblDisplayPrioritySkeletalMuscleLv.hidden = YES;
    self.lbldisplayPrioritySkeletalMuscleLv.hidden = YES;
    
    self.lblDisplayPriorityRestingMetabolism.hidden = YES;
    self.lbldisplayPriorityRestingMetabolism.hidden = YES;
    
    self.lblDisplayPriorityBMI.hidden = YES;
    self.lbldisplayPriorityBMI.hidden = YES;
    
    self.lblDisplayPriorityBodyAge.hidden = YES;
    self.lbldisplayPriorityBodyAge.hidden = YES;
    
    self.lblDisplayPriorityBodyFat.hidden = YES;
    self.lbldisplayPriorityBodyFat.hidden = YES;
    
    self.lblDisplayEnableVisceralFatLv.hidden = YES;
    self.lbldisplayEnableVisceralFatLv.hidden = YES;
    
    self.lblDisplayEnableSkeletalMuscleLv.hidden = YES;
    self.lbldisplayEnableSkeletalMuscleLv.hidden = YES;
    
    self.lblDisplayEnableRestingMetabolism.hidden = YES;
    self.lbldisplayEnableRestingMetabolism.hidden = YES;
    
    self.lblDisplayEnableBMI.hidden = YES;
    self.lbldisplayEnableBMI.hidden = YES;
    
    self.lblDisplayEnableBodyAge.hidden = YES;
    self.lbldisplayEnableBodyAge.hidden = YES;
    
    self.lblDisplayEnableBodyFat.hidden = YES;
    self.lbldisplayEnableBodyFat.hidden = YES;
    
    self.lblTimeFormat.hidden = YES;
    self.lbltimeFormat.hidden = YES;
    
    self.lblDateFormat.hidden = YES;
    self.lbldateFormat.hidden = YES;
    
    self.lblweightUnitDevice.hidden = YES;
    self.lblWeightUnitDevice.hidden = YES;

    self.lblsequenceNumberTitle.hidden = YES;
    self.lblSequenceNumber.hidden = YES;
#endif
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.scrollView flashScrollIndicators];
    [self.omronDevicesScrollView flashScrollIndicators];
}

- (void)updateBodyCompositionViewHeight:(CGFloat)newHeight {
    // Get height constraint
    NSLayoutConstraint *heightConstraint = nil;
    for (NSLayoutConstraint *constraint in self.bodyCompositionDevicesInfomationView.constraints) {
        if (constraint.firstItem == self.bodyCompositionDevicesInfomationView && constraint.firstAttribute == NSLayoutAttributeHeight) {
            heightConstraint = constraint;
            break;
        }
    }

    //Update if height constraint is found
    if (heightConstraint) {
        heightConstraint.constant = newHeight;
    }

    // Rearrange Auto Layout
    [self.bodyCompositionDevicesInfomationView setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.3 animations:^{
        [self.bodyCompositionDevicesInfomationView layoutIfNeeded];
    }];
}

- (void) updateUIWithVitalDeviceInfomation:(NSMutableDictionary *)DeviceSettingsData{
    NSString *dateOfBirthValue = @"-";
    NSString *gender = @"-";
    NSString *height = @"-";
    NSString *batteryRemaining = @"-";
    
    NSString *displayPriorityBodyFat = @"-";
    NSString *displayPriorityVisceralFatLv = @"-";
    NSString *displayPrioritySkeletalMuscleLv = @"-";
    NSString *displayPriorityRestingMetabolism = @"-";
    
    NSString *displayPriorityBMI = @"-";
    NSString *displayPriorityBodyAge = @"-";
    NSString *displayEnableBodyFat = @"-";
    NSString *displayEnableVisceralFatLv = @"-";
    
    NSString *displayEnableSkeletalMuscleLv = @"-";
    NSString *displayEnableRestingMetabolism = @"-";
    NSString *displayEnableBMI = @"-";
    NSString *displayEnableBodyAge = @"-";
    
    NSString *timeFormat = @"-";
    NSString *dateFormat = @"-";
    NSString *weightUnitDevice = @"-";
    
    
    for (NSDictionary *settings in DeviceSettingsData) {
        if ([settings containsKey:OMRONDeviceTimeSettingsKey]) {
            NSDictionary *deviceTimeSettings = [settings objectForKey:OMRONDeviceTimeSettingsKey];
            NSString *stringValue = [deviceTimeSettings[OMRONDeviceTimeSettingsFormatKey] description];
            NSInteger intValue = [stringValue integerValue];
            if (intValue == OMRONDeviceTimeFormat12Hour) {
                timeFormat = [NSString stringWithFormat:@"%ld(12h)", (long)OMRONDeviceTimeFormat12Hour];
            } else if (intValue == OMRONDeviceTimeFormat24Hour) {
                timeFormat = [NSString stringWithFormat:@"%ld(24h)", (long)OMRONDeviceTimeFormat24Hour];
            } else {
                timeFormat = @"-";
            }
        }
        
        if ([settings containsKey:OMRONDeviceDateSettingsKey]) {
            NSDictionary *deviceDateSettings = [settings objectForKey:OMRONDeviceDateSettingsKey];
            NSString *stringValue = [deviceDateSettings[OMRONDeviceDateSettingsFormatKey] description];
            NSInteger intValue = [stringValue integerValue];
            if (intValue == OMRONDeviceDateFormatDayMonth) {
                dateFormat = [NSString stringWithFormat:@"%ld(DD/MM)", (long)OMRONDeviceDateFormatDayMonth];
            } else if (intValue == OMRONDeviceDateFormatMonthDay) {
                dateFormat = [NSString stringWithFormat:@"%ld(MM/DD)", (long)OMRONDeviceDateFormatMonthDay];
            } else {
                dateFormat = @"-";
            }
        }
        
        if ([settings containsKey:OMRONDeviceWeightSettingsKey]) {
            NSDictionary *deviceWeightSettings = [settings objectForKey:OMRONDeviceWeightSettingsKey];
            NSString *stringValue = [deviceWeightSettings[OMRONDeviceWeightSettingsUnitKey] description];
            NSInteger intValue = [stringValue integerValue];
            if (intValue == OMRONDeviceWeightUnitKg) {
                weightUnitDevice = [NSString stringWithFormat:@"%ld(kg)", (long)OMRONDeviceWeightUnitKg];
            } else if (intValue == OMRONDeviceWeightUnitSt) {
                weightUnitDevice = [NSString stringWithFormat:@"%ld(St)", (long)OMRONDeviceWeightUnitSt];
            } else if (intValue == OMRONDeviceWeightUnitLbs) {
                weightUnitDevice = [NSString stringWithFormat:@"%ld(Lbs)", (long)OMRONDeviceWeightUnitLbs];
            } else {
                weightUnitDevice = @"-";
            }
        }
        
        if([settings containsKey:OMRONDevicePersonalSettingsKey]){
            NSDictionary *personalSettings = settings[OMRONDevicePersonalSettingsKey];
            for (NSDictionary* mainKey in personalSettings.allKeys) {
                NSDictionary *userNumberPersonal = personalSettings[mainKey];
                
                if([userNumberPersonal containsKey:OMRONDevicePersonalSettingsWeightKey]){
                    NSDictionary *devicePersonalSettingsSettingsWeight = userNumberPersonal[OMRONDevicePersonalSettingsWeightKey];
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayPriorityBodyFatKey]){
                        displayPriorityBodyFat = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayPriorityBodyFatKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayPriorityVisceralFatLevelKey]){
                        displayPriorityVisceralFatLv = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayPriorityVisceralFatLevelKey];
                    }
                    
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayPrioritySkeletalMuscleLevelKey]){
                        displayPrioritySkeletalMuscleLv = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayPrioritySkeletalMuscleLevelKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayPriorityRestingMetabolismKey]){
                        displayPriorityRestingMetabolism = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayPriorityRestingMetabolismKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayEnableVisceralFatLevelKey]){
                        displayEnableVisceralFatLv = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayEnableVisceralFatLevelKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayEnableSkeletalMuscleLevelKey]){
                        displayEnableSkeletalMuscleLv = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayEnableSkeletalMuscleLevelKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayEnableRestingMetabolismKey]){
                        displayEnableRestingMetabolism = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayEnableRestingMetabolismKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayEnableBMIKey]){
                        displayEnableBMI = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayEnableBMIKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayPriorityBMIKey]){
                        displayPriorityBMI = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayPriorityBMIKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayPriorityBodyAgeKey]){
                        displayPriorityBodyAge = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayPriorityBodyAgeKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayEnableBodyAgeKey]){
                        displayEnableBodyAge = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayEnableBodyAgeKey];
                    }
                    if([devicePersonalSettingsSettingsWeight containsKey:OMRONDevicePersonalSettingsWeightDisplayEnableBodyFatKey]){
                        displayEnableBodyFat = devicePersonalSettingsSettingsWeight[OMRONDevicePersonalSettingsWeightDisplayEnableBodyFatKey];
                    }
                }
                
                if([userNumberPersonal containsKey:OMRONDevicePersonalSettingsUserDateOfBirthKey]){
                    dateOfBirthValue = userNumberPersonal[OMRONDevicePersonalSettingsUserDateOfBirthKey];
                }else{
                    
                }
                if([userNumberPersonal containsKey:OMRONDevicePersonalSettingsUserGenderKey]){
                    NSString *stringValue = [userNumberPersonal[OMRONDevicePersonalSettingsUserGenderKey] description];
                    NSInteger intValue = [stringValue integerValue];
                    if (intValue == OMRONDevicePersonalSettingsUserGenderTypeMale) {
                        gender = [NSString stringWithFormat:@"%ld(Male)", (long)OMRONDevicePersonalSettingsUserGenderTypeMale];
                    }else if (intValue == OMRONDevicePersonalSettingsUserGenderTypeFemale){
                        gender = [NSString stringWithFormat:@"%ld(Female)", (long)OMRONDevicePersonalSettingsUserGenderTypeFemale];
                    }else{
                        gender = @"-";
                    }
                }
                if([userNumberPersonal containsKey:OMRONDevicePersonalSettingsUserHeightKey]){
                    NSString *heightStr = userNumberPersonal[OMRONDevicePersonalSettingsUserHeightKey];
                    NSString *heightExp = userNumberPersonal[OMRONDevicePersonalSettingsUserHeightExponentKey];
                    height = [NSString stringWithFormat:@"%g", [heightStr doubleValue] * pow(10, [heightExp intValue])];
                }
            }
        }
    }
    
    NSMutableDictionary *deviceInformation = [localPeripheral getDeviceInformation];
    if([deviceInformation containsKey:OMRONDeviceInformationBatteryRemainingKey]){
        batteryRemaining = [NSString stringWithFormat:@"%@%%", deviceInformation[OMRONDeviceInformationBatteryRemainingKey]];
    }
    NSDate *date = [self getDateOfBirthNSDateType:dateOfBirthValue Format:@"yyyyMMdd"];
    dateOfBirthValue = [self getDate:date];
    self.lblDateOfBirth.text = [NSString stringWithFormat:@"%@", dateOfBirthValue];
    self.lblGender.text = [NSString stringWithFormat:@"%@", gender];
    self.lblHeight.text = [NSString stringWithFormat:@"%@", height];
    self.lblDisplayPriorityVisceralFatLv.text = [NSString stringWithFormat:@"%@", displayPriorityVisceralFatLv];
    self.lblDisplayPrioritySkeletalMuscleLv.text = [NSString stringWithFormat:@"%@", displayPrioritySkeletalMuscleLv];
    self.lblDisplayPriorityRestingMetabolism.text = [NSString stringWithFormat:@"%@", displayPriorityRestingMetabolism];
    self.lblDisplayPriorityBMI.text = [NSString stringWithFormat:@"%@", displayPriorityBMI];
    self.lblDisplayPriorityBodyAge.text = [NSString stringWithFormat:@"%@", displayPriorityBodyAge];
    self.lblDisplayPriorityBodyFat.text = [NSString stringWithFormat:@"%@", displayPriorityBodyFat];
    self.lblDisplayEnableBodyFat.text = [NSString stringWithFormat:@"%@", displayEnableBodyFat];
    self.lblDisplayEnableVisceralFatLv.text = [NSString stringWithFormat:@"%@", displayEnableVisceralFatLv];
    
    self.lblDisplayEnableSkeletalMuscleLv.text = [NSString stringWithFormat:@"%@", displayEnableSkeletalMuscleLv];
    self.lblDisplayEnableRestingMetabolism.text = [NSString stringWithFormat:@"%@", displayEnableRestingMetabolism];
    self.lblDisplayEnableBMI.text = [NSString stringWithFormat:@"%@", displayEnableBMI];
    self.lblDisplayEnableBodyAge.text = [NSString stringWithFormat:@"%@", displayEnableBodyAge];
    self.lblTimeFormat.text = [NSString stringWithFormat:@"%@", timeFormat];
    self.lblDateFormat.text = [NSString stringWithFormat:@"%@", dateFormat];
    self.lblWeightUnitDevice.text = [NSString stringWithFormat:@"%@", weightUnitDevice];
    self.lblBatteryRemaining.text = batteryRemaining;
}

- (void)getPersonalSettings:(NSMutableArray **)deviceSettings {
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
                
        NSNumber *height = [object valueForKey:HeightKey];
        
        NSString *dateOfBirth = [object valueForKey:DateOfBirthKey];
        
        NSNumber *gender = [object valueForKey:GenderKey];
        
        NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : height,
                                        OMRONDevicePersonalSettingsUserDateOfBirthKey : dateOfBirth,
                                        OMRONDevicePersonalSettingsUserGenderKey : gender};
        
        [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
        
    }
    [*deviceSettings addObject:personalSettings];
}

- (void)getWeightSettings:(NSMutableArray **)deviceSettings {
    
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
    [*deviceSettings addObject:weightSettings];
}

- (void)getTimeFormat:(NSMutableArray **)deviceSettings {
    
    // Time Format
    NSNumber *timeFormat24Hour = @(OMRONDeviceTimeFormat24Hour);
    NSDictionary *timeFormatSettings = @{ OMRONDeviceTimeSettingsFormatKey : timeFormat24Hour };
    NSMutableDictionary *timeSettings = [[NSMutableDictionary alloc] init];
    [timeSettings setObject:timeFormatSettings forKey:OMRONDeviceTimeSettingsKey];
    
    [*deviceSettings addObject:timeSettings];
}
@end
