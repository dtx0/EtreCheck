/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "AppDelegate.h"
#import "NSMutableAttributedString+Etresoft.h"
#import <ServiceManagement/ServiceManagement.h>
#import <unistd.h>
#import <CarbonCore/BackupCore.h>
#import "ByteCountFormatter.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "Utilities.h"
#import "Checker.h"
#import "SlideshowView.h"
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CoreImage.h>
#import "LaunchdCollector.h"
#import "Model.h"
#import "NSAttributedString+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "DetailManager.h"
#import "HelpManager.h"
#import "EtreCheckToolbarItem.h"

// Toolbar items.
#define kShareToolbarItemID @"sharetoolbaritem"
#define kHelpToolbarItemID @"helptoolbaritem"

NSComparisonResult compareViews(id view1, id view2, void * context);

@interface AppDelegate ()

- (void) collectInfo;

@end

@implementation AppDelegate

@synthesize window;
@synthesize logWindow = myLogWindow;
@synthesize progress = myProgress;
@synthesize spinner = mySpinner;
@synthesize statusView = myStatusView;
@synthesize logView;
@synthesize displayStatus = myDisplayStatus;
@synthesize log;
@synthesize nextProgressIncrement = myNextProgressIncrement;
@synthesize progressTimer = myProgressTimer;
@synthesize machineIcon = myMachineIcon;
@synthesize applicationIcon = myApplicationIcon;
@synthesize magnifyingGlass = myMagnifyingGlass;
@synthesize magnifyingGlassShade = myMagnifyingGlassShade;
@synthesize finderIcon = myFinderIcon;
@synthesize demonImage = myDemonImage;
@synthesize agentImage = myAgentImage;
@synthesize collectionStatus = myCollectionStatus;
@synthesize reportView = myReportView;
@synthesize animationView = myAnimationView;
@synthesize userParametersPanel = myUserParametersPanel;
@synthesize clipboardCopyToolbarItemView = myClipboardCopyToolbarItemView;
@synthesize clipboardCopyButton = myClipboardCopyButton;
@synthesize shareToolbarItemView = myShareToolbarItemView;
@synthesize shareButton = myShareButton;
@synthesize helpToolbarItemView = myHelpToolbarItemView;
@synthesize helpButton = myHelpButton;
@synthesize helpButtonImage = myHelpButtonImage;
@synthesize helpButtonInactiveImage = myHelpButtonInactiveImage;
@synthesize toolbar = myToolbar;
@synthesize detailManager = myDetailManager;
@synthesize helpManager = myHelpManager;
@synthesize adwareManager = myAdwareManager;
@synthesize reportAvailable = myReportAvailable;
@synthesize reportStartTime = myReportStartTime;

@dynamic ignoreKnownAppleFailures;
@dynamic checkAppleSignatures;
@dynamic hideAppleTasks;

- (bool) ignoreKnownAppleFailures
  {
  return [[Model model] ignoreKnownAppleFailures];
  }

- (void) setIgnoreKnownAppleFailures: (bool) ignoreKnownAppleFailures
  {
  [[Model model] setIgnoreKnownAppleFailures: ignoreKnownAppleFailures];
  }

- (bool) checkAppleSignatures
  {
  return [[Model model] checkAppleSignatures];
  }

- (void) setCheckAppleSignatures: (bool) checkAppleSignatures
  {
  [[Model model] setCheckAppleSignatures: checkAppleSignatures];
  }

- (bool) hideAppleTasks
  {
  return [[Model model] hideAppleTasks];
  }

- (void) setHideAppleTasks: (bool) hideAppleTasks
  {
  [[Model model] setHideAppleTasks: hideAppleTasks];
  }

// Destructor.
- (void) dealloc
  {
  self.displayStatus = nil;
  
  [super dealloc];
  }

