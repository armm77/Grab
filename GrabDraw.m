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

+ (NSImage *)captureWindowWithID:(Window)window display:(Display *)display {
    XWindowAttributes gwa;
    XGetWindowAttributes(display, window, &gwa);
    XRaiseWindow(display, window);
    XFlush(display);
    XCompositeRedirectWindow(display, window, CompositeRedirectAutomatic);

    XImage *image = XGetImage(display, window, 0, 0, gwa.width, gwa.height, AllPlanes, ZPixmap);
    if (!image) {
        NSLog(@"Could not get window image.");
        return nil;
    }

    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]
                                  initWithBitmapDataPlanes:nil
                                                pixelsWide:gwa.width
                                                pixelsHigh:gwa.height
                                             bitsPerSample:8
                                           samplesPerPixel:4
                                                  hasAlpha:YES
                                                  isPlanar:NO
                                            colorSpaceName:NSDeviceRGBColorSpace
                                               bytesPerRow:4 * gwa.width
                                              bitsPerPixel:32];

    unsigned char *data = [imageRep bitmapData];
    for (NSUInteger y = 0; y < (NSUInteger)gwa.height; y++) {
        for (NSUInteger x = 0; x < (NSUInteger)gwa.width; x++) {
            unsigned long pixel = XGetPixel(image, x, y);
            NSUInteger index = (y * (NSUInteger)gwa.width + x) * 4;
            data[index + 0] = (pixel & 0xFF0000) >> 16; // Red
            data[index + 1] = (pixel & 0x00FF00) >> 8;  // Green
            data[index + 2] = (pixel & 0x0000FF);       // Blue
            data[index + 3] = 0xFF;                     // Alpha
        }
    }

    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"CloseShutter" ofType:@"wav"];
    NSSound *clickSound = [[NSSound alloc] initWithContentsOfFile:soundFilePath byReference:YES];
    [clickSound play];

    NSImage *nsImage = [[NSImage alloc] initWithSize:NSMakeSize(gwa.width, gwa.height)];
    [nsImage addRepresentation:imageRep];

    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect screenFrame = [mainScreen frame];
    NSWindow *nsWindow;

    NSRect windowFrame;
    if (gwa.width == (int)screenFrame.size.width && gwa.height == (int)screenFrame.size.height) {
        CGFloat windowX = (screenFrame.size.width - 800) / 2;
        CGFloat windowY = (screenFrame.size.height - 600) / 2;
        windowFrame = NSMakeRect(windowX, windowY, 800, 600);

        nsWindow = [[NSWindow alloc] initWithContentRect:windowFrame
                                               styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskMiniaturizable | 
                                                          NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
        [nsWindow setTitle:@"Untitled.png"];
        DraggableImageView *imageView = [[DraggableImageView alloc] initWithFrame:NSMakeRect(0, 0, gwa.width, gwa.height)];
        [imageView setImage:nsImage];

        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:windowFrame];
        [scrollView setDocumentView:imageView];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:YES];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

        [nsWindow setContentView:scrollView];
        [nsWindow makeKeyAndOrderFront:nil];
    } else {
        CGFloat windowX = (screenFrame.size.width - gwa.width) / 2;
        CGFloat windowY = (screenFrame.size.height - gwa.height) / 2;
        windowFrame = NSMakeRect(windowX, windowY, gwa.width, gwa.height);

        nsWindow = [[NSWindow alloc] initWithContentRect:windowFrame
                                               styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskMiniaturizable | 
                                                          NSWindowStyleMaskClosable)
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
        [nsWindow setTitle:@"Untitled.png"];
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, gwa.width, gwa.height)];
        [imageView setImage:nsImage];
        [nsWindow setContentView:imageView];
        [nsWindow makeKeyAndOrderFront:nil];
    }
    
    [nsWindow setReleasedWhenClosed:NO];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification
                                                      object:nsWindow
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
            [nsWindow makeKeyAndOrderFront:nil];
        }
    }];

    XDestroyImage(image);
    return nsImage;
}

+ (NSImage *)captureScreenRect:(NSRect)rect display:(Display *)display {
    Window root = DefaultRootWindow(display);
    XImage *image = XGetImage(display, root, (int)rect.origin.x, (int)rect.origin.y,
                             (unsigned int)rect.size.width, (unsigned int)rect.size.height, AllPlanes, ZPixmap);
    if (!image) {
        NSLog(@"Could not get image of screen section.");
        return nil;
    }

    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]
                                  initWithBitmapDataPlanes:nil
                                                pixelsWide:(int)rect.size.width
                                                pixelsHigh:(int)rect.size.height
                                             bitsPerSample:8
                                           samplesPerPixel:4
                                                  hasAlpha:YES
                                                  isPlanar:NO
                                            colorSpaceName:NSDeviceRGBColorSpace
                                               bytesPerRow:(4 * (int)rect.size.width)
                                              bitsPerPixel:32];

    unsigned char *data = [imageRep bitmapData];
    for (NSUInteger y = 0; y < (NSUInteger)rect.size.height; y++) {
        for (NSUInteger x = 0; x < (NSUInteger)rect.size.width; x++) {
            unsigned long pixel = XGetPixel(image, x, y);
            NSUInteger index = (y * (NSUInteger)rect.size.width + x) * 4;
            data[index + 0] = (pixel & 0xFF0000) >> 16; // Red
            data[index + 1] = (pixel & 0x00FF00) >> 8;  // Green
            data[index + 2] = (pixel & 0x0000FF);       // Blue
            data[index + 3] = 0xFF;                     // Alpha
        }
    }

    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"CloseShutter" ofType:@"wav"];
    NSSound *clickSound = [[NSSound alloc] initWithContentsOfFile:soundFilePath byReference:YES];
    [clickSound play];

    NSImage *nsImage = [[NSImage alloc] initWithSize:rect.size];
    [nsImage addRepresentation:imageRep];

    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect screenFrame = [mainScreen frame];

    NSWindow *window;  

    NSRect windowFrame;
    if (NSEqualSizes(rect.size, screenFrame.size)) {
        CGFloat windowX = (screenFrame.size.width - 800) / 2;
        CGFloat windowY = (screenFrame.size.height - 600) / 2; 
        windowFrame = NSMakeRect(windowX, windowY, 800, 600);
        
        window = [[NSWindow alloc] initWithContentRect:windowFrame
                                             styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskMiniaturizable | 
						        NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
        [window setTitle:@"Untitled.png"];
	DraggableImageView *imageView = [[DraggableImageView alloc] initWithFrame:NSMakeRect(0, 0, rect.size.width, rect.size.height)];
        [imageView setImage:nsImage];

        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:windowFrame];
        [scrollView setDocumentView:imageView];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:YES];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

        [window setContentView:scrollView];
        [window makeKeyAndOrderFront:nil];
    } else {
        CGFloat windowX = (screenFrame.size.width - rect.size.width) / 2;
        CGFloat windowY = (screenFrame.size.height - rect.size.height) / 2;  
        windowFrame = NSMakeRect(windowX, windowY, rect.size.width, rect.size.height);

        window = [[NSWindow alloc] initWithContentRect:windowFrame
                                             styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskMiniaturizable | 
                                                        NSWindowStyleMaskClosable)
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
        [window setTitle:@"Untitled.png"];
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(windowX, windowY, rect.size.width, rect.size.height)];
        [imageView setImage:nsImage];
        [window setContentView:imageView];
        [window makeKeyAndOrderFront:nil];
    }
    
    [window setReleasedWhenClosed:NO];
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

    XDestroyImage(image);
    return nsImage;
}

@end

