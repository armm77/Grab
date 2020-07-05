/* 
   Project: Grab

   Author: me

   Created: 2020-07-04 16:14:10 +0300 by me
   
   Application Controller
*/

#import "AppController.h"

@implementation AppController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init
{
  if ((self = [super init]))
    {
    }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
// Uncomment if your application is Renaissance-based
//  [NSBundle loadGSMarkupNamed: @"Main" owner: self];
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName
{
  return NO;
}

- (void) showPrefPanel: (id)sender
{
}

- (void) showInfoPanel: (id)sender
{
 if (!infoPanel)
   {
     if (![NSBundle loadNibNamed:@"InfoPanel" owner:self])
       {
         NSLog (@"Faild to load InfoPanel.gorm");
         NSBeep ();
         return;
       }
     [infoPanel center];
   }
 [infoPanel makeKeyAndOrderFront:nil];
}

- (void) showInspectorPanel: (id)sender
{
 if (!inspectorPanel)
   {
     if (![NSBundle loadNibNamed:@"InspectorPanel" owner:self])
       {
         NSLog (@"Faild to load InspectorPanel.gorm");
         NSBeep ();
         return;
       }
     [inspectorPanel center];
   }
 [inspectorPanel makeKeyAndOrderFront:nil];
}

@end
