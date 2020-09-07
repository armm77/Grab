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

#import "GrabController.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

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

- (void) showInfoPanel: (id)sender
{
 if (!infoPanel)
   {
     if (![NSBundle loadNibNamed:@"InfoPanel" owner:self])
       {
         NSLog (@"Faild to load InfoPanel.gorm");
         return;
       }
     [infoPanel center];
   }
 [infoPanel makeKeyAndOrderFront:nil];
}

- (void) showCursorPanel: (id)sender
{
 if (!cursorPanel)
   {
     if (![NSBundle loadNibNamed:@"CursorTypes" owner:self])
       {
         NSLog (@"Faild to load CursorTypes.gorm");
         return;
       }
     [cursorPanel center];
   }
 [cursorPanel makeKeyAndOrderFront:nil];
}

- (void) showInspectorPanel: (id)sender
{
 if (!inspectorPanel)
   {
     if (![NSBundle loadNibNamed:@"InspectorPanel" owner:self])
       {
         NSLog (@"Faild to load InspectorPanel.gorm");
         return;
       }
     [inspectorPanel center];
   }
 [inspectorPanel makeKeyAndOrderFront:nil];
}

- (void) captureSelection: (id)sender
{
  NSApp = [NSApplication sharedApplication];
  [NSApp setApplicationIconImage:[NSImage imageNamed:@"CameraNormal.tiff"]];

  Display *display = XOpenDisplay(NULL);
  Window window = DefaultRootWindow(display);
  Cursor cursor = XCreateFontCursor(display, XC_crosshair);
  XEvent event;
  GC gc;
  XGCValues gcval;
  int pressed = 0, done = 0, finish = 0;
  int rect_x = 0, rect_y = 0, rect_w = 0, rect_h = 0, ry = 0, rx = 0;
  int fd = ConnectionNumber(display);
  fd_set fds;

  XGrabPointer(display, window, False, ButtonMotionMask | \
              ButtonPressMask | ButtonReleaseMask, \
              GrabModeAsync, GrabModeAsync, \
              window, cursor, CurrentTime);

  gcval.function = GXxor;
  gcval.foreground = XWhitePixel(display, DefaultScreen(display));
  gcval.background = XBlackPixel(display, DefaultScreen(display));
  gcval.plane_mask = gcval.background ^ gcval.foreground;
  gcval.subwindow_mode = IncludeInferiors;
  gcval.line_width = 1;

  gc = XCreateGC(display, window, GCFunction | GCForeground | \
                GCBackground | GCSubwindowMode | GCLineWidth, &gcval);

  while (!done && !finish) {
    FD_ZERO(&fds);
    FD_SET(fd, &fds);
    select(fd + 1, &fds, NULL, NULL, NULL);
    while (XPending(display)) {
      XNextEvent(display, &event);
      switch (event.type) {
        case ButtonPress:
            rx = event.xbutton.x;
            ry = event.xbutton.y;
            pressed = 1;
          break;
        case ButtonRelease:
            done = 1;
          break;
        case MotionNotify:
            if (pressed) {
              if (rect_w) {
                XDrawRectangle(display, window, gc, rect_x, rect_y,\
                                rect_w, rect_h);
              } else {
                XChangeActivePointerGrab(display,
                                       ButtonMotionMask | ButtonReleaseMask,\
                                       cursor, CurrentTime);
                }
                rect_x = rx;
                rect_y = ry;
                rect_w = event.xmotion.x - rect_x;
                rect_h = event.xmotion.y - rect_y;

                if (rect_w == 0) ++rect_w;
                if (rect_h == 0) ++rect_h;

                if (rect_w < 0) {
                  rect_x += rect_w;
                  rect_w = 0 - rect_w;
                }
                if (rect_h < 0) {
                  rect_y += rect_h;
                  rect_h = 0 - rect_h;
                }

                XDrawRectangle(display, window, gc, rect_x, rect_y,\
                              rect_w, rect_h);
                XFlush(display);
              }
          break;
        default:
          break;
      }
    }
  }

  if (rect_w != 0 && !done) {
		XDrawRectangle(display, window, gc, rect_x, rect_y, rect_w, rect_h);
		XFlush(display);
	}

  XImage *image = XGetImage(display, window, rect_x, rect_y,\
                  rect_w, rect_h, AllPlanes, ZPixmap);

  [self savaAsImage:image];

  XUngrabPointer(display, CurrentTime);
	XFreeCursor(display, cursor);
	XFreeGC(display, gc);
	XSync(display, True);
  XCloseDisplay(display);
}

