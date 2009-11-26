//
//  DeviceBrowserDelegate.h
//  Camera Buddy
//
//  Created by Andre Anjos on 08/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ImageCaptureCore/ImageCaptureCore.h>
#import "DownloadDelegate.h"

@interface DeviceBrowserDelegate : NSObject <ICDeviceBrowserDelegate> {
 
  // Create an instance variable for the device browser
  // and an array for the cameras the browser finds
  ICDeviceBrowser * mDeviceBrowser;
  NSMutableArray * mCameras;
  IBOutlet DownloadDelegate* downloadDelegate;
  
}  

// Cameras are properties of the device browser stored in an array
@property(retain) NSMutableArray* cameras;

-(id) init;
-(void) dealloc;

@end
