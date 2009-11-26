//
//  CameraController.m
//  Camera Buddy
//
//  Created by Andre Anjos on 05/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import "CameraController.h"
#import "ExampleDateDelegate.h"
#import "utils.h"

@implementation CameraController

- (id) init {

  self = [super init];
  return self;
  
}

- (void) dealloc {

  [super dealloc];
  
}

- (void) startMonitor {
  //observe downloadDelegate.OpenCameras
  [downloadDelegate addObserver:self forKeyPath:@"openCameras" options:0 context:NULL];
}

- (void) observeValueForKeyPath:(NSString*) keyPath 
  ofObject:(id) object
  change:(NSDictionary*) change
  context:(void*) context {
  
  if ([keyPath isEqualToString:@"openCameras"]) {
    for (ICCameraDevice* device in [object valueForKey:@"openCameras"]) {
      [device addObserver:self forKeyPath:@"mediaFiles" options:0 context:NULL];
    }
    [self updateDeviceList:object];
  
  } else if ([keyPath isEqualToString:@"mediaFiles"]) {
    [self updateDeviceList:object];
  }
}

- (void)updateMainWindow:(ICCameraDevice*)device {
  [transferButton setEnabled:NO];
  [transferButton setTitle:@"Wait..."];

  if (device) {
    //icon
    NSArray* files = [device valueForKey:@"mediaFiles"];
    
    //first, we check to see if we possess an overwritten icon file for this device
    //NSLog(@"updating with %@...", device.name);
    NSString* customIconFile = [device.name stringByAppendingString:@".icns"];
    NSString* customIconPath = [[NSBundle mainBundle] pathForResource:customIconFile ofType:@""];
    NSImage* newIcon = NULL;
    if (customIconPath != nil) newIcon = [[NSImage alloc] initWithContentsOfFile:customIconPath];
    else newIcon = [[NSImage alloc] initWithCGImage:device.icon size:NSZeroSize];
    
    [NSApp setApplicationIconImage:newIcon];
    [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%d", [files count]]];
    [newIcon release];
  
    //adjust the time difference.
    if (cameraHasCapability(device, ICCameraDeviceCanSyncClock)) [adjustTimeSeconds setDoubleValue:(-1*device.timeOffset)];
    else [adjustTimeSeconds setDoubleValue:0.0];
    [transferButton setEnabled:YES];
  }
  else {
    [NSApp setApplicationIconImage:nil];
    [[NSApp dockTile] setBadgeLabel:nil];
    [transferButton setEnabled:NO];
    [adjustTimeSeconds setDoubleValue:0.0];
    [transferButton setEnabled:NO];
  }
  [transferButton setTitle:@"Transfer"];
}

/**
 * updates the device list at the main window
 */
- (IBAction)updateDeviceList:(id)sender {
  [transferButton setEnabled:NO];
  [transferButton setTitle:@"Wait..."];
  
  [deviceList removeAllItems];
  NSArray* openCameras = [downloadDelegate valueForKey:@"openCameras"];
  for (ICCameraDevice *device in openCameras) {
    NSArray* files = [device valueForKey:@"mediaFiles"];
    NSString* numberOfFiles = NULL;
    if ([files count] == 1) numberOfFiles = [NSString stringWithFormat:@"1 file"];
    else numberOfFiles = [NSString stringWithFormat:@"%d files", [files count]];
    off_t size = 0;
    const off_t kbLimit = 10*1024;
    const off_t mbLimit = kbLimit*1024;
    const off_t gbLimit = mbLimit*1024;
    for (ICCameraFile *file in files) size += file.fileSize;
    if (size > gbLimit) numberOfFiles = [NSString stringWithFormat:@"%@, %d Gb", numberOfFiles, size/(1024*1024*1024)]; 
    else if (size > mbLimit) numberOfFiles = [NSString stringWithFormat:@"%@, %d Mb", numberOfFiles, size/(1024*1024)]; 
    else if (size > kbLimit) numberOfFiles = [NSString stringWithFormat:@"%@, %d kb", numberOfFiles, size/(1024)]; 
    else if (size != 1) numberOfFiles = [NSString stringWithFormat:@"%@, %d bytes", numberOfFiles, size];
    else numberOfFiles = [NSString stringWithFormat:@"%@, 1 byte", numberOfFiles];
    NSString* title = [NSString stringWithFormat:@"%@ (%@)", [device valueForKey:@"name"], numberOfFiles];
    [deviceList addItemWithTitle:title];
  }
  
  //this will also unblock the buttons
  if ([openCameras count]) [self updateMainWindow:[openCameras objectAtIndex:0]];
  else [self updateMainWindow:NULL];
}

- (IBAction)didSelectDevice:(id)sender
{
  //get the selected camera device
  NSUInteger selectedItem = [deviceList indexOfSelectedItem];
  NSUInteger counter = 0;
  ICCameraDevice* selectedDevice = NULL;
  for (ICCameraDevice* device in [downloadDelegate valueForKey:@"openCameras"]) {
    if (counter++ == selectedItem) selectedDevice = device;
  }
  [self updateMainWindow:selectedDevice];
}

/**
 * executes the transfer action, calling the camera manager for this operation
 */
- (IBAction)transfer:(id)sender {

  //get the selected camera device, release everything else...
  NSUInteger selectedItem = [deviceList indexOfSelectedItem];
  NSUInteger counter = 0;
  ICCameraDevice* selectedDevice = NULL;
  for (ICCameraDevice* device in [downloadDelegate valueForKey:@"openCameras"]) {
    if (counter++ == selectedItem) selectedDevice = device;
    else [device requestCloseSession]; //free device for other activities
  }
  
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSString* outputDirectory = [defaults objectForKey:@"outputDirectory"];
  
  //perform the file transfer
  NSMutableDictionary* downloadOptions = [NSMutableDictionary dictionaryWithCapacity:6];
  NSNumber* True = [NSNumber numberWithInt:1];
  NSNumber* False = [NSNumber numberWithInt:0];
  [downloadOptions setValue:True forKey:ICOverwrite];  
  if (isOn(moveFiles)) [downloadOptions setObject:True forKey:ICDeleteAfterSuccessfulDownload];
  else [downloadOptions setObject:False forKey:ICDeleteAfterSuccessfulDownload];
  
  for (ICCameraFile* file in [selectedDevice valueForKey:@"mediaFiles"]) {
    //we need to adjust the time if the user has asked so...
    NSDate* useDate = file.creationDate;
    if (isOn(adjustTime)) useDate = [useDate dateByAddingTimeInterval:[adjustTimeSeconds doubleValue]];
    NSError* error = NULL;
    //compute the directory name
    NSURL *saveToDirectory = createDirectory(outputDirectory, 
                                             [outputDirectoryFormat stringValue], 
                                             [overrideLocale stringValue], 
                                             isOn(makeGroupWriteable), 
                                             useDate, 
                                             error);
    if (!saveToDirectory) {
      NSLog(@"error: %@", [error localizedDescription]);
      [messageText setStringValue:[NSString stringWithFormat:@"Error: Could not create directory at %@. Cause: %@", 
        outputDirectory, [error localizedDescription]]];
      [NSApp beginSheet:messageWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }

    [downloadOptions setObject:saveToDirectory forKey:ICDownloadsDirectoryURL];
    [downloadOptions setObject:file.name forKey:ICSaveAsFilename];
    
    //request the files to be downloaded, transfer control to download window.
    [downloadDelegate addFile:file];
    [selectedDevice requestDownloadFile:file options:downloadOptions downloadDelegate:downloadDelegate 
      didDownloadSelector:@selector(didDownloadFile:error:options:contextInfo:) contextInfo:NULL];
  }
}

- (IBAction) cancelDownload:(id)sender
{
  //get the selected camera device, release everything else...
  NSUInteger selectedItem = [deviceList indexOfSelectedItem];
  NSUInteger counter = 0;
  ICCameraDevice* selectedDevice = NULL;
  for (ICCameraDevice* device in [downloadDelegate valueForKey:@"openCameras"]) {
    if (counter++ == selectedItem) selectedDevice = device;
    else [device requestOpenSession]; //take devices back
  }
  //NSLog(@"Requesting %@ to stop...", selectedDevice.name);
  [selectedDevice cancelDownload];
}

@end
