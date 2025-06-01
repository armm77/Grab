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

/// Main controller for the Grab application.
/// Manages the interface, panels, graphic resources, and screen capture.
@interface GrabController ()
// Application info panel.
@property (nonatomic, strong) id infoPanel;
// Help panel.
@property (nonatomic, strong) id helpPanel;
// Inspector panel.
@property (nonatomic, strong) id inspectorPanel;
// Cursor types panel.
@property (nonatomic, strong) id cursorPanel;
// Help text field.
@property (nonatomic, strong) id helpText;

// Version text field.
@property (nonatomic, assign) IBOutlet NSTextField *verField;
// Copyright text field.
@property (nonatomic, assign) IBOutlet NSTextField *copyrightField;
// Dictionary with application information.
@property (nonatomic, strong) NSDictionary *infoDict;

// Array of image views associated with cameraEyeImages
@property (nonatomic, strong) NSArray<NSImageView *> *imageViews;

@end

@implementation GrabController {
    BOOL audioEnabled;
}

/// Returns the singleton instance of the controller.
/// @return Shared instance of GrabController.
+ (instancetype)sharedController {
    static GrabController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

/// Called when the nib has been loaded.
- (void)awakeFromNib {
    [self loadAudioStateFromPlist];
    [self updateMenuItemTitle];
}

/// Toggles the audio state (on/off).
/// @param sender The object that sent the action.
- (IBAction)toggleAudio:(id)sender {
    audioEnabled = !audioEnabled;
    [self updateMenuItemTitle];
    [self saveAudioStateToPlist];
}

/// Updates the audio menu item title according to the current state.
- (void)updateMenuItemTitle {
    NSString *newTitle = audioEnabled ? NSLocalizedString(@"Turn Sound Off", @"Menu item to turn sound off")
                                      : NSLocalizedString(@"Turn Sound On", @"Menu item to turn sound on");
    
    if (self.audioMenuItem) {
        [self.audioMenuItem setTitle:newTitle];
    } else {
        NSLog(@"Error: Menu item is not connected.");
    }
}

/// Loads the audio state from the preferences plist file.
- (void)loadAudioStateFromPlist {
    NSString *configPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/Grab.plist"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
        NSMutableDictionary *config = [NSMutableDictionary dictionary];
        config[@"SoundEnabled"] = @YES;
        
        NSError *error = nil;
        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:config
                                                                       format:NSPropertyListXMLFormat_v1_0
                                                                      options:0
                                                                        error:&error];
        if (plistData) {
            BOOL success = [plistData writeToFile:configPath atomically:YES];
            if (success) {
                NSLog(NSLocalizedString(@"Plist file created successfully with audio enabled.", @"Log: plist created"));
                audioEnabled = YES; // Set the audio enabled by default in the application
            } else {
                NSLog(NSLocalizedString(@"Error: Could not create plist file.", @"Log: plist creation failed"));
                audioEnabled = YES;
            }
        } else {
            NSLog(NSLocalizedString(@"Error serializing plist: %@", @"Log: plist serialization error"), error.localizedDescription);
            audioEnabled = YES;
        }
        
    } else {
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:configPath];
        
        if (config == nil) {
            NSLog(NSLocalizedString(@"The plist file could not be loaded. The default value of sound on (YES) will be used.", @"Log: plist load failed"));
            audioEnabled = YES;
        } else {
            NSNumber *soundEnabledValue = config[@"SoundEnabled"];
            
            if (soundEnabledValue != nil) {
                audioEnabled = [soundEnabledValue boolValue];
            } else {
                audioEnabled = YES;
            }
        }
    }
}

