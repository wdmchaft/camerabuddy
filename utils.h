/*
 *  utils.h
 *  Camera Buddy
 *
 *  Created by Andre Anjos on 24/11/2009.
 *  Copyright 2009 CERN. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

/**
 * Tells us if a button is in ON state
 */
BOOL isOn (NSButton* button);

/**
 * Helper function to calculate and create the directory required for the photo in question.
 * A reference date is passed as parameter to be used for the outputDirectoryFormat.
 */
NSURL* createDirectory (NSString* outputDirectory, NSString* outputDirectoryFormat,
  NSString* overrideLocale, BOOL makeGroupWriteable, NSDate* referenceDate, NSError* error);

/**
 * Converts a date template using the user defined locale and a reference date
 * Please read information
 * here: http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns for the
 * format acceptable for "outputDirectoryFormat".
 */ 
NSString* convertDateTemplate (NSString* outputDirectoryFormat,
                               NSString* overrideLocale,
                               NSDate* referenceDate);
                               
/**
 * Checks if the camera device has a certain capability.
 */
BOOL cameraHasCapability(ICCameraDevice* device, NSString* capability);

/**
 * Overwrites the value of a key in a dictionary only if it already exists
 */
void overwriteIfExists(NSMutableDictionary* dict, NSString* key, id value);

/**
 * Converts a string in the style yyyy:MM:dd HH:mm:ss into a cocoa date
 */
NSDate* convertExifDate (NSString* date);

/**
 * Converts a cocoa date into a string representation. Please read information
 * here: http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
 * for the description of the format string.
 */
NSString* convertDateWithFormat (NSDate* date, NSString* format);
