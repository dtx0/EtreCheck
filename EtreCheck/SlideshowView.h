/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

@class CIImage;
@class CATransition;

@interface SlideshowView : NSView
  {
  NSView * currentView;
  NSView * myMaskView;
  }

// A view to use as a mask.
@property (retain) NSView * maskView;

// Show a new image.
- (void) transitionToImage: (NSImage *) newImage;

// Show a new view.
- (void) transitionToView: (NSView *) newView;

// Set the transition style.
- (void) updateSubviewsWithTransition: (NSString *) transition;

// Set the transition style with subtype.
- (void) updateSubviewsWithTransition: (NSString *) transition
  subType: (NSString *) subtype;

@end