/// Saves the current audio state to the preferences plist file.
- (void)saveAudioStateToPlist {
    NSString *configPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/Grab.plist"];
    NSMutableDictionary *config = [NSMutableDictionary dictionary];

    config[@"SoundEnabled"] = @(audioEnabled);

    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:config
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&error];
    if (plistData) {
        BOOL success = [plistData writeToFile:configPath atomically:YES];
        if (success) {
            NSLog(NSLocalizedString(@"Audio settings successfully saved in XML format.", @"Log: audio settings saved"));
        } else {
            NSLog(NSLocalizedString(@"Error: Failed to save audio settings.", @"Log: audio settings save failed"));
        }
    } else {
        NSLog(NSLocalizedString(@"Error serializing the plist: %@", @"Log: plist serialization error"), error.localizedDescription);
    }
}

/// Indicates if the sound is enabled.
/// @return YES if sound is enabled, NO otherwise.
- (BOOL)isSoundEnabled {
    [self loadAudioStateFromPlist];
    return audioEnabled;
}

/// Plays a sound if audio is enabled.
/// @param soundName Name of the sound file (without extension).
- (void)playSoundWithName:(NSString *)soundName {
    BOOL soundEnabled = [[GrabController sharedController] isSoundEnabled];

    if (soundEnabled) {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:soundName ofType:@"wav"];
        NSSound *clickSound = [[NSSound alloc] initWithContentsOfFile:soundFilePath byReference:NO];
        if (clickSound) {
            [clickSound play];
            [NSThread sleepForTimeInterval:clickSound.duration];
        } else {
            NSLog(@"Could not load sound from path: %@", soundFilePath);
        }
    } else {
        NSLog(@"Sound is disabled.");
    }
}

/// Loads the graphic resources needed for the interface.
- (void)loadResources
{
    NSMutableArray *loadedImages = [NSMutableArray array];
    NSArray *imageNames = @[@"CameraEye1", @"CameraEye2", @"CameraEye3"];
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    config[@"SoundEnabled"] = @YES;
    
    NSString *backgroundPath = [[NSBundle mainBundle] pathForResource:@"common_Tile" ofType:@"tiff"];
    _backgroundImage = [[NSImage alloc] initWithContentsOfFile:backgroundPath];
    if (!_backgroundImage) {
        NSLog(@"Error: Unable to load image common_Tile.tiff");
        return;
    }
    
    for (NSString *imageName in imageNames) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tiff"];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
        if (image) {
            [loadedImages addObject:[self compositeImage:_backgroundImage withOverlay:image]];
        } else {
            NSLog(NSLocalizedString(@"Error: Unable to load image %@", @"Log: image load failed"), imageName);
        }
    }
    _cameraEyeImages = [loadedImages copy];

    NSString *pieImagePath = [[NSBundle mainBundle] pathForResource:@"PiePieces" ofType:@"tiff"];
    NSImage *pieImage = [[NSImage alloc] initWithContentsOfFile:pieImagePath];
    _piePiecesImage = [pieImage copy];
    if (!_piePiecesImage) {
        NSLog(@"Error: Unable to load image PiePieces.tiff");
    }
    
    NSString *flashImagePath = [[NSBundle mainBundle] pathForResource:@"CameraEyeFlash" ofType:@"tiff"];
    NSImage *flashImage = [[NSImage alloc] initWithContentsOfFile:flashImagePath];
    _cameraEyeFlashImage = [self compositeImage:_backgroundImage withOverlay:flashImage];
    if (!_cameraEyeFlashImage) {
        NSLog(@"Error: Unable to load image CameraEyeFlash.tiff");
    }
    
    NSString *normalImagePath = [[NSBundle mainBundle] pathForResource:@"CameraNormal" ofType:@"tiff"];
    NSImage *normalImage = [[NSImage alloc] initWithContentsOfFile:normalImagePath];
    _cameraNormalImage = [self compositeImage:_backgroundImage withOverlay:normalImage];
    if (!_cameraNormalImage) {
        NSLog(@"Error: Unable to load image CameraNormal.tiff");
    }
    
    NSString *watchImagePath = [[NSBundle mainBundle] pathForResource:@"CameraWatch" ofType:@"tiff"];
    NSImage *watchImage = [[NSImage alloc] initWithContentsOfFile:watchImagePath];
    _cameraWatchImage = [self compositeImage:_backgroundImage withOverlay:watchImage];
    if (!_cameraWatchImage) {
        NSLog(NSLocalizedString(@"Error: Unable to load image CameraWatch.tiff", @"Log: image load failed"));
    }
    
    NSString *watchFlashImagePath = [[NSBundle mainBundle] pathForResource:@"CameraWatchFlash" ofType:@"tiff"];
    NSImage *watchFlashImage = [[NSImage alloc] initWithContentsOfFile:watchFlashImagePath];
    _cameraWatchFlashImage = [self compositeImage:_backgroundImage withOverlay:watchFlashImage];
    if (!_cameraWatchFlashImage) {
        NSLog(@"Error: Unable to load image CameraWatchFlash.tiff");
    }
}

