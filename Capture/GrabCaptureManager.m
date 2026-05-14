/*
   Project: Grab
   Module:  GrabCaptureManager

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabCaptureManager.h"
#import "GrabCaptureManager+Private.h"
#import "GrabSession.h"
#import "GrabAudioManager.h"
#import "GrabPreferencesManager.h"
#import "GrabResourceManager.h"
#import "GrabAnimationController.h"
#import "GrabImageProcessor.h"
#import "GrabDraw.h"

#import <X11/Xlib.h>
#import <X11/Xutil.h>
#import <X11/cursorfont.h>
#import <X11/Xcursor/Xcursor.h>
#include <unistd.h>

// Timeout for XGrabPointer event loops: 30 seconds.
// If no ButtonPress arrives within this window, the capture is aborted
// and all X11 resources are released — prevents permanent freeze.
static const NSTimeInterval kGrabPointerTimeoutSeconds = 30.0;

static GrabCaptureManager *_sharedInstance      = nil;
static dispatch_once_t     _sharedInstanceToken = 0;

@interface GrabCaptureManager ()
@property (nonatomic, strong) GrabAnimationController *animationController;
@property (nonatomic, strong) NSTimer   *countdownTimer;
// One-shot timer that fires _doFullScreenCapture after the flash delay.
// Stored so it can be invalidated if the capture is aborted or the app quits.
@property (nonatomic, strong) NSTimer   *pendingCaptureTimer;
@property (nonatomic, assign) NSInteger  currentCountdownFrame;
@property (nonatomic, assign) BOOL       countdownRunning;
@end

@implementation GrabCaptureManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    dispatch_once(&_sharedInstanceToken, ^{
        _sharedInstance = [[self alloc] initPrivate];
    });
    return _sharedInstance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _animationController = [[GrabAnimationController alloc] init];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Use +[GrabCaptureManager sharedManager].");
    return nil;
}

#pragma mark - Display helper

- (Display *)_openDisplay {
    const char *displayName = [[[NSProcessInfo processInfo]
                                  environment][@"DISPLAY"] UTF8String];
    Display *display = XOpenDisplay(displayName);
    if (!display) {
        NSLog(@"GrabCaptureManager: could not open X11 display '%s'.",
              displayName ? displayName : "(null)");
    }
    return display;
}

#pragma mark - XGrabPointer with timeout

// Waits for a ButtonPress event on display, blocking at most
// kGrabPointerTimeoutSeconds. Uses select(2) on the X11 file descriptor
// so the thread sleeps in the kernel with 0% CPU while waiting.
//
// Returns YES and fills *eventOut on ButtonPress.
// Returns NO (and logs) on timeout or X11 error — callers must release
// all grabbed resources and abort the capture.
- (BOOL)_waitForButtonPressOnDisplay:(Display *)display
                               event:(XEvent *)eventOut {
    int xfd = ConnectionNumber(display);
    NSTimeInterval deadline = [NSDate timeIntervalSinceReferenceDate]
                              + kGrabPointerTimeoutSeconds;

    while (YES) {
        while (XPending(display)) {
            XNextEvent(display, eventOut);
            if (eventOut->type == ButtonPress) return YES;
        }

        NSTimeInterval remaining = deadline - [NSDate timeIntervalSinceReferenceDate];
        if (remaining <= 0) {
            NSLog(@"GrabCaptureManager: XGrabPointer timed out after %.0f s — aborting.",
                  kGrabPointerTimeoutSeconds);
            return NO;
        }

        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(xfd, &fds);
        struct timeval tv;
        tv.tv_sec  = (long)remaining;
        tv.tv_usec = (long)((remaining - tv.tv_sec) * 1e6);
        // Guard: floating-point precision can produce a slightly negative
        // tv_usec when remaining is very small. select() with a negative
        // tv_usec has undefined behaviour on some kernels.
        if (tv.tv_usec < 0) { tv.tv_sec = 0; tv.tv_usec = 0; }
        int ret = select(xfd + 1, &fds, NULL, NULL, &tv);
        if (ret < 0) {
            NSLog(@"GrabCaptureManager: select() error %d — aborting capture.", errno);
            return NO;
        }
    }
}

#pragma mark - Cursor builder

// Attempts to build an XCursor from the CameraPointer TIFF resource.
// Extracted from _buildCameraPointerCursorOnDisplay: to avoid goto across
// ObjC variable declarations under ARC. Returns None on any failure.
- (Cursor)_tryBuildXcursorFromPointerImageOnDisplay:(Display *)display {
    NSImage *pointerImg = [GrabResourceManager sharedManager].cameraPointerImage;
    if (!pointerImg) return None;

    NSBitmapImageRep *rep = nil;
    for (NSImageRep *r in [pointerImg representations]) {
        if ([r isKindOfClass:[NSBitmapImageRep class]]) {
            rep = (NSBitmapImageRep *)r;
            break;
        }
    }
    if (!rep) {
        NSData *tiffData = [pointerImg TIFFRepresentation];
        if (tiffData) rep = [NSBitmapImageRep imageRepWithData:tiffData];
    }
    if (!rep) return None;

    unsigned int imgW = (unsigned int)[rep pixelsWide];
    unsigned int imgH = (unsigned int)[rep pixelsHigh];
    if (imgW == 0 || imgH == 0) return None;

    XcursorImage *ximg = XcursorImageCreate(imgW, imgH);
    if (!ximg) return None;

    ximg->xhot = imgW / 2;
    ximg->yhot = imgH / 2;
    XcursorPixel *dst = ximg->pixels;
    for (unsigned int py = 0; py < imgH; py++) {
        for (unsigned int px = 0; px < imgW; px++) {
            NSUInteger idx = py * imgW + px;
            NSColor *c = [[rep colorAtX:px y:py]
                            colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            if (!c) { dst[idx] = 0; continue; }
            unsigned char r = (unsigned char)([c redComponent]   * 255.0 + 0.5);
            unsigned char g = (unsigned char)([c greenComponent] * 255.0 + 0.5);
            unsigned char b = (unsigned char)([c blueComponent]  * 255.0 + 0.5);
            unsigned char a = (unsigned char)([c alphaComponent] * 255.0 + 0.5);
            dst[idx] = ((XcursorPixel)a << 24) |
                       ((XcursorPixel)r << 16) |
                       ((XcursorPixel)g <<  8) |
                        (XcursorPixel)b;
        }
    }
    Cursor cursor = XcursorImageLoadCursor(display, ximg);
    XcursorImageDestroy(ximg);
    return cursor; // None if XcursorImageLoadCursor failed
}

// Builds an XCursor from the CameraPointer TIFF resource.
// Falls back to XC_hand2 if the image is unavailable or cursor creation fails.
// Must be called from a background thread (pixel-level NSBitmapImageRep access).
- (Cursor)_buildCameraPointerCursorOnDisplay:(Display *)display {
    Cursor cursor = [self _tryBuildXcursorFromPointerImageOnDisplay:display];
    if (cursor != None) return cursor;
    NSLog(@"GrabCaptureManager: CameraPointer cursor unavailable, using XC_hand2.");
    return XCreateFontCursor(display, XC_hand2);
}

// Builds an XCursor from a TIFF file inside the CursorTypes.gorm bundle.
// The gorm bundle lives inside the main .app bundle under Resources/.
// Falls back to the XC_left_ptr system cursor on any failure.
// Must be called from a background thread (pixel-level NSBitmapImageRep access).
- (Cursor)_buildCursorFromGormTiff:(NSString *)tiffName onDisplay:(Display *)display {
    // Path: Grab.app/Resources/CursorTypes.gorm/<tiffName>.tiff
    NSString *gormPath = [[NSBundle mainBundle] pathForResource:@"CursorTypes"
                                                         ofType:@"gorm"];
    if (!gormPath) {
        NSLog(@"GrabCaptureManager: CursorTypes.gorm not found in bundle.");
        return XCreateFontCursor(display, XC_left_ptr);
    }
    NSString *tiffPath = [[gormPath stringByAppendingPathComponent:tiffName]
                          stringByAppendingPathExtension:@"tiff"];
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:tiffPath];
    if (!img) {
        NSLog(@"GrabCaptureManager: could not load %@", tiffPath);
        return XCreateFontCursor(display, XC_left_ptr);
    }

    NSBitmapImageRep *rep = nil;
    for (NSImageRep *r in [img representations]) {
        if ([r isKindOfClass:[NSBitmapImageRep class]]) { rep = (NSBitmapImageRep *)r; break; }
    }
    if (!rep) {
        NSData *tiff = [img TIFFRepresentation];
        if (tiff) rep = [NSBitmapImageRep imageRepWithData:tiff];
    }
    if (!rep) return XCreateFontCursor(display, XC_left_ptr);

    unsigned int w = (unsigned int)[rep pixelsWide];
    unsigned int h = (unsigned int)[rep pixelsHigh];
    if (w == 0 || h == 0) return XCreateFontCursor(display, XC_left_ptr);

    XcursorImage *ximg = XcursorImageCreate(w, h);
    if (!ximg) return XCreateFontCursor(display, XC_left_ptr);
    ximg->xhot = w / 2;
    ximg->yhot = h / 2;
    XcursorPixel *dst = ximg->pixels;
    for (unsigned int py = 0; py < h; py++) {
        for (unsigned int px = 0; px < w; px++) {
            NSUInteger idx = py * w + px;
            NSColor *c = [[rep colorAtX:px y:py]
                            colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            if (!c) { dst[idx] = 0; continue; }
            unsigned char r2 = (unsigned char)([c redComponent]   * 255.0 + 0.5);
            unsigned char g  = (unsigned char)([c greenComponent] * 255.0 + 0.5);
            unsigned char b  = (unsigned char)([c blueComponent]  * 255.0 + 0.5);
            unsigned char a  = (unsigned char)([c alphaComponent] * 255.0 + 0.5);
            dst[idx] = ((XcursorPixel)a << 24) |
                       ((XcursorPixel)r2 << 16) |
                       ((XcursorPixel)g  <<  8) |
                        (XcursorPixel)b;
        }
    }
    Cursor cursor = XcursorImageLoadCursor(display, ximg);
    XcursorImageDestroy(ximg);
    return (cursor != None) ? cursor : XCreateFontCursor(display, XC_left_ptr);
}

// Returns the X11 Cursor for capture based on the saved cursorType preference.
// GrabCursorTypeCameraPointer uses the main bundle TIFF (existing path).
// All other types load their TIFF from CursorTypes.gorm and build an Xcursor,
// so the cursor during capture is visually identical to the panel button image.
- (Cursor)_buildCaptureCursorOnDisplay:(Display *)display {
    GrabCursorType type = [GrabPreferencesManager sharedManager].cursorType;

    // CameraPointer (default) uses the existing main-bundle path.
    if (type == GrabCursorTypeCameraPointer) {
        return [self _buildCameraPointerCursorOnDisplay:display];
    }

    // All other types: load the TIFF from CursorTypes.gorm.
    NSString *tiffName = [GrabPreferencesManager tiffNameForCursorType:type];
    if (tiffName) {
        return [self _buildCursorFromGormTiff:tiffName onDisplay:display];
    }

    // Fallback (should never reach here).
    return [self _buildCameraPointerCursorOnDisplay:display];
}

// Aborts the current capture: releases X11 resources and closes the panel
// on the main thread. Called from background threads on timeout or error.
- (void)_abortCaptureWithDisplay:(Display *)display cursor:(Cursor)cursor {
    XUngrabPointer(display, CurrentTime);
    XFreeCursor(display, cursor);
    XCloseDisplay(display);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_animationController closePanel];
    });
}

#pragma mark - Core resource guard (shared by Screen and Window capture)

// Returns YES if all core assets required by Screen and Window capture are
// loaded. Logs a diagnostic and returns NO otherwise.
- (BOOL)_verifyCoreResourcesForCapture:(NSString *)captureModeName {
    GrabResourceManager *res = [GrabResourceManager sharedManager];
    if ([res loadResources] &&
        res.cameraNormalImage &&
        res.cameraEyeFlashImage &&
        res.cameraEyeImages.count > 0) {
        return YES;
    }
    NSLog(@"GrabCaptureManager: resources not ready for %@ capture.", captureModeName);
    return NO;
}

#pragma mark - Full-screen capture

- (void)captureWindowFromMenuOrigin:(NSPoint)menuOrigin {
    if (![self _verifyCoreResourcesForCapture:@"window"]) return;
    GrabResourceManager *res = [GrabResourceManager sharedManager];
    NSPoint origin = NSEqualPoints(menuOrigin, NSZeroPoint)
                     ? [_animationController _finalPanelOrigin]
                     : menuOrigin;
    [_animationController createPanelWithImage:res.cameraNormalImage
                                        target:self
                                        action:@selector(_activateWindowCursor)
                                   originPoint:origin];
}

- (void)captureFullScreenFromMenuOrigin:(NSPoint)menuOrigin {
    if (![self _verifyCoreResourcesForCapture:@"full-screen"]) return;
    GrabResourceManager *res = [GrabResourceManager sharedManager];
    NSPoint origin = NSEqualPoints(menuOrigin, NSZeroPoint)
                     ? [_animationController _finalPanelOrigin]
                     : menuOrigin;
    [_animationController createPanelWithImage:res.cameraNormalImage
                                        target:self
                                        action:@selector(_activateFullScreenCursor)
                                   originPoint:origin];
}

- (void)_activateFullScreenCursor {
    [_animationController startMotionDrivenEyeAnimation];
    [NSThread detachNewThreadSelector:@selector(_fullScreenCaptureThread)
                             toTarget:self
                           withObject:nil];
}

- (void)_fullScreenCaptureThread {
    @autoreleasepool {
        Display *display = [self _openDisplay];
        if (!display) return;

        Window root   = DefaultRootWindow(display);
        Cursor cursor = [self _buildCaptureCursorOnDisplay:display];

        int grabResult = XGrabPointer(display, root, False,
                                      ButtonPressMask | PointerMotionMask,
                                      GrabModeAsync, GrabModeAsync,
                                      None, cursor, CurrentTime);
        if (grabResult != GrabSuccess) {
            NSLog(@"GrabCaptureManager: XGrabPointer failed (%d) for full-screen.", grabResult);
            [self _abortCaptureWithDisplay:display cursor:cursor];
            return;
        }

        XEvent event;
        if (![self _waitForButtonPressOnDisplay:display event:&event]) {
            [self _abortCaptureWithDisplay:display cursor:cursor];
            return;
        }

        XUngrabPointer(display, CurrentTime);
        XFreeCursor(display, cursor);

        [_animationController performSelectorOnMainThread:@selector(_stopMotionAndShowFlash)
                                              withObject:nil
                                           waitUntilDone:NO];

        [[GrabAudioManager sharedManager] playSound:GrabSoundOpenShutter];
        [NSThread sleepForTimeInterval:0.8];

        [_animationController performSelectorOnMainThread:@selector(closePanel)
                                              withObject:nil
                                           waitUntilDone:YES];

        XWindowAttributes gwa;
        XGetWindowAttributes(display, root, &gwa);
        NSRect rect  = NSMakeRect(0, 0, gwa.width, gwa.height);
        NSImage *image = [GrabImageProcessor captureRect:rect
                                                 display:display
                                              rootWindow:root];
        XCloseDisplay(display);

        if (!image) {
            NSLog(@"GrabCaptureManager: full-screen capture returned nil image.");
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[GrabSession sharedSession] setCapturedImage:image];
            [GrabDraw showImage:image];
            [[GrabAudioManager sharedManager] playCloseShutterAsync];
        });
    }
}

// Used by timed-capture flow — bypasses the animation sequence entirely.
- (void)_doFullScreenCapture {
    _pendingCaptureTimer = nil; // fired — clear the reference
    [_animationController closePanel];
    [NSThread detachNewThreadSelector:@selector(_doFullScreenCaptureThread)
                             toTarget:self
                           withObject:nil];
}

- (void)_doFullScreenCaptureThread {
    @autoreleasepool {
        Display *display = [self _openDisplay];
        if (!display) return;

        Window root = DefaultRootWindow(display);
        XWindowAttributes gwa;
        XGetWindowAttributes(display, root, &gwa);
        NSRect rect  = NSMakeRect(0, 0, gwa.width, gwa.height);
        NSImage *image = [GrabImageProcessor captureRect:rect
                                                 display:display
                                              rootWindow:root];
        XCloseDisplay(display);

        if (!image) {
            NSLog(@"GrabCaptureManager: full-screen capture (timed) returned nil image.");
            return;
        }

        // Wait for OpenShutter to finish before showing the image window.
        [[GrabAudioManager sharedManager] playSound:GrabSoundOpenShutter];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[GrabSession sharedSession] setCapturedImage:image];
            [GrabDraw showImage:image];
            [[GrabAudioManager sharedManager] playCloseShutterAsync];
        });
    }
}

#pragma mark - Window capture

- (void)_activateWindowCursor {
    [_animationController startMotionDrivenEyeAnimation];
    [NSThread detachNewThreadSelector:@selector(_windowCaptureThread)
                             toTarget:self
                           withObject:nil];
}

- (void)_windowCaptureThread {
    @autoreleasepool {
        Display *display = [self _openDisplay];
        if (!display) return;

        Window root   = DefaultRootWindow(display);
        Cursor cursor = [self _buildCaptureCursorOnDisplay:display];

        int grabResult = XGrabPointer(display, root, False,
                                      ButtonPressMask | PointerMotionMask,
                                      GrabModeAsync, GrabModeAsync,
                                      None, cursor, CurrentTime);
        if (grabResult != GrabSuccess) {
            NSLog(@"GrabCaptureManager: XGrabPointer failed (%d) for window.", grabResult);
            [self _abortCaptureWithDisplay:display cursor:cursor];
            return;
        }

        XEvent event;
        if (![self _waitForButtonPressOnDisplay:display event:&event]) {
            [self _abortCaptureWithDisplay:display cursor:cursor];
            return;
        }

        // Walk up the window tree until we reach a direct child of root.
        Window targetWindow = event.xbutton.subwindow;
        if (targetWindow != None) {
            Window parent = targetWindow;
            Window rootCheck, parentCheck;
            Window *children  = NULL;
            unsigned int nchildren = 0;
            while (parent != None && parent != root) {
                targetWindow = parent;
                if (!XQueryTree(display, targetWindow,
                                &rootCheck, &parentCheck,
                                &children, &nchildren)) break;
                if (children) XFree(children);
                children = NULL;
                if (parentCheck == root) break;
                parent = parentCheck;
            }
        }

        XUngrabPointer(display, CurrentTime);
        XFreeCursor(display, cursor);

        [_animationController performSelectorOnMainThread:@selector(_stopMotionAndShowFlash)
                                              withObject:nil
                                           waitUntilDone:NO];

        [[GrabAudioManager sharedManager] playSound:GrabSoundOpenShutter];
        [NSThread sleepForTimeInterval:0.8];

        [_animationController performSelectorOnMainThread:@selector(closePanel)
                                              withObject:nil
                                           waitUntilDone:YES];

        NSImage *image = nil;
        if (targetWindow == None) {
            XWindowAttributes gwa;
            XGetWindowAttributes(display, root, &gwa);
            NSRect rect = NSMakeRect(0, 0, gwa.width, gwa.height);
            image = [GrabImageProcessor captureRect:rect
                                            display:display
                                         rootWindow:root];
        } else {
            image = [GrabImageProcessor captureWindow:targetWindow display:display];
        }

        XCloseDisplay(display);

        if (!image) {
            NSLog(@"GrabCaptureManager: window capture returned nil image.");
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[GrabSession sharedSession] setCapturedImage:image];
            [GrabDraw showImage:image];
            [[GrabAudioManager sharedManager] playCloseShutterAsync];
        });
    }
}

#pragma mark - Section capture

- (void)captureScreenSection {
    [NSThread detachNewThreadSelector:@selector(_sectionCaptureThread)
                             toTarget:self
                           withObject:nil];
}

- (void)_sectionCaptureThread {
    @autoreleasepool {
        Display *display = [self _openDisplay];
        if (!display) return;

        Window root = DefaultRootWindow(display);
        NSRect selectedRect = [self _runRubberBandSelectionOnDisplay:display root:root];

        if (selectedRect.size.width <= 0 || selectedRect.size.height <= 0) {
            NSLog(@"GrabCaptureManager: section capture cancelled.");
            XCloseDisplay(display);
            return;
        }

        NSImage *image = [GrabImageProcessor captureRect:selectedRect
                                                 display:display
                                              rootWindow:root];
        XCloseDisplay(display);

        if (!image) {
            NSLog(@"GrabCaptureManager: section capture returned nil image.");
            return;
        }

        // Wait for OpenShutter to finish before showing the image window.
        [[GrabAudioManager sharedManager] playSound:GrabSoundOpenShutter];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[GrabSession sharedSession] setCapturedImage:image];
            [GrabDraw showImage:image];
            [[GrabAudioManager sharedManager] playCloseShutterAsync];
        });
    }
}

// ── SelectCursor bitmap (16×16, inverted-L shape) ────────────────────────────
// Matches the original NeXT/OpenStep selection cursor from SelectCursor.tiff.
// Format: LSB-first (X11 standard), 2 bytes per row, 16 pixels wide.
// Hotspot at (0, 0) — the top-left corner of the L.
static char _selectCursorBits[] = {
    0xff, 0xff,  // row  0: full horizontal arm
    0x01, 0x00,  // row  1: vertical arm (col 0 only)
    0x01, 0x00,  // row  2
    0x01, 0x00,  // row  3
    0x01, 0x00,  // row  4
    0x01, 0x00,  // row  5
    0x01, 0x00,  // row  6
    0x01, 0x00,  // row  7
    0x01, 0x00,  // row  8
    0x01, 0x00,  // row  9
    0x01, 0x00,  // row 10
    0x01, 0x00,  // row 11
    0x01, 0x00,  // row 12
    0x01, 0x00,  // row 13
    0x01, 0x00,  // row 14
    0x01, 0x00   // row 15
};

static void _drawCoordLabel(Display *dpy, Window root,
                             GC gcText, GC gcShadow,
                             XFontStruct *font,
                             int mx, int my, const char *label,
                             int *out_x, int *out_y,
                             int *out_w, int *out_h)
{
    int len     = (int)strlen(label);
    int textW   = font ? XTextWidth(font, label, len) : (int)len * 8;
    int ascent  = font ? font->ascent  : 10;
    int descent = font ? font->descent :  3;
    int tx = mx - textW - 4;
    int ty = my + ascent + 2;
    XDrawString(dpy, root, gcShadow, tx + 1, ty + 1, label, len);
    XDrawString(dpy, root, gcText,   tx,     ty,     label, len);
    if (out_x) *out_x = tx - 1;
    if (out_y) *out_y = my;
    if (out_w) *out_w = textW + 6;
    if (out_h) *out_h = ascent + descent + 4;
}

static void _restoreRegion(Display *dpy, Window root, GC gcCopy,
                            XImage *bg, int x, int y, int w, int h,
                            int sw, int sh)
{
    if (x < 0) { w += x; x = 0; }
    if (y < 0) { h += y; y = 0; }
    if (x + w > sw) w = sw - x;
    if (y + h > sh) h = sh - y;
    if (w <= 0 || h <= 0) return;
    XPutImage(dpy, root, gcCopy, bg, x, y, x, y,
              (unsigned)w, (unsigned)h);
}

- (NSRect)_runRubberBandSelectionOnDisplay:(Display *)display root:(Window)root {
    int screen = DefaultScreen(display);
    int sw     = DisplayWidth(display,  screen);
    int sh     = DisplayHeight(display, screen);

    // Wait for the GNUstep menu to fully close before capturing background.
    usleep(150000);
    XSync(display, False);

    XImage *bg = XGetImage(display, root, 0, 0,
                           (unsigned)sw, (unsigned)sh, AllPlanes, ZPixmap);
    if (!bg) {
        NSLog(@"GrabCaptureManager: XGetImage failed for selection background.");
        return NSZeroRect;
    }

    Pixmap srcPm  = XCreateBitmapFromData(display, root, _selectCursorBits, 16, 16);
    Pixmap maskPm = XCreateBitmapFromData(display, root, _selectCursorBits, 16, 16);
    XColor black = {0}, white = {0};
    black.red = black.green = black.blue = 0;
    white.red = white.green = white.blue = 65535;
    Cursor selectCursor = XCreatePixmapCursor(display, srcPm, maskPm,
                                               &black, &black, 0, 0);
    XFreePixmap(display, srcPm);
    XFreePixmap(display, maskPm);

    unsigned long blackPx = XBlackPixel(display, screen);
    unsigned long whitePx = XWhitePixel(display, screen);

    XGCValues gcv;
    memset(&gcv, 0, sizeof(gcv));

    gcv.foreground     = blackPx;
    gcv.background     = whitePx;
    gcv.subwindow_mode = IncludeInferiors;
    GC gcCopy = XCreateGC(display, root,
                          GCForeground | GCBackground | GCSubwindowMode, &gcv);

    gcv.foreground     = blackPx;
    gcv.background     = whitePx;
    gcv.function       = GXcopy;
    gcv.plane_mask     = AllPlanes;
    gcv.subwindow_mode = IncludeInferiors;
    GC gcDraw = XCreateGC(display, root,
                          GCFunction | GCForeground | GCBackground |
                          GCPlaneMask | GCSubwindowMode, &gcv);
    XSetLineAttributes(display, gcDraw, 1, LineSolid, CapButt, JoinMiter);

    gcv.foreground = blackPx;
    gcv.background = whitePx;
    gcv.function   = GXcopy;
    gcv.plane_mask = AllPlanes;
    GC gcText = XCreateGC(display, root,
                          GCForeground | GCBackground | GCFunction |
                          GCPlaneMask | GCSubwindowMode, &gcv);

    gcv.foreground = whitePx;
    gcv.background = blackPx;
    GC gcShadow = XCreateGC(display, root,
                             GCForeground | GCBackground | GCFunction |
                             GCPlaneMask | GCSubwindowMode, &gcv);

    XFontStruct *font = XLoadQueryFont(display, "fixed");
    if (!font) font = XLoadQueryFont(display, "*");
    if (font) {
        XSetFont(display, gcText,   font->fid);
        XSetFont(display, gcShadow, font->fid);
    }

    int grabmask = ButtonMotionMask | ButtonPressMask | ButtonReleaseMask
                 | PointerMotionMask;

    // Section capture uses XGrabKeyboard — no timeout loop needed because the
    // user can always press a key to abort. XGrabPointer failure is still
    // checked to avoid blocking on XNextEvent with no active grab.
    int grabResult = XGrabPointer(display, root, False, grabmask,
                                  GrabModeAsync, GrabModeAsync,
                                  root, selectCursor, CurrentTime);
    if (grabResult != GrabSuccess) {
        NSLog(@"GrabCaptureManager: XGrabPointer failed (%d) for selection.", grabResult);
        XDestroyImage(bg);
        XFreeGC(display, gcCopy);
        XFreeGC(display, gcDraw);
        XFreeGC(display, gcText);
        XFreeGC(display, gcShadow);
        if (font) XFreeFont(display, font);
        XFreeCursor(display, selectCursor);
        return NSZeroRect;
    }

    XGrabKeyboard(display, root, False, GrabModeAsync, GrabModeAsync, CurrentTime);

    int rx = 0, ry = 0;
    int rect_x = 0, rect_y = 0, rect_w = 0, rect_h = 0;
    int btnPressed = 0, done = 0;
    int prev_mx = -1;
    int labelX = 0, labelY = 0, labelW = 0, labelH = 0;
    char label[32];

    XEvent ev;
    while (!done) {
        XNextEvent(display, &ev);

        if (ev.type == MotionNotify) {
            while (XPending(display)) {
                XEvent next;
                XPeekEvent(display, &next);
                if (next.type != MotionNotify) break;
                XNextEvent(display, &ev);
            }
        }

        switch (ev.type) {

            case ButtonPress:
                if (prev_mx >= 0 && labelW > 0) {
                    _restoreRegion(display, root, gcCopy, bg,
                                   labelX, labelY, labelW, labelH, sw, sh);
                    XFlush(display);
                }
                btnPressed = 1;
                rx = ev.xbutton.x;
                ry = ev.xbutton.y;
                rect_x = rx; rect_y = ry;
                rect_w = 0;  rect_h = 0;
                prev_mx = rx;
                XChangeActivePointerGrab(display, grabmask, None, CurrentTime);
                break;

            case MotionNotify: {
                int mx = ev.xmotion.x;
                int my = ev.xmotion.y;

                if (prev_mx >= 0 && labelW > 0) {
                    _restoreRegion(display, root, gcCopy, bg,
                                   labelX, labelY, labelW, labelH, sw, sh);
                }

                if (btnPressed) {
                    if (rect_w > 0 && rect_h > 0)
                        _restoreRegion(display, root, gcCopy, bg,
                                       rect_x - 2, rect_y - 2,
                                       rect_w + 4, rect_h + 4, sw, sh);

                    rect_x = (rx < mx) ? rx : mx;
                    rect_y = (ry < my) ? ry : my;
                    rect_w = abs(mx - rx);
                    rect_h = abs(my - ry);

                    if (rect_w > 0 && rect_h > 0)
                        XDrawRectangle(display, root, gcDraw,
                                       rect_x, rect_y,
                                       (unsigned)rect_w, (unsigned)rect_h);

                    snprintf(label, sizeof(label), "%d, %d", rect_w, rect_h);
                } else {
                    snprintf(label, sizeof(label), "%d, %d", mx, my);
                }

                _drawCoordLabel(display, root, gcText, gcShadow, font,
                                mx, my, label,
                                &labelX, &labelY, &labelW, &labelH);
                XFlush(display);
                prev_mx = mx;
                break;
            }

            case ButtonRelease:
                done = 1;
                break;

            case KeyPress:
                NSLog(@"GrabCaptureManager: key pressed, aborting selection.");
                done = 2;
                break;

            default:
                break;
        }
    }

    if (prev_mx >= 0 && labelW > 0) {
        _restoreRegion(display, root, gcCopy, bg,
                       labelX, labelY, labelW, labelH, sw, sh);
    }
    if (rect_w > 0 && rect_h > 0) {
        _restoreRegion(display, root, gcCopy, bg,
                       rect_x - 2, rect_y - 2,
                       rect_w + 4, rect_h + 4, sw, sh);
    }
    XFlush(display);

    XUngrabPointer(display,  CurrentTime);
    XUngrabKeyboard(display, CurrentTime);

    XDestroyImage(bg);
    XFreeGC(display, gcCopy);
    XFreeGC(display, gcDraw);
    XFreeGC(display, gcText);
    XFreeGC(display, gcShadow);
    if (font) XFreeFont(display, font);
    XFreeCursor(display, selectCursor);

    if (done == 2 || rect_w <= 0 || rect_h <= 0) return NSZeroRect;
    return NSMakeRect(rect_x, rect_y, rect_w, rect_h);
}

#pragma mark - Timed capture

- (void)cancelPendingCapture {
    [_countdownTimer invalidate];
    _countdownTimer = nil;
    [_pendingCaptureTimer invalidate];
    _pendingCaptureTimer = nil;
    _countdownRunning = NO;
    [_animationController closePanel];
}

- (void)startTimedCaptureFromMenuOrigin:(NSPoint)menuOrigin {
    GrabResourceManager *res = [GrabResourceManager sharedManager];
    if (![res loadResources] || !res.piePiecesImage || !res.cameraWatchImage) {
        NSLog(@"GrabCaptureManager: resources not ready for timed capture.");
        return;
    }
    [_countdownTimer invalidate];
    _countdownTimer = nil;
    [_pendingCaptureTimer invalidate];
    _pendingCaptureTimer = nil;
    _countdownRunning = NO;
    _currentCountdownFrame = 0;

    // NSZeroPoint means the call came from services (no menu click origin).
    // In that case skip the fly-in animation and show the panel at its
    // final corner position directly.
    BOOL animated = !NSEqualPoints(menuOrigin, NSZeroPoint);
    if (animated) {
        [_animationController createPanelWithImage:res.cameraWatchImage
                                            target:self
                                            action:@selector(_userStartedCountdown)
                                       originPoint:menuOrigin];
    } else {
        [_animationController createPanelWithImage:res.cameraWatchImage
                                            target:self
                                            action:@selector(_userStartedCountdown)
                                       originPoint:[_animationController _finalPanelOrigin]];
    }
    [_animationController showWatchIcon];
}

- (void)_userStartedCountdown {
    if (_countdownRunning) return;
    _countdownRunning = YES;
    _currentCountdownFrame = 0;
    _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(_countdownTick)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)_countdownTick {
    NSInteger totalFrames = [GrabPreferencesManager sharedManager].timerDuration;
    if (_currentCountdownFrame >= totalFrames) {
        [_countdownTimer invalidate];
        _countdownTimer = nil;
        _countdownRunning = NO;

        // Play sounds on a background thread — both calls block for the sound
        // duration. Calling them on the main thread (from NSTimer) would
        // freeze the UI for up to ~2 seconds.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[GrabAudioManager sharedManager] playSound:GrabSoundTimerDone];
            [[GrabAudioManager sharedManager] playSound:GrabSoundOpenShutter];
        });

        [_animationController showWatchFlashThenClose];

        [_pendingCaptureTimer invalidate];
        _pendingCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                target:self
                                                              selector:@selector(_doFullScreenCapture)
                                                              userInfo:nil
                                                               repeats:NO];
        return;
    }
    [_animationController updatePieFrame:_currentCountdownFrame];
    _currentCountdownFrame++;
}

@end