// Start the application.
- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
  {
  [self checkForUpdates];
  
  [self.window.contentView addSubview: self.animationView];
  
  myDisplayStatus = [NSAttributedString new];
  self.log = [[NSMutableAttributedString new] autorelease];

  [self.logView
    setLinkTextAttributes:
      @{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone),
        NSCursorAttributeName : [NSCursor pointingHandCursor]
      }];
    
  [self.machineIcon updateSubviewsWithTransition: kCATransitionFade];
  [self.machineIcon
    transitionToImage: [[Utilities shared] unknownMachineIcon]];

  [self.applicationIcon updateSubviewsWithTransition: kCATransitionPush];
  [self.applicationIcon
    transitionToImage: [[Utilities shared] genericApplicationIcon]];
        
  [self.magnifyingGlass setHidden: NO];
    
  [self.finderIcon setImage: [[Utilities shared] FinderIcon]];
  [self.demonImage setHidden: NO];
  [self.agentImage setHidden: NO];
  
  //[self.logView setHidden: YES];
  
  [self.animationView
    sortSubviewsUsingFunction: compareViews context: self];
  
  // Set delegate for notification center.
  [[NSUserNotificationCenter defaultUserNotificationCenter]
    setDelegate: self];

  // Handle my own "etrecheck:" URLs.
  NSAppleEventManager * appleEventManager =
    [NSAppleEventManager sharedAppleEventManager];
  
  [appleEventManager
    setEventHandler: self
    andSelector: @selector(handleGetURLEvent:withReplyEvent:)
    forEventClass:kInternetEventClass
    andEventID: kAEGetURL];
  
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [self collectUserParameters];
    });
    
  [self.shareButton sendActionOn: NSLeftMouseDownMask];

  self.progress.layerUsesCoreImageFilters = YES;
  self.spinner.layerUsesCoreImageFilters = YES;
  
  self.helpButtonImage = [NSImage imageNamed: @"Help"];
  self.helpButtonInactiveImage = [NSImage imageNamed: @"HelpInactive"];
  }

// Dim the display on deactivate.
- (void) applicationDidResignActive: (NSNotification *) notification
  {
  NSNumber * curScreenNum =
    [self.window.screen.deviceDescription objectForKey: @"NSScreenNumber"];

  if(!CGDisplayUsesOpenGLAcceleration(curScreenNum.unsignedIntValue))
    return;
    
  CIFilter * grayscale = [CIFilter filterWithName: @"CIColorMonochrome"];
  [grayscale setDefaults];
  [grayscale
    setValue:
      [CIColor colorWithRed: 0.3f green: 0.3f blue: 0.3f alpha: 1.0f]
    forKey: @"inputColor"];
    
  CIFilter * gamma = [CIFilter filterWithName:@"CIGammaAdjust"];
  [gamma setDefaults];
  [gamma setValue: [NSNumber numberWithDouble: 0.3] forKey: @"inputPower"];
    
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      self.helpButton.image = self.helpButtonInactiveImage;
      [self.reportView setContentFilters: @[grayscale, gamma]];
      
      if(self.animationView)
        {
        [self.animationView setContentFilters: @[grayscale, gamma]];

        CIFilter * grayscale =
          [CIFilter filterWithName: @"CIColorMonochrome"];
        [grayscale setDefaults];
        [grayscale
          setValue:
            [CIColor colorWithRed: 0.6f green: 0.6f blue: 0.6f alpha: 1.0f]
          forKey: @"inputColor"];
          
        [self.magnifyingGlassShade setContentFilters: @[grayscale]];
        }
    });
  }

// Un-dim the display on activate.
- (void) applicationWillBecomeActive: (NSNotification *) notification
  {
  NSNumber * curScreenNum =
    [self.window.screen.deviceDescription objectForKey: @"NSScreenNumber"];

  if(!CGDisplayUsesOpenGLAcceleration(curScreenNum.unsignedIntValue))
    return;

  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      self.helpButton.image = self.helpButtonImage;
      [self.reportView setContentFilters: @[]];

      if(self.animationView)
        {
        [self.animationView setContentFilters: @[]];
        [self.magnifyingGlassShade setContentFilters: @[]];
        [self.progress setNeedsDisplay: YES];
        }
    });
  }

