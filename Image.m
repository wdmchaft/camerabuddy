//
//  Image.m
//  Camera Buddy
//
//  Created by Andre Anjos on 14/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import "Image.h"
#import <CoreFoundation/CoreFoundation.h>
#import "utils.h"

NSImage* normalizeExifOrientation(NSImage* existingImage, NSNumber* exifOrientation)
{
  /**
   * Some explanation of the EXIF orientation tag can be found here:
   * http://sylvana.net/jpegcrop/exif_orientation.html
   */
  
  /**
   * Verified rotations: 1, 3, 6 and 8
   */
   
  NSImage *rotatedImage = NULL;
  NSSize existingSize = [existingImage size];
  switch ([exifOrientation intValue]) {
    case 5:
    case 6:
    case 7:
    case 8:
      rotatedImage = [[NSImage alloc] initWithSize:NSMakeSize(existingSize.height, existingSize.width)];
      break;
    default:
      rotatedImage = [[NSImage alloc] initWithSize:existingSize];
  }

  NSSize newSize = [rotatedImage size];

  //say we will draw on this one
  [rotatedImage lockFocus];

  NSAffineTransform *tform = [NSAffineTransform transform];
  
  switch ([exifOrientation intValue]) {
    case 2:
      [tform scaleXBy:-1.0 yBy:1.0];
      [tform translateXBy:newSize.width yBy:0];
      break;
    case 3:
      [tform rotateByDegrees: 180];
      [tform translateXBy:-newSize.width yBy:-newSize.height];      
      break;
    case 5:
      break;
    case 6:
      [tform rotateByDegrees: -90];
      [tform translateXBy:-newSize.height yBy:0];      
      break;
    case 7:
      break;
    case 8:
      [tform rotateByDegrees: 90];
      [tform translateXBy:0 yBy:-newSize.width];      
      break;
    default:
      break;
  }
    
  [tform concat];
  [existingImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
  [tform release];
  [rotatedImage unlockFocus];
    
  return rotatedImage;
}

@implementation Image

@synthesize path = mPath;

- (id)initWithURL:(NSURL*)path {


  if ( self = [super init] ) {
    mPath = [path copy];
    mImage = NULL; 
    mProperties = NULL;
    mImageType = NULL;
    mImageNeedsSaving = NO;
   }

  return self;

}

- (void)dealloc {
  if (mImageNeedsSaving) [self save];
  [mPath release];
  [super dealloc];
}

- (void)makeNameLowerCaseFileName
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *fileName = [[mPath lastPathComponent] lowercaseString];
  NSURL *dirName = [mPath URLByDeletingLastPathComponent];
  NSURL *destinationURL = [dirName URLByAppendingPathComponent:fileName];
  NSURL *tmpURL = [dirName URLByAppendingPathComponent:@"tmp.file"];

  NSError *error = nil;
  
  //OSX is very weird about lower/upper case...
  if (![fileManager moveItemAtURL:mPath toURL:tmpURL error:&error]) {
    NSLog(@"Error when renaming files: %@", [error localizedDescription]);
    return;
  }
  if (![fileManager moveItemAtURL:tmpURL toURL:destinationURL error:&error]) {
    NSLog(@"Error when renaming files: %@", [error localizedDescription]);
    return;
  }
  [mPath release];
  mPath = [destinationURL copy];
}

- (BOOL)openToEdit
{
  if (mImage) return YES; //do not open the same image again
  
  CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((CFURLRef)mPath, NULL);
  
  //get the image itself
  CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
  mImage = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
  if (imageRef) CFRelease(imageRef); //?

  //get image properties
  CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
  mProperties = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary*)properties];
  CFRelease(properties);
  mImageType = CGImageSourceGetType(sourceRef);
  
  CFRelease(sourceRef);
  
  mImageNeedsSaving = NO;
  return YES;
}

