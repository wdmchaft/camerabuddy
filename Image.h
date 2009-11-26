//
//  Image.h
//  Camera Buddy
//
//  Created by Andre Anjos on 14/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Image : NSObject {

  NSURL *mPath;
  NSImage *mImage;
  NSMutableDictionary *mProperties;
  CFStringRef mImageType; 
  BOOL mImageNeedsSaving; 
}

@property(retain) NSURL* path;

- (id)initWithURL:(NSURL*)path;
- (void)dealloc;

// move the file to a lower case basename
- (void)makeNameLowerCaseFileName;

// Adjust the image orientation based on the EXIF markings.
// Please note that this is done in a lossy way. Apple does not
// provide APIs for lossless rotation of jpeg images. You can
// mitigate this problem by peeking the implementation of 'jpegtran'
// that is part of the libjpeg open source package. It requires,
// obviously, the use of libjpeg itself. The way forward is to either
// integrate a new libjpeg framework within this product or having
// it externally and bringing in only the libraries and headers.
- (void)normalizeExifOrientation;

// Adjusts the time on the various time markers inside the image metadata.
// Please note this will need to re-write the image which will re-apply
// compression. Currently, re-writing is done only once even if you apply
// this function many times. Please consult the code for "openToEdit" and
// "save" to figure out why.
- (void)adjustPhotoTimeBy:(NSNumber*)seconds;

// resets file permissions
- (void)setPermissions:(NSNumber*)posixPermissions;
- (void)makeGroupWriteable;
- (void)makeReadeableToAll;

// opens the pointed image for editing
- (void)openToEdit;

// save a currently opened image, overwriting the existing image
- (void)save;

// returns a rotated and resized thumbnail of the image
- (NSImage*)createThumbnail:(NSNumber*)size;

// returns a cocoa image of my current state
- (NSImage*)getImage;

@end
