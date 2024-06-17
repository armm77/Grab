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
#import <GrabWork.h>

@implementation GrabWork : NSObject

// Function to convert pixel data from BGRA to RGBA
void convertBGRAtoRGBA(unsigned char *dest, unsigned char *src, int width, int height) {
    int bytesPerPixel = 4; // Since we're dealing with BGRA to RGBA
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int pixelIndex = (y * width + x) * bytesPerPixel;

            // Extract BGRA components from the source
            unsigned char blue = src[pixelIndex];
            unsigned char green = src[pixelIndex + 1];
            unsigned char red = src[pixelIndex + 2];
            unsigned char alpha = src[pixelIndex + 3];

            // Store RGBA components in the destination
            dest[pixelIndex] = red;
            dest[pixelIndex + 1] = green;
            dest[pixelIndex + 2] = blue;
            dest[pixelIndex + 3] = alpha;
        }
    }
}

- (id) init 
{
  xDisplay = XOpenDisplay(NULL);
  if (!xDisplay) {
     NSLog(@"Can't open Xorg display."
           @" Please setup DISPLAY environment variable.");
     return nil;
  }

  xRootWindow = RootWindow(xDisplay, DefaultScreen(xDisplay));
  if (!xRootWindow) {
     NSLog(@"Can't open Xorg root window."
           @" Please setup DISPLAY environment variable.");
     return nil;
  }

  return self;
}

- (void) dealloc
{
  [_timer invalidate];
  [_timer release];

  XCloseDisplay(xDisplay);

  [super dealloc];
}

-(void) updateCountDownTime
{
  if (totalSeconds != 1) {
     totalSeconds -= 1;
     NSLog (@"Timer:%02d",totalSeconds);
  } else {
     [self captureScreen];
     [_timer invalidate];
  }
}

- (void) captureSelection
{
  NSLog(@"To be implemented.");
}

- (void) captureWindow
{
  NSLog(@"To be implemented.");
  Window rwindow, cwindow;
  XWindowAttributes gwa;
  int root_x, root_y, win_x, win_y;
  unsigned int  mask;

  XQueryPointer(xDisplay, xRootWindow, &rwindow, &cwindow, \
                &root_x, &root_y, &win_x, &win_y, &mask); 
  XGetWindowAttributes(xDisplay, cwindow, &gwa);
  XImage *image = XGetImage(xDisplay, cwindow, 0, 0, \
                  gwa.width, gwa.height, AllPlanes, ZPixmap);
  NSLog(@"To be implemented.");
  [self saveAsImage:image];
}

- (void) captureScreen
{

  XWindowAttributes gwa;
  XGetWindowAttributes(xDisplay, xRootWindow, &gwa);
  XImage *image = XGetImage(xDisplay, xRootWindow, 0, 0, \
                  gwa.width, gwa.height, AllPlanes, ZPixmap);
    
  [self saveAsImage:image];
}

- (void) captureTimedScreen
{
  totalSeconds = 5;
  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
  
  selector:@selector(updateCountDownTime) userInfo:nil repeats:YES];
}

- (void) saveAsImage: (XImage *)image
{
  // Create buffers for the source (BGRA) and destination (RGBA) data
  int bytesPerPixel = 4; // BGRA to RGBA means 4 bytes per pixel
  unsigned char *rgbaData = (unsigned char *)malloc(image->width * image->height * bytesPerPixel);

  // Convert BGRA to RGBA
  convertBGRAtoRGBA(rgbaData, (unsigned char *)image->data, image->width, image->height);

  // Create an NSBitmapImageRep from the converted RGBA data                
  NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
                                initWithBitmapDataPlanes: &rgbaData
                                              pixelsWide: image->width
                                              pixelsHigh: image->height
                                           bitsPerSample: 8
                                         samplesPerPixel: 4
                                                hasAlpha: YES
                                                isPlanar: NO
                                          colorSpaceName: NSDeviceRGBColorSpace 
                                            bitmapFormat: 0
                                             bytesPerRow: image->width * bytesPerPixel 
                                            bitsPerPixel: 32];
                                          
  // Create an NSImage from the bitmap representation
  NSImage *screenImage = [[NSImage alloc] initWithSize: NSMakeSize(image->width, image->height)];
  [screenImage addRepresentation:bitmapRep];

  // Save the image as a TIFF 
  //NSData *imageData = [bitmapRep TIFFRepresentation];
  //[imageData writeToFile:@"capture_RGBA.tiff" atomically:YES]; 
  
  // Save the image as a PNG
  NSData *imageDataPNG = [bitmapRep representationUsingType: NSPNGFileType properties:nil];
  [imageDataPNG writeToFile:@"capture_RGBA.png" atomically:YES];
}

@end
