/*
   Project: Grab
   Module:  GrabDraw

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GrabDraw
 *
 * Stateless utility class (all methods are class methods).
 *
 * Responsibilities:
 *   - Creating and configuring the result NSWindow.
 *   - Choosing between DraggableImageView (full-screen) and NSImageView.
 *   - Presenting NXTSavePanel (DesktopKit) and writing image data to disk.
 */
@interface GrabDraw : NSObject

/**
 * Creates a result window and displays image in it.
 * Must be called on the main thread.
 *
 * @param image  The NSImage to display. Must not be nil.
 */
+ (void)showImage:(NSImage *)image;

/**
 * Presents a save panel and writes image to the chosen location.
 *
 * @param image  The NSImage to save. If nil, logs and returns NO.
 * @return       YES on success, NO if the user cancelled or save failed.
 */
+ (BOOL)saveImageToDisk:(nullable NSImage *)image;

@end

NS_ASSUME_NONNULL_END

/**
 * GrabDraw_releaseWindow
 *
 * Removes window from GrabDraw's internal retain set so ARC can release it.
 * Must be called from GrabImageWindow -windowShouldClose: when the user
 * confirms closing (Don't Save or Save).
 */
void GrabDraw_releaseWindow(NSWindow * _Nonnull window);
