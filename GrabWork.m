/*
   Project: Grab
   Author: Andres Morales
   Created: 2020-07-04 16:14:10 +0300 by armm77

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
#import <SystemKit/OSEScreen.h>
#import <GrabWork.h>

@implementation GrabWork : NSObject

/* LSBFirst: BGRA -> RGBA */
static void
convertrow_lsb(unsigned char *drow, unsigned char *srow, XImage *img) {
	int sx, dx;

	for(sx = 0, dx = 0; dx < img->bytes_per_line; sx += 4) {
		drow[dx++] = srow[sx + 2]; /* B -> R */
		drow[dx++] = srow[sx + 1]; /* G -> G */
		drow[dx++] = srow[sx];     /* R -> B */
		if(img->depth == 32)
			drow[dx++] = srow[sx + 3]; /* A -> A */
		else
			drow[dx++] = 255;
	}
}

/* MSBFirst: ARGB -> RGBA */
static void
convertrow_msb(unsigned char *drow, unsigned char *srow, XImage *img) {
	int sx, dx;

	for(sx = 0, dx = 0; dx < img->bytes_per_line; sx += 4) {
		drow[dx++] = srow[sx + 1]; /* G -> R */
		drow[dx++] = srow[sx + 2]; /* B -> G */
		drow[dx++] = srow[sx + 3]; /* A -> B */
		if(img->depth == 32)
			drow[dx++] = srow[sx]; /* R -> A */
		else
			drow[dx++] = 255;
	}
}

- (void) dealloc
{
  [_timer invalidate];
  [_timer release];
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
  //NSApp = [NSApplication sharedApplication];
  //[NSApp setApplicationIconImage:[NSImage imageNamed:@"CameraNormal.tiff"]];

  Display *display = XOpenDisplay(NULL);
  Window window = DefaultRootWindow(display);
  Cursor cursor = XCreateFontCursor(display, XC_crosshair);
  XEvent event;
  GC gc;
  XGCValues gcval;
  int pressed = 0, done = 0, finish = 0;
  int po_x = 0, po_y = 0, width = 0, height = 0, ry = 0, rx = 0;
  int fd = ConnectionNumber(display);
  fd_set fds;

  XGrabPointer(display, window, False, ButtonMotionMask | \
              ButtonPressMask | ButtonReleaseMask, \
              GrabModeAsync, GrabModeAsync, \
              window, cursor, CurrentTime);

  gcval.function = GXxor;
  gcval.foreground = XWhitePixel(display, DefaultScreen(display));
  gcval.background = XBlackPixel(display, DefaultScreen(display));
  gcval.plane_mask = gcval.background ^ gcval.foreground;
  gcval.subwindow_mode = IncludeInferiors;
  gcval.line_width = 1;

  gc = XCreateGC(display, window, GCFunction | GCForeground | \
                GCBackground | GCSubwindowMode | GCLineWidth, &gcval);

  while (!done && !finish) {
    FD_ZERO(&fds);
    FD_SET(fd, &fds);
    select(fd + 1, &fds, NULL, NULL, NULL);
    while (XPending(display)) {
      XNextEvent(display, &event);
      switch (event.type) {
        case ButtonPress:
            rx = event.xbutton.x;
            ry = event.xbutton.y;
            pressed = 1;
          break;
        case ButtonRelease:
            done = 1;
          break;
        case MotionNotify:
            if (pressed) {
              if (width) {
                XDrawRectangle(display, window, gc, po_x, po_y, \
                              width, height);
                NSLog(@"1.XDrawRectangle");
              } else {
                XChangeActivePointerGrab(display, ButtonMotionMask | \
                                        ButtonReleaseMask, cursor, \
                                        CurrentTime);
                NSLog(@"2.XChangeActivePointerGrab");
                }
                po_x = rx;
                po_y = ry;
                width = event.xmotion.x - po_x;
                height = event.xmotion.y - po_y;

                if (width == 0) ++width;
                if (height == 0) ++height;

                if (width < 0) {
                  po_x += width;
                  width = 0 - width;
                }
                if (height < 0) {
                  po_y += height;
                  height = 0 - height;
                }

                XDrawRectangle(display, window, gc, po_x, po_y,\
                              width, height);
                NSLog(@"3.XDrawRectangle");
                XFlush(display);
              }
          break;
        case KeyPress:
          fprintf(stderr, "Key was pressed, aborting shot\n");
          done = 2;
          break;
        case KeyRelease:
          /* ignore */
          break;
        default:
          break;
      }
    }
  }

  if (width != 0 && !done) {
		XDrawRectangle(display, window, gc, po_x, po_y, width, height);
		XFlush(display);
	}

  XImage *image = XGetImage(display, window, po_x, po_y,\
                  width, height, AllPlanes, ZPixmap);

  [self saveAsImage:image];

  XUngrabPointer(display, CurrentTime);
  XUngrabServer(display);
	XFreeCursor(display, cursor);
	XFreeGC(display, gc);
	XSync(display, True);
  XCloseDisplay(display);
}

