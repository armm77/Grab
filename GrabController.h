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

#include <arpa/inet.h> // define tipos de variables uint32_t
#include <stdio.h>
#include <stdlib.h>
#include <X11/X.h>
#include <sys/select.h>
#include <X11/Xutil.h>
#include <X11/cursorfont.h>

#import <AppKit/AppKit.h>
#import <X11/Xlib.h>
#import <GrabView.h>

@interface GrabController : NSObject
{
  GrabView  *_grabView;
  NSBundle  *_bundle;
  NSCursor  *_cursor;
  NSTimer   *_timer;
  NSImage	  *_buttonImage;
  NSString  *_imagePath;
  NSApplication *NSApp;

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

- (void) savaAsImage: (XImage *)image;
- (void) updateCountDownTime;

- (void) showInfoPanel: (id)sender;
- (void) showCursorPanel: (id)sender;
- (void) showInspectorPanel: (id)sender;

- (void) captureSelection: (id)sender;
- (void) captureWindow: (id)sender;
- (void) captureScreen: (id)sender;
- (void) captureTimedScreen: (id)sender;

@end
