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

@interface GrabController : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSButton *appIconButton;
@property (nonatomic, strong) NSImage *backgroundImage;
@property (nonatomic, strong) NSImage *cameraEyeFlashImage;
@property (nonatomic, strong) NSImage *cameraNormalImage;
@property (nonatomic, strong) NSImage *piePiecesImage;
@property (nonatomic, strong) NSImage *cameraWatchImage;
@property (nonatomic, strong) NSImage *cameraWatchFlashImage;
@property (nonatomic, strong) NSImage *capturedImage;
@property (nonatomic, strong) NSArray<NSImage *> *cameraEyeImages;

@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) int currentFrame;
@property (nonatomic, assign) int currentImageIndex;

@property (nonatomic, assign) IBOutlet NSMenuItem *audioMenuItem;
@property (nonatomic, strong) NSPanel *appIconMenuItem;
@property (nonatomic, strong) NSPanel *appIconPanel;

+ (instancetype)sharedController;
- (IBAction)toggleAudio:(id)sender;
- (void)loadAudioStateFromPlist;
- (void)saveAudioStateToPlist;
- (void)updateMenuItemTitle;
- (BOOL)isSoundEnabled;

- (void)startTimer:(id)sender;
- (void)appIconWindow:(id)sender;
- (void)appIconFullScreen:(id)sender;
- (void)appIconTimeScreen:(id)sender;
- (void)captureScreenSection:(id)sender;

- (void)showHelpPanel:(id)sender;
- (void)showInfoPanel:(id)sender;
- (void)showCursorPanel:(id)sender;
- (void)showInspectorPanel:(id)sender;

@end