- (void)save
{
  if (mImageNeedsSaving) {
    //use the next line to overwrite the JPEG compression level.
    //NSLog(@"Jpeg compression level for %@ is %@", mPath, [mProperties valueForKey:(NSString*)kCGImageDestinationLossyCompressionQuality]);
    [mProperties setObject:[NSNumber numberWithFloat:0.95] forKey:(NSString*)kCGImageDestinationLossyCompressionQuality];
    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL((CFURLRef)mPath, mImageType, 1, NULL);
    CGImageRef writeableImage = [mImage CGImageForProposedRect:NULL context:NULL hints:NULL];
    CGImageDestinationAddImage(myImageDest, writeableImage, (CFDictionaryRef)mProperties);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);
            
    //finally, we set the creation time of the file to the expected value, found in the EXIF tag
    NSString* dateString = [mProperties objectForKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
    if (dateString) {
      NSDate* date = convertExifDate(dateString);
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSError *error = nil;
      NSDictionary *attr = [NSDictionary dictionaryWithObject:date forKey:NSFileCreationDate];
      if (![fileManager setAttributes:attr ofItemAtPath:[mPath path] error:&error]) {
        NSLog(@"Error when setting creating date of file: %@", [error localizedDescription]);
      }
    }
  }
  
  [mImage release];
  CFRelease(mImageType);
  [mProperties release];
  mImage = NULL;
  mImageType = NULL;
  mProperties = NULL;
  mImageNeedsSaving = NO;
}

- (void)normalizeExifOrientation
{
  if (![self openToEdit]) return;
  NSNumber* orientation = [NSNumber numberWithInt:[[mProperties objectForKey:(NSString*)kCGImagePropertyOrientation] intValue]];
  //NSLog(@"%@: %@", mPath, orientation);
  NSImage* rotated = normalizeExifOrientation(mImage, orientation);
  [mImage autorelease];
  mImage = rotated;
  NSNumber* newOrientation = [NSNumber numberWithInt:1];
  NSMutableDictionary* tiffProperties = [mProperties objectForKey:(NSString*)kCGImagePropertyTIFFDictionary];
  overwriteIfExists(mProperties, (NSString*)kCGImagePropertyOrientation, newOrientation);
  overwriteIfExists(tiffProperties, (NSString*)kCGImagePropertyTIFFOrientation, newOrientation);
  mImageNeedsSaving = YES;
}

- (void)adjustPhotoTimeBy:(NSNumber*)seconds
{
  if (![self openToEdit]) return;
  NSMutableDictionary* exifProperties = [mProperties objectForKey:(NSString*)kCGImagePropertyExifDictionary];
  NSMutableDictionary* tiffProperties = [mProperties objectForKey:(NSString*)kCGImagePropertyTIFFDictionary];
  NSString* dateString = [exifProperties objectForKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
  
  if (!dateString) return; //no date set on metadata
  
  //gets the date and time the image was taken, convert it into a NSDate object
  NSDate* date = convertExifDate(dateString);
  NSDate* newDate = [date dateByAddingTimeInterval:[seconds doubleValue]];
  NSString* newDateString = convertDateWithFormat(newDate, @"yyyy:MM:dd HH:mm:ss");  
  
  overwriteIfExists(exifProperties, (NSString*)kCGImagePropertyExifDateTimeOriginal, newDateString);
  overwriteIfExists(exifProperties, (NSString*)kCGImagePropertyExifDateTimeDigitized, newDateString);
  overwriteIfExists(tiffProperties, (NSString*)kCGImagePropertyTIFFDateTime, newDateString);

  //GPSDateStamp, GPSTimeStamp, IPTCDateCreated, IPTCTimeCreated ??
  
  mImageNeedsSaving = YES;
}

- (void)setPermissions:(NSNumber*)posixPermissions
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  NSDictionary *attr = [NSDictionary dictionaryWithObject:posixPermissions forKey:NSFilePosixPermissions];
  if (![fileManager setAttributes:attr ofItemAtPath:[mPath path] error:&error]) {
    NSLog(@"Error when setting permission of file: %@", [error localizedDescription]);
  }
}

- (void)makeReadeableToAll
{
  [self setPermissions:[NSNumber numberWithInt:0644]];
}

- (void)makeGroupWriteable
{
  [self setPermissions:[NSNumber numberWithInt:0664]];
}

- (NSImage*)createThumbnail:(NSNumber*)size
{
  //this method is presently UNUSED, we are currently getting the whole image with [getImage] bellow
  if (![self openToEdit]) return NULL; //just to create the property dictionary
  CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((CFURLRef)mPath, NULL);
  NSDictionary* dict = [NSDictionary dictionaryWithObject:size forKey:(NSString*)kCGImageSourceThumbnailMaxPixelSize];
  CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (CFDictionaryRef)dict);
  NSImage* retval = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
  NSNumber* orientation = [NSNumber numberWithInt:[[mProperties objectForKey:(NSString*)kCGImagePropertyOrientation] intValue]];
  retval = normalizeExifOrientation(retval, orientation);
  CFRelease(sourceRef);
  CFRelease(imageRef);
  return retval;
}

- (NSImage*)getImage
{
  if (![self openToEdit]) return NULL; //just to create the property dictionary
  return mImage;  
}

@end
