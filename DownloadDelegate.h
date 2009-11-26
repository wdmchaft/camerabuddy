//
//  DownloadDelegate.h
//  Camera Buddy
//
//  Created by Andre Anjos on 10/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

@interface DownloadDelegate : NSObject <ICCameraDeviceDelegate> {

  IBOutlet NSImageView *thumbnail;
  IBOutlet NSProgressIndicator *progressIndicator;
  IBOutlet NSTextField *statusText;
  IBOutlet NSWindow *progressWindow;
  IBOutlet NSWindow *messageWindow;
  IBOutlet NSTextField *messageText;
  IBOutlet NSWindow *mainWindow;
  IBOutlet NSButton *adjustPhotoTime;
  IBOutlet NSTextField *adjustPhotoTimeBySeconds;
  IBOutlet NSButton *synchronizeClock;
  IBOutlet NSButton *makeGroupWriteable;
  IBOutlet NSButton *rotatePhotos;
  NSMutableArray *mOpenCameras;
  NSMutableArray *mRequestQueue;
}

@property(retain) NSMutableArray* openCameras;
@property(retain) NSMutableArray* requestQueue;

- (id)init;
- (void)dealloc;
- (void)addFile:(ICCameraFile*)file;
- (BOOL) synchronizeClock:(ICCameraDevice*)device;

@end
