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

@implementation GrabController

- (void) loadResources
{
    NSMutableArray *loadedImages = [NSMutableArray array];
    
    NSString *backgroundPath = [[NSBundle mainBundle] pathForResource:@"common_Tile" ofType:@"tiff"];
    backgroundImage = [[NSImage alloc] initWithContentsOfFile:backgroundPath];
    if (!backgroundImage) {
        NSLog(@"Error: Unable to load image common_Tile.tiff");
        return;
    }
    
    NSArray *imageNames = @[@"CameraEye1", @"CameraEye2", @"CameraEye3"];
    for (NSString *imageName in imageNames) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tiff"];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
        if (image) {
            [loadedImages addObject:[self compositeImage:backgroundImage withOverlay:image]];
        } else {
            NSLog(@"Error: Unable to load image %@", imageName);
        }
    }
    cameraEyeImages = [loadedImages copy];

    NSString *pieImagePath = [[NSBundle mainBundle] pathForResource:@"PiePieces" ofType:@"tiff"];
    NSImage *pieImage = [[NSImage alloc] initWithContentsOfFile:pieImagePath];
    piePiecesImage = [pieImage copy];
    if (!piePiecesImage) {
        NSLog(@"Error: Unable to load image PiePieces.tiff");
    }
    
    NSString *flashImagePath = [[NSBundle mainBundle] pathForResource:@"CameraEyeFlash" ofType:@"tiff"];
    NSImage *flashImage = [[NSImage alloc] initWithContentsOfFile:flashImagePath];
    cameraEyeFlashImage = [self compositeImage:backgroundImage withOverlay:flashImage];
    if (!cameraEyeFlashImage) {
        NSLog(@"Error: Unable to load image CameraEyeFlash.tiff");
    }
    
    NSString *normalImagePath = [[NSBundle mainBundle] pathForResource:@"CameraNormal" ofType:@"tiff"];
    NSImage *normalImage = [[NSImage alloc] initWithContentsOfFile:normalImagePath];
    cameraNormalImage = [self compositeImage:backgroundImage withOverlay:normalImage];
    if (!cameraNormalImage) {
        NSLog(@"Error: Unable to load image CameraNormal.tiff");
    }
    
    NSString *watchImagePath = [[NSBundle mainBundle] pathForResource:@"CameraWatch" ofType:@"tiff"];
    NSImage *watchImage = [[NSImage alloc] initWithContentsOfFile:watchImagePath];
    cameraWatchImage = [self compositeImage:backgroundImage withOverlay:watchImage];
    if (!cameraWatchImage) {
        NSLog(@"Error: Unable to load image CameraWatch.tiff");
    }
    
    NSString *watchFlashImagePath = [[NSBundle mainBundle] pathForResource:@"CameraWatchFlash" ofType:@"tiff"];
    NSImage *watchFlashImage = [[NSImage alloc] initWithContentsOfFile:watchFlashImagePath];
    cameraWatchFlashImage = [self compositeImage:backgroundImage withOverlay:watchFlashImage];
    if (!cameraWatchFlashImage) {
        NSLog(@"Error: Unable to load image CameraWatchFlash.tiff");
    }
}

- (NSImage *) compositeImage:(NSImage *)background withOverlay:(NSImage *)overlay 
{
    NSImage *compositeImage = [[NSImage alloc] initWithSize:background.size];
    
    [compositeImage lockFocus];
    [background drawInRect:NSMakeRect(0, 0, background.size.width, background.size.height)];
    [overlay drawInRect:NSMakeRect(0, 0, overlay.size.width, overlay.size.height)];
    [compositeImage unlockFocus];
    
    return compositeImage;
}

- (void) updateAppIconImage
{
    currentImageIndex = (currentImageIndex + 1) % cameraEyeImages.count;
    [appIconButton setImage:cameraEyeImages[currentImageIndex]];
}

- (void) appIconWindow:(id)sender
{
    [self loadResources];
    if (cameraEyeImages.count == 0 || !cameraEyeFlashImage) {
        NSLog(@"Error: Images not loaded correctly. cameraEyeImages.count cameraEyeFlashImage");
        return;
    }
    
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    NSRect panelFrame = NSMakeRect(screenFrame.size.width - 67, screenFrame.size.height - 64, 64, 64);
    appIconPanel = [[NSPanel alloc] initWithContentRect:panelFrame
                                              styleMask:NSWindowStyleMaskBorderless
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];

    [appIconPanel setLevel:NSStatusWindowLevel];
    [appIconPanel setOpaque:NO];
    [appIconPanel setBackgroundColor:[NSColor clearColor]];
    [appIconPanel makeKeyAndOrderFront:nil];
    
    appIconButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [appIconButton setBordered:NO];
    [appIconButton setImage:cameraNormalImage];
    [appIconButton setTarget:self];
    [appIconButton setAction:@selector(captureWindow)];

    [[appIconPanel contentView] addSubview:appIconButton];
}