// Handle an "etrecheck:" URL.
- (void) handleGetURLEvent: (NSAppleEventDescriptor *) event
  withReplyEvent: (NSAppleEventDescriptor *) reply
  {
  NSString * urlString =
    [[event paramDescriptorForKeyword: keyDirectObject] stringValue];
  
  NSURL * url = [NSURL URLWithString: urlString];
    
  if([[url scheme] isEqualToString: @"etrecheck"])
    {
    NSString * manager = [url host];
    
    if([manager isEqualToString: @"detail"])
      [self.detailManager showDetail: [[url path] substringFromIndex: 1]];
    else if([manager isEqualToString: @"help"])
      [self.helpManager showDetail: [[url path] substringFromIndex: 1]];
    else if([manager isEqualToString: @"adware"])
      [self.adwareManager showDetail: [[url path] substringFromIndex: 1]];
    }
  }

// Check for a new version.
- (void) checkForUpdates
  {
  NSURL * url =
    [NSURL
      URLWithString:
        @"http://etresoft.com/download/ApplicationUpdates.plist"];
  
  NSData * data = [NSData dataWithContentsOfURL: url];
  
  if(data)
    {
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
      
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    
    NSString * appBundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    NSNumber * appVersion =
      [numberFormatter
        numberFromString:
          [[[NSBundle mainBundle] infoDictionary]
            objectForKey: @"CFBundleVersion"]];

    NSDictionary * info = [NSDictionary readPropertyListData: data];
    
    for(NSString * key in info)
      if([key isEqualToString: @"Application Updates"])
        for(NSDictionary * attributes in [info objectForKey: key])
          {
          NSString * bundleId =
            [attributes objectForKey: @"CFBundleIdentifier"];
          
          if([appBundleId isEqualToString: bundleId])
            {
            NSNumber * version =
              [numberFormatter
                numberFromString:
                  [attributes objectForKey: @"CFBundleVersion"]];
            
            if([version intValue] > [appVersion intValue])
              [self
                presentUpdate:
                  [NSURL URLWithString: [attributes objectForKey: @"URL"]]];
            }
        }
      
    [numberFormatter release];
    }
  }

// Show the update dialog.
- (void) presentUpdate: (NSURL *) url
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Update Available", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"updateavailable", NULL)];

  // This is the rightmost, first, default button.
  [alert
    addButtonWithTitle: NSLocalizedString(@"Quit and go to update", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Skip", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertFirstButtonReturn)
    {
    [[NSWorkspace sharedWorkspace] openURL: url];
    
    [[NSApplication sharedApplication] terminate: self];
    }
    
  [alert release];
  }

// Collect the user message.
- (void) collectUserParameters
  {
  [[NSUserDefaults standardUserDefaults]
    removeObjectForKey: @"dontshowusermessage"];

  [[NSApplication sharedApplication]
    beginSheet: self.userParametersPanel
    modalForWindow: self.window
    modalDelegate: self
    didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
    contextInfo: nil];
  }
  
- (void) didEndSheet: (NSWindow *) sheet
  returnCode: (NSInteger) returnCode contextInfo: (void *) contextInfo
  {
  [sheet orderOut: self];
  }

// Start the report.
- (IBAction) start: (id) sender
  {
  [[NSApplication sharedApplication] endSheet: self.userParametersPanel];
  
  self.reportStartTime = [NSDate date];
  
  [self startProgressTimer];
  
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      [self collectInfo];
    });
  }

// Start the progress timer.
- (void) startProgressTimer
  {
  self.progressTimer =
    [NSTimer
      scheduledTimerWithTimeInterval: .3
      target: self
      selector: @selector(fireProgressTimer:)
      userInfo: nil
      repeats: YES];
  }

// Progress timer.
- (void) fireProgressTimer: (NSTimer *) timer
  {
  double current = [self.progress doubleValue];
  
  current = current + 0.5;
    
  if(current > self.nextProgressIncrement)
    return;
    
  [self updateProgress: current];
  
  if(current >= 100)
    [timer invalidate];
  }
  
// Cancel the report.
- (IBAction) cancel: (id) sender
  {
  [[NSApplication sharedApplication] endSheet: self.userParametersPanel];

  [[NSApplication sharedApplication] terminate: sender];
  }

