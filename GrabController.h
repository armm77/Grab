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
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface GrabController : NSObject <NSApplicationDelegate> {
  id  infoPanel;
  id  helpPanel;
  id  cursorPanel;
  id  inspectorPanel;
  id  helpText;

  IBOutlet NSTextField* verField;
  IBOutlet NSTextField* copyrightField;
  NSDictionary *infoDict;

  NSPanel *appIconPanel;
  NSButton *appIconButton;
  NSArray<NSImage *> *cameraEyeImages;
  NSImage *backgroundImage;
  NSImage *cameraEyeFlashImage;
  NSImage *cameraNormalImage;
  NSImage *piePiecesImage;
  NSImage *cameraWatchImage;
  NSImage *cameraWatchFlashImage;
  NSImage *capturedImage;
  NSTimer *animationTimer;
  NSTimer *timer;
  int currentFrame;
  int currentImageIndex;
}

- (IBAction)copyImageToClipboard:(id)sender;
- (void)setCapturedImage:(NSImage *)image;

- (void) startTimer:(id)sender;
- (void) appIconWindow:(id)sender;
- (void) appIconFullScreen:(id)sender;
- (void) appIconTimeScreen:(id)sender;
- (void) captureScreenSection:(id)sender;

- (void) showHelpPanel:(id)sender;
- (void) showInfoPanel:(id)sender;
- (void) showCursorPanel:(id)sender;
- (void) showInspectorPanel:(id)sender;

@end
