//
//  ExampleDateDelegate.m
//  Camera Buddy
//
//  Created by Andre Anjos on 14/11/2009.
//  Copyright 2009 CERN. All rights reserved.
//

#import "ExampleDateDelegate.h"
#import "utils.h"

@implementation ExampleDateDelegate

- (void)controlTextDidChange:(NSNotification *)aNotification
{
  NSString* converted = convertDateTemplate([directoryFormat stringValue], [overrideLocale stringValue], [NSDate date]);
  //NSLog(@"Reading format: %@", [directoryFormat stringValue]);
  [directoryExample setStringValue:converted];
}

@end
