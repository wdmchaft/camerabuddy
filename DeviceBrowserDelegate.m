//
//  DeviceBrowserDelegate.m
//  Camera Buddy
//
//  Created by Andre Anjos on 08/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import "DeviceBrowserDelegate.h"

@implementation DeviceBrowserDelegate

@synthesize cameras = mCameras;

- (id)init {

  if ( self = [super init] ) {
  
    mCameras = [[NSMutableArray alloc] initWithCapacity:0];
    
    // Get an instance of ICDeviceBrowser
    mDeviceBrowser = [[ICDeviceBrowser alloc] init];
  
    // Assign a delegate
    mDeviceBrowser.delegate = self;
  
    // Look for cameras in all available locations
    mDeviceBrowser.browsedDeviceTypeMask = mDeviceBrowser.browsedDeviceTypeMask 
                                        | ICDeviceTypeMaskCamera
                                        | ICDeviceLocationTypeMaskLocal
                                        | ICDeviceLocationTypeMaskShared
                                        | ICDeviceLocationTypeMaskBonjour
                                        | ICDeviceLocationTypeMaskBluetooth
                                        | ICDeviceLocationTypeMaskRemote;
                                        
    // Start browsing for cameras
    [mDeviceBrowser start];
      
  }
  
  return self;

}

- (void)dealloc {
  mDeviceBrowser.delegate = NULL;          
  [mDeviceBrowser stop];     
  [mDeviceBrowser release];          
  [mCameras release];
  [super dealloc];
}

// device browser delegate
- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{    
  if ( addedDevice.type & ICDeviceTypeCamera ) {
    addedDevice.delegate = downloadDelegate;
    // implement manual observer notification for the cameras property
  
    [self willChangeValueForKey:@"cameras"];
    [mCameras addObject:addedDevice];
    [self didChangeValueForKey:@"cameras"];
    
    [addedDevice requestOpenSession];
  }
}

// device browser delegate
- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing
{
  device.delegate = NULL;
    
  // implement manual observer notification for the cameras property
  [self willChangeValueForKey:@"cameras"];
  [mCameras removeObject:device];
  [self didChangeValueForKey:@"cameras"];
}

@end