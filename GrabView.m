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
#import <GrabView.h>

@implementation GrabView : NSView

- (id) initWithFrame: (NSRect)rect
{
  [super initWithFrame: rect];
  return self;
}

- (BOOL) acceptsFirstMouse: (NSEvent *)anEvent
{
  return YES;
}

- (void) mouseDown: (NSEvent *)event
{
 /* switch ([event]) {
    case captureScreen : {
      grabWork = [[GrabWork alloc] init];
      [grabWork captureScreen];
      break;
    }
    default:
      break;
  }
*/

  [self setImage:[NSImage imageNamed:[NSString
                    stringWithFormat:@"CameraWatchFlash.tiff"]]];
  NSLog(@"MouseDown");
}

- (void) drawRect: (NSRect)rect
{
  [[NSImage imageNamed:@"common_Tile"] compositeToPoint:NSMakePoint(0,0)
                                              operation:NSCompositeSourceOver];
  [_buttonImage compositeToPoint:NSMakePoint(0,0)
                       operation:NSCompositeSourceOver];
  
  [_appImage compositeToPoint:NSMakePoint(8,8)
                    operation:NSCompositeSourceOver];
  _appImage = [[NSImage imageNamed:@"Grab.App.tiff"] copy];
  NSLog(@"drawRect");
  [super drawRect:rect];
}

- (void) setImage: (NSImage *)image
{
  if (_buttonImage != nil) {
    [_buttonImage release];
  }
  _appImage = [[NSImage imageNamed:@" "] copy];
  _buttonImage = [image copy];
  [self setNeedsDisplay:YES];
}

- (void) dealloc
{
  [_appImage release];
  [_buttonImage release];
  [super dealloc];
}

@end
