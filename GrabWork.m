/*
   Project: Grab

   Author: Andres Morales

   Created: 2020-07-04 16:14:10 +0300 by armm77

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
#import <SystemKit/OSEScreen.h>
#import "GrabWork.h"
#import "GrabView.h"
#import "GrabController.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

@implementation GrabWork : NSObject

- (void) dealloc
{
  [_timer invalidate];
  [_timer release];
  [super dealloc];
}

-(void) updateCountDownTime
{
  if (totalSeconds != 1) {
     totalSeconds -= 1;
     NSLog (@"Timer:%02d",totalSeconds);
  } else {
//     [self captureScreen];
     [_timer invalidate];
  }
}

- (void) captureSelection
{
  //NSApp = [NSApplication sharedApplication];
  //[NSApp setApplicationIconImage:[NSImage imageNamed:@"CameraNormal.tiff"]];

  Display *display = XOpenDisplay(NULL);
  Window window = DefaultRootWindow(display);
  Cursor cursor = XCreateFontCursor(display, XC_crosshair);
  XEvent event;
  GC gc;
  XGCValues gcval;
  int pressed = 0, done = 0, finish = 0;
  int po_x = 0, po_y = 0, width = 0, height = 0, ry = 0, rx = 0;
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
              if (width) {
                XDrawRectangle(display, window, gc, po_x, po_y, \
                              width, height);
                NSLog(@"1.XDrawRectangle");
              } else {
                XChangeActivePointerGrab(display, ButtonMotionMask | \
                                        ButtonReleaseMask, cursor, \
                                        CurrentTime);
                NSLog(@"2.XChangeActivePointerGrab");
                }
                po_x = rx;
                po_y = ry;
                width = event.xmotion.x - po_x;
                height = event.xmotion.y - po_y;

                if (width == 0) ++width;
                if (height == 0) ++height;

                if (width < 0) {
                  po_x += width;
                  width = 0 - width;
                }
                if (height < 0) {
                  po_y += height;
                  height = 0 - height;
                }

                XDrawRectangle(display, window, gc, po_x, po_y,\
                              width, height);
                NSLog(@"3.XDrawRectangle");
                XFlush(display);
              }
          break;
        case KeyPress:
          fprintf(stderr, "Key was pressed, aborting shot\n");
          done = 2;
          break;
        case KeyRelease:
          /* ignore */
          break;
        default:
          break;
      }
    }
  }

  if (width != 0 && !done) {
		XDrawRectangle(display, window, gc, po_x, po_y, width, height);
		XFlush(display);
	}

  XImage *image = XGetImage(display, window, po_x, po_y,\
                  width, height, AllPlanes, ZPixmap);

  [self saveAsImage:image];

  XUngrabPointer(display, CurrentTime);
  XUngrabServer(display);
	XFreeCursor(display, cursor);
	XFreeGC(display, gc);
	XSync(display, True);
  XCloseDisplay(display);
}

- (void) captureWindow
{
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

  [self saveAsImage:image];

  XUngrabPointer(display, CurrentTime);
  XUngrabServer(display);
  XFreeCursor(display, cursor);
	XSync(display, True);
  XCloseDisplay(display);
}

- (void) captureScreen
{
  Display *display = XOpenDisplay(NULL);
  Window window = DefaultRootWindow(display);
  XWindowAttributes gwa;

  XGetWindowAttributes(display, window, &gwa);

  XImage *image = XGetImage(display, window, 0, 0, \
                  gwa.width, gwa.height, AllPlanes, ZPixmap);

  [self saveAsImage:image];

  XCloseDisplay(display);
}

- (void) captureTimedScreen
{

    //grabView = [[GrabView alloc] init];
    [grabView setImage:[NSImage imageNamed:@"Grab.App.tiff"]];
    [grabView setNeedsDisplay:YES];
  totalSeconds = 5;
  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
  selector:@selector(updateCountDownTime) userInfo:nil repeats:YES];
}

- (void) saveAsImage: (XImage *)image
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
