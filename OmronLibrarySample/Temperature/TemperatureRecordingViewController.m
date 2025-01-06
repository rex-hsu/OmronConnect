//
//  TemperatureRecordingViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/17/21.
//  Copyright © 2021 Omron HealthCare Inc. All rights reserved.
//

#import "TemperatureRecordingViewController.h"
#import "OmronLogger.h"
@interface TemperatureRecordingViewController () {
    
    BOOL isRecording;
}

@property (weak, nonatomic) IBOutlet UIButton *recordingButton;
@property (weak, nonatomic) IBOutlet UILabel *instructionErrorLabel;
@property (weak, nonatomic) IBOutlet UILabel *lblTimestamp;
@property (weak, nonatomic) IBOutlet UILabel *lblTemperture;
@property (weak, nonatomic) IBOutlet UILabel *lblSignalLevel;
@end

@implementation TemperatureRecordingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recordingButton.layer.cornerRadius = 5.0; // 5.0 indicates the radius to round
    self.recordingButton.layer.masksToBounds = YES;
    
    [self customNavigationBarTitle:@"Record Temperature" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    isRecording = NO;
    
    // Set UI
    [self resetView];
    
    // Configure Peripheral Manager
    [self startOmronPeripheralManager];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self requestMicrophonePermission];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Stop recording
    [[OmronPeripheralManager sharedManager] stopRecordingWithCompletionBlock:nil];
}

- (IBAction)recordingButtonPressed:(id)sender {
    
    if(isRecording) {
        
        [self.recordingButton setTitle:@"Start" forState:UIControlStateNormal];
        
        // Stop recording
        [[OmronPeripheralManager sharedManager] stopRecordingWithCompletionBlock:nil];
        
        // Update UI
        [self resetView];
        
    }else {
        
        [self.recordingButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        // Start recording
        [self startRecording];
    }
    
    isRecording = !isRecording;
}

/**
 Start Recording
 */
- (void)startRecording {
    
    // Reset UI
    self.instructionErrorLabel.text = @"Turn ON Thermometer and place near microphone. Transferring in progress...";
    self.lblTimestamp.text = @"-";
    self.lblTemperture.text = @"-";
    self.lblSignalLevel.text = @"-";
    
    // Configure OMRON Peripheral with Local Name per specification
    OmronPeripheral *peripheral = [[OmronPeripheral alloc] initWithLocalName:OMRONThermometerMC280B andUUID:@""];
    
    // Start Recording
    [[OmronPeripheralManager sharedManager] startRecording:peripheral
                                          onSignalStrength:^(double signal) {
        
        // Output SignalLevel
        self.lblSignalLevel.text = [NSString stringWithFormat:@"%ld ", (long)[self signalLevel:signal]];
    } withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        if(error == nil) {
            
            ILogMethodLine(@"Device Information - %@", [peripheral getDeviceInformation]);
            
            [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                
                ILogMethodLine(@"vitalData - %@", vitalData);
                if(vitalData) {
                    // Update UI
                    [self updateUIWithData:vitalData];
                }else {
                    // No readings
                    self.instructionErrorLabel.text = @"Turn OFF Thermometer";
                }
                
            }];
        }else {
            
            ILogMethodLine(@"Error - %@", error);
            self.instructionErrorLabel.text = [NSString stringWithFormat:@"%@", [error localizedDescription]];
        }
        
        // Stop recording
        [[OmronPeripheralManager sharedManager] stopRecordingWithCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
           
            ILogMethodLine(@"Device Information - %@", [peripheral getDeviceInformation]);
        }];
        
        isRecording = !isRecording;
        
        [self.recordingButton setTitle:@"Start" forState:UIControlStateNormal];
        
    }];
}

// Start Omron Peripheral Manager
- (void)startOmronPeripheralManager {
    
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
    
    
    // Set Configuration to New Configuration (mandatory to set configuration)
    [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:peripheralConfig];
    
    // Start OmronPeripheralManager (mandatory)
    [[OmronPeripheralManager sharedManager] startManager];
    
}

/**
 Update UI with data
 */
- (void)updateUIWithData:(NSMutableDictionary *)vitalData {
    
    if(vitalData.allKeys.count > 0) {
        
        for (NSString *key in vitalData.allKeys) {
            
            // Temperature Data
            if([key isEqualToString:OMRONVitalDataTemperatureKey]) {
                
                NSMutableArray *uploadData = [vitalData objectForKey:key];
                NSMutableDictionary *latestData = [uploadData lastObject];
                
                if(latestData) {
                    
                    if([latestData valueForKey:OMRONTemperatureLevelKey] != nil) {
                        if([[latestData valueForKey:OMRONTemperatureLevelKey] integerValue] == OMRONTemperatureLevelTypeHigh) {
                            self.lblTemperture.text = @"Temperature High. Record again.";
                        }else if([[latestData valueForKey:OMRONTemperatureLevelKey] integerValue] == OMRONTemperatureLevelTypeLow) {
                            self.lblTemperture.text = @"Temperature Low. Record again.";
                        }
                    }else {
                        // Temperature with unit
                        self.lblTemperture.text = [NSString stringWithFormat:@"%@%@", [latestData valueForKey:OMRONTemperatureKey], [[latestData valueForKey:OMRONTemperatureUnitKey] integerValue] == OMRONTemperatureUnitTypeCelsius ? @"°C" : @"°F"];
                    }
                    
                    // Date time of recording
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[latestData valueForKey:OMRONTemperatureDataStartDateKey] doubleValue]];
                    self.lblTimestamp.text = [self getDateTime:date];
                    self.instructionErrorLabel.text = @"Turn OFF Thermometer";
                    
                }else {
                    
                    self.instructionErrorLabel.text = @"No readings. Turn OFF Thermometer.";
                }
            }
        }
    }
}

/**
 Signal Level update
 */
- (NSInteger)signalLevel:(double)signal {
    
    NSInteger level;
    
    if (signal > 30) {
        level = 5;
    }
    else if (signal > 26) {
        level = 4;
    }
    else if (signal > 22) {
        level = 3;
    }
    else if (signal > 18) {
        level = 2;
    }
    else if (signal > 14) {
        level = 1;
    }
    else {
        level = 0;
    }
    
    return level;
}

#pragma mark - UI functionalities

/**
 Set UI Labels
 */
- (void)resetView {
    self.lblTimestamp.text = @"-";
    self.lblTemperture.text = @"-";
    self.lblSignalLevel.text = @"-";
    self.instructionErrorLabel.text = @"Turn ON Thermometer. \nBegin transferring temperature reading by placing Thermometer near microphone of smartphone.";
}

@end
