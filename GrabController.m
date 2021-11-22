/*
   Project: Grab
   Author: Andres Morales
   Created: 2021-05-12 16:14:10 +0300 by armm77
   Application Controller

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
#import <GrabController.h>

@implementation GrabController

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
  if (!(self = [super init])) {
    return nil;
  }
  return self;
}

- (void) awakeFromNib
{
  if (grabView)
    return;

  grabView = [[GrabView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
  [[NSApp iconWindow] setContentView:grabView];
}

- (void) dealloc
{
  [super dealloc];
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
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

- (void) showInfoPanel: (id)sender
{
 if (!infoPanel) {
     if (![NSBundle loadNibNamed:@"InfoPanel" owner:self]) {
         NSLog (@"Faild to load InfoPanel.gorm");
         return;
       }
     [infoPanel center];
   }
 [infoPanel makeKeyAndOrderFront:nil];
}

- (void) showCursorPanel: (id)sender
{
 if (!cursorPanel) {
     if (![NSBundle loadNibNamed:@"CursorTypes" owner:self]) {
         NSLog (@"Faild to load CursorTypes.gorm");
         return;
       }
     [cursorPanel center];
   }
 [cursorPanel makeKeyAndOrderFront:nil];
}

- (void) showInspectorPanel: (id)sender
{
 if (!inspectorPanel) {
     if (![NSBundle loadNibNamed:@"InspectorPanel" owner:self]) {
         NSLog (@"Faild to load InspectorPanel.gorm");
         return;
       }
     [inspectorPanel center];
   }
 [inspectorPanel makeKeyAndOrderFront:nil];
}

- (void) optionSelection: (id)sender
{
  NSLog(@"optionSelection");
  grabWork = [[GrabWork alloc] init];
  [grabWork captureSelection];
}

- (void) optionWindow: (id)sender
{
  NSLog(@"optionWindow");
  [grabView setImage:[NSImage imageNamed:@"CameraEye1.tiff"]];
  grabWork = [[GrabWork alloc] init];
  [grabWork captureWindow];
}

- (void) optionScreen: (id)sender
{
  NSLog(@"optionScreen");
  [grabView setImage:[NSImage imageNamed:@"CameraNormal.tiff"]];

  grabWork = [[GrabWork alloc] init];
  [grabWork captureScreen];
}

- (void) optionTimedScreen: (id)sender
{
  NSLog(@"optionTimedScreen");
  [grabView setImage:[NSImage imageNamed:@"CameraWatch.tiff"]];

  grabWork = [[GrabWork alloc] init];
  [grabWork captureTimedScreen];
}

@end
