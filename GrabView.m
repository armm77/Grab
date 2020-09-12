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

#import "GrabView.h"

@implementation GrabView : NSView

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent
{
  return YES;
}

- (void)mouseDown:(NSEvent *)event
{
  NSLog(@"mouseDown:");
  if ([event clickCount] >= 2)
    {
      [NSApp activateIgnoringOtherApps:YES];
    }
  else
    {
      [self setImage:[NSImage imageNamed:@"WaitCursor.tiff"]];
    }
}

- (id)initWithFrame:(NSRect)frameRect
{
  [super initWithFrame:frameRect];

  _buttonImage = [[NSImage imageNamed:@"CameraWatch.tiff"] copy];

  return self;
}

- (void)drawRect:(NSRect)rect
{
  [[NSImage imageNamed:@"common_Tile"] compositeToPoint:NSMakePoint(0, 0)
                                              operation:NSCompositeSourceOver];
  [_buttonImage
    compositeToPoint:NSMakePoint((64 - [_buttonImage size].width)/2, 20)
           operation:NSCompositeSourceOver];

  [super drawRect:rect];
}

- (void)dealloc
{
  [_buttonImage release];
  [super dealloc];
}

- (void)setImage:(NSImage *)image
{
  if (_buttonImage != nil) {
    [_buttonImage release];
  }
  _buttonImage = [image copy];
  [_buttonImage setScalesWhenResized:NO];

  [self setNeedsDisplay:YES];
}

@end