/// Creates a composite image from a background and an overlay.
/// @param background Background image.
/// @param overlay Overlay image.
/// @return Composite image.
- (NSImage *)compositeImage:(NSImage *)background withOverlay:(NSImage *)overlay
{
    NSImage *compositeImage = [[NSImage alloc] initWithSize:background.size];
    
    [compositeImage lockFocus];
    [background drawInRect:NSMakeRect(0, 0, background.size.width, background.size.height)];
    [overlay drawInRect:NSMakeRect(0, 0, overlay.size.width, overlay.size.height)];
    [compositeImage unlockFocus];
    
    return compositeImage;
}

/// Updates the application icon image.
- (void)updateAppIconImage
{
    _currentImageIndex = (_currentImageIndex + 1) % _cameraEyeImages.count;
    [_appIconButton setImage:_cameraEyeImages[_currentImageIndex]];
}

- (void) appIconWindow:(id)sender
{
    [self loadResources];
    if (_cameraEyeImages.count == 0 || !_cameraEyeFlashImage) {
        NSLog(NSLocalizedString(@"Error: Images not loaded correctly. cameraEyeImages.count cameraEyeFlashImage", @"Log: images not loaded"));
        return;
    }
    
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    NSRect panelFrame = NSMakeRect(screenFrame.size.width - 67, screenFrame.size.height - 64, 64, 64);
    _appIconPanel = [[NSPanel alloc] initWithContentRect:panelFrame
                                               styleMask:NSWindowStyleMaskBorderless
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];

    [_appIconPanel setLevel:NSStatusWindowLevel];
    [_appIconPanel setOpaque:NO];
    [_appIconPanel setBackgroundColor:[NSColor clearColor]];
    [_appIconPanel makeKeyAndOrderFront:nil];
    
    _appIconButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [_appIconButton setBordered:NO];
    [_appIconButton setImage:_cameraNormalImage];
    [_appIconButton setTarget:self];
    [_appIconButton setAction:@selector(captureWindow)];

    [[_appIconPanel contentView] addSubview:_appIconButton];
}

