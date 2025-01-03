//
//  PairedDeviceListTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/20/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "PairedDeviceListTableViewController.h"
#import "AppDelegate.h"
#import "BPViewController.h"
#import "PulseOxymeterReadingsViewController.h"
#import "WheezeReadingsViewController.h"
#import "BPReadingsViewController.h"
#import "VitalOptionsTableViewController.h"
#import "WeightReadingsViewController.h"
#import "OmronLogger.h"
@interface PairedDeviceListTableViewController () {
    
    NSMutableArray *devicesList;
}

@property (nonatomic, strong) UIAlertController *alert;

@end

@implementation PairedDeviceListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    devicesList = [self retrieveDevicesFromDB];
    
    // Customize Navigation Bar
    [self customNavigationBarTitle:@"Device Data History" withFont:[UIFont fontWithName:@"Courier" size:16]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return devicesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"devicesCell" forIndexPath:indexPath];
    // Add UILongPressGestureRecognizer to the cell
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [cell addGestureRecognizer:longPressGesture];
    
    NSMutableDictionary *item = [devicesList objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:18];
    cell.textLabel.text = [item valueForKey:@"displayName"];
    
    cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
    cell.detailTextLabel.text = [item valueForKey:@"localName"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableDictionary *currentDevice = [devicesList objectAtIndex:indexPath.row];
        
        if([[currentDevice valueForKey:@"category"] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
            
            // Blood Pressure Device
            BPReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPReadingsViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
            
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
            
            // Activity Device
            VitalOptionsTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"VitalOptionsTableViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryPulseOximeter) {
            
            // Pulse Oxymeter Device
            PulseOxymeterReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PulseOxymeterReadingsViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryWheeze) {
            
            // Wheeze Device
            PulseOxymeterReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WheezeReadingsViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBodyComposition){
            // Weight Device
            WeightReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WeightReadingsViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
        }
        
    });
    
}

- (NSMutableArray *)retrieveDevicesFromDB {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"DeviceDataHistory" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DeviceDataHistory"];
    
    fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:[[entity propertiesByName] objectForKey:@"localName"], [[entity propertiesByName] objectForKey:@"displayName"], [[entity propertiesByName] objectForKey:@"category"],[[entity propertiesByName] objectForKey:@"identifier"], nil];
    fetchRequest.returnsDistinctResults = YES;
    fetchRequest.resultType = NSDictionaryResultType;
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *deviceDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *deviceData = [[NSMutableDictionary alloc] init];
        [deviceData setValue:[info valueForKey:@"localName"] forKey:@"localName"];
        [deviceData setValue:[info valueForKey:@"displayName"] forKey:@"displayName"];
        [deviceData setValue:[info valueForKey:@"category"] forKey:@"category"];
        [deviceData setValue:[info valueForKey:@"identifier"] forKey:@"identifier"];
        
        if(![deviceDataList containsObject:deviceData])
            [deviceDataList addObject:deviceData];
    }
    
    deviceDataList = [[[deviceDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    ILogMethodLine(@"Device list - %@", deviceDataList);

    return deviceDataList;
    
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
    self.alert = [UIAlertController alertControllerWithTitle:@"Delete History" message:@"Are you sure you want to delete history for this device？" preferredStyle:UIAlertControllerStyleAlert];
    // Create an attribute for the title string
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Delete History" attributes:titleAttributes];
    [self.alert setValue:attributedTitle forKey:@"attributedTitle"];
    // Create attributes for message strings
    NSDictionary *messageAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0]
    };
    NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:@"Are you sure you want to delete history for this device？" attributes:messageAttributes];
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
            devicesList = [self retrieveDevicesFromDB];
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
                                   entityForName:@"DeviceDataHistory" inManagedObjectContext:managedContext];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DeviceDataHistory"];
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSMutableDictionary *currentDevice = [devicesList  objectAtIndex:index];
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
    
    NSMutableDictionary *currentDevice = [devicesList  objectAtIndex:index];
    if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
        entity = [NSEntityDescription entityForName:@"BPData" inManagedObjectContext:managedContext];
        fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BPData"];
    }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
        entity = [NSEntityDescription entityForName:@"ActivityData" inManagedObjectContext:managedContext];
        fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ActivityData"];
    }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryPulseOximeter) {
        entity = [NSEntityDescription entityForName:@"PulseOxymeterData" inManagedObjectContext:managedContext];
        fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PulseOxymeterData"];
    }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryWheeze) {
        entity = [NSEntityDescription entityForName:@"WheezeData" inManagedObjectContext:managedContext];
        fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WheezeData"];
    }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBodyComposition) {
        entity = [NSEntityDescription entityForName:@"WeightData" inManagedObjectContext:managedContext];
        fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WeightData"];
    }
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@", [[currentDevice valueForKey:@"localName"] lowercaseString]];
    [fetchRequest setEntity:entity];
    fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSMutableDictionary *currentDevice = [devicesList objectAtIndex:index];
        if([[currentDevice valueForKey:LocalNameKey] caseInsensitiveCompare:[info valueForKey:LocalNameKey]] == NSOrderedSame) {
            [managedContext deleteObject:info];
        }
    }
    
    error = nil;
    if (![managedContext save:&error]) {
        NSLog(@"Failed to delete from Core Data: %@", error);
        // Perform error handling
        return;
    }
}

- (void)closeAlert {
    [self.alert dismissViewControllerAnimated:YES completion:nil];
    self.alert = nil;
}
@end