// Allow the program to close when closing the window.
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:
  (NSApplication *) sender
  {
  return YES;
  }

// Fire it up.
- (void) collectInfo
  {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.progress startAnimation: self];
      [self.spinner startAnimation: self];
    });

  [self setupNotificationHandlers];
  
  Checker * checker = [Checker new];
  
  NSAttributedString * results = [checker check];
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self printEtreCheckHeader];
  
      [self.log appendAttributedString: results];
  
      [self displayOutput];
    });
    
  [checker release];
  [LaunchdCollector cleanup];
  
  [pool drain];
  }

// Print the EtreCheck header.
- (void) printEtreCheckHeader
  {
  NSBundle * bundle = [NSBundle mainBundle];
  
  [self.log
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"EtreCheck version: %@ (%@)\nReport generated %@\n", NULL),
            [bundle
              objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
            [bundle objectForInfoDictionaryKey: @"CFBundleVersion"],
            [self currentDate]]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];
    
  [self.log
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"Runtime %@\n", NULL), [self elapsedTime]]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  [self.log
    appendString: NSLocalizedString(@"downloadetrecheck", NULL)
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  [self.log
    appendAttributedString:
      [Utilities
        buildURL: @"http://etresoft.com/etrecheck"
        title: @"http://etresoft.com/etrecheck"]];
    
  [self.log appendString: @"\n\n"];
  
  [self printLinkInstructions];
  
  [self printErrors];
  }

// Print link instructions.
- (void) printLinkInstructions
  {
  [self.log
    appendRTFData:
      [NSData
        dataWithContentsOfFile:
          [[NSBundle mainBundle]
            pathForResource: @"linkhelp" ofType: @"rtf"]]];

  if([[Model model] adwareFound])
    [self.log
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"adwarehelp" ofType: @"rtf"]]];

  [self.log appendString: @"\n"];
  }

// Print errors during EtreCheck itself.
- (void) printErrors
  {
  NSArray * terminatedTasks = [[Model model] terminatedTasks];
  
  if(terminatedTasks.count > 0)
    {
    [self.log
      appendString:
        NSLocalizedString(
          @"The following internal tasks failed to complete:\n", NULL)
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];

    for(NSString * task in terminatedTasks)
      {
      [self.log
        appendString: task
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
      [self.log appendString: @"\n"];
      }

    [self.log appendString: @"\n"];
    }
  }

// Get the current date as a string.
- (NSString *) currentDate
  {
  NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle: NSDateFormatterShortStyle];
  [dateFormatter setTimeStyle: NSDateFormatterShortStyle];
  
  NSString * dateString = [dateFormatter stringFromDate: [NSDate date]];
  
  [dateFormatter release];

  return dateString;
  }

// Get the elapsed time as a string.
- (NSString *) elapsedTime
  {
  NSDate * current = [NSDate date];
  
  NSTimeInterval interval =
    [current timeIntervalSinceDate: self.reportStartTime];

  NSUInteger minutes = (NSUInteger)interval / 60;
  NSUInteger seconds = (NSUInteger)interval - (minutes * 60);
  
  return
    [NSString
      stringWithFormat:
        @"%ld:%02ld", (unsigned long)minutes, (unsigned long)seconds];
  }

// Setup notification handlers.
- (void) setupNotificationHandlers
  {
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(statusUpdated:)
    name: kStatusUpdate
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(progressUpdated:)
    name: kProgressUpdate
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(applicationFound:)
    name: kFoundApplication
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showMachineIcon:)
    name: kShowMachineIcon
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showCollectionStatus:)
    name: kCollectionStatus
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showDemonAgent:)
    name: kShowDemonAgent
    object: nil];
  }

// Handle a status update.
- (void) statusUpdated: (NSNotification *) notification
  {
  NSMutableAttributedString * newStatus = [self.displayStatus mutableCopy];
  
  [newStatus
    appendString:
      [NSString stringWithFormat: @"%@\n", [notification object]]];

  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      NSMutableAttributedString * status = [newStatus copy];
      self.displayStatus = status;

      [status release];
      
      [[self.statusView animator]
        scrollRangeToVisible:
          NSMakeRange(self.statusView.string.length, 0)];
    });
  
  [newStatus release];
  }
  