- (void) appIconFullScreen:(id)sender
{
    [self loadResources];
    if (!_cameraNormalImage || !_cameraEyeFlashImage) {
        NSLog(NSLocalizedString(@"Error: Images not loaded correctly. CameraNormal CameraEyeFlash", @"Log: images not loaded"));
        return;
    }
    
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    NSRect panelFrame = NSMakeRect(screenFrame.size.width - 67, screenFrame.size.height - 64, 64, 64);
    _appIconPanel = [[NSPanel alloc] initWithContentRect:panelFrame
                                               styleMask:NSWindowStyleMaskBorderless
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
    [_appIconPanel setLevel:NSStatusWindowLevel];
    [_appIconPanel setOpaque:NO];
    [_appIconPanel setBackgroundColor:[NSColor clearColor]];
    [_appIconPanel makeKeyAndOrderFront:nil];
    
    _appIconButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    [_appIconButton setBordered:NO];
    [_appIconButton setImage:_cameraNormalImage];
    [_appIconButton setTarget:self];
    [_appIconButton setAction:@selector(iconCaptureFullScreen)];
    
    [[_appIconPanel contentView] addSubview:_appIconButton];
}

- (void) appIconTimeScreen:(id)sender
{
    [self loadResources];
    if (!_piePiecesImage || !_cameraWatchImage || !_cameraWatchFlashImage) {
        NSLog(NSLocalizedString(@"Error: Images not loaded correctly. PiePieces CameraWatch CameraWatchFlash", @"Log: images not loaded"));
        return;
    }

    NSRect screenFrame = [[NSScreen mainScreen] frame];
    NSRect panelFrame = NSMakeRect(screenFrame.size.width - 67, screenFrame.size.height - 64, 64, 64);

    _appIconPanel = [[NSPanel alloc] initWithContentRect:panelFrame
                                               styleMask:NSWindowStyleMaskBorderless
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];

    [_appIconPanel setLevel:NSStatusWindowLevel];
    [_appIconPanel setOpaque:NO];
    [_appIconPanel setBackgroundColor:[NSColor clearColor]];
    [_appIconPanel makeKeyAndOrderFront:nil];

    _appIconButton = [[NSButton alloc] initWithFrame:panelFrame];
    [_appIconButton setBordered:NO];
    [_appIconButton setTarget:self];
    [_appIconButton setAction:@selector(startTimer:)];

    [self updateAppIconWithCameraImage];

    [[_appIconPanel contentView] addSubview:_appIconButton];
    [_appIconButton setFrameOrigin:NSMakePoint(0, 0)];
}

- (void) iconCaptureFullScreen
{
    [_appIconButton setImage:_cameraEyeFlashImage];
    [self playSoundWithName:@"OpenShutter"];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                    repeats:NO
                                      block:^(NSTimer * _Nonnull timer) {
        [self captureFullScreen];
        [_appIconPanel close];
        _appIconPanel = nil;
        _appIconButton = nil;
    }];
}

- (void) startTimer:(id)sender
{
    _currentFrame = 0;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(updateFrame)
                                            userInfo:nil
                                             repeats:YES];
}

- (void) updateFrame
{
    if (_currentFrame >= 9) {
        [self playSoundWithName:@"TimerDone"];
        [_timer invalidate];
        [self playSoundWithName:@"OpenShutter"];
        [self showFlashImage];
        [self captureFullScreen];
        return;
    }

    [self updateAppIconWithPiePiece];
    _currentFrame++;
}

- (void) updateAppIconWithCameraImage
{
    NSImage *compositeImage = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
    [compositeImage lockFocus];

    [_backgroundImage drawInRect:NSMakeRect(0, 0, 64, 64)
                        fromRect:NSZeroRect
                       operation:NSCompositeSourceOver
                        fraction:1.0];

    [_cameraWatchImage drawInRect:NSMakeRect(0, 0, 64, 64)
                         fromRect:NSZeroRect
                        operation:NSCompositeSourceOver
                         fraction:1.0];

    [compositeImage unlockFocus];
    [_appIconButton setImage:compositeImage];
}

- (void) updateAppIconWithPiePiece
{
    NSImage *compositeImage = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
    [compositeImage lockFocus];

    [_backgroundImage drawInRect:NSMakeRect(0, 0, 64, 64)
                        fromRect:NSZeroRect
                       operation:NSCompositeSourceOver
                        fraction:1.0];

    [_cameraWatchImage drawInRect:NSMakeRect(0, 0, 64, 64)
                         fromRect:NSZeroRect
                        operation:NSCompositeSourceOver
                         fraction:1.0];

    if (_currentFrame < 10) {
        NSRect sourceRect = NSMakeRect(_currentFrame * 17, 0, 17, 17);
        NSRect destRect = NSMakeRect(41, 40, 17, 17);
        [_piePiecesImage drawInRect:destRect
                           fromRect:sourceRect
                          operation:NSCompositeSourceOver
                           fraction:1.0];
    }

    [compositeImage unlockFocus];
    [_appIconButton setImage:compositeImage];
}