- (void) captureWindow: (id)sender
{
  NSApp = [NSApplication sharedApplication];
  [NSApp setApplicationIconImage:[NSImage imageNamed:@"CameraNormal.tiff"]];

  Display *display = XOpenDisplay(NULL);
  Window window = DefaultRootWindow(display);
  Cursor cursor = XCreateFontCursor(display, XC_hand2);
  XEvent event;
  XWindowAttributes gwa;
  int click = 0;
  int fd = ConnectionNumber(display);
  fd_set fds;

  XGrabPointer(display, window, False, ButtonReleaseMask, \
             GrabModeAsync, GrabModeAsync, \
             None, cursor, CurrentTime);

  while (!click) {
     FD_ZERO(&fds);
     FD_SET(fd, &fds);
     select(fd + 1, &fds, NULL, NULL, NULL);
     if (XPending(display)) {
        XNextEvent(display, &event);
        if (event.type == 5) {
           if (event.xbutton.subwindow)
              window = event.xbutton.subwindow;
         click = 1;
      }
    }
  }

  XMapRaised(display, window);
  XGetWindowAttributes(display, window, &gwa);

  XImage *image = XGetImage(display, window, 0, 0, \
                  gwa.width, gwa.height, AllPlanes, ZPixmap);

  [self savaAsImage:image];

  XUngrabPointer(display, CurrentTime);
  XFreeCursor(display, cursor);
	XSync(display, True);
  XCloseDisplay(display);
}


- (void) captureScreen: (id)sender
{
  NSApp = [NSApplication sharedApplication];
  [NSApp setApplicationIconImage:[NSImage imageNamed:@"CameraNormal.tiff"]];

  Display *display = XOpenDisplay(NULL);
  Window window = DefaultRootWindow(display);
  XWindowAttributes gwa;

  XGetWindowAttributes(display, window, &gwa);

  XImage *image = XGetImage(display, window, 0, 0, \
                  gwa.width, gwa.height, AllPlanes, ZPixmap);

  [self savaAsImage:image];

  XCloseDisplay(display);
}

-(void) updateCountDownTime
{
  if (totalSeconds != 1) {
     totalSeconds -= 1;
     NSLog (@"Timer:%02d",totalSeconds);
  } else {
     [self captureScreen:nil];
     [_timer invalidate];
  }
}

- (void) captureTimedScreen: (id)sender
{
  totalSeconds = 10;
  NSApp = [NSApplication sharedApplication];
  [NSApp setApplicationIconImage:[NSImage imageNamed:@"CameraWatch.tiff"]];
  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
  selector:@selector(updateCountDownTime) userInfo:nil repeats:YES];
}

- (void) savaAsImage: (XImage *)image
{
  char *rgb = malloc(image->width * image->height * 3);

  for(int i = 0, j = 0; i <  image->width * image->height * 4; i = i + 4){
     rgb[j] = image->data[i+2];
     rgb[j+1] = image->data[i+1];
     rgb[j+2] = image->data[i];
     j = j + 3;
  }

  int result = stbi_write_png("CaptureScreen.png", image->width, \
               image->height, 3, rgb, image->width *  3);
  NSLog(@"Capture Screen %d", result);
  XFree(image);
}

@end
