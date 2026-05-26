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

    // Fast path: direct pointer walk over xImage->data.
    //
    // Conditions required for safe direct access:
    //   - ZPixmap format (pixels packed in scanline order, no XY bit-planes)
    //   - 32 bits per pixel (the universal X11 visual depth on modern hardware)
    //   - 8 bits per channel in the red/green/blue masks (0xFF each)
    //
    // On little-endian hosts (x86, aarch64) X11 stores each pixel as BGRA in
    // memory, so byte offsets are: [0]=B [1]=G [2]=R [3]=pad.
    // On big-endian hosts the byte order is ARGB, so offsets flip to:
    // [1]=R [2]=G [3]=B.
    //
    // If any condition is not met we fall back to XGetPixel(), which handles
    // all depths and formats correctly at the cost of ~10–20× more overhead.

    BOOL usedFastPath = NO;

    if (xImage->format == ZPixmap &&
        xImage->bits_per_pixel == 32 &&
        (xImage->red_mask   & 0xFF) == 0 &&
        (xImage->green_mask & 0xFF) == 0 &&
        (xImage->blue_mask  & 0xFF) == 0)
    {
        // Determine per-channel byte offsets from the masks, which are
        // guaranteed to be 0x00FF0000 / 0x0000FF00 / 0x000000FF in some order.
        int rShift = 0, gShift = 0, bShift = 0;
        unsigned long rm = xImage->red_mask;
        unsigned long gm = xImage->green_mask;
        unsigned long bm = xImage->blue_mask;
        while (rm > 0xFF) { rm >>= 8; rShift++; }
        while (gm > 0xFF) { gm >>= 8; gShift++; }
        while (bm > 0xFF) { bm >>= 8; bShift++; }

        // Adjust for host byte order: on big-endian hosts the bytes inside
        // each 32-bit word are reversed relative to the mask offsets.
        if (xImage->byte_order == MSBFirst) {
            rShift = 3 - rShift;
            gShift = 3 - gShift;
            bShift = 3 - bShift;
        }

        const unsigned char *src = (const unsigned char *)xImage->data;
        NSUInteger bpl = (NSUInteger)xImage->bytes_per_line;

        for (NSUInteger y = 0; y < height; y++) {
            const unsigned char *row = src + y * bpl;
            unsigned char       *dst = data + y * width * 4;
            for (NSUInteger x = 0; x < width; x++) {
                const unsigned char *px = row + x * 4;
                dst[0] = px[rShift]; // R
                dst[1] = px[gShift]; // G
                dst[2] = px[bShift]; // B
                dst[3] = 0xFF;       // A
                dst += 4;
            }
        }
        usedFastPath = YES;
    }

    if (!usedFastPath) {
        // Fallback: XGetPixel() handles any depth, format, and byte order.
        NSLog(@"GrabImageProcessor: using XGetPixel fallback "
              @"(format=%d bpp=%d byte_order=%d).",
              xImage->format, xImage->bits_per_pixel, xImage->byte_order);
        for (NSUInteger y = 0; y < height; y++) {
            for (NSUInteger x = 0; x < width; x++) {
                unsigned long pixel = XGetPixel(xImage, (int)x, (int)y);
                NSUInteger idx = (y * width + x) * 4;
                data[idx + 0] = (unsigned char)((pixel & xImage->red_mask)   >> 16);
                data[idx + 1] = (unsigned char)((pixel & xImage->green_mask) >>  8);
                data[idx + 2] = (unsigned char)( pixel & xImage->blue_mask);
                data[idx + 3] = 0xFF;
            }
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

    // Guard: zero-size window — nothing to capture.
    if (w == 0 || h == 0) {
        NSLog(@"GrabImageProcessor: captureWindow skipped — window has zero size (%u×%u).", w, h);
        return nil;
    }

    // ── Raise window to top, capture, restore Z-order ────────────────────────
    //
    // Without an active compositor there is no off-screen backing store to
    // read: XCompositeNameWindowPixmap returns None and a direct XGetImage
    // reads whatever pixels are visible on-screen, including the contents of
    // any overlapping windows.
    //
    // The reliable approach is to temporarily raise the target window to the
    // top of the stacking order so it is fully exposed, capture, then restore
    // the original Z-order precisely.
    //
    // Strategy:
    //   1. Record the sibling immediately above `window` in the stacking order
    //      using XQueryTree so we can restack precisely afterward.
    //   2. XRaiseWindow — brings `window` to the front.
    //   3. XSync + usleep(50 ms) — lets the server flush exposure events and
    //      the window repaint the newly exposed area.
    //   4. XGetImage — reads the now-fully-visible window pixels.
    //   5. XConfigureWindow CWSibling+Below — inserts `window` back just below
    //      its former above-sibling, exactly restoring the original Z-order.
    //
    // The user will see a brief flash (< 150 ms). This is unavoidable in
    // bare X11 — the same technique is used by xwd(1) and ImageMagick import(1).

    // Step 1: find the sibling immediately above `window` (bottom-to-top order).
    Window aboveSibling = None;
    {
        Window root_ret, parent_ret;
        Window *children  = NULL;
        unsigned int nchildren = 0;
        if (XQueryTree(display, DefaultRootWindow(display),
                       &root_ret, &parent_ret, &children, &nchildren) && children) {
            for (unsigned int i = 0; i < nchildren; i++) {
                if (children[i] == window && i + 1 < nchildren) {
                    aboveSibling = children[i + 1];
                    break;
                }
            }
            XFree(children);
        }
    }

    // Step 2: raise the window to the top of the stack.
    XRaiseWindow(display, window);

    // Step 3: flush and wait for the server to process exposure events.
    XSync(display, False);
    usleep(50000); // 50 ms — enough for one repaint cycle on any hardware

    // Step 4: capture the fully-exposed window.
    NSImage *image = nil;
    {
        XImage *xImg = XGetImage(display, window, 0, 0, w, h, AllPlanes, ZPixmap);
        if (xImg) {
            NSBitmapImageRep *rep = [self _bitmapRepFromXImage:xImg width:w height:h];
            XDestroyImage(xImg);
            if (rep) {
                image = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
                [image addRepresentation:rep];
            }
        } else {
            NSLog(@"GrabImageProcessor: XGetImage failed for window 0x%lx.", window);
        }
    }

    // Step 5: restore the original Z-order.
    if (aboveSibling != None) {
        XWindowChanges wc;
        memset(&wc, 0, sizeof(wc));
        wc.sibling    = aboveSibling;
        wc.stack_mode = Below;
        XConfigureWindow(display, window, CWSibling | CWStackMode, &wc);
        XFlush(display);
    }

    return image;
}

@end
