//
//  WheezeViewController.m
//  OmronLibrarySample
//
//  Created by TranThanh Tuan on 2023/03/03.
//  Copyright © 2023 Omron HealthCare Inc. All rights reserved.
//

#import "QuartzCore/QuartzCore.h"
#import "WheezeViewController.h"
#import "AppDelegate.h"
#import "WheezeReadingsViewController.h"
#import "AppDelegate.h"
#import "OmronLogger.h"

@interface WheezeViewController (){
    
    // Tracks Connected Omron Peripheral
    OmronPeripheral *localPeripheral;
    bool isTransfer;
    bool isConnect;
    
}

@property (weak, nonatomic) IBOutlet UILabel *lblTimeStamp;
@property (weak, nonatomic) IBOutlet UILabel *lblWheezeKey;
@property (weak, nonatomic) IBOutlet UILabel *lblWheezeErrorNoiseKey;
@property (weak, nonatomic) IBOutlet UILabel *lblWheezeErrorDecreaseBreathingSoundLevelKey;
@property (weak, nonatomic) IBOutlet UILabel *lblWheezeErrorSurroundingNoiseKey;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblLocalName;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralErrorCode;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralError;
@property (weak, nonatomic) IBOutlet UILabel *lbldeviceModel;
@property (weak, nonatomic) IBOutlet UILabel *lblUserSelected;
@property (weak, nonatomic) IBOutlet UILabel *lblSequenceNumber;
@property (weak, nonatomic) IBOutlet UILabel *lblSequenceNumberTitle;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searching;
@property (weak, nonatomic) IBOutlet UILabel *lblBatteryRemaining;
@property (weak, nonatomic) IBOutlet UIButton *transferButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnReadingList;

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

@implementation WheezeViewController

#pragma mark - View Controller Life cycles

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.transferButton.layer.cornerRadius = 5.0; // 5.0 indicates the radius to round
    self.transferButton.layer.masksToBounds = YES;
    isTransfer = NO;
    isConnect = NO;

    //Showing and hiding labels
    [self configureLabelVisibilyty];

    [self updateLocalPeripheral: self.omronLocalPeripheral];
    
    self.lbldeviceModel.text = [NSString stringWithFormat:@"%@ - Connection Status", [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelDisplayNameKey]];
    self.lblLocalName.text = [NSString stringWithFormat:@"%@\n\n%@", self.omronLocalPeripheral.localName,  self.omronLocalPeripheral.UUID];
    [self customNavigationBarTitle:@"Data Transfer" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    // Default to 1 for single user device
    if(self.users.count == 0) {
        self.users = [[NSMutableArray alloc] initWithArray:@[@(1)]];
    }
    
    self.searching.hidden = YES;
    // Start OmronPeripheralManager
    [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:YES];
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
    
    // Disclaimer: Read definition before usage
    peripheralConfig.enableAllDataRead = isHistoric;
    
    // Holds settings
    NSMutableArray *deviceSettings = [[NSMutableArray alloc] init];
    
    // Scan settings (optional)
    [self getScanSettings:&deviceSettings withPairing:pairing];

    // Set Device settings to the peripheral
    peripheralConfig.deviceSettings = deviceSettings;

    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
    // Pass the last sequence number of reading  tracked by app - "SequenceKey" for each vital data (user number and sequence number mapping)
    // peripheralConfig.sequenceNumbersForTransfer = @{@1 : @42, @2 : @8};
    
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
    
    self.transferButton.enabled = NO;
    self.transferButton.backgroundColor = [UIColor grayColor];
    self.btnReadingList.enabled = NO;
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
    
    if([self.users count] > 1) {
        // Use param different to check function availability
    }else {
        // Use regular function with one user type
        [self transferUserDataWithPeripheral:peripheralLocal];
    }
}

