/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import "EtreCheckToolbar.h"

// A toolbar that validates properly.
@implementation EtreCheckToolbar

- (void) validateVisibleItems
  {
  for(NSToolbarItem * toolbarItem in self.visibleItems)
    [toolbarItem validate];
  }

@end
