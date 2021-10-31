/*
   Project: Grab
   Author: Andres Morales
   Created: 2020-07-04 16:14:10 +0300 by armm77
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
#import <AppKit/AppKit.h>
#import <GrabView.h>
#import <GrabWork.h>

@interface GrabController : NSObject
{
  GrabView    *grabView;
  GrabWork    *grabWork;
  NSTimer     *_timer;

  int totalSeconds;

  id  infoPanel;
  id  cursorPanel;
  id  inspectorPanel;
}

+ (void) initialize;

- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
            openFile: (NSString *)fileName;

- (void) showInfoPanel: (id)sender;
- (void) showCursorPanel: (id)sender;
- (void) showInspectorPanel: (id)sender;

- (void) optionSelection: (id)sender;
- (void) optionWindow: (id)sender;
- (void) optionScreen: (id)sender;
- (void) optionTimedScreen: (id)sender;

@end
