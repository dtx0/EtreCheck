/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2013. All rights reserved.
 **********************************************************************/

#import "DispatchSource.h"

@implementation DispatchSource

#pragma mark - Properties

@synthesize type = myType;
@synthesize handle = myHandle;
@synthesize mask = myMask;

@synthesize queue = myQueue;
@synthesize source = mySource;
@synthesize enabled = myEnabled;

@synthesize eventHandler = myEventHandler;
@synthesize cancelHandler = myCancelHandler;

@synthesize startTime = myStartTime;
@synthesize intervalTime = myIntervalTime;
@synthesize leewayTime = myLeewayTime;

// If the type is write, then set the suspended flag so the source can
// be easily enabled and disabled.
- (void) setType: (dispatch_source_type_t) newType
  {
  if(myType != newType)
    {
    [self willChangeValueForKey: @"type"];
    
    myType = newType;
    
    if(myType == DISPATCH_SOURCE_TYPE_WRITE)
      myEnabled = NO;
      
    [self didChangeValueForKey: @"type"];
    }
  }

- (dispatch_source_type_t) type
  {
  return myType;
  }

// Get the dispatch queue, creating it if necessary.
- (dispatch_queue_t) queue
  {
  if(!myQueue)
    {
    NSString * name =
      [NSString
        stringWithFormat:
          @"%@ Q%lu",
          myType == DISPATCH_SOURCE_TYPE_WRITE ? @"Write" : @"Read",
          myHandle];
    
    myQueue = dispatch_queue_create([name UTF8String], NULL);
    }
    
  return myQueue;
  }

// Get the dispatch source, creating it if necessary.
- (dispatch_source_t) source
  {
  if(!mySource)
    {
    mySource =
      dispatch_source_create(self.type, self.handle, self.mask, self.queue);
    
    if(self.eventHandler)
      dispatch_source_set_event_handler(mySource, self.eventHandler);
      
    if(self.cancelHandler)
      dispatch_source_set_cancel_handler(mySource, self.cancelHandler);

    if(self.type == DISPATCH_SOURCE_TYPE_TIMER)
      dispatch_source_set_timer(
        mySource,
        dispatch_walltime(NULL, self.startTime),
        self.intervalTime,
        self.leewayTime);
    }
    
  return mySource;
  }

- (void) setSource: (dispatch_source_t) newSource
  {
  if(mySource != newSource)
    {
    [self willChangeValueForKey: @"source"];
    
    mySource = newSource;
    
    [self didChangeValueForKey: @"source"];
    }
  }

// Get the dispatch event handler.
- (dispatch_block_t) eventHandler
  {
  return myEventHandler;
  }

- (void) setEventHandler: (dispatch_block_t) newHandler
  {
  if(myEventHandler != newHandler)
    {
    [self willChangeValueForKey: @"eventHandler"];
    
    myEventHandler = [newHandler copy];

    [self didChangeValueForKey: @"eventHandler"];
    }
  }

// Get the dispatch cancel handler.
- (dispatch_block_t) cancelHandler
  {
  return myCancelHandler;
  }

- (void) setCancelHandler: (dispatch_block_t) newHandler
  {
  if(myCancelHandler != newHandler)
    {
    [self willChangeValueForKey: @"cancelHandler"];
    
    myCancelHandler = [newHandler copy];

    [self didChangeValueForKey: @"cancelHandler"];
    }
  }

#pragma mark - Housekeeping

- (void) dealloc
  {
  [self stop];
  
  [super dealloc];
  }

#pragma mark - Dispatch source

// Enable the source.
- (void) enable
  {
  if(!self.enabled)
    {
    self.enabled = YES;
    
    dispatch_resume(self.source);
    }
  }

// Disable the source.
- (void) disable
  {
  if(self.enabled)
    {
    self.enabled = NO;
    
    dispatch_suspend(self.source);
    }
  }

// Stop the source.
- (void) stop
  {
  if(self.source)
    {
    [self enable];
    
    dispatch_source_cancel(self.source);

    self.enabled = NO;
    dispatch_release(self.source);
    dispatch_release(self.queue);
    self.source = nil;
    myQueue = nil;
    self.eventHandler = nil;
    self.cancelHandler = nil;
    }
  }

@end

