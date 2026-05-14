/*
   Project: Grab
   Module:  GrabImageProcessor

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabImageProcessor.h"

@interface GrabImageProcessor ()
+ (nullable NSBitmapImageRep *)_bitmapRepFromXImage:(XImage *)xImage
                                              width:(NSUInteger)width
                                             height:(NSUInteger)height;
@end

@implementation GrabImageProcessor

#pragma mark - Private: XImage → NSBitmapImageRep

+ (NSBitmapImageRep *)_bitmapRepFromXImage:(XImage *)xImage
                                     width:(NSUInteger)width
                                    height:(NSUInteger)height {
    if (!xImage) {
        NSLog(@"GrabImageProcessor: XImage is NULL.");
        return nil;
    }

    NSBitmapImageRep *rep =
        [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                pixelsWide:(NSInteger)width
                                                pixelsHigh:(NSInteger)height
                                             bitsPerSample:8
                                           samplesPerPixel:4
                                                  hasAlpha:YES
                                                  isPlanar:NO
                                            colorSpaceName:NSDeviceRGBColorSpace
                                               bytesPerRow:(NSInteger)(4 * width)
                                              bitsPerPixel:32];
    if (!rep) {
        NSLog(@"GrabImageProcessor: failed to allocate NSBitmapImageRep (%lu×%lu).",
              (unsigned long)width, (unsigned long)height);
        return nil;
    }

    unsigned char *data = [rep bitmapData];
    for (NSUInteger y = 0; y < height; y++) {
        for (NSUInteger x = 0; x < width; x++) {
            unsigned long pixel = XGetPixel(xImage, (int)x, (int)y);
            NSUInteger idx = (y * width + x) * 4;
            data[idx + 0] = (unsigned char)((pixel & 0xFF0000) >> 16); // R
            data[idx + 1] = (unsigned char)((pixel & 0x00FF00) >>  8); // G
            data[idx + 2] = (unsigned char)( pixel & 0x0000FF);        // B
            data[idx + 3] = 0xFF;                                      // A
        }
    }
    return rep;
}

#pragma mark - Public: Screen rect capture

+ (NSImage *)captureRect:(NSRect)rect
                 display:(Display *)display
              rootWindow:(Window)rootWindow {

    if (rect.size.width <= 0 || rect.size.height <= 0) {
        NSLog(@"GrabImageProcessor: captureRect called with zero/negative size.");
        return nil;
    }

    XImage *xImage = XGetImage(display,
                                rootWindow,
                                (int)rect.origin.x,
                                (int)rect.origin.y,
                                (unsigned int)rect.size.width,
                                (unsigned int)rect.size.height,
                                AllPlanes,
                                ZPixmap);
    if (!xImage) {
        NSLog(@"GrabImageProcessor: XGetImage failed for rect (%g,%g %g×%g).",
              rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
        return nil;
    }

    NSBitmapImageRep *rep = [self _bitmapRepFromXImage:xImage
                                                 width:(NSUInteger)rect.size.width
                                                height:(NSUInteger)rect.size.height];
    XDestroyImage(xImage);
    if (!rep) return nil;

    NSImage *image = [[NSImage alloc] initWithSize:rect.size];
    [image addRepresentation:rep];
    return image;
}

#pragma mark - Public: Window capture

+ (NSImage *)captureWindow:(Window)window display:(Display *)display {
    XWindowAttributes gwa;
    XGetWindowAttributes(display, window, &gwa);

    unsigned int w = (unsigned int)gwa.width;
    unsigned int h = (unsigned int)gwa.height;

    // Guard: minimized or zero-size windows have gwa.width/height == 0.
    // XCompositeRedirectWindow must not be called before this check because
    // there is no pixmap to redirect to — and we must not leave a redirect
    // active if we return early.
    if (w == 0 || h == 0) {
        NSLog(@"GrabImageProcessor: captureWindow skipped — window has zero size (%u×%u).", w, h);
        return nil;
    }

    // Ask the compositor for an off-screen copy so we capture the window's
    // own pixels even when it is partially occluded.
    XCompositeRedirectWindow(display, window, CompositeRedirectAutomatic);
    XSync(display, False);

    Pixmap pixmap = XCompositeNameWindowPixmap(display, window);
    if (!pixmap) {
        // Fallback: direct XGetImage. Must still unredirect to avoid leaving
        // the compositor redirect active after we return.
        NSLog(@"GrabImageProcessor: XCompositeNameWindowPixmap failed — "
              @"falling back to direct XGetImage.");
        XCompositeUnredirectWindow(display, window, CompositeRedirectAutomatic);
        XImage *xImg = XGetImage(display, window, 0, 0, w, h, AllPlanes, ZPixmap);
        if (!xImg) return nil;
        NSBitmapImageRep *rep = [self _bitmapRepFromXImage:xImg width:w height:h];
        XDestroyImage(xImg);
        if (!rep) return nil;
        NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
        [img addRepresentation:rep];
        return img;
    }

    XImage *xImage = XGetImage(display, pixmap, 0, 0, w, h, AllPlanes, ZPixmap);
    XFreePixmap(display, pixmap);
    XCompositeUnredirectWindow(display, window, CompositeRedirectAutomatic);

    if (!xImage) {
        NSLog(@"GrabImageProcessor: XGetImage on composite pixmap failed.");
        return nil;
    }

    NSBitmapImageRep *rep = [self _bitmapRepFromXImage:xImage width:w height:h];
    XDestroyImage(xImage);
    if (!rep) return nil;

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
    [image addRepresentation:rep];
    return image;
}

@end
