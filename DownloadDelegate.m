//
//  DownloadDelegate.m
//  Camera Buddy
//
//  Created by Andre Anjos on 10/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import "DownloadDelegate.h"
#import "Image.h"
#import "utils.h"

@implementation DownloadDelegate

@synthesize openCameras = mOpenCameras;
@synthesize requestQueue = mRequestQueue;

- (id)init {

  if ( self = [super init] ) {
    mOpenCameras = [[NSMutableArray alloc] initWithCapacity:0];
    mRequestQueue = [[NSMutableArray alloc] init];
  }

  return self;

}

- (void)dealloc {
  [mRequestQueue release];
  [mOpenCameras release];
  [super dealloc];
}

// camera delegate
- (void)didRemoveDevice:(ICDevice *)device
{
  // implement manual observer notification for the openCameras property
  [self willChangeValueForKey:@"openCameras"];
  [mOpenCameras removeObject:device];
  [self didChangeValueForKey:@"openCameras"];
}

// camera delegate
- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error
{
  // implement manual observer notification for the openCameras property
  [self willChangeValueForKey:@"openCameras"];
  [mOpenCameras removeObject:device];
  [self didChangeValueForKey:@"openCameras"];
}

// camera delegate
- (void)deviceDidBecomeReady:(ICDevice*)device
{
  // implement manual observer notification for the openCameras property
  [self willChangeValueForKey:@"openCameras"];
  //NSLog(@"Adding camera %@ on %@", device.name, self);
  [mOpenCameras addObject:device];
  [self didChangeValueForKey:@"openCameras"];
}

-(void) cameraDevice:(ICCameraDevice*)device didReceiveThumbnailForItem:(ICCameraFile*)file
{
  if (!file.thumbnailIfAvailable) return;
  NSImage* thumbImage = [[NSImage alloc] initWithCGImage:file.thumbnailIfAvailable size:NSZeroSize];
  [thumbnail setImage:thumbImage];
  [thumbnail displayIfNeeded];
}

// start download
-(void) addFile:(ICCameraFile*)file
{
  if (![mRequestQueue count]) {
    [progressIndicator setMinValue:0.0];
    [progressIndicator setDoubleValue:0.0];
    [statusText setStringValue:[NSString stringWithFormat:@"0/0 Mb"]];
    [NSApp beginSheet:progressWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
  }
  
  double total = 0.0;
  for (ICCameraFile* file in mRequestQueue) total += file.fileSize;
  [progressIndicator setMaxValue:total];
  [self willChangeValueForKey:@"requestQueue"];
  [mRequestQueue addObject:file];
  [self didChangeValueForKey:@"requestQueue"];
}

// download delegate itself
- (void)didDownloadFile:(ICCameraFile*)file 
  error:(NSError*)error 
  options:(NSDictionary*)options 
  contextInfo:(void*)contextInfo
{
  const unsigned long Mb = 1024 * 1024;
  [progressIndicator setDoubleValue:[progressIndicator doubleValue] + [file fileSize]];
  [statusText setStringValue:[NSString stringWithFormat:@"%.0f/%.0f Mb", [progressIndicator doubleValue]/Mb,
    [progressIndicator maxValue]/Mb ] ];
  [self willChangeValueForKey:@"requestQueue"];
  [mRequestQueue removeObject:file];
  [self didChangeValueForKey:@"requestQueue"];
  if (![mRequestQueue count]) {
    BOOL clockSynchronized = [self synchronizeClock:file.device]; //try to synchronize the clock of this camera
    [NSApp endSheet:progressWindow];
    [progressWindow orderOut:self];
    NSString* message = [NSString stringWithString:@"All files downloaded successfully."];
    if (clockSynchronized) message = [message stringByAppendingString:@" Camera clock synchronized."];
    [messageText setStringValue:message];
    [NSApp beginSheet:messageWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
  }

  NSURL* downloadPath = [options valueForKey:ICDownloadsDirectoryURL];
  Image* image = [[Image alloc] initWithURL:[downloadPath URLByAppendingPathComponent:[options valueForKey:ICSavedFilename]]];
  [image makeNameLowerCaseFileName];

  //update the thumbnail on the progress window...
  //NSRect thumbnailSize = [thumbnail bounds];
  //NSImage* thumbImage = [image createThumbnail:[NSNumber numberWithInt:thumbnailSize.size.width]];
  //[thumbnail setImage:thumbImage];
  //[thumbnail displayIfNeeded];
  //[thumbImage release];
  
  //now we rotate the file, if required by the user
  if (isOn(rotatePhotos)) [image normalizeExifOrientation];

  [thumbnail setImage:[image getImage]];
  [thumbnail displayIfNeeded];

  //adjust the photo time, if requested
  if (isOn(adjustPhotoTime)) {
    int value = [adjustPhotoTimeBySeconds doubleValue];
    [image adjustPhotoTimeBy:[NSNumber numberWithInt:value]];
  }

  //adjust the reading permissions
  if (isOn(makeGroupWriteable)) [image makeGroupWriteable];
  else [image makeReadeableToAll];
    
  //finally, we save the image, releasing internal allocations that avoid saving too many times.
  [image save];
  [image release];
}

- (BOOL)synchronizeClock:(ICCameraDevice*)device
{
  if (isOn(synchronizeClock) && cameraHasCapability(device, ICCameraDeviceCanSyncClock)) {
    [device requestSyncClock];
    return YES;
  }
  return NO;
}

@end