// Handle a progress update.
- (void) progressUpdated: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      //[self updateProgress: self.nextProgressIncrement];
      
      self.nextProgressIncrement = [[notification object] doubleValue];
    });
  }

- (void) updateProgress: (double) amount
  {
  // Try to make Snow Leopard update.
  if((self.nextProgressIncrement - [self.progress doubleValue]) > 1)
    [self.progress setNeedsDisplay: YES];

  if([self.progress isIndeterminate])
    [self.progress setIndeterminate: NO];
    
  // Snow Leopard doesn't like animations with CA layers.
  // Beat it with a rubber hose.
  [self.progress setHidden: YES];
  [self.progress setDoubleValue: amount];
  [self.progress setHidden: NO];
  [self.progress startAnimation: self];
  }

// Handle an application found.
- (void) applicationFound: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.applicationIcon transitionToImage: [notification object]];
    });
  }

// Show a machine icon.
- (void) showMachineIcon: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.machineIcon transitionToImage: [notification object]];
    });
  }

// Show the coarse collection status.
- (void) showCollectionStatus: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      // Move the spinner to make room for the status.
      NSString * status = [notification object];
      
      NSRect oldRect =
        [self.collectionStatus
          boundingRectWithSize: NSMakeSize(1000, 1000)
          options:0
          attributes:
            @{
              NSFontAttributeName: [NSFont labelFontOfSize: 12.0]
            }];

      NSRect newRect =
        [status
          boundingRectWithSize: NSMakeSize(1000, 1000)
          options:0
          attributes:
            @{
              NSFontAttributeName: [NSFont labelFontOfSize: 12.0]
            }];

      NSRect frame = [self.spinner frame];
      
      if(oldRect.size.width > 0)
        frame.origin.x -= 24;
      
      frame.origin.x -= oldRect.size.width / 2;
      frame.origin.x += newRect.size.width / 2;
      frame.origin.x += 24;
      
      // Snow Leopard doesn't like progress indicators with CA layers.
      // Beat it with a rubber hose.
      [self.spinner setHidden: YES];
      [self.spinner setFrame: frame];
      [self.spinner setHidden: NO];
      
      self.collectionStatus = [notification object];
    });
  }

// Show the demon and agent animation.
- (void) showDemonAgent: (NSNotification *) notification
  {
  NSRect demonStartFrame = [self.demonImage frame];
  NSRect demonEndFrame = demonStartFrame;
  
  demonEndFrame.origin.x -= 45;

  NSRect agentStartFrame = [self.agentImage frame];
  NSRect agentEndFrame = agentStartFrame;
  
  agentEndFrame.origin.x += 45;

  [self animateDemon: demonEndFrame];
  [self animateDemon: demonStartFrame agent: agentEndFrame];
  [self animateAgent: agentStartFrame];
  }

// Show the demon.
- (void) animateDemon: (NSRect) demonEndFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.demonImage animator] setFrame: demonEndFrame];
      
      [NSAnimationContext endGrouping];
    });
  }

// Hide the demon and show the agent.
- (void) animateDemon: (NSRect) demonStartFrame agent: (NSRect) agentEndFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.demonImage animator] setFrame: demonStartFrame];
      [[self.agentImage animator] setFrame: agentEndFrame];

      [NSAnimationContext endGrouping];
    });
  }

// Hide the agent.
- (void) animateAgent: (NSRect) agentStartFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(21 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.agentImage animator] setFrame: agentStartFrame];

      [NSAnimationContext endGrouping];
    });
  }

// Show the output pane.
- (void) displayOutput
  {
  [self.progressTimer invalidate];
  
  NSData * rtfData =
    [self.log
      RTFFromRange: NSMakeRange(0, [self.log length])
      documentAttributes: @{}];
  
  NSRange range =
    NSMakeRange(0, [[self.logView textStorage] length]);

  [self.logView
    replaceCharactersInRange: range withRTF: rtfData];
    
  // Adjust the size of the content frame to prevent horizontal scrolling.
  NSRect contentFrame = [self.logView frame];
    
  contentFrame.size.width -= 20;
  
  [self.logView setFrame: contentFrame];
  
  [self transitionToReportView];
  }

