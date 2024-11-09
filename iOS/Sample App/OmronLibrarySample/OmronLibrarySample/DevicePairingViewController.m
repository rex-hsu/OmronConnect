//
//  BPViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import "QuartzCore/QuartzCore.h"
#import "DevicePairingViewController.h"
#import "AppDelegate.h"
#import "BPReadingsViewController.h"
#import "VitalOptionsTableViewController.h"
#import "ReminderListTableViewController.h"
#import "OmronLogger.h"
#import <UserNotifications/UserNotifications.h>
#import "PersonalInfoSettingsViewController.h"
#import "DeviceListViewController.h"
@interface DevicePairingViewController () <UITableViewDataSource, UITableViewDelegate> {
    
    // Tracks Connected Omron Peripheral
    OmronPeripheral *localPeripheral;
    
    NSMutableArray *scannedPeripheral;
    NSMutableDictionary *deviceConfig;
    
    NSMutableArray *selectedUsers;
    NSString *intSelectedUsers;
    int userNumber;
    
    bool isScan;
    bool isConnect;
}

@property (weak, nonatomic) IBOutlet UILabel *lblConnectingSearching;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *devicesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searching;
@property (weak, nonatomic) IBOutlet UIView *connectingToDeviceView;
@property (weak, nonatomic) IBOutlet UIImageView *deviceImageView;
@property (weak, nonatomic) IBOutlet UILabel *lblModelName;
@property (weak, nonatomic) IBOutlet UILabel *lblIdentifier;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (strong, nonatomic) UIButton *btnUser1;
@property (strong, nonatomic) UIButton *btnUser2;
@property (strong, nonatomic) UIButton *btnUser3;
@property (strong, nonatomic) UIButton *btnUser4;

@end

@implementation DevicePairingViewController

#pragma mark - View Controller Life cycles

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.btnCancel.layer.cornerRadius = 5.0; // 5.0 indicates the radius to round
    self.btnCancel.layer.masksToBounds = YES;
    isConnect = NO;
    isScan = NO;
    selectedUsers = [NSMutableArray array];
    
    scannedPeripheral = [[NSMutableArray alloc] init];
    
    [self customNavigationBarTitle:@"Device Pairing" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    // Start OmronPeripheralManager
    [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:YES];
    
    [self checkPersonalSettingData];
    
    [self StartScanning];
    
    
}

// Start Omron Peripheral Manager
- (void)startOmronPeripheralManagerWithHistoricRead:(BOOL)isHistoric withPairing:(BOOL)pairing {
    
    OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
    NSMutableArray *filterDevices = [[NSMutableArray alloc] init];
    
    for(NSString *deviceInfo in self.deviceList){
        // Filter device to scan and connect (optional)
        
        if([deviceInfo valueForKey:OMRONBLEConfigDeviceGroupIDKey] && [deviceInfo valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]) {
            if([self.protocolSelect isEqualToString:BLEDeviceKey]){
                // New Supported Format - Add entire data model to filter list
                [filterDevices addObject:deviceInfo];
            }else{
                if([[deviceInfo valueForKey:OMRONBLEConfigDeviceProtocolKey] isEqualToString:@"OMRONAudioProtocol"]){
                    self.searching.hidden = YES;
                    [scannedPeripheral addObject:deviceInfo];
                    [self.tableView reloadData];
                }
            }
        }
    }
    peripheralConfig.deviceFilters = filterDevices;// Filter Devices
    
    
    // Set Scan timeout interval (optional)
    peripheralConfig.timeoutInterval = 30; // Seconds
    
    // Holds settings
    NSMutableArray *deviceSettings = [[NSMutableArray alloc] init];
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    // Get existing data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonalData"];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (results && results.count > 0) {
        
        [self getPersonalSettings:&deviceSettings];
    }
    [self getWeightSettings:&deviceSettings];
    
    [self getActivitySettings:&deviceSettings];
    // Scan settings (optional)
    [self getScanSettings:&deviceSettings withPairing:pairing];
    
    // Set Device settings to the peripheral
    peripheralConfig.deviceSettings = deviceSettings;
    
    peripheralConfig.enableiBeaconWithTransfer = true;
    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
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
    
    if(isConnect){
        isConnect = NO;
        // Disconnects Omron Peripherals
        [[OmronPeripheralManager sharedManager] disconnectPeripheral:localPeripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {}];
    }
    if(isScan){
        isScan = NO;
        // Stop Scanning for devices if scanning
        [[OmronPeripheralManager sharedManager] stopScanPeripherals];
    }
}

