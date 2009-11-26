//
//  Camera_BuddyAppDelegate.m
//  Camera Buddy
//
//  Created by Andre Anjos on 05/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import "Camera_BuddyAppDelegate.h"
#import "CameraController.h"

@implementation Camera_BuddyAppDelegate

@synthesize window;

+ (void)initialize {

  NSString* initialDefaultsPath;
  NSDictionary* initialDefaults;
    
  initialDefaultsPath = [[NSBundle mainBundle] pathForResource:@"InitialDefaults" ofType:@"plist"];
  assert(initialDefaultsPath != nil);
        
  initialDefaults = [NSDictionary dictionaryWithContentsOfFile:initialDefaultsPath];
  assert(initialDefaults != nil);
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:initialDefaults];
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialDefaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [cameraController startMonitor];
  [cameraController updateDeviceList:aNotification];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  for (ICCameraDevice* device in downloadDelegate.openCameras) [device requestCloseSession];
  return NSTerminateNow;
}

- (IBAction)showPreferencesWindow:(id)sender
{
  [exampleDateDelegate controlTextDidChange:nil];
  [NSApp beginSheet:preferencesWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)dismissPreferencesWindow:(id)sender
{
  [NSApp endSheet:preferencesWindow];
  [preferencesWindow orderOut:sender];
}

- (IBAction)resetToFactoryDefaults:(id)sender
{
  [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:sender];
}

- (IBAction)quitApplication:(id)sender
{
  [NSApp endSheet:messageWindow];
  [messageWindow orderOut:sender];
  [NSApp terminate:sender];
}

@end
