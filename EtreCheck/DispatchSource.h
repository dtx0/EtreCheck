/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2013. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface DispatchSource : NSObject
  {
  dispatch_source_type_t myType;
  uintptr_t myHandle;
  unsigned long myMask;

  dispatch_queue_t myQueue;
  dispatch_source_t mySource;
  BOOL myEnabled;
  
  dispatch_block_t myEventHandler;
  dispatch_block_t myCancelHandler;
  
  dispatch_time_t myStartTime;
  uint64_t myIntervalTime;
  uint64_t myLeewayTime;
  }

@property (assign) dispatch_source_type_t type;
@property (assign) uintptr_t handle;
@property (assign) unsigned long mask;

@property (readonly) dispatch_queue_t queue;
@property (assign) dispatch_source_t source;
@property (assign) BOOL enabled;

@property (assign) dispatch_block_t eventHandler;
@property (assign) dispatch_block_t cancelHandler;

@property (assign) dispatch_time_t startTime;
@property (assign) uint64_t intervalTime;
@property (assign) uint64_t leewayTime;

// Enable the source.
- (void) enable;

// Disable the source.
- (void) disable;

// Stop the source.
- (void) stop;

@end
