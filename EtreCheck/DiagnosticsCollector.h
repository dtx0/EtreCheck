/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect diagnostics information.
@interface DiagnosticsCollector : Collector
  {
  bool insufficientPermissions;
  
  NSDateFormatter * myDateFormatter;
  NSDateFormatter * myLogDateFormatter;
  
  BOOL hasOutput;
  
  NSMutableSet * myPaths;
  }

@property (retain) NSDateFormatter * dateFormatter;
@property (retain) NSDateFormatter * logDateFormatter;
@property (retain) NSMutableSet * paths;

@end
