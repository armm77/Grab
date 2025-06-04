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
#import "DraggableImageView.h"

@implementation GrabDraw

+ (void)playSoundWithName:(NSString *)soundName {
    BOOL soundEnabled = [[GrabController sharedController] isSoundEnabled];

    if (soundEnabled) {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:soundName ofType:@"wav"];
        NSSound *clickSound = [[NSSound alloc] initWithContentsOfFile:soundFilePath byReference:NO];
        [clickSound play];
        [NSThread sleepForTimeInterval:clickSound.duration];
    }
}

+ (NSBitmapImageRep *)bitmapImageRepFromXImage:(XImage *)image width:(NSUInteger)width height:(NSUInteger)height {
    if (!image) {
        NSLog(NSLocalizedString(@"Image data is nil.", @"Error message when XImage is nil"));
        return nil;
    }
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]
                                  initWithBitmapDataPlanes:nil
                                                pixelsWide:width
                                                pixelsHigh:height
                                             bitsPerSample:8
                                           samplesPerPixel:4
                                                  hasAlpha:YES
                                                  isPlanar:NO
                                            colorSpaceName:NSDeviceRGBColorSpace
                                               bytesPerRow:4 * width
                                              bitsPerPixel:32];

    unsigned char *data = [imageRep bitmapData];
    for (NSUInteger y = 0; y < (NSUInteger)height; y++) {
        for (NSUInteger x = 0; x < (NSUInteger)width; x++) {
            unsigned long pixel = XGetPixel(image, x, y);
            NSUInteger index = (y * (NSUInteger)width + x) * 4;
            data[index + 0] = (pixel & 0xFF0000) >> 16; // Red
            data[index + 1] = (pixel & 0x00FF00) >> 8;  // Green
            data[index + 2] = (pixel & 0x0000FF);       // Blue
            data[index + 3] = 0xFF;                     // Alpha
        }
    }
    return imageRep;
}

/// Helper method for saving an image to disk.
/// Returns YES if the save was successful, NO if there was an error or the user canceled.
+ (BOOL)saveImageToDisk:(NSImage *)image
{
    if (!image) {
        NSLog(NSLocalizedString(@"No image to save.", @"Log: save with no image"));
        return NO;
    }

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"png", @"tiff", @"jpg"]];
    [savePanel setNameFieldStringValue:@"CapturedImage"];
    [savePanel setMessage:NSLocalizedString(@"Choose a location to save the image.", @"Save panel message")];

    NSInteger result = [savePanel runModal];
    if (result == NSModalResponseOK) {
        NSURL *fileURL = [savePanel URL];
        return [self saveImage:image toURL:fileURL];
    }
    return NO;
}

+ (BOOL)saveImage:(NSImage *)image toURL:(NSURL *)fileURL
{
    if (!image || !fileURL) return NO;
    NSString *ext = [[fileURL pathExtension] lowercaseString];
    NSData *imageData = [self imageDataFromImage:image withExtension:ext];
    NSError *error = nil;
    BOOL success = [imageData writeToURL:fileURL options:NSDataWritingAtomic error:&error];
    if (!success) {
        NSLog(NSLocalizedString(@"Failed to save image: %@", @"Log: save failed"), error.localizedDescription);
    }
    return success;
}

+ (NSData *)imageDataFromImage:(NSImage *)image withExtension:(NSString *)ext
{
    NSData *imageData = [image TIFFRepresentation];
    if ([ext isEqualToString:@"png"]) {
        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:imageData];
        return [imageRep representationUsingType:NSPNGFileType properties:@{}];
    } else if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]) {
        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:imageData];
        return [imageRep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionFactor: @0.9}];
    }
    return imageData;
}

