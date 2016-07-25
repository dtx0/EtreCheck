/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemLaunchdCollector.h"
#import "Model.h"

@interface LaunchdCollector ()

// Is this a known Apple file?
- (bool) isKnownAppleFile: (NSString *) path
  info: (NSMutableDictionary *) info;

@end

@implementation SystemLaunchdCollector

// Is this a known Apple file?
- (bool) isKnownAppleFile: (NSString * ) path
  info: (NSMutableDictionary *) info
  {
  // First see if this file is claiming Apple status. If so, check to see
  // if I agree. If so, this is a known file.
  if([[info objectForKey: kApple] boolValue])
    {
    NSString * executable = [info objectForKey: kExecutable];

    if([executable length] > 0)
      {
      if([[Model model] isKnownAppleNonShellExecutable: executable])
        return YES;
 
      if([path hasPrefix: @"/System/Library/Launch"])
        return [[Model model] isKnownAppleExecutable: executable];
      }
    }
    
  return NO;
  }

@end
