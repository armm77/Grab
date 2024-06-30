/*
   Project: Grab
   Author: Andres Morales
   Created: 2021-05-12 16:14:10 +0300 by armm77

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
#import "GrabDraw.h"
#import <X11/Xlib.h>
#import <X11/Xutil.h>
#import <X11/cursorfont.h>
#import <X11/extensions/Xfixes.h>

@implementation GrabController

- (void) applicationDidFinishLaunching: (NSNotification *)notification 
{
}

- (void) captureWindow:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Display *display = XOpenDisplay(NULL);
        if (!display) {
            NSLog(@"Error: couldnt open screen X11.");
            return;
        }

        Window root = DefaultRootWindow(display);
        Cursor cursor = XCreateFontCursor(display, XC_hand2);
        XGrabPointer(display, root, False, ButtonPressMask, GrabModeSync, GrabModeAsync, None, cursor, CurrentTime);

        XEvent event;
        XAllowEvents(display, SyncPointer, CurrentTime);
        XNextEvent(display, &event);

        Window window = event.xbutton.subwindow;
        if (window == None) {
            NSLog(@"No window selected.");
            XUngrabPointer(display, CurrentTime);
            XCloseDisplay(display);
            return;
        }

        XUngrabPointer(display, CurrentTime);

        NSImage *image = [GrabDraw captureWindowWithID:window display:display];
        if (!image) {
            NSLog(@"Error: couldn't capture window image.");
            XCloseDisplay(display);
            return;
        }

        XCloseDisplay(display);
    });
}

- (void) captureScreenSection:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Display *display = XOpenDisplay(NULL);
        if (!display) {
            NSLog(@"Error: couldn't open screen X11.");
            return;
        }

        Window root = DefaultRootWindow(display);

        if (XGrabPointer(display, root, False, ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
                         GrabModeAsync, GrabModeAsync, None, None, CurrentTime) != GrabSuccess) {
            NSLog(@"Error: couldn't capture pointer.");
            XCloseDisplay(display);
            return;
        }
    
    int done = 0, ret = 0;
    int rx = 0, ry = 0, btn_pressed = 0/*, test_x=0, test_y=0*/;
    int rect_x = 0, rect_y = 0, rect_w = 0, rect_h = 0;

    Cursor cursor    = XCreateFontCursor(display, XC_crosshair);
    Cursor cursor_nw = XCreateFontCursor(display, XC_ul_angle);
    Cursor cursor_ne = XCreateFontCursor(display, XC_ur_angle);
    Cursor cursor_se = XCreateFontCursor(display, XC_lr_angle);
    Cursor cursor_sw = XCreateFontCursor(display, XC_ll_angle);

    XGCValues gcval;
    gcval.foreground = XWhitePixel(display, 0);
    gcval.function   = GXxor;
    gcval.background = XBlackPixel(display, 0);
    gcval.plane_mask = gcval.background ^ gcval.foreground;
    gcval.subwindow_mode = IncludeInferiors;

    GC gc = XCreateGC(display, root,
                      GCFunction|GCForeground|GCBackground|GCSubwindowMode,
                      &gcval);

    //LineSolid	- LineOnOffDash	- LineDoubleDash
    XSetLineAttributes(display, gc, 2, LineSolid, CapButt, JoinMiter);

    ret = XGrabPointer(
        display, root, False,
        ButtonMotionMask | ButtonPressMask | ButtonReleaseMask,
        GrabModeAsync, GrabModeAsync, root, cursor, CurrentTime);

    if (ret != GrabSuccess)
        NSLog(@"Error: couldn't grab pointer\n");

    ret = XGrabKeyboard(display, root, False, GrabModeAsync, GrabModeAsync, CurrentTime);
    if (ret != GrabSuccess)
        NSLog(@"Error: couldn't grab keyboard\n");

    XEvent ev;
    int grabmask = ButtonMotionMask | ButtonReleaseMask;
    while (1) {
        while (!done && XPending(display)) {
            XNextEvent(display, &ev);

            switch (ev.type) {
            case MotionNotify:
                if (btn_pressed) {
                    if (rect_w)
                        XDrawRectangle(display, root, gc, rect_x, rect_y, rect_w, rect_h);

                    rect_x = rx;
                    rect_y = ry;
                    rect_w = ev.xmotion.x - rect_x;
                    rect_h = ev.xmotion.y - rect_y;
                    //test_x = ev.xmotion.x;
                    //test_y = ev.xmotion.y;

                    // Change the cursor to show we're selecting a region
                    if (rect_w < 0 && rect_h < 0)
                        XChangeActivePointerGrab(display, grabmask, cursor_nw, CurrentTime);
                    else if (rect_w < 0 && rect_h > 0)
                        XChangeActivePointerGrab(display, grabmask, cursor_sw, CurrentTime);
                    else if (rect_w > 0 && rect_h < 0)
                        XChangeActivePointerGrab(display, grabmask, cursor_ne, CurrentTime);
                    else if (rect_w > 0 && rect_h > 0)
                        XChangeActivePointerGrab(display, grabmask, cursor_se, CurrentTime);

                    XClearWindow(display, root);

                    if (rect_w < 0) {
                        rect_x += rect_w;
                        rect_w = 0 - rect_w;
                    }
                    if (rect_h < 0) {
                        rect_y += rect_h;
                        rect_h = 0 - rect_h;
                    }

                    // dimensiones 
                    //char dimensions[32];
                    //snprintf(dimensions, sizeof(dimensions), "%d x %d", abs(test_x - rx), abs(test_y - ry));
                    //XDrawString(display, root, gc, test_x + 15, test_y +15, dimensions, strlen(dimensions));
                    //NSLog(@"%d x %d", test_x, test_y);
                    // dimensiones

                    // draw rectangle
                    XDrawRectangle(display, root, gc, rect_x, rect_y, rect_w, rect_h);


                    XFlush(display);
                }
                break;
            case ButtonRelease:
                done = 1;
                break;
            case ButtonPress:
                btn_pressed = 1;
                rx = ev.xbutton.x;
                ry = ev.xbutton.y;
                break;
            case KeyPress:
                NSLog(@"key pressed, aborting selection\n");
                done = 2;
                break;
            case KeyRelease:
                /* ignore */
                break;
            default:
                break;
            }
        }
        if (done)
            break;

    }

    Window root_win;
    unsigned int root_w = 0, root_h = 0, root_b, root_d;
    int root_x = 0, root_y = 0;

    ret = XGetGeometry(display, root, &root_win, &root_x, &root_y,
                       &root_w, &root_h, &root_b, &root_d);
    if (ret == False)
        NSLog(@"error: failed to get root window geometry\n");

    if (rect_w) {
        XDrawRectangle(display, root, gc, rect_x, rect_y, rect_w, rect_h);
        XFlush(display);
    }

    NSRect rect = NSMakeRect(rect_x, rect_y, rect_w, rect_h);
    NSImage *image = [GrabDraw captureScreenRect:rect display:display];
    if (!image) {
        NSLog(@"Could not capture section of screen image.");
        XCloseDisplay(display);
        return;
    }

    XClearWindow(display, root);
    XUngrabPointer(display, CurrentTime);
    XUngrabKeyboard(display, CurrentTime);
    XFreeCursor(display, cursor);
    XFreeGC(display, gc);
    XSync(display, True);
    XUngrabServer(display);
    XCloseDisplay(display);
    });
}

