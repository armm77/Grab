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
#import <X11/Xlib.h>
#import <X11/Xutil.h>
#import <AppKit/AppKit.h>

@implementation GrabDraw

+ (NSImage *)captureWindowWithID:(Window)window display:(Display *)display {
    XWindowAttributes gwa;
    XGetWindowAttributes(display, window, &gwa);

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

    XDestroyImage(image);
    NSImage *nsImage = [[NSImage alloc] init];
    [nsImage addRepresentation:imageRep];
    return nsImage;
}

+ (NSImage *)captureScreenRect:(NSRect)rect display:(Display *)display {
    Window root = DefaultRootWindow(display);
    XImage *image = XGetImage(display, root, (int)rect.origin.x, (int)rect.origin.y, (unsigned int)rect.size.width, (unsigned int)rect.size.height, AllPlanes, ZPixmap);
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
                                  bytesPerRow:4 * (int)rect.size.width
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

    XDestroyImage(image);
    NSImage *nsImage = [[NSImage alloc] init];
    [nsImage addRepresentation:imageRep];
    return nsImage;
}

@end

