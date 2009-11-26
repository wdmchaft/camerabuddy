/*
 *  utils.cpp
 *  Camera Buddy
 *
 *  Created by Andre Anjos on 24/11/2009.
 *  Copyright 2009 CERN. All rights reserved.
 *
 */

#include "utils.h"

BOOL isOn (NSButton* button) {
  return [button state] == NSOnState;
}

NSURL* createDirectory (NSString* outputDirectory, NSString* outputDirectoryFormat,
  NSString* overrideLocale, BOOL makeGroupWriteable, NSDate* referenceDate, NSError* error)
{
  NSString *converted = convertDateTemplate(outputDirectoryFormat, overrideLocale, referenceDate);
  NSString *dir = [NSString stringWithFormat:@"%@/%@", outputDirectory, converted];
  dir = [dir stringByExpandingTildeInPath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSNumber* posixPermissions = NULL;
  if (makeGroupWriteable) posixPermissions = [NSNumber numberWithInt:0775];
  else posixPermissions = [NSNumber numberWithInt:0755];
  NSDictionary *attr = [NSDictionary dictionaryWithObject:posixPermissions forKey:NSFilePosixPermissions];
  BOOL success = [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:attr error:&error];
  if (!success) return NULL;
  //NSLog(@"Created directory %@", dir);
  return [NSURL fileURLWithPath:dir isDirectory:YES];
}

NSString* convertDateTemplate (NSString* outputDirectoryFormat,
                               NSString* overrideLocale,
                               NSDate* referenceDate)
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  NSLocale *userLocale = [[NSLocale alloc] initWithLocaleIdentifier:overrideLocale];
  [dateFormatter setLocale:userLocale];
  [dateFormatter setDateFormat:outputDirectoryFormat];
  NSString *converted = [[dateFormatter stringFromDate:referenceDate] lowercaseString];
  [dateFormatter release];
  [userLocale release];
  //NSLog(@"Converting %@ gave us %@", outputDirectoryFormat, converted);
  return converted;
}

BOOL cameraHasCapability(ICCameraDevice* device, NSString* capability)
{
  NSArray* capabilities = [device valueForKey:@"capabilities"];
  return [capabilities containsObject:capability];
}

void overwriteIfExists(NSMutableDictionary* dict, NSString* key, id value)
{
  if ([dict objectForKey:key]) [dict setObject:value forKey:key];
}

NSDate* convertExifDate (NSString* date)
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  NSLocale *userLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  [dateFormatter setLocale:userLocale];
  [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
  NSDate *converted = [dateFormatter dateFromString:date];
  [dateFormatter release];
  [userLocale release];
  return converted;
}

NSString* convertDateWithFormat (NSDate* date, NSString* format)
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  NSLocale *userLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  [dateFormatter setLocale:userLocale];
  [dateFormatter setDateFormat:format];
  NSString *converted = [dateFormatter stringFromDate:date];
  [dateFormatter release];
  [userLocale release];
  return converted;
}