- (void) appIconFullScreen:(id)sender
{
    [self loadResources];
    if (!cameraNormalImage || !cameraEyeFlashImage) {
        NSLog(@"Error: Images not loaded correctly. CameraNormal CameraEyeFlash");
        return;
    }
    
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    NSRect panelFrame = NSMakeRect(screenFrame.size.width - 67, screenFrame.size.height - 64, 64, 64);
    appIconPanel = [[NSPanel alloc] initWithContentRect:panelFrame
                                              styleMask:NSWindowStyleMaskBorderless
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [appIconPanel setLevel:NSStatusWindowLevel];
    [appIconPanel setOpaque:NO];
    [appIconPanel setBackgroundColor:[NSColor clearColor]];
    [appIconPanel makeKeyAndOrderFront:nil];
    
    appIconButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [appIconButton setBordered:NO];
    [appIconButton setImage:cameraNormalImage];
    [appIconButton setTarget:self];
    [appIconButton setAction:@selector(iconCaptureFullScreen)];
    
    [[appIconPanel contentView] addSubview:appIconButton];
}

- (void) appIconTimeScreen:(id)sender
{
    [self loadResources];
    if (!piePiecesImage || !cameraWatchImage || !cameraWatchFlashImage) {
        NSLog(@"Error: Images not loaded correctly. PiePieces CameraWatch CameraWatchFlash");
        return;
    }

    NSRect screenFrame = [[NSScreen mainScreen] frame];
    NSRect panelFrame = NSMakeRect(screenFrame.size.width - 67, screenFrame.size.height - 64, 64, 64);

    appIconPanel = [[NSPanel alloc] initWithContentRect:panelFrame
                                              styleMask:NSWindowStyleMaskBorderless
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];

    [appIconPanel setLevel:NSStatusWindowLevel];
    [appIconPanel setOpaque:NO];
    [appIconPanel setBackgroundColor:[NSColor clearColor]];
    [appIconPanel makeKeyAndOrderFront:nil];

    appIconButton = [[NSButton alloc] initWithFrame:panelFrame];
    [appIconButton setBordered:NO];
    [appIconButton setTarget:self];
    [appIconButton setAction:@selector(startTimer:)];

    [self updateAppIconWithCameraImage];

    [[appIconPanel contentView] addSubview:appIconButton];
    [appIconButton setFrameOrigin:NSMakePoint(0, 0)];
}

- (void) iconCaptureFullScreen
{
    [appIconButton setImage:cameraEyeFlashImage];

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                    repeats:NO
                                      block:^(NSTimer * _Nonnull timer) {
        [self captureFullScreen];
        [appIconPanel close];
        appIconPanel = nil;
        appIconButton = nil;
    }];
}

- (void) startTimer:(id)sender
{
    currentFrame = 0;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(updateFrame)
                                           userInfo:nil
                                            repeats:YES];
}

- (void) updateFrame
{
    if (currentFrame >= 10) {
        [timer invalidate];
        NSString *soundTimerPath = [[NSBundle mainBundle] pathForResource:@"TimerDone" ofType:@"wav"];
        NSSound *soundTimer = [[NSSound alloc] initWithContentsOfFile:soundTimerPath byReference:NO];
        [soundTimer play];
        [NSThread sleepForTimeInterval:soundTimer.duration];
        [self showFlashImage];
        return;
    }

    [self updateAppIconWithPiePiece];
    currentFrame++;
}

- (void) updateAppIconWithCameraImage
{
    NSImage *compositeImage = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
    [compositeImage lockFocus];

    [backgroundImage drawInRect:NSMakeRect(0, 0, 64, 64)
                       fromRect:NSZeroRect
                      operation:NSCompositeSourceOver
                       fraction:1.0];

    [cameraWatchImage drawInRect:NSMakeRect(0, 0, 64, 64)
                        fromRect:NSZeroRect
                       operation:NSCompositeSourceOver
                        fraction:1.0];

    [compositeImage unlockFocus];
    [appIconButton setImage:compositeImage];
}