- (void) showFlashImage
{
    NSImage *compositeImage = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
    [compositeImage lockFocus];

    [_backgroundImage drawInRect:NSMakeRect(0, 0, 64, 64)
                        fromRect:NSZeroRect
                       operation:NSCompositeSourceOver
                        fraction:1.0];

    [_cameraWatchFlashImage drawInRect:NSMakeRect(0, 0, 64, 64)
                              fromRect:NSZeroRect
                             operation:NSCompositeSourceOver
                              fraction:1.0];

    [compositeImage unlockFocus];
    [_appIconButton setImage:compositeImage];

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                    repeats:NO
                                      block:^(NSTimer * _Nonnull timer) {
        [_appIconPanel close];
        _appIconPanel = nil;
        _appIconButton = nil;
    }];
}

- (void) captureWindow
{
    [_appIconButton setImage:_cameraEyeImages[0]];
    _currentImageIndex = 0;
    _animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                       target:self
                                                     selector:@selector(updateAppIconImage)
                                                     userInfo:nil
                                                      repeats:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Display *display = XOpenDisplay(NULL);
        if (!display) {
            NSLog(NSLocalizedString(@"Error: couldnt open screen X11.", @"Log: X11 open failed"));
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
           [self playSoundWithName:@"OpenShutter"];
           [_animationTimer invalidate];
           _animationTimer = nil;
           [_appIconButton setImage:_cameraEyeFlashImage];

           [NSThread sleepForTimeInterval:1.0];
           [_appIconPanel close];
           _appIconPanel = nil;
           _appIconButton = nil;

           window = root;
           image = [GrabDraw captureScreenRect:NSMakeRect(0, 0, DisplayWidth(display, DefaultScreen(display)),
                                                          DisplayHeight(display, DefaultScreen(display))) display:display rootWindow:root];
       } else {
           [self playSoundWithName:@"OpenShutter"];
           [_animationTimer invalidate];
           _animationTimer = nil;
           [_appIconButton setImage:_cameraEyeFlashImage];

           [NSThread sleepForTimeInterval:1.0];
           [_appIconPanel close];
           _appIconPanel = nil;
           _appIconButton = nil;

           XRaiseWindow(display, window);
           image = [GrabDraw captureWindowWithID:window display:display];
       }

        XUngrabPointer(display, CurrentTime);

        if (!image) {
            NSLog(NSLocalizedString(@"Error: couldn't capture window image.", @"Log: window capture failed"));
            XCloseDisplay(display);
            return;
        }

        _capturedImage = image;

        XCloseDisplay(display);
    });
}

- (void) captureScreenSection:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Display *display = XOpenDisplay(NULL);
        if (!display) {
            NSLog(NSLocalizedString(@"Error: couldn't open screen X11.", @"Log: X11 open failed"));
            return;
        }

        Window root = DefaultRootWindow(display);

        if (XGrabPointer(display, root, False, ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
                         GrabModeAsync, GrabModeAsync, None, None, CurrentTime) != GrabSuccess) {
            NSLog(NSLocalizedString(@"Error: couldn't capture pointer.", @"Log: pointer capture failed"));
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
    NSImage *image = [GrabDraw captureScreenRect:rect display:display rootWindow:root];
    if (!image) {
        NSLog(NSLocalizedString(@"Could not capture section of screen image.", @"Log: section capture failed"));
        XCloseDisplay(display);
        return;
    }

    _capturedImage = image;

    XClearWindow(display, root);
    XUngrabPointer(display, CurrentTime);
    XUngrabKeyboard(display, CurrentTime);
    XFreeCursor(display, cursor);
    XFreeCursor(display, cursor_nw);
    XFreeCursor(display, cursor_ne);
    XFreeCursor(display, cursor_se);
    XFreeCursor(display, cursor_sw);
    XFreeGC(display, gc);
    XCloseDisplay(display);
    });
}