#pragma mark - Table View Data Source and Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return scannedPeripheral.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 65.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:16];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
    OmronPeripheral *peripheral = [scannedPeripheral objectAtIndex:indexPath.row];
    if([self.protocolSelect isEqualToString:BLEDeviceKey]){
        peripheral = [[OmronPeripheral alloc] initWithLocalName:peripheral.localName andUUID:peripheral.UUID];
        OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
        deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
        
        cell.textLabel.text = [deviceConfig valueForKey:OMRONBLEConfigDeviceModelNameKey];
        cell.detailTextLabel.text = peripheral.localName;
    }else{
        peripheral = [[OmronPeripheral alloc] initWithLocalName:OMRONThermometerMC280B andUUID:@""];
        OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
        deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
        
        cell.textLabel.text = [deviceConfig valueForKey:OMRONBLEConfigDeviceModelNameKey];
        cell.detailTextLabel.text = [deviceConfig valueForKey:OMRONBLEConfigDeviceIdentifierKey];
        
    }
    
    cell.detailTextLabel.numberOfLines = 5;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        OmronPeripheral *peripheral = [scannedPeripheral objectAtIndex:indexPath.row];
        if([self.protocolSelect isEqualToString:BLEDeviceKey]){
            if([self existenceDevicePairingDataCheck:[peripheral valueForKey:LocalNameKey] deviceInfo:peripheral]){
                // Stop Scanning for devices if scanning
                [[OmronPeripheralManager sharedManager] stopScanPeripherals];
                [self showDialogtWithMessage:@"This device is already registered." title:@"Info" withAction:@"deviceRegistered" localPeripheral:nil];
            }else{
                self.navigationItem.hidesBackButton = YES;
                self.tableView.hidden = YES;
                self.connectingToDeviceView.hidden = NO;
                self.lblConnectingSearching.text =@"Connecting to device";
                
                peripheral = [[OmronPeripheral alloc] initWithLocalName:peripheral.localName andUUID:peripheral.UUID];
                OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
                deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
                self.filterDeviceModel = deviceConfig;
                // Start OmronPeripheralManager
                [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:YES];
                self.lblModelName.text =[NSString stringWithFormat:@"modelName : %@", [deviceConfig valueForKey:OMRONBLEConfigDeviceModelNameKey]];
                self.lblIdentifier.text =[NSString stringWithFormat:@"identifier : %@", [deviceConfig valueForKey:OMRONBLEConfigDeviceIdentifierKey]];
                self.deviceImageView.image = [UIImage imageNamed:[deviceConfig valueForKey:OMRONBLEConfigDeviceImageKey]];
                intSelectedUsers = [deviceConfig valueForKey:OMRONBLEConfigDeviceUsersKey];
                self.btnCancel.hidden = YES;
                
                [self userNumberSelectionDialog:[[deviceConfig valueForKey:OMRONBLEConfigDeviceUsersKey] intValue] omronPeripheral :  peripheral];
            }
            
            
        }else{
            
            if([self existenceDevicePairingDataCheck:OMRONThermometerMC280B deviceInfo:peripheral]){
                [self showDialogtWithMessage:@"This device is already registered." title:@"Info" withAction:@"deviceRegistered" localPeripheral:nil];
            }else{
                [self showDialogtWithMessage : @"Omron device paired successfully!" title:@"Device paired" withAction : @"pairedSuccessfully" localPeripheral:peripheral];
            }
        }
    });
}

#pragma mark - Connect to Device

- (IBAction)cancelClick:(id)sender {
    
    scannedPeripheral = [[NSMutableArray alloc] init];
    [self.tableView reloadData];
    
    // Stop Scanning of Omron Peripherals
    [self stopScanning];
}

#pragma mark - OmronPeripheralManager Connect / Pair Function

- (void)connectPeripheral:(OmronPeripheral *)peripheral {
    
    // Connects to Peripheral and Pairs device without Wait
    [[OmronPeripheralManager sharedManager] connectPeripheral:peripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        [self connectionUpdateWithPeripheral:peripheral withError:error withWait:NO];
        
    }];
}