- (void) captureWindow
{
  Display *display = XOpenDisplay(NULL);
  Window window = DefaultRootWindow(display);
  Cursor cursor = XCreateFontCursor(display, XC_hand2);
  XEvent ev;
  int rev = 0;

  //XWindowAttributes gwa;

 /* if (XGrabPointer(display, window, False, ButtonPressMask | \
               ButtonReleaseMask, GrabModeAsync, GrabModeAsync, \
               window, cursor, CurrentTime) != GrabSuccess) {
                 NSLog(@"XGrabPointer: NULL\n");
  }*/

/*	while (ev.type != ButtonPress) {
		XNextEvent(display, &ev);
		window = ev.xbutton.subwindow;
    NSLog(@"1.Window: %lu\n", window);
	}
/*
	while (rev == 0) {
    XGetInputFocus(display, &window, &rev);
    NSLog(@"XGetInputFocus: %d\n", XGetInputFocus);
    NSLog(@"display: %d\n", display);
    NSLog(@"window: %lu\n", window);
    NSLog(@"rev: %d\n", rev);
	}
*/
XGetInputFocus(display, &window, &rev);

// NSLog(@"XGetInputFocus: %d\n", XGetInputFocus);
/*
  XEvent ev = {0};
	while (ev.type != ButtonPress) {
		XNextEvent(display, &ev);
		window = ev.xbutton.subwindow;
    NSLog(@"Window: %lu\n", window);
	}
*/
  //XMapRaised(display, window);
 // XGetWindowAttributes(display, window, &gwa);

  //XImage *image = XGetImage(display, window, 0, 0, \
  //                gwa.width, gwa.height, AllPlanes, ZPixmap);

  //[self saveAsImage:image];
  
  NSLog(@"XGetInputFocus: %d\n", XGetInputFocus);
  NSLog(@"display: %d\n", display);
  NSLog(@"window: %lu\n", window);
  NSLog(@"rev: %d\n", rev);
  NSLog(@"==Salida de Captura Windows==");

  XUngrabPointer(display, CurrentTime);
  XFreeCursor(display, cursor);
	XSync(display, True);
  XCloseDisplay(display);
}

- (void) captureScreen
{
  Display *display = XOpenDisplay(NULL);
  Window window = DefaultRootWindow(display);
  XWindowAttributes gwa;

  XGetWindowAttributes(display, window, &gwa);

  XImage *image = XGetImage(display, window, 0, 0, \
                  gwa.width, gwa.height, AllPlanes, ZPixmap);

  [self saveAsImage:image];

  XCloseDisplay(display);
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

//  NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData:rgb];
// Create an NSImage and add the bitmap rep to it...
//NSImage *image2 = [[NSImage alloc] init];
//[image2 addRepresentation:image];
//[image2 writeToFile:@"/Users/armm77/Image@2x.png" atomically:NO];
//[bitmapRep release];
//bitmapRep = nil;

  XFree(image);
}

@end