// Transition to the report view.
- (void) transitionToReportView
  {
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(didScroll:)
    name: NSViewBoundsDidChangeNotification
    object: [[self.logView enclosingScrollView] contentView]];
  
  [[[self.logView enclosingScrollView] contentView]
    setPostsBoundsChangedNotifications: YES];

  [self.window makeFirstResponder: self.logView];
  
  NSRect frame = [self.window frame];
  
  if(frame.size.height < 512)
    {
    frame.origin.y -= (512 - frame.size.height)/2;
    frame.size.height = 512;
    }
    
  double duration = [window animationResizeTime: frame];
  
  [NSAnimationContext beginGrouping];
  
  self.toolbar.visible = YES;
  self.reportAvailable = YES;
  [self.toolbar validateVisibleItems];
  
  [[NSAnimationContext currentContext] setDuration: duration];
  
  [self.window.contentView addSubview: self.reportView];
  
  [[self.animationView animator] removeFromSuperview];
  
  self.animationView = nil;
  
  [NSAnimationContext endGrouping];

  [window setFrame: frame display: YES animate: YES];

  [[self.logView enclosingScrollView] setHasVerticalScroller: YES];
  [self.window setShowsResizeIndicator: YES];
  [self.window
    setStyleMask: [self.window styleMask] | NSResizableWindowMask];
  
  [self notify];

  [self.logView
    scrollRangeToVisible: NSMakeRange([self.log length] - 2, 1)];
  [self.logView scrollRangeToVisible: NSMakeRange(0, 1)];
  }

// Handle a scroll change in the report view.
- (void) didScroll: (NSNotification *) notification
  {
  [self.detailManager closeDetail: self];
  [self.helpManager closeDetail: self];
  [self.adwareManager closeDetail: self];
  }

// Notify the user that the report is done.
- (void) notify
  {
  if(![NSUserNotificationCenter class])
    return;
    
  // Notify the user.
  NSUserNotification * notification = [[NSUserNotification alloc] init];
    
  notification.title = @"Etrecheck";
  notification.informativeText =
    NSLocalizedString(@"Report complete", NULL);
  
  // TODO: Do something clever with sound and notifications.
  notification.soundName = NSUserNotificationDefaultSoundName;
  
  [[NSUserNotificationCenter defaultUserNotificationCenter]
    deliverNotification: notification];
    
  [notification release];
  }

// Display web site when the user clicks on a notification.
- (void) userNotificationCenter: (NSUserNotificationCenter *) center
  didActivateNotification: (NSUserNotification *) notification
  {
  if([self.window isMiniaturized])
    [self.window deminiaturize: self];
    
  [self.window makeKeyAndOrderFront: self];
  }

// Copy the report to the clipboard.
- (IBAction) copyToClipboard: (id) sender
  {
  NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];
 
  [pasteboard clearContents];
 
  NSError * error = nil;
  
  NSData * rtfData =
    [self.log
      dataFromRange: NSMakeRange(0, [self.log length])
      documentAttributes:
        @
          {
          NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
          }
      error: & error];

  [pasteboard setData: rtfData forType: NSPasteboardTypeRTF];
  }
  
// Show a custom about panel.
- (IBAction) showAbout: (id) sender
  {
  [[NSApplication sharedApplication]
    orderFrontStandardAboutPanelWithOptions: @{@"Version" : @""}];
  }

// Go to the Etresoft web site.
- (IBAction) gotoEtresoft: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL: [NSURL URLWithString: @"http://www.etresoft.com"]];
  }

// Display more info.
- (IBAction) moreInfo: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL:
      [NSURL URLWithString: @"http://www.etresoft.com/etrecheck_story"]];
  }

// Show the log window.
- (IBAction) showLog: (id) sender
  {
  [self.logWindow makeKeyAndOrderFront: sender];
  }