- (void) captureFullScreen
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Display *display = XOpenDisplay(NULL);
        if (!display) {
            NSLog(NSLocalizedString(@"Could not open screen X11.", @"Log: X11 open failed"));
            return;
        }

        Window root = DefaultRootWindow(display);
        if (!root) {
            NSLog(NSLocalizedString(@"Could not open Window.", @"Log: Window open failed"));
            return;
        }

        XWindowAttributes gwa;
        XGetWindowAttributes(display, root, &gwa);

        NSRect rect = NSMakeRect(0, 0, gwa.width, gwa.height);
        NSImage *image = [GrabDraw captureScreenRect:rect display:display rootWindow:root];
        if (!image) {
            NSLog(NSLocalizedString(@"Could not capture screen image.", @"Log: screen capture failed"));
            XCloseDisplay(display);
            return;
        }

        _capturedImage = image;

        XCloseDisplay(display);
    });
}

- (void) dealloc
{
  [super dealloc];
}

- (void) showHelpPanel:(id)sender
{
  if (!_helpPanel) {
      if (![NSBundle loadNibNamed:@"HelpPanel" owner:self]) {
          NSLog (NSLocalizedString(@"Faild to load HelpPanel.gorm", @"Log: help panel load failed"));
          return;
        }
      [_helpPanel center];
    }

  NSString *textPath = [[NSBundle mainBundle] pathForResource:@"HelpPanel" ofType: @"rtf"];
  NSData *text = [NSData dataWithContentsOfFile:textPath];
  [_helpText replaceCharactersInRange:NSMakeRange(0, 0) withRTF:text];

  [_helpPanel makeKeyAndOrderFront:nil];
}

/// Shows the information panel.
/// @param sender The object that sent the action.
- (void)showInfoPanel:(id)sender
{
  NSString *file = [[NSBundle mainBundle] pathForResource:@"GrabInfo" ofType: @"plist"];
  _infoDict = [NSDictionary dictionaryWithContentsOfFile:file];

  if (!_infoPanel) {
      if (![NSBundle loadNibNamed:@"InfoPanel" owner:self]) {
          NSLog (NSLocalizedString(@"Faild to load InfoPanel.gorm", @"Log: info panel load failed"));
          return;
        }
      [_verField setStringValue:[NSString stringWithFormat:@"Release %@", [_infoDict objectForKey:@"ApplicationRelease"]]];
      [_copyrightField setStringValue:[_infoDict objectForKey:@"Copyright"]];
      [_infoPanel center];
    }
  [_infoPanel makeKeyAndOrderFront:nil];
}

/// Shows the cursor types panel.
/// @param sender The object that sent the action.
- (void)showCursorPanel:(id)sender
{
  if (!_cursorPanel) {
      if (![NSBundle loadNibNamed:@"CursorTypes" owner:self]) {
          NSLog (NSLocalizedString(@"Faild to load CursorTypes.gorm", @"Log: cursor panel load failed"));
          return;
        }
      [_cursorPanel center];
    }
  [_cursorPanel makeKeyAndOrderFront:nil];
}

