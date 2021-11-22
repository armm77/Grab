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

/* LSBFirst: BGRA -> RGBA */
static void
convertrow_lsb(unsigned char *drow, unsigned char *srow, XImage *image) {
	int sx, dx;

	for(sx = 0, dx = 0; dx < image->bytes_per_line; sx += 4) {
		drow[dx++] = srow[sx + 2]; /* B -> R */
		drow[dx++] = srow[sx + 1]; /* G -> G */
		drow[dx++] = srow[sx];     /* R -> B */
		if(image->depth == 32)
			drow[dx++] = srow[sx + 3]; /* A -> A */
		else
			drow[dx++] = 255;
	}
}

/* MSBFirst: ARGB -> RGBA */
static void
convertrow_msb(unsigned char *drow, unsigned char *srow, XImage *image) {
	int sx, dx;

	for(sx = 0, dx = 0; dx < image->bytes_per_line; sx += 4) {
		drow[dx++] = srow[sx + 1]; /* G -> R */
		drow[dx++] = srow[sx + 2]; /* B -> G */
		drow[dx++] = srow[sx + 3]; /* A -> B */
		if(image->depth == 32)
			drow[dx++] = srow[sx]; /* R -> A */
		else
			drow[dx++] = 255;
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
  
  FILE *fp;
  fp = fopen("test.png", "w");
  if (fp == NULL) {
     	NSLog(@"Cannot open file.\n");
 	    XDestroyImage(image); 
  } else {
    NSLog(@"Capture Screen");
  }
  
	png_structp png_struct_p;
	png_infop png_info_p;
	void (*convert)(unsigned char *, unsigned char *, XImage *);
	unsigned char *drow = NULL, *srow;
	int h;

	png_struct_p = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL,
	                                       NULL);
	png_info_p = png_create_info_struct(png_struct_p);

	png_init_io(png_struct_p, fp);
	
	png_set_IHDR(png_struct_p, png_info_p, image->width, image->height, 8,
	             PNG_COLOR_TYPE_RGB_ALPHA, PNG_INTERLACE_NONE,
	             PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);
	             
	png_write_info(png_struct_p, png_info_p);

	srow = (unsigned char *)image->data;
	drow = calloc(1, image->width * 4);

	if(image->byte_order == LSBFirst)
		convert = convertrow_lsb;
	else
		convert = convertrow_msb;

	for(h = 0; h < image->height; h++) {
		 convert(drow, srow, image);
		 srow += image->bytes_per_line;
		 png_write_row(png_struct_p, drow);
	}

	png_write_end(png_struct_p, NULL);

	free(drow);
	png_free_data(png_struct_p, png_info_p, PNG_FREE_ALL, -1);
	png_destroy_write_struct(&png_struct_p, NULL);
  fclose(fp);

  XFree(image);
}

@end