// Single User data transfer
- (void)transferUserDataWithPeripheral:(OmronPeripheral *)peripheral {
    
    OMRONVitalDataTransferCategory category = OMRONVitalDataTransferCategoryAll;
    
    /*
     * Starts Data Transfer from Omron Peripherals.
     * endDataTransferFromPeripheralWithCompletionBlock of OmronConnectivityLibrary need to be called once data retrieved is saved
     * For single user device, selected user will be passed as 1
     * withWait : Only YES is supported now
     */
    isTransfer = YES;
    [[OmronPeripheralManager sharedManager] startDataTransferFromPeripheral:peripheral withUser:[[self.users firstObject] intValue] withWait:YES withType:category withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
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
                isTransfer = NO;
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
    
    if(vitalData.allKeys.count > 0) {
        
        for (NSString *key in vitalData.allKeys) {
            
            // Wheeze Data
            if([key isEqualToString:OMRONVitalDataWheezeKey]) {
                
                NSMutableArray *uploadData = [vitalData objectForKey:key];
                
                // Save to DB
                if([uploadData count] > 0) {
                    ILogMethodLine(@"Wheeze Data - %@", uploadData);
                    ILogMethodLine(@"Wheeze Data With Key : %@ \n %@ \n", key, vitalData[key]);
                    
                    // Save to DB
                    [self saveWheezeToDB:uploadData withDeviceInfo:deviceInfo];
                    [self saveDeviceDataHistory:deviceInfo];
                    
                }
                    
                // Update UI with last element in Wheeze
                NSMutableDictionary *latestData = [uploadData lastObject];
                
                if(latestData) {
                    
                    [self updateUIWithVitalData:latestData];
                    [self updateUIWithVitalDeviceInfomation];
                    
                }else {
                    [self updateUIWithVitalDeviceInfomation];
                    self.lblPeripheralError.text = @"No new Wheeze readings";
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
                
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        if(vitalData.allKeys.count > 0) {
                            
                            ILogMethodLine(@"Vital Data - %@", vitalData);
                            
                            for (NSString *key in vitalData.allKeys) {
                                
                                if([key isEqualToString:OMRONVitalDataWheezeKey]) {
                                    
                                    NSMutableArray *uploadData = [vitalData objectForKey:key];
                                    NSMutableDictionary *latestData = [uploadData lastObject];
                                    
                                    if(latestData) {
                                        
                                        [self updateUIWithVitalData:latestData];
                                        [self updateUIWithVitalDeviceInfomation];
                                    }
                                }
                            }
                        }else {
                            [self updateUIWithVitalDeviceInfomation];
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

- (void)saveWheezeToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *bpItem in dataList) {
        
        NSManagedObject *poInfo = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"WheezeData"
                                   inManagedObjectContext:context];
        
        
        [poInfo setValue:[bpItem valueForKey:OMRONWheezeKey] forKey:@"wheeze"];
        [poInfo setValue:[bpItem valueForKey:OMRONWheezeErrorNoiseKey] forKey:@"errorNoise"];
        [poInfo setValue:[bpItem valueForKey:OMRONWheezeErrorDecreaseBreathingSoundLevelKey] forKey:@"errorDecreaseBreathingSoundLevel"];
        [poInfo setValue:[bpItem valueForKey:OMRONWheezeErrorSurroundingNoiseKey] forKey:@"errorSurroundingNoise"];
        [poInfo setValue:[bpItem valueForKey:OMRONWheezeDataUserIdKey] forKey:@"user"];
        [poInfo setValue:[NSString stringWithFormat:@"%@", [bpItem valueForKey:OMRONWheezeDataStartDateKey]] forKey:@"startDate"];
        
        // Set Device Information
        [poInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [poInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [poInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [poInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        
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

- (void)setConnectionStateNotifications {
    
    [[OmronPeripheralManager sharedManager] onConnectStateChangeWithCompletionBlock:^(int state) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *status = @"-";
            
            if (state == OMRONBLEConnectionStateConnecting) {
                status = @"Connecting...";
                isConnect = YES;
            } else if (state == OMRONBLEConnectionStateConnected) {
                status = @"Connected";
            } else if (state == OMRONBLEConnectionStateDisconnecting) {
                status = @"Disconnecting...";
                isConnect = NO;
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
            
            if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryWheeze) {
                
                WheezeReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WheezeReadingsViewController"];
                controller.selectedDevice = currentDevice;
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }
            
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
- (void)updateUIWithVitalData:(NSMutableDictionary *)vitalData {
    
    self.lblWheezeKey.text = [self convertResultNumbersToLettersForWheeze:[NSString stringWithFormat:@"%@",[vitalData valueForKey:OMRONWheezeKey]]];
    self.lblWheezeErrorNoiseKey.text = [self convertResultNumbersToLettersForError:[NSString stringWithFormat:@"%@",[vitalData valueForKey:OMRONWheezeErrorNoiseKey]]];
    self.lblWheezeErrorDecreaseBreathingSoundLevelKey.text = [self convertResultNumbersToLettersForError:[NSString stringWithFormat:@"%@",[vitalData valueForKey:OMRONWheezeErrorDecreaseBreathingSoundLevelKey]]];
    self.lblWheezeErrorSurroundingNoiseKey.text =  [self convertResultNumbersToLettersForError:[NSString stringWithFormat:@"%@",[vitalData valueForKey:OMRONWheezeErrorSurroundingNoiseKey]]];
    self.lblUserSelected.text = [NSString stringWithFormat:@"User %@", [vitalData valueForKey:OMRONWheezeDataUserIdKey]];
    self.lblSequenceNumber.text =  [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWheezeDataSequenceKey]];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[vitalData valueForKey:OMRONWheezeDataStartDateKey] doubleValue]];
    self.lblTimeStamp.text = [self getDateTime:date];
    
}

- (void)resetLabels {
    
    self.transferButton.enabled = YES;
    self.transferButton.backgroundColor = [self getCustomColor];
    self.btnReadingList.enabled = YES;
    self.searching.hidden = YES;
    self.lblTimeStamp.text = @"-";
    self.lblWheezeKey.text =  @"-";
    self.lblWheezeErrorNoiseKey.text = @"-";
    self.lblWheezeErrorDecreaseBreathingSoundLevelKey.text = @"-";
    self.lblWheezeErrorSurroundingNoiseKey.text = @"-";
    self.lblUserSelected.text = @"-";
    self.lblSequenceNumber.text = @"-";
    self.lblStatus.text = @"-";
    self.lblPeripheralError.text = @"-";
    self.lblPeripheralErrorCode.text = @"-";
    self.lblBatteryRemaining.text = @"-";
}

- (void)configureLabelVisibilyty {
#ifdef OMRON_DEVTEST
    self.lblSequenceNumber.hidden = NO;
    self.lblSequenceNumberTitle.hidden = NO;
#else
    self.lblSequenceNumber.hidden = YES;
    self.lblSequenceNumberTitle.hidden = YES;
#endif
}

#pragma mark - Check Result Functions

// The function to check the measurement result.
- (NSString*)convertResultNumbersToLettersForWheeze:(NSString*)resultNumber {
        if (resultNumber == [NSString stringWithFormat:@"%d", OMRONWheezeTypeUndetected]) {
            return [resultNumber stringByAppendingString:@" : Not Detected"];
        }else if (resultNumber == [NSString stringWithFormat:@"%d", OMRONWheezeTypeError]) {
            return [resultNumber stringByAppendingString:@" : Measurement error"];
        } else {
            return [resultNumber stringByAppendingString:@" : Detected"];
        }
}
// The function to check the error result.
- (NSString*)convertResultNumbersToLettersForError:(NSString*)resultNumber {
        if (resultNumber == [NSString stringWithFormat:@"%d", OMRONWheezeErrorTypeNo]) {
            return [resultNumber stringByAppendingString:@" : Not Error"];
        } else {
            return [resultNumber stringByAppendingString:@" : Error"];
        }
}

- (void)updateLocalPeripheral:(OmronPeripheral *)peripheral {
    localPeripheral = peripheral;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.scrollView flashScrollIndicators];
}

- (void) updateUIWithVitalDeviceInfomation{
    NSString *batteryRemaining = @"-";

    NSMutableDictionary *deviceInformation = [localPeripheral getDeviceInformation];
    if([deviceInformation containsKey:OMRONDeviceInformationBatteryRemainingKey]){
        batteryRemaining = [NSString stringWithFormat:@"%@%%", deviceInformation[OMRONDeviceInformationBatteryRemainingKey]];
    }
    self.lblBatteryRemaining.text = batteryRemaining;
}
@end