// Shwo the EtreCheck window.
- (IBAction) showEtreCheck: (id) sender
  {
  [self.window makeKeyAndOrderFront: sender];
  }

// Confirm cancel.
- (IBAction) confirmCancel: (id) sender
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Confirm cancellation", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(
        @"Are you sure you want to cancel this EtreCheck report?", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"No, continue", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Yes, cancel", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertSecondButtonReturn)
    [self cancel: sender];
    
  [alert release];
  }

// Save the EtreCheck report.
- (IBAction) saveReport: (id) sender
  {
  NSSavePanel * savePanel = [NSSavePanel savePanel];
  
  [savePanel setAllowedFileTypes: @[@"rtf"]];
  
  NSInteger result = [savePanel runModal];
  
  if(result == NSFileHandlingPanelOKButton)
    {
    NSError * error = nil;
    
    NSData * rtfData =
      [self.log
        dataFromRange: NSMakeRange(0, [self.log length])
        documentAttributes:
          @
            {
            NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
            }
        error: & error];
      
    if(rtfData)
      [rtfData writeToURL: [savePanel URL] atomically: YES];
    }
  }

// Print the report. This needs to be a selector for AppDelegate so that
// the delegate can disable the toolbar item via validateToolbarItem.
- (IBAction) printReport: (id) sender
  {
  [self.logView print: sender];
  }

#pragma mark - NSToolbarDelegate conformance

