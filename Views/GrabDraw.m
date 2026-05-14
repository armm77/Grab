/*
   Project: Grab
   Module:  GrabDraw

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabDraw.h"
#import "DraggableImageView.h"
#import "GrabImageWindow.h"
#import <DesktopKit/NXTSavePanel.h>
#import <math.h>

// Under ARC with setReleasedWhenClosed:NO, NSWindow has no implicit owner after
// -makeKeyAndOrderFront: returns. We keep every result window alive by holding
// a strong reference here; the window removes itself via GrabDraw_releaseWindow
// when the user closes it.
static NSMutableArray *_openWindows = nil;

static void _retainResultWindow(NSWindow *w) {
    NSCAssert([NSThread isMainThread],
              @"_retainResultWindow must be called on the main thread.");
    if (!_openWindows) _openWindows = [NSMutableArray array];
    [_openWindows addObject:w];
}

void GrabDraw_releaseWindow(NSWindow *w) {
    NSCAssert([NSThread isMainThread],
              @"GrabDraw_releaseWindow must be called on the main thread.");
    [_openWindows removeObjectIdenticalTo:w];
}

@interface GrabDraw ()
+ (NSData *)_imageDataFromImage:(NSImage *)image withExtension:(NSString *)ext;
+ (NSRect)_halfSizeRectForImageSize:(NSSize)size screenFrame:(NSRect)screen;
+ (NSRect)_centeredRectForImageSize:(NSSize)size screenFrame:(NSRect)screen;
+ (NSWindow *)_makeWindowWithFrame:(NSRect)frame imageSize:(NSSize)imageSize;
+ (void)_installImage:(NSImage *)image
             inWindow:(NSWindow *)window
            imageSize:(NSSize)imageSize
         isFullScreen:(BOOL)isFullScreen;
@end

@implementation GrabDraw

#pragma mark - Public

+ (void)showImage:(NSImage *)image {
    if (!image) {
        NSLog(@"GrabDraw: showImage called with nil image.");
        return;
    }

    NSRect screenFrame = [[NSScreen mainScreen] frame];

    // Use a 1-point tolerance instead of exact equality to handle HiDPI
    // screens where backing-store scaling can introduce sub-point differences
    // between the captured image size and the reported screen size.
    BOOL isFullScreen = (fabs(image.size.width  - screenFrame.size.width)  < 1.0 &&
                         fabs(image.size.height - screenFrame.size.height) < 1.0);
    NSRect imageRect  = isFullScreen
        ? [self _halfSizeRectForImageSize:image.size screenFrame:screenFrame]
        : [self _centeredRectForImageSize:image.size screenFrame:screenFrame];

    NSWindow *window = [self _makeWindowWithFrame:imageRect imageSize:image.size];
    if ([window isKindOfClass:[GrabImageWindow class]]) {
        [(GrabImageWindow *)window setCapturedImage:image];
    }
    [self _installImage:image
               inWindow:window
              imageSize:image.size
           isFullScreen:isFullScreen];

    // Retain the window so ARC does not release it when this method returns.
    // GrabImageWindow calls GrabDraw_releaseWindow when the user closes it.
    _retainResultWindow(window);
}

+ (BOOL)saveImageToDisk:(NSImage *)image {
    if (!image) {
        NSLog(@"GrabDraw: saveImageToDisk called with nil image.");
        return NO;
    }

    NSSavePanel *panel = [NXTSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"png", @"tiff", @"jpg"]];
    [panel setNameFieldStringValue:[@"CapturedImage" stringByAppendingPathExtension:@"png"]];
    [panel setMessage:NSLocalizedString(@"Choose a location to save the image.",
                                        @"Save panel message")];

    if ([panel runModal] != NSModalResponseOK) return NO;

    NSURL *url = [panel URL];
    NSString *ext = [[url pathExtension] lowercaseString];
    NSData *data  = [self _imageDataFromImage:image withExtension:ext];
    if (!data) return NO;

    NSError *error = nil;
    BOOL ok = [data writeToURL:url options:NSDataWritingAtomic error:&error];
    if (!ok) {
        NSLog(@"GrabDraw: failed to save — %@", error.localizedDescription);
        return NO;
    }
    return YES;
}

#pragma mark - Private

+ (NSData *)_imageDataFromImage:(NSImage *)image withExtension:(NSString *)ext {
    NSData *tiffData = [image TIFFRepresentation];
    if (!tiffData) return nil;

    // GNUstep uses the legacy short enum names (NSPNGFileType, NSJPEGFileType).
    if ([ext isEqualToString:@"png"]) {
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
        return [rep representationUsingType:NSPNGFileType properties:@{}];
    }
    if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]) {
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
        return [rep representationUsingType:NSJPEGFileType
                                 properties:@{NSImageCompressionFactor: @0.9}];
    }
    return tiffData; // Default: TIFF
}

// Fix #10: include screenFrame.origin so windows are correctly positioned on
// secondary monitors where the screen origin is not (0, 0).
+ (NSRect)_halfSizeRectForImageSize:(NSSize)size screenFrame:(NSRect)screen {
    CGFloat w  = size.width  / 2.0;
    CGFloat h  = size.height / 2.0;
    CGFloat ox = screen.origin.x + (screen.size.width  - w) / 2.0;
    CGFloat oy = screen.origin.y + (screen.size.height - h) / 2.0;
    return NSMakeRect(ox, oy, w, h);
}

+ (NSRect)_centeredRectForImageSize:(NSSize)size screenFrame:(NSRect)screen {
    CGFloat w  = size.width  + 20.0;
    CGFloat h  = size.height + 20.0;
    CGFloat ox = screen.origin.x + (screen.size.width  - w) / 2.0;
    CGFloat oy = screen.origin.y + (screen.size.height - h) / 2.0;
    return NSMakeRect(ox, oy, w, h);
}

+ (NSWindow *)_makeWindowWithFrame:(NSRect)frame imageSize:(NSSize)imageSize {
    GrabImageWindow *window =
        [[GrabImageWindow alloc] initWithContentRect:frame
                                           styleMask:(NSWindowStyleMaskTitled        |
                                                      NSWindowStyleMaskMiniaturizable |
                                                      NSWindowStyleMaskClosable      |
                                                      NSWindowStyleMaskResizable)
                                             backing:NSBackingStoreBuffered
                                               defer:NO];
    [window setTitle:NSLocalizedString(@"Untitled.png", @"Default window title for new image")];
    // Must be NO under ARC: the default YES would send an extra -release on
    // close, causing a double-free. Lifetime is managed by _openWindows above.
    [window setReleasedWhenClosed:NO];
    [window setDelegate:window];
    return window;
}

+ (void)_installImage:(NSImage *)image
             inWindow:(NSWindow *)window
            imageSize:(NSSize)imageSize
         isFullScreen:(BOOL)isFullScreen {

    NSRect contentBounds = NSMakeRect(0, 0, imageSize.width, imageSize.height);
    NSView *imageView;

    if (isFullScreen) {
        DraggableImageView *dragView = [[DraggableImageView alloc] initWithFrame:contentBounds];
        [dragView setImage:image];
        imageView = dragView;
    } else {
        NSImageView *iv = [[NSImageView alloc] initWithFrame:contentBounds];
        [iv setImage:image];
        imageView = iv;
    }

    NSScrollView *scroll = [[NSScrollView alloc]
        initWithFrame:[[window contentView] bounds]];
    [scroll setDocumentView:imageView];
    [scroll setHasVerticalScroller:YES];
    [scroll setHasHorizontalScroller:YES];

    [window setContentView:scroll];
    [window makeKeyAndOrderFront:nil];
}

@end