- (void)connectPeripheralWithWait:(OmronPeripheral *)peripheral {
    
    // Connects to Peripheral and Pairs device + Wait
    [[OmronPeripheralManager sharedManager] connectPeripheral:peripheral withWait:true withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        [self connectionUpdateWithPeripheral:peripheral withError:error withWait:YES];
        
    }];
}

- (void)resumeConnection {
    
    if([selectedUsers count] > 1) {
        [[OmronPeripheralManager sharedManager] resumeConnectPeripheralWithUsers:selectedUsers withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
            
            [self connectionUpdateWithPeripheral:peripheral withError:error withWait:NO];
        }];
    }else{
        [[OmronPeripheralManager sharedManager] resumeConnectPeripheralWithUser:[[selectedUsers firstObject] intValue] withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
            
            [self connectionUpdateWithPeripheral:peripheral withError:error withWait:NO];
        }];
    }
}

- (void)connectionUpdateWithPeripheral:(OmronPeripheral *)peripheral withError:(NSError *)error withWait:(BOOL)wait {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(error == nil) {
            
            // Save Peripheral Details
            localPeripheral = peripheral;
            
            // Retrieves Peripheral Configuration with GroupId and GroupIncludedGroupID
            OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
            NSMutableDictionary *deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
            ILogMethodLine(@"Device Information - %@", [peripheral getDeviceInformation]);
            ILogMethodLine(@"Device Configuration - %@", deviceConfig);
            ILogMethodLine(@"Device Settings - %@", [peripheral getDeviceSettings]);
            
            // Wait
            if(wait) {
                [self performSelector:@selector(resumeConnection) withObject:nil afterDelay:1.0];
            }else {
                
                [self showDialogtWithMessage : @"Omron device paired successfully!" title:@"Device paired" withAction : @"pairedSuccessfully" localPeripheral:localPeripheral];
                self.searching.hidden = YES;
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        if(vitalData.allKeys.count > 0) {
                            
                            ILogMethodLine(@"Vital Data - %@", vitalData);
                        }
                    }
                }];
            }
            
        }else {
            
            NSString *description = [error localizedDescription];
            NSString *errorCodeString = [NSString stringWithFormat:@"Error: %ld", (long)error.code];
            NSString *combinedString = [NSString stringWithFormat:@"%@\n%@", description, errorCodeString];
            
            [self resetView];
            self.searching.hidden = YES;
            [self showDialogtWithMessage : combinedString title:@"Info" withAction : @"error" localPeripheral:nil];
            ILogMethodLine(@"Error - %@", error);
        }
    });
}

- (void)endConnection {
    
    [[OmronPeripheralManager sharedManager] endConnectPeripheralWithCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error == nil) {
                
                // Save Peripheral Details
                localPeripheral = peripheral;
                
                // Retrieves Peripheral Configuration with GroupId and GroupIncludedGroupID
                OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
                NSMutableDictionary *deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
                ILogMethodLine(@"Device Information - %@", [peripheral getDeviceInformation]);
                ILogMethodLine(@"Device Configuration - %@", deviceConfig);
                ILogMethodLine(@"Device Settings - %@", [peripheral getDeviceSettings]);
                
            }else {
                
                [self resetView];
                ILogMethodLine(@"Error - %@", error);
            }
        });
    }];
}

#pragma mark - Data Save

