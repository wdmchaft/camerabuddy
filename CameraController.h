//
//  CameraController.h
//  Camera Buddy
//
//  Created by Andre Anjos on 05/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/Automator.h>
#import "DeviceBrowserDelegate.h"
#import "DownloadDelegate.h"

@interface CameraController : NSObject {
  IBOutlet NSPopUpButton *deviceList;
  IBOutlet NSButton *transferButton;
  IBOutlet DownloadDelegate* downloadDelegate;
  IBOutlet NSWindow *messageWindow;
  IBOutlet NSTextField *messageText;
  IBOutlet NSWindow *mainWindow;
  IBOutlet NSTextField *progressText;
  
  //these are the app settings
  IBOutlet NSButton *moveFiles;
  IBOutlet NSButton *makeGroupWriteable;
  IBOutlet NSTextField *outputDirectoryFormat;
  IBOutlet NSTextField *overrideLocale;
  IBOutlet NSButton* adjustTime;
  IBOutlet NSTextField *adjustTimeSeconds;
}

- (id) init;
- (void) dealloc;
- (void) startMonitor;
- (IBAction)updateDeviceList:(id)sender;
- (IBAction)transfer:(id)sender;
- (void) observeValueForKeyPath:(NSString*) keyPath 
    ofObject:(id) object
    change:(NSDictionary*) change
    context:(void*) context;
- (IBAction)cancelDownload:(id)sender;
- (IBAction)didSelectDevice:(id)sender;
@end
