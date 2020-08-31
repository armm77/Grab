/*
   Project: Grab

   Author: Andres Morales

   Created: 2020-07-04 16:14:10 +0300 by armm77

   Application Controller
*/

#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import <X11/Xlib.h>

@interface AppController : NSObject
{
  NSTimer  *_timer;
  //NSCursor *_cursor;

  int totalSeconds;

  id  infoPanel;
  id  cursorPanel;
  id  inspectorPanel;

  Display *gDisplay;
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
- (void) captureScreen;
- (void) captureTimedScreen: (id)sender;

//- (void) saveAsPngWithName:(NSString*) fileName;

@end

#endif