- (void)savePairingDeviceDataToDB:(NSString *)mainTable peripheral : (OmronPeripheral *)peripheral{
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    NSManagedObject *pairingDeviceInfo = [NSEntityDescription
                                          insertNewObjectForEntityForName:mainTable
                                          inManagedObjectContext:context];
    //Where to set keys and values
    NSString *localName = [peripheral valueForKey:LocalNameKey];
    NSString *uuid = [NSString stringWithFormat:@"%@",[peripheral valueForKey:@"UUID"]];
    
    if([self.protocolSelect isEqualToString:BLEDeviceKey]){
        
        if(![self existenceDevicePairingDataCheck:localName deviceInfo:peripheral]){
            [pairingDeviceInfo setValue:[NSString stringWithFormat:@"%@", localName ] forKey:LocalNameKey];
            [pairingDeviceInfo setValue:[NSString stringWithFormat:@"%@", uuid] forKey:UuidKey];
            // Check if selectedUsers is not empty
            if (selectedUsers.count > 0) {
                // Get value from selectedUsers
                NSNumber *userNumber = selectedUsers[0];
                
                // Set value to pairingDeviceInfo
                [pairingDeviceInfo setValue:userNumber forKey:UserNumberKey];
            } else {
                // Error handling when selectedUsers is empty
                [pairingDeviceInfo setValue:@(1) forKey:UserNumberKey];
            }
            
            [pairingDeviceInfo setValue: [self getPairingSequence:[localPeripheral getDeviceSettings]] forKey:SequenceNumber];
            
            
            NSError *error;
            if ([context save:&error]) {
                
                
            }else {
                
                ILogMethodLine(@"Error Saving pairing device Data");
            }
        }else{
            
        }
        
    }else{
        
        if(![self existenceDevicePairingDataCheck:OMRONThermometerMC280B deviceInfo:peripheral]){
            localName = OMRONThermometerMC280B;
            uuid =@" ";
            [pairingDeviceInfo setValue:[NSString stringWithFormat:@"%@", localName] forKey:LocalNameKey];
            [pairingDeviceInfo setValue:[NSString stringWithFormat:@"%@", uuid] forKey:UuidKey];
            // Check if selectedUsers is not empty
            if (selectedUsers.count > 0) {
                // Get value from selectedUsers
                NSNumber *userNumber = selectedUsers[0];
                
                // Set value to pairingDeviceInfo
                [pairingDeviceInfo setValue:userNumber forKey:UserNumberKey];
            } else {
                // Error handling when selectedUsers is empty
                [pairingDeviceInfo setValue:@(1) forKey:UserNumberKey];
                NSLog(@"selectedUsers is empty.");
            }
            
            [pairingDeviceInfo setValue: @(0) forKey:SequenceNumber];
            
            
            NSError *error;
            if ([context save:&error]) {
                
                
            }else {
                
                ILogMethodLine(@"Error Saving pairing device Data");
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

- (void)resetView {
    self.btnCancel.hidden = YES;
    self.tableView.hidden = YES;
}


-(void) checkPersonalSettingData{
    if([self.protocolSelect isEqualToString:BLEDeviceKey]){
        AppDelegate *appDel = [AppDelegate sharedAppDelegate];
        
        NSManagedObjectContext *context = [appDel managedObjectContext];
        
        // Get existing data
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonalData"];
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
        
        if (results.count < 1) {
            self.btnCancel.hidden = YES;
            [self showDialogtWithMessage : @"Please set personal setting" title : @"Info" withAction : @"NoPersonalSettingData"  localPeripheral:nil];
        }else{
            self.btnCancel.hidden = NO;
        }
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
            
        }else if ([userAction isEqualToString:@"pairedSuccessfully"] || [userAction isEqualToString:@"error"]){
            if([userAction isEqualToString:@"pairedSuccessfully"]){
                [self savePairingDeviceDataToDB:@"PairingDeviceData" peripheral : localPeripheral];
            }
            DeviceListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DeviceListViewController"];
            [self.navigationController pushViewController:controller animated:YES];
        }else if([userAction isEqualToString:@"deviceRegistered"]){
            if([self.protocolSelect isEqualToString:BLEDeviceKey]){
                [self startScanning];
            }
        }
    }];
    
    [configError addAction:okButton];
    [self presentViewController:configError animated:YES completion:nil];
}

- (void)userNumberSelectionDialog:(int)numberOfUsers omronPeripheral : (OmronPeripheral *) peripheral{
    
    switch (numberOfUsers) {
            
        case 2:
            [self selectUser:true omronPeripheral:peripheral];
            break;
            
        case 4:
            [self selectUser:false omronPeripheral:peripheral];
            break;
        default:
            [selectedUsers addObject:@(1)];
            [self connectPeripheral:peripheral];
            break;
    }
}

- (void) StartScanning{
    
    if([self.protocolSelect isEqualToString:BLEDeviceKey]){
        ILogMethodLine(@"Start Scan");
        self.lblConnectingSearching.text =@"Searching for device";
        [self resetView];
        [self checkPersonalSettingData];
        
        self.tableView.hidden = NO;
        self.searching.hidden = NO;
        [self setConnectionStateNotifications];
        [self startScanning];
    }else{
        [self resetView];
        self.lblConnectingSearching.text =@"Select sound wave device";
        self.btnCancel.hidden = NO;
        self.tableView.hidden = NO;
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

- (Boolean) existenceDevicePairingDataCheck : (NSString *)localName deviceInfo : (OmronPeripheral *)deviceInfo{
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PairingDeviceData" inManagedObjectContext:managedContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PairingDeviceData"];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects) {
        if ([[[object valueForKey:LocalNameKey] lowercaseString] isEqualToString:[localName lowercaseString]]) {
            // Strings are matched case-insensitively
            return YES;
        }
    }
    
    return false;
}
- (void) startScanning{
    isScan = YES;
    // Start Scanning of Omron Peripherals
    [[OmronPeripheralManager sharedManager] startScanPeripheralsWithCompletionBlock:^(NSArray *retrievedPeripherals, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            ILogMethodLine(@"Retrieved Peripherals - %@", retrievedPeripherals);
            
            if(error == nil) {
                
                scannedPeripheral = [[NSMutableArray alloc] initWithArray:retrievedPeripherals];
                
                [self.tableView reloadData];
                
            }else {
                
                ILogMethodLine(@"Error - %@", error);
                NSString *description = [error localizedDescription];
                NSString *errorCodeString = [NSString stringWithFormat:@"Error: %ld", (long)error.code];
                NSString *combinedString = [NSString stringWithFormat:@"%@\n%@", description, errorCodeString];
                
                isScan = NO;
                [self resetView];
                scannedPeripheral = [[NSMutableArray alloc] initWithArray:retrievedPeripherals];
                [self showDialogtWithMessage : combinedString title:@"Info" withAction : @"error" localPeripheral:nil];
                [self.tableView reloadData];
            }
        });
    }];
}