- (void) captureFullScreen:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Display *display = XOpenDisplay(NULL);
        if (!display) {
            NSLog(@"Could not open screen X11.");
            return;
        }

        Window root = DefaultRootWindow(display);
        XWindowAttributes gwa;
        XGetWindowAttributes(display, root, &gwa);

        NSRect rect = NSMakeRect(0, 0, gwa.width, gwa.height);
        NSImage *image = [GrabDraw captureScreenRect:rect display:display];
        if (!image) {
            NSLog(@"Could not capture screen image.");
            XCloseDisplay(display);
            return;
        }

        XCloseDisplay(display);
    });
}

- (void) captureTimedScreen:(id)sender
{
  [self startCountdown];
}

- (void) startCountdown 
{
  self.countdown = 10;
  self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(updateCountdown)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void) dealloc
{
  [self stopCountdown];
  [super dealloc];
}

- (void) updateCountdown
{
  self.countdown--;
  //NSLog(@"Countdown: %ld", (long)self.countdown);
  if (self.countdown == 0) {
     [self stopCountdown];
     [self captureFullScreen:self];
  }
}

- (void) stopCountdown 
{
  [self.countdownTimer invalidate];
  self.countdownTimer = nil;
}

- (void) showHelpPanel:(id)sender
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"HelpPanel" ofType:@"rtf"];
    if (filePath) {
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
        if (fileContents) {
            NSTextStorage *textStorage = [textView textStorage];
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:fileContents];
        } else {
            NSLog(@"Error reading file: %@", filePath);
        }
    } else {
        NSLog(@"File not found: HelpPanel.rtf");
    }
}


- (void) showInfoPanel:(id)sender
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

- (void) showCursorPanel:(id)sender
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

- (void) showInspectorPanel:(id)sender
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

@end