// Helper method to create a window
+ (NSWindow *)createWindowWithRect:(NSRect)rect screenFrame:(NSRect)screenFrame {
    NSRect imageRect;
    NSWindow *window;
    NSUInteger rectWidth = rect.size.width / 2;
    NSUInteger rectHeight = rect.size.height / 2;
    NSSize maxSize = NSMakeSize(rect.size.width + 21, rect.size.height + 51);

    if (NSEqualSizes(rect.size, screenFrame.size)) {
        CGFloat windowX = (screenFrame.size.width / 2.0) - (((CGFloat)rectWidth) / 2.0);
        CGFloat windowY = (screenFrame.size.height / 2.0) - (((CGFloat)rectHeight) / 2.0);
        imageRect = NSMakeRect(windowX, windowY, rect.size.width / 2.0 , rect.size.height / 2.0);
    } else {
        CGFloat windowX = (screenFrame.size.width - rect.size.width) / 2;
        CGFloat windowY = (screenFrame.size.height - rect.size.height) / 2;
        imageRect = NSMakeRect(windowX, windowY, rect.size.width + 20, rect.size.height + 20);
    }

    window = [[NSWindow alloc] initWithContentRect:imageRect
                                         styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskMiniaturizable |
                                                    NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
    [window setTitle:NSLocalizedString(@"Untitled.png", @"Default window title for new image")];
    [window setMaxSize:maxSize];
    [window setReleasedWhenClosed:NO];
    return window;
}

// Helper method to set up image view and scroll view
+ (void)setupImageViewInWindow:(NSWindow *)window withImage:(NSImage *)nsImage rect:(NSRect)rect screenFrame:(NSRect)screenFrame {
    NSRect frame = [window frame];
    NSView *imageView;
    if (NSEqualSizes(rect.size, screenFrame.size)) {
        imageView = [[DraggableImageView alloc] initWithFrame:NSMakeRect(0, 0, rect.size.width, rect.size.height)];
    } else {
        imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, rect.size.width, rect.size.height)];
    }
    [(id)imageView setImage:nsImage];
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
    [scrollView setDocumentView:imageView];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    [window setContentView:scrollView];
    [window makeKeyAndOrderFront:nil];
}

// Method to capture window
+ (NSImage *)captureWindowWithID:(Window)window display:(Display *)display {
    XWindowAttributes gwa;
    XGetWindowAttributes(display, window, &gwa);
    XRaiseWindow(display, window);
    XFlush(display);
    XCompositeRedirectWindow(display, window, CompositeRedirectAutomatic);

    XImage *image = XGetImage(display, window, 0, 0, gwa.width, gwa.height, AllPlanes, ZPixmap);
    NSBitmapImageRep *imageRep = [self bitmapImageRepFromXImage:image width:gwa.width height:gwa.height];

    if (!imageRep) return nil;

    NSImage *finalImage = [[NSImage alloc] initWithSize:NSMakeSize(gwa.width, gwa.height)];
    [finalImage addRepresentation:imageRep];

    [self playSoundWithName:@"CloseShutter"];
    NSRect windowRect = NSMakeRect(0, 0, gwa.width, gwa.height);
    [self showImageInWindow:finalImage rect:windowRect screenFrame:[NSScreen mainScreen].frame];
    return finalImage;
}

// Method to capture screen rect
+ (NSImage *)captureScreenRect:(NSRect)rect display:(Display *)display rootWindow:(Window)rootWindow {

    XImage *image = XGetImage(display, rootWindow, (int)rect.origin.x, (int)rect.origin.y,
                             (unsigned int)rect.size.width, (unsigned int)rect.size.height, AllPlanes, ZPixmap);

    NSBitmapImageRep *imageRep = [self bitmapImageRepFromXImage:image
                                                          width:(NSUInteger)rect.size.width
                                                         height:(NSUInteger)rect.size.height];

    if (!imageRep) return nil;

    NSImage *finalImage = [[NSImage alloc] initWithSize:rect.size];
    [finalImage addRepresentation:imageRep];

    [self playSoundWithName:@"CloseShutter"];
    NSRect screenRect = NSMakeRect(0, 0, rect.size.width, rect.size.height);
    [self showImageInWindow:finalImage rect:screenRect screenFrame:[NSScreen mainScreen].frame];
    return finalImage;
}

+ (void)showImageInWindow:(NSImage *)image rect:(NSRect)rect screenFrame:(NSRect)screenFrame
{
    NSWindow *nsWindow = [self createWindowWithRect:rect screenFrame:screenFrame];
    [self setupImageViewInWindow:nsWindow withImage:image rect:rect screenFrame:screenFrame];
}

@end

