//
//  PulseOxymeterViewController.m
//  OmronLibrarySample
//
//  Created by Shohei Tomoe on 2022/10/27.
//  Copyright © 2022 Omron HealthCare Inc. All rights reserved.
//

#import  "QuartzCore/QuartzCore.h"
#import "PulseOxymeterViewController.h"
#import "AppDelegate.h"
#import "PulseOxymeterReadingsViewController.h"

#import "AppDelegate.h"
#import "OmronLogger.h"
@interface PulseOxymeterViewController (){
    
    // Tracks Connected Omron Peripheral
    OmronPeripheral *localPeripheral;
    bool isTransfer;
    bool isConnect;
    int counter;
}

@property (weak, nonatomic) IBOutlet UILabel *lblTimeStamp;
@property (weak, nonatomic) IBOutlet UILabel *lblSpO2;
@property (weak, nonatomic) IBOutlet UILabel *lblPulseRate;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblSpO2Unit;
@property (weak, nonatomic) IBOutlet UILabel *lblPulseRateUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblLocalName;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralErrorCode;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralError;
@property (weak, nonatomic) IBOutlet UILabel *lbldeviceModel;
@property (weak, nonatomic) IBOutlet UIView *devicesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searching;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *transferButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnReadingList;
- (IBAction)readingListButtonPressed:(id)sender;

@end

@implementation PulseOxymeterViewController

#pragma mark - View Controller Life cycles

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.transferButton.layer.cornerRadius = 5.0; // 5.0 indicates the radius to round
    self.transferButton.layer.masksToBounds = YES;
    isTransfer = NO;
    isConnect = NO;
    
    [self updateLocalPeripheral: self.omronLocalPeripheral];
    
    counter = 0;
    
    self.devicesView.hidden = NO;
    self.searching.hidden = YES;
    
    self.scrollView.backgroundColor = self.devicesView.backgroundColor;
    
    self.lbldeviceModel.text = [NSString stringWithFormat:@"%@ - Connection Status", [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelDisplayNameKey]];
    self.lblLocalName.text = [NSString stringWithFormat:@"%@\n\n%@", self.omronLocalPeripheral.localName,  self.omronLocalPeripheral.UUID];
    [self customNavigationBarTitle:@"Data Transfer" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    // Default to 1 for single user device
    if(self.users.count == 0) {
        self.users = [[NSMutableArray alloc] initWithArray:@[@(1)]];
    }
    
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
    
    counter++;
    
    [self resetLabels];
    
    self.btnReadingList.enabled = NO;
    self.transferButton.enabled = NO;
    self.transferButton.backgroundColor = [UIColor grayColor];
    self.searching.hidden = NO;
    
    if(localPeripheral) {
            [self startOmronPeripheralManagerWithHistoricRead:YES withPairing:NO];
            [self performDataTransfer];
    }else {
        
        self.lblPeripheralError.text = @"No device paired";
    }
}

- (void)performDataTransfer {
    
    // Connection State
    [self setConnectionStateNotifications];
    
    // Only Activity Device - HeartGuide
    [self onPeriodicNotifications];
    
    OmronPeripheral *peripheralLocal = [[OmronPeripheral alloc] initWithLocalName:localPeripheral.localName andUUID:localPeripheral.UUID];
    
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
    
    OMRONVitalDataTransferCategory category = OMRONVitalDataTransferCategoryAll;
    
    // Activity
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
        if(counter %2 != 0) {
            category = OMRONVitalDataTransferCategoryBloodPressure;
        }
    }
    
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
            
            // PulseOximeter Data
            if([key isEqualToString:OMRONVitalDataPulseOximeterKey]) {
                
                NSMutableArray *uploadData = [vitalData objectForKey:key];
                
                // Save to DB
                if([uploadData count] > 0) {
                    ILogMethodLine(@"Pulse Oxymeter Data - %@", uploadData);
                    ILogMethodLine(@"Pulse Oxymeter Data With Key : %@ \n %@ \n", key, vitalData[key]);
                    
                    // Save to DB
                    [self savePulseOxymeterToDB:uploadData withDeviceInfo:deviceInfo];
                    [self saveDeviceDataHistory:deviceInfo];
                    
                }
                    
                // Update UI with last element in Palus Oxymeter
                NSMutableDictionary *latestData = [uploadData lastObject];
                
                if(latestData) {
                    
                    [self updateUIWithVitalData:latestData];
                    
                }else {
                    
                    self.lblPeripheralError.text = @"No new pluse Oxymeter readings";
                }
            }
            
        }
        
    }else {
        
        self.lblPeripheralError.text = @"No new readings transferred";
    }
    
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
                                
                                if([key isEqualToString:OMRONVitalDataPulseOximeterKey]) {
                                    
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

- (void)savePulseOxymeterToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *bpItem in dataList) {
        
        NSManagedObject *poInfo = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"PulseOxymeterData"
                                   inManagedObjectContext:context];
        
        
        [poInfo setValue:[bpItem valueForKey:OMRONPulseOximeterSPO2LevelKey] forKey:@"spO2"];
        [poInfo setValue:[bpItem valueForKey:OMRONPulseOximeterPulseRateKey] forKey:@"pulse"];
        
        [poInfo setValue:[NSString stringWithFormat:@"%@", [bpItem valueForKey:OMRONPulseOximeterDataStartDateKey]] forKey:@"startDate"];
        
        // Set Device Information
        [poInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [poInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [poInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [poInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        
        [poInfo setValue:[bpItem valueForKey:OMRONPulseOximeterDataUserIdKey] forKey:@"user"];
        
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

- (void)onPeriodicNotifications {
    
    [[OmronPeripheralManager sharedManager] onPeriodicWithCompletionBlock:^{
        
        ILogMethodLine(@"Periodic call from device");
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
            
            if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryPulseOximeter) {
                
                PulseOxymeterReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PulseOxymeterReadingsViewController"];
                controller.selectedDevice = currentDevice;
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }
            
        }];
    }
}

#pragma mark - Utility UI Functions

- (void)updateUIWithVitalData:(NSMutableDictionary *)vitalData {
    
    self.lblSpO2Unit.text = @"%";
    self.lblPulseRateUnit.text = @"bpm";
    
    // Set display unit
    self.lblSpO2Unit.hidden = NO;
    self.lblPulseRateUnit.hidden = NO;
    
    self.lblSpO2.text =  [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONPulseOximeterSPO2LevelKey]];
    self.lblPulseRate.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONPulseOximeterPulseRateKey]];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[vitalData valueForKey:OMRONPulseOximeterDataStartDateKey] doubleValue]];
    self.lblTimeStamp.text = [self getDateTime:date];
}

- (void)resetLabels {
    
    self.btnReadingList.enabled = YES;
    self.transferButton.enabled = YES;
    self.transferButton.backgroundColor = [self getCustomColor];
    self.searching.hidden = YES;
    self.lblSpO2Unit.hidden = YES;
    self.lblPulseRateUnit.hidden = YES;
    self.lblSpO2.text =  @"-";
    self.lblPulseRate.text = @"-";
    self.lblTimeStamp.text = @"-";
    self.lblStatus.text = @"-";
    self.lblPeripheralError.text = @"-";
    self.lblPeripheralErrorCode.text = @"-";
}

- (void)updateLocalPeripheral:(OmronPeripheral *)peripheral {
    localPeripheral = peripheral;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.scrollView flashScrollIndicators];
}
@end

