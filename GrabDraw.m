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
#import "GrabDraw.h"
#import "DraggableImageView.h"

@implementation GrabDraw

+ (NSBitmapImageRep *)bitmapImageRepFromXImage:(XImage *)image width:(NSUInteger)width height:(NSUInteger)height {
    if (!image) {
        NSLog(@"Image data is nil.");
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

+ (void)playSoundWithName:(NSString *)soundName {
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:soundName ofType:@"wav"];
    NSSound *clickSound = [[NSSound alloc] initWithContentsOfFile:soundFilePath byReference:YES];
    [clickSound play];
}

// Helper method to handle window close alert
+ (void)handleWindowCloseAlertForWindow:(NSWindow *)window withImageRep:(NSBitmapImageRep *)imageRep {
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification
                                                      object:window
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Close"];
        [alert setInformativeText:@"Save changes to Untitled.png?"];
        [alert addButtonWithTitle:@"Save"];
        [alert addButtonWithTitle:@"Don't Save"];
        [alert addButtonWithTitle:@"Cancel"];

        NSModalResponse response = [alert runModal];
        if (response == NSAlertFirstButtonReturn) {
            NSSavePanel *savePanel = [NSSavePanel savePanel];
            [savePanel setAllowedFileTypes:@[@"png"]];
            [savePanel setNameFieldStringValue:@"Untitled.png"];
            if ([savePanel runModal] == NSModalResponseOK) {
                NSURL *saveURL = [savePanel URL];
                NSData *imageData = [imageRep representationUsingType:NSPNGFileType properties:@{}];
                [imageData writeToURL:saveURL atomically:YES];
            }
        } else if (response == NSAlertThirdButtonReturn) {
            [window makeKeyAndOrderFront:nil];
        }
    }];
}

// Helper method to create a window
+ (NSWindow *)createWindowWithRect:(NSRect)rect screenFrame:(NSRect)screenFrame {
    NSRect imageRect;
    NSWindow *window;
    NSUInteger rectWidth = rect.size.width / 2;
    NSUInteger rectHeight = rect.size.height / 2;
    NSSize maxSize = NSMakeSize(rect.size.width + 21, rect.size.height + 51);

    if (NSEqualSizes(rect.size, screenFrame.size)) {
        CGFloat windowX = (screenFrame.size.width / 2) - (rectWidth / 2);
        CGFloat windowY = (screenFrame.size.height / 2)- (rectHeight / 2);
        imageRect = NSMakeRect(windowX, windowY, rect.size.width / 2 , rect.size.height / 2);
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
    [window setTitle:@"Untitled.png"];
    [window setMaxSize:maxSize];
    [window setReleasedWhenClosed:NO];
    return window;
}

// Helper method to set up image view and scroll view
+ (void)setupImageViewInWindow:(NSWindow *)window withImage:(NSImage *)nsImage rect:(NSRect)rect screenFrame:(NSRect)screenFrame{
    NSRect frame = [window frame];

    if (NSEqualSizes(rect.size, screenFrame.size)) {
        DraggableImageView *imageView = [[DraggableImageView alloc] initWithFrame:NSMakeRect(0, 0, rect.size.width, rect.size.height)];
        [imageView setImage:nsImage];
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
        [scrollView setDocumentView:imageView];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:YES];
        [window setContentView:scrollView];
    } else {
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, rect.size.width, rect.size.height)];
        [imageView setImage:nsImage];
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
        [scrollView setDocumentView:imageView];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:YES];
        [window setContentView:scrollView];
    }
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

    // Create and display the image viewer window
    NSWindow *nsWindow = [self createWindowWithRect:windowRect
                                        screenFrame:[NSScreen mainScreen].frame];

    [self setupImageViewInWindow:nsWindow withImage:finalImage
                                               rect:windowRect
                                        screenFrame:[NSScreen mainScreen].frame];

    // Handle window close alert
    [self handleWindowCloseAlertForWindow:nsWindow withImageRep:imageRep];

    return finalImage;
}

// Method to capture screen rect
+ (NSImage *)captureScreenRect:(NSRect)rect display:(Display *)display {
    Window root = DefaultRootWindow(display);
    XImage *image = XGetImage(display, root, (int)rect.origin.x, (int)rect.origin.y,
                             (unsigned int)rect.size.width, (unsigned int)rect.size.height, AllPlanes, ZPixmap);

    NSBitmapImageRep *imageRep = [self bitmapImageRepFromXImage:image
                                                          width:(NSUInteger)rect.size.width
                                                         height:(NSUInteger)rect.size.height];

    if (!imageRep) return nil;

    NSImage *finalImage = [[NSImage alloc] initWithSize:rect.size];
    [finalImage addRepresentation:imageRep];

    [self playSoundWithName:@"CloseShutter"];
    NSRect screenRect = NSMakeRect(0, 0, rect.size.width, rect.size.height);

    NSWindow *nsWindow = [self createWindowWithRect:rect
                                        screenFrame:[NSScreen mainScreen].frame];

    // Create and display the image viewer window
    [self setupImageViewInWindow:nsWindow withImage:finalImage
                                               rect:screenRect
                                        screenFrame:[NSScreen mainScreen].frame];

    // Handle window close alert
    [self handleWindowCloseAlertForWindow:nsWindow withImageRep:imageRep];

    return finalImage;
}

@end