/// Shows the inspector panel.
/// @param sender The object that sent the action.
- (void)showInspectorPanel:(id)sender
{
    if (!_inspectorPanel) {
        if (![NSBundle loadNibNamed:@"InspectorPanel" owner:self]) {
            NSLog (NSLocalizedString(@"Faild to load InspectorPanel.gorm", @"Log: inspector panel load failed"));
            return;
        }
        [_inspectorPanel center];
    }

    if (_capturedImage) {
        NSBitmapImageRep *bitmap = [[_capturedImage representations] firstObject];
        NSInteger width = bitmap.pixelsWide;
        NSInteger height = bitmap.pixelsHigh;
        NSInteger depth = bitmap.bitsPerPixel;
        BOOL hasAlpha = bitmap.hasAlpha;
        NSData *tiffData = [_capturedImage TIFFRepresentation];
        NSUInteger size = [tiffData length];

        [_widthField setStringValue:[NSString stringWithFormat:@"%04ld", (long)width]];
        [_heightField setStringValue:[NSString stringWithFormat:@"%04ld", (long)height]];
        [_depthField setStringValue:[NSString stringWithFormat:@"%04ld", (long)depth]];
        [_sizeField setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)size]];
        [_alphaCheckbox setState:hasAlpha ? NSControlStateValueOn : NSControlStateValueOff];
    } else {
        [_widthField setStringValue:@"0000"];
        [_heightField setStringValue:@"0000"];
        [_depthField setStringValue:@"0000"];
        [_sizeField setStringValue:@"0"];
        [_alphaCheckbox setState:NSControlStateValueOff];
    }

    [_inspectorPanel makeKeyAndOrderFront:nil];
}


- (IBAction)printImage:(id)sender
{
    if (!_capturedImage) {
        NSLog(NSLocalizedString(@"No image to print.", @"Log: print with no image"));
        return;
    }

    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, _capturedImage.size.width, _capturedImage.size.height)];
    [imageView setImage:_capturedImage];

    NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:imageView];
    [printOp runOperation];
}

- (IBAction)copyImage:(id)sender
{
    if (!_capturedImage) {
        NSLog(NSLocalizedString(@"No image to copy.", @"Log: copy with no image"));
        return;
    }

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:@[NSPasteboardTypeTIFF] owner:nil];
    NSData *tiffData = [_capturedImage TIFFRepresentation];
    BOOL success = (tiffData && [pasteboard setData:tiffData forType:NSPasteboardTypeTIFF]);
    if (success) {
        NSLog(NSLocalizedString(@"Image copied to clipboard.", @"Log: image copied"));
    } else {
        NSLog(NSLocalizedString(@"Failed to copy image to clipboard.", @"Log: image copy failed"));
    }
}

- (IBAction)saveImage:(id)sender
{
    if (!_capturedImage) {
        NSLog(NSLocalizedString(@"No image to save.", @"Log: save with no image"));
        return;
    }

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"png"]];
    [savePanel setNameFieldStringValue:@"Untitled"];
    [savePanel setMessage:NSLocalizedString(@"Choose a location to save the image.", @"Save panel message")];

    [savePanel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *fileURL = [savePanel URL];
            if (fileURL) {
                NSData *imageData = [_capturedImage TIFFRepresentation];
                if (!imageData) {
                    NSLog(NSLocalizedString(@"Failed to get image data.", @"Log: image data failed"));
                    return;
                }

                NSString *fileExtension = [[fileURL pathExtension] lowercaseString];
                if ([fileExtension isEqualToString:@"png"]) {
                    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:imageData];
                    imageData = [imageRep representationUsingType:NSPNGFileType properties:@{}];
                }

                NSError *error = nil;
                BOOL success = [imageData writeToURL:fileURL options:NSDataWritingAtomic error:&error];
                if (success) {
                    NSLog(NSLocalizedString(@"Image saved successfully to %@", @"Log: image saved"), [fileURL path]);
                } else {
                    NSLog(NSLocalizedString(@"Failed to save image: %@", @"Log: save failed"), error.localizedDescription);
                }
            }
        }
    }];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(printImage:) ||
        [menuItem action] == @selector(copyImageToPasteboard:) ||
        [menuItem action] == @selector(showInspectorPanel:) ||
        [menuItem action] == @selector(saveImage:)) {
        return (_capturedImage != nil);
    }
    return YES;
}

@end