- (void) toolbarWillAddItem: (NSNotification *) notification
  {
  NSToolbarItem * addedItem =
    [[notification userInfo] objectForKey: @"item"];
    
  if([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier])
    {
    [addedItem setToolTip: NSLocalizedString(@"Print Report", NULL)];
    [addedItem setTarget: self];
    [addedItem setAction: @selector(printReport:)];
    }
  }

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  willBeInsertedIntoToolbar: (BOOL) flag
  {
  if([itemIdentifier isEqualToString: kShareToolbarItemID])
    {
    // Create the NSToolbarItem and setup its attributes.
    EtreCheckToolbarItem * item =
      [[[EtreCheckToolbarItem alloc]
        initWithItemIdentifier: itemIdentifier] autorelease];
    
    if([NSSharingServicePicker class])
      {
      [item setLabel: NSLocalizedString(@"Share Report", nil)];
      [item setPaletteLabel: NSLocalizedString(@"Share Report", nil)];
      [item setView: self.shareToolbarItemView];
      item.control = self.shareButton;
      }
    else
      {
      [item setLabel: NSLocalizedString(@"Copy to clipboard", nil)];
      [item setPaletteLabel: NSLocalizedString(@"Copy to clipboard", nil)];
      [item setView: self.clipboardCopyToolbarItemView];
      item.control = self.clipboardCopyButton;
      }
      
    [item setTarget: self];
    [item setAction: nil];
    item.appDelegate = self;
    
    return item;
    }
  else if([itemIdentifier isEqualToString: kHelpToolbarItemID])
    {
    // Create the NSToolbarItem and setup its attributes.
    EtreCheckToolbarItem * item =
      [[[EtreCheckToolbarItem alloc]
        initWithItemIdentifier: itemIdentifier] autorelease];
    
    [item setLabel: NSLocalizedString(@"Help", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Help", nil)];
    [item setTarget: self];
    [item setAction: nil];
    [item setView: self.helpToolbarItemView];
    item.control = self.helpButton;
    item.appDelegate = self;
    
    return item;
    }
    
  return nil;
  }

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
  {
  return
    @[
      kShareToolbarItemID,
      kHelpToolbarItemID,
      NSToolbarFlexibleSpaceItemIdentifier,
      NSToolbarPrintItemIdentifier
    ];
    
  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "default" list of items.
  }

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
  {
  return
    @[
      kShareToolbarItemID,
      kHelpToolbarItemID,
      NSToolbarFlexibleSpaceItemIdentifier,
      NSToolbarPrintItemIdentifier
    ];

  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "allowed" list of items.
  }

// Validate toolbar items.
- (BOOL) validateToolbarItem: (NSToolbarItem *) theItem
  {
  return self.reportAvailable;
  }

#pragma mark - Sharing

// Share the EtreCheck report.
- (IBAction) shareReport: (id) sender
  {
  NSSharingServicePicker * sharingServicePicker =
    [[NSSharingServicePicker alloc]
      initWithItems:
        [NSArray arrayWithObjects: self.log, nil]];
    
  sharingServicePicker.delegate = self;
  
  [sharingServicePicker
    showRelativeToRect: NSZeroRect
    ofView: sender
    preferredEdge: NSMinYEdge];
    
  [sharingServicePicker release];
  }

#pragma mark - NSSharingServicePickerDelegate conformance

- (id <NSSharingServiceDelegate>)
  sharingServicePicker: (NSSharingServicePicker *) sharingServicePicker
  delegateForSharingService: (NSSharingService *) sharingService
  {
  return self;
  }

- (void) sharingServicePicker:
  (NSSharingServicePicker *) sharingServicePicker
  didChooseSharingService: (NSSharingService *) service
  {
  [service setDelegate: self];
  }

- (NSArray *)
  sharingServicePicker: (NSSharingServicePicker *) sharingServicePicker
  sharingServicesForItems: (NSArray *) items
  proposedSharingServices: (NSArray *) proposedServices
  {
   NSMutableArray * sharingServices = [NSMutableArray array];
   
   NSSharingService * customService =
     [[[NSSharingService alloc]
       initWithTitle: NSLocalizedString(@"Copy to clipboard", NULL)
       image: [NSImage imageNamed: @"Copy"]
       alternateImage: nil
       handler:
         ^{
          [self doCustomServiceWithItems: items];
          }] autorelease];
    
  [sharingServices addObject: customService];
  [sharingServices
    addObject:
      [NSSharingService
        sharingServiceNamed: NSSharingServiceNameComposeEmail]];
  [sharingServices
    addObject:
      [NSSharingService
        sharingServiceNamed: NSSharingServiceNameComposeMessage]];
  
  return sharingServices;
  }

- (void) doCustomServiceWithItems: (NSArray *) items
  {
  [self copyToClipboard: self];
  }

#pragma mark - NSSharingServiceDelegate conformance

// Define the window that gets dimmed out during sharing.
- (NSWindow *) sharingService: (NSSharingService *) sharingService
  sourceWindowForShareItems: (NSArray *)items
  sharingContentScope: (NSSharingContentScope *) sharingContentScope
  {
  return self.window;
  }

- (NSRect) sharingService: (NSSharingService *) sharingService
  sourceFrameOnScreenForShareItem: (id<NSPasteboardWriting>) item
  {
  NSRect frame = [self.logView bounds];
  
  frame = [self.logView convertRect: frame toView: nil];
  
  return [[self.logView window] convertRectToScreen: frame];
  
  return frame;
  }

- (NSImage *) sharingService: (NSSharingService *) sharingService
  transitionImageForShareItem: (id <NSPasteboardWriting>) item
  contentRect: (NSRect *) contentRect
  {
  NSRect rect = [self.logView bounds];
  
  NSBitmapImageRep * imageRep =
    [self.logView bitmapImageRepForCachingDisplayInRect: rect];
  [self.logView cacheDisplayInRect: rect toBitmapImageRep: imageRep];

  NSImage * image = [[NSImage alloc] initWithSize: rect.size];
  [image addRepresentation: imageRep];
   
  return [image autorelease];
  }

#pragma mark - Control EtreCheck behaviour

@end

NSComparisonResult compareViews(id view1, id view2, void * context)
  {
  AppDelegate * self = (AppDelegate *)context;
  
  if(view1 == self.applicationIcon)
    return NSOrderedAscending;
    
  if(view1 == self.magnifyingGlass && view2 == self.applicationIcon)
    return NSOrderedDescending;
    
  if(view1 == self.magnifyingGlass)
    return NSOrderedAscending;
    
  if(view1 == self.magnifyingGlassShade)
    return NSOrderedAscending;

  return NSOrderedSame;
  }

