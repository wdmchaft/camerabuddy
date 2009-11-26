//
//  Camera_BuddyAppDelegate.h
//  Camera Buddy
//
//  Created by Andre Anjos on 05/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CameraController.h"
#import "ExampleDateDelegate.h"

@interface Camera_BuddyAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    IBOutlet CameraController *cameraController;
    IBOutlet NSWindow *preferencesWindow;
    IBOutlet NSWindow *messageWindow;
    IBOutlet ExampleDateDelegate *exampleDateDelegate;
    IBOutlet DownloadDelegate *downloadDelegate;
    IBOutlet NSWindow *mainWindow;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)dismissPreferencesWindow:(id)sender;
- (IBAction)resetToFactoryDefaults:(id)sender;
- (IBAction)quitApplication:(id)sender;

@end