- (void) updateAppIconWithPiePiece
{
    NSImage *compositeImage = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
    [compositeImage lockFocus];

    [backgroundImage drawInRect:NSMakeRect(0, 0, 64, 64)
                       fromRect:NSZeroRect
                      operation:NSCompositeSourceOver
                       fraction:1.0];

    [cameraWatchImage drawInRect:NSMakeRect(0, 0, 64, 64)
                        fromRect:NSZeroRect
                       operation:NSCompositeSourceOver
                        fraction:1.0];

    if (currentFrame < 10) {
        NSRect sourceRect = NSMakeRect(currentFrame * 17, 0, 17, 17);
        NSRect destRect = NSMakeRect(41, 40, 17, 17);
        [piePiecesImage drawInRect:destRect
                          fromRect:sourceRect
                         operation:NSCompositeSourceOver
                          fraction:1.0];
    }

    [compositeImage unlockFocus];
    [appIconButton setImage:compositeImage];
}

- (void) showFlashImage
{
    [self captureFullScreen];
    NSImage *compositeImage = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
    [compositeImage lockFocus];

    [backgroundImage drawInRect:NSMakeRect(0, 0, 64, 64)
                       fromRect:NSZeroRect
                      operation:NSCompositeSourceOver
                       fraction:1.0];

    [cameraWatchFlashImage drawInRect:NSMakeRect(0, 0, 64, 64)
                             fromRect:NSZeroRect
                            operation:NSCompositeSourceOver
                             fraction:1.0];

    [compositeImage unlockFocus];
    [appIconButton setImage:compositeImage];

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                    repeats:NO
                                      block:^(NSTimer * _Nonnull timer) {
        [appIconPanel close];
        appIconPanel = nil;
        appIconButton = nil;
    }];
}

- (void) captureWindow
{
    [appIconButton setImage:cameraEyeImages[0]];
    currentImageIndex = 0;
    animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 
                                                      target:self 
                                                    selector:@selector(updateAppIconImage) 
                                                    userInfo:nil 
                                                     repeats:YES];

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
        NSImage *image;

	if (window == None) {
            window = root;
            image = [GrabDraw captureScreenRect:NSMakeRect(0, 0, DisplayWidth(display, DefaultScreen(display)), 
                                                           DisplayHeight(display, DefaultScreen(display))) display:display];
        } else {
            XRaiseWindow(display, window);
            image = [GrabDraw captureWindowWithID:window display:display];
        }

        XUngrabPointer(display, CurrentTime);

        if (!image) {
            NSLog(@"Error: couldn't capture window image.");
            XCloseDisplay(display);
            return;
        } else {
            [animationTimer invalidate];
            animationTimer = nil;
            [appIconButton setImage:cameraEyeFlashImage];

            NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"OpenShutter" ofType:@"wav"];
            NSSound *sound = [[NSSound alloc] initWithContentsOfFile:soundPath byReference:NO];
            [sound play];
            [NSThread sleepForTimeInterval:sound.duration];

            [NSThread sleepForTimeInterval:1.0];
            [appIconPanel close];
            appIconPanel = nil;
            appIconButton = nil;
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

- (void) captureFullScreen
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

- (void) dealloc
{
  [super dealloc];
}

- (void) showHelpPanel:(id)sender
{
  if (!helpPanel) {
      if (![NSBundle loadNibNamed:@"HelpPanel" owner:self]) {
          NSLog (@"Faild to load HelpPanel.gorm");
          return;
        }
      [helpPanel center];
    }

  NSString *textPath = [[NSBundle mainBundle] pathForResource:@"HelpPanel" ofType: @"rtf"];
  NSData *text = [NSData dataWithContentsOfFile:textPath];
  [helpText replaceCharactersInRange:NSMakeRange(0, 0) withRTF:text];

  [helpPanel makeKeyAndOrderFront:nil];
}

- (void) showInfoPanel:(id)sender
{
  NSString *file = [[NSBundle mainBundle] pathForResource:@"GrabInfo" ofType: @"plist"];
  infoDict = [NSDictionary dictionaryWithContentsOfFile:file];

  if (!infoPanel) {
      if (![NSBundle loadNibNamed:@"InfoPanel" owner:self]) {
          NSLog (@"Faild to load InfoPanel.gorm");
          return;
        }
      [verField setStringValue:[NSString stringWithFormat:@"Release %@", [infoDict objectForKey:@"ApplicationRelease"]]];
      [copyrightField setStringValue:[infoDict objectForKey:@"Copyright"]];
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

