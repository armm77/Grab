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
#import <AppKit/AppKit.h>
#import <SystemKit/OSEScreen.h>
#import <GrabView.h>
#include <sys/select.h>
#include <stdio.h>
#include <stdlib.h>
#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/cursorfont.h>
#include <png.h>

@interface GrabWork : NSObject
{
  OSEDisplay  *oseDisplay;
  OSEScreen   *oseSreen;
  GrabView    *grabView;
  NSString    *_imagePath;
  NSCursor    *_cursor;
  NSTimer     *_timer;

  int totalSeconds;
}

- (void) saveAsImage: (XImage *)image;
- (void) updateCountDownTime;

- (void) captureSelection;
- (void) captureWindow;
- (void) captureScreen;
- (void) captureTimedScreen;

@end