- (NSNumber *)getPairingSequence : (NSMutableArray *)deviceSettings{
    for (NSDictionary *settingsDict in deviceSettings) {
        if([settingsDict objectForKey:OMRONDeviceSettingsKey]){
            NSDictionary *lastSequenceNumbersDict = settingsDict[OMRONDeviceSettingsKey];
            if (lastSequenceNumbersDict) {
                
                for (NSDictionary *stt in lastSequenceNumbersDict) {
                    if([lastSequenceNumbersDict objectForKey:OMRONDeviceSettingsLastSequenceNumbersKey]){
                        lastSequenceNumbersDict = lastSequenceNumbersDict[stt];
                        if(lastSequenceNumbersDict){
                            
                            for (NSDictionary *stt2 in lastSequenceNumbersDict) {
                                if([lastSequenceNumbersDict objectForKey:[selectedUsers[0] stringValue]]){
                                    NSNumber *sequenceNumber = lastSequenceNumbersDict[stt2];
                                    return sequenceNumber;
                                }
                                break;
                            }
                        }
                    }
                    break;
                }
            }
        }
        break;
    }
    return @(0);
}

- (void)selectUser : (BOOL) userFlag omronPeripheral : (OmronPeripheral *) peripheral{
    
    int heightDialog = 330;
    int heightCustomView = 200;
    const int MARGIN_VALUE = 50;
    
    // True if the number of users on the device is 2, False otherwise.
    if(userFlag){
        heightDialog = 230;
        heightCustomView = 100;
    }
    
    // Create an instance of the dialog controller
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Please select a user number" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    // Create a constraint on the UIAlertController's view height
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:alertController.view
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:heightDialog];
    [alertController.view addConstraint:heightConstraint];
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Please select a user number" attributes:titleAttributes];
    [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    
    // Create custom view
    int xCustomView = 0;
    int yCustomView = 70;
    int widthCustomView = 270;
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(xCustomView, yCustomView, widthCustomView, heightCustomView)];
    
    int xCoordinate = 0;
    int yCoordinate = 0;
    int contentWidth = 270;
    int contentHeight = 50;
    //Create vUser1 and add tap gesture
    UIView *vUser1 = [[UIView alloc] initWithFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    UITapGestureRecognizer *user1Tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(user1Tapped:)];
    [vUser1 addGestureRecognizer:user1Tapped];
    
    yCoordinate += MARGIN_VALUE;
    // Create vUser2 and add tap gesture
    UIView *vUser2 = [[UIView alloc] initWithFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    UITapGestureRecognizer *user2Tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(user2Tapped:)];
    [vUser2 addGestureRecognizer:user2Tapped];
    
    yCoordinate += MARGIN_VALUE;
    // Create vUser3 and add tap gesture
    UIView *vUser3 = [[UIView alloc] initWithFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    UITapGestureRecognizer *user3Tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(user3Tapped:)];
    [vUser3 addGestureRecognizer:user3Tapped];
    
    yCoordinate += MARGIN_VALUE;
    // Create vUser4 and add tap gesture
    UIView *vUser4 = [[UIView alloc] initWithFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    UITapGestureRecognizer *user4Tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(user4Tapped:)];
    [vUser4 addGestureRecognizer:user4Tapped];
    
    contentWidth = 20;
    contentHeight = 20;
    xCoordinate = 20;
    yCoordinate = 15;
    // Create UIButton
    self.btnUser1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnUser1 setFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    [self.btnUser1 setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
    [self.btnUser1 setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
    self.btnUser1.selected = YES;
    [self.btnUser1 addTarget:self action:@selector(user1Tapped:)forControlEvents:UIControlEventTouchUpInside];
    userNumber = 1;
    
    yCoordinate += MARGIN_VALUE;
    // Create UIButton
    self.btnUser2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnUser2 setFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    [self.btnUser2 setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
    [self.btnUser2 setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
    [self.btnUser2 addTarget:self action:@selector(user2Tapped:)forControlEvents:UIControlEventTouchUpInside];
    
    yCoordinate += MARGIN_VALUE;
    // Create UIButton
    self.btnUser3 = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnUser3 setFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    [self.btnUser3 setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
    [self.btnUser3 setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
    [self.btnUser3 addTarget:self action:@selector(user3Tapped:)forControlEvents:UIControlEventTouchUpInside];
    
    yCoordinate += MARGIN_VALUE;
    // Create UIButton
    self.btnUser4 = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnUser4 setFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    [self.btnUser4 setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
    [self.btnUser4 setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
    [self.btnUser4 addTarget:self action:@selector(user4Tapped:)forControlEvents:UIControlEventTouchUpInside];
    
    contentWidth = 200;
    contentHeight = 20;
    xCoordinate = 50;
    yCoordinate = 15;
    // Create UILabel
    UILabel *lblUser1 = [[UILabel alloc] initWithFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    lblUser1.font = [UIFont systemFontOfSize:14];
    lblUser1.text = @"user 1";
    
    yCoordinate += MARGIN_VALUE;
    // Create UILabel
    UILabel *lblUser2 = [[UILabel alloc] initWithFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    lblUser2.font = [UIFont systemFontOfSize:14];
    lblUser2.text = @"user 2";
    
    yCoordinate += MARGIN_VALUE;
    // Create UILabel
    UILabel *lblUser3 = [[UILabel alloc] initWithFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    lblUser3.font = [UIFont systemFontOfSize:14];
    lblUser3.text = @"user 3";
    
    yCoordinate += MARGIN_VALUE;
    // Create UILabel
    UILabel *lblUser4 = [[UILabel alloc] initWithFrame:CGRectMake(xCoordinate, yCoordinate, contentWidth, contentHeight)];
    lblUser4.font = [UIFont systemFontOfSize:14];
    lblUser4.text = @"user 4";
    
    [customView addSubview:vUser1];
    [customView addSubview:vUser2];
    [customView addSubview:self.btnUser1];
    [customView addSubview:self.btnUser2];
    [customView addSubview:lblUser1];
    [customView addSubview:lblUser2];
    
    //If the number of users on the device is 4
    if(!userFlag){
        [customView addSubview:vUser3];
        [customView addSubview:vUser4];
        [customView addSubview:self.btnUser3];
        [customView addSubview:self.btnUser4];
        [customView addSubview:lblUser3];
        [customView addSubview:lblUser4];
    }
    
    // Add custom view to alert controller
    [alertController.view addSubview:customView];
    
    // Add OK button
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //Write here the process when the OK button is tapped
        [selectedUsers addObject:@(userNumber)];
        [self connectPeripheralWithWait:peripheral];
    }];
    [alertController addAction:okAction];
    // show dialog
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)user1Tapped:(UITapGestureRecognizer *)gesture {
    self.btnUser1.selected = YES;
    self.btnUser2.selected = NO;
    self.btnUser3.selected = NO;
    self.btnUser4.selected = NO;
    userNumber = 1;
}

- (void)user2Tapped:(UITapGestureRecognizer *)gesture {
    self.btnUser1.selected = NO;
    self.btnUser2.selected = YES;
    self.btnUser3.selected = NO;
    self.btnUser4.selected = NO;
    userNumber = 2;

}
- (void)user3Tapped:(UITapGestureRecognizer *)gesture {
    self.btnUser1.selected = NO;
    self.btnUser2.selected = NO;
    self.btnUser3.selected = YES;
    self.btnUser4.selected = NO;
    userNumber = 3;

}

- (void)user4Tapped:(UITapGestureRecognizer *)gesture {
    self.btnUser1.selected = NO;
    self.btnUser2.selected = NO;
    self.btnUser3.selected = NO;
    self.btnUser4.selected = YES;
    userNumber = 4;

}

- (void)getWeightSettings:(NSMutableArray **)deviceSettings {
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBodyComposition) {
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
}

- (void)getActivitySettings:(NSMutableArray **)deviceSettings {
    
    // Activity
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
        
        // Test Functions
        // Time Format
        NSDictionary *timeFormatSettings = @{ OMRONDeviceTimeSettingsFormatKey : @(OMRONDeviceTimeFormat12Hour) };
        NSMutableDictionary *timeSettings = [[NSMutableDictionary alloc] init];
        [timeSettings setObject:timeFormatSettings forKey:OMRONDeviceTimeSettingsKey];
        
        // Date Format
        NSDictionary *dateFormatSettings = @{ OMRONDeviceDateSettingsFormatKey : @(OMRONDeviceDateFormatDayMonth) };
        NSMutableDictionary *dateSettings = [[NSMutableDictionary alloc] init];
        [dateSettings setObject:dateFormatSettings forKey:OMRONDeviceDateSettingsKey];
        
        // Distance Format
        NSDictionary *distanceFormatSettings = @{ OMRONDeviceDistanceSettingsUnitKey : @(OMRONDeviceDistanceUnitMile) };
        NSMutableDictionary *distanceSettings = [[NSMutableDictionary alloc] init];
        [distanceSettings setObject:distanceFormatSettings forKey:OMRONDeviceDistanceSettingsKey];
        
        // Sleep Settings
        // TODO: Values to test
        NSDictionary *sleepTimeSettings = @{ OMRONDeviceSleepSettingsAutomaticKey: @(OMRONDeviceSleepAutomaticOff),
                                             OMRONDeviceSleepSettingsAutomaticStartTimeKey : @"3",
                                             OMRONDeviceSleepSettingsAutomaticStopTimeKey : @"20"
        };
        NSMutableDictionary *sleepSettings = [[NSMutableDictionary alloc] init];
        [sleepSettings setObject:sleepTimeSettings forKey:OMRONDeviceSleepSettingsKey];
        
        // Alarm Settings
        
        // Alarm1 Time
        NSMutableDictionary *alarmTime1 = [[NSMutableDictionary alloc] init];
        [alarmTime1 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime1 setValue:@"54" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm1 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays1 = [[NSMutableDictionary alloc] init];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm1 = [[NSMutableDictionary alloc] init];
        [alarm1 setObject: alarmDays1 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm1 setObject: alarmTime1 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm1 setValue:@(OMRONDeviceAlarmTypeMeasure) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        // Alarm2 Time
        NSMutableDictionary *alarmTime2 = [[NSMutableDictionary alloc] init];
        [alarmTime2 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime2 setValue:@"56" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm2 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays2 = [[NSMutableDictionary alloc] init];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm2 = [[NSMutableDictionary alloc] init];
        [alarm2 setObject: alarmDays2 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm2 setObject: alarmTime2 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm2 setValue:@(OMRONDeviceAlarmTypeNormal) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        
        // Alarm3 Time
        NSMutableDictionary *alarmTime3 = [[NSMutableDictionary alloc] init];
        [alarmTime3 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime3 setValue:@"58" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm3 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays3 = [[NSMutableDictionary alloc] init];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm3 = [[NSMutableDictionary alloc] init];
        [alarm3 setObject: alarmDays3 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm3 setObject: alarmTime3 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm3 setValue:@(OMRONDeviceAlarmTypeMedication) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        // Add Alarm1, Alarm2, Alarm3 to List
        NSMutableArray *alarms = [[NSMutableArray alloc] init];
        [alarms addObject: alarm1];
        [alarms addObject: alarm2];
        [alarms addObject: alarm3];
        
        NSMutableDictionary *alarmSettings = [[NSMutableDictionary alloc] init];
        [alarmSettings setObject:alarms forKey:OMRONDeviceAlarmSettingsKey];
        
        NSMutableArray *notificationEnabledList = [[NSMutableArray alloc] init];
        [notificationEnabledList addObject:@"com.google.Gmail"];
        [notificationEnabledList addObject:@"com.apple.mobilemail"];
        [notificationEnabledList addObject:@"com.apple.mobilephone"];
        [notificationEnabledList addObject:@"com.apple.MobileSMS"];
        [notificationEnabledList addObject:@"com.omronhealthcare.connectivitylibrary"];
        
        NSMutableDictionary *notificationSettings = [[NSMutableDictionary alloc] init];
        [notificationSettings setObject:notificationEnabledList forKey:OMRONDeviceNotificationSettingsKey];
        
        // Notification enable settings
        NSDictionary *notificationEnableSettings = @{ OMRONDeviceNotificationStatusKey : @(OMRONDeviceNotificationStatusOn) };
        NSMutableDictionary *notificationSettingsEnable = [[NSMutableDictionary alloc] init];
        [notificationSettingsEnable setObject:notificationEnableSettings forKey:OMRONDeviceNotificationEnableSettingsKey];
        
        
        [*deviceSettings addObject:notificationSettingsEnable];
        [*deviceSettings addObject:notificationSettings];
        
        [*deviceSettings addObject:timeSettings];
        [*deviceSettings addObject:dateSettings];
        [*deviceSettings addObject:distanceSettings];
        [*deviceSettings addObject:sleepSettings];
        [*deviceSettings addObject:alarmSettings];
    }
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
        
        NSString *originalString = [object valueForKey:DateOfBirthKey];
        
        NSNumber *height = [object valueForKey:HeightKey];
        
        NSString *dateOfBirth = originalString;
        
        NSNumber *gender = [object valueForKey:GenderKey];
        
        NSNumber *stride = [object valueForKey:StrideKey];
        
        NSNumber *weight = [object valueForKey:WeightKey];
        
        NSDictionary *bloodPressurePersonalSettings = @{ OMRONDevicePersonalSettingsBloodPressureTruReadEnableKey : @(OMRONDevicePersonalSettingsBloodPressureTruReadOff),
                                                         OMRONDevicePersonalSettingsBloodPressureTruReadIntervalKey : @(OMRONDevicePersonalSettingsBloodPressureTruReadInterval60)
        };
        NSDictionary *settings = @{};
        if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
            settings = @{               OMRONDevicePersonalSettingsUserHeightKey : height,
                                        OMRONDevicePersonalSettingsUserWeightKey : weight,
                                        OMRONDevicePersonalSettingsUserStrideKey : stride,
                                        OMRONDevicePersonalSettingsTargetStepsKey : @"1000",
                                        OMRONDevicePersonalSettingsTargetSleepKey : @"420",
            };
        }else if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
            settings = @{OMRONDevicePersonalSettingsUserDateOfBirthKey : dateOfBirth,
                         OMRONDevicePersonalSettingsBloodPressureKey : bloodPressurePersonalSettings};
        }else if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBodyComposition) {
            settings = @{ OMRONDevicePersonalSettingsUserHeightKey : height,
                                        OMRONDevicePersonalSettingsUserDateOfBirthKey : dateOfBirth,
                                        OMRONDevicePersonalSettingsUserGenderKey : gender
            };
        }
        [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
        
    }
    self.settingsModel = personalSettings;
    [*deviceSettings addObject:personalSettings];
}

- (void) stopScanning{
    // Stop Scanning of Omron Peripherals
    [[OmronPeripheralManager sharedManager] stopScanPeripheralsWithCompletionBlock:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil) {
                
                DeviceListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DeviceListViewController"];
                [self.navigationController pushViewController:controller animated:YES];
            }
        });
        
    }];
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
                
            }
        });
    }];
}

@end
