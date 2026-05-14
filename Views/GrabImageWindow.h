/*
   Project: Grab
   Module:  GrabImageWindow

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GrabImageWindow
 *
 * NSWindow subclass that intercepts the close button and presents a
 * native NextSpace NXTRunAlertPanel (Save / Don't Save / Cancel)
 * before closing the captured image window.
 */
@interface GrabImageWindow : NSWindow

/// The captured image held by this window. Used by the Save action.
@property (nonatomic, strong) NSImage *capturedImage;

@end

NS_ASSUME_NONNULL_END
