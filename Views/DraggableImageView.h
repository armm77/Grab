/*
   Project: Grab
   Module:  DraggableImageView

   Copyright (C) 2020-2026 Andres Morales

   A custom NSImageView that allows the user to drag (pan) a full-screen
   image that has been scaled to fit the window.

   Cursor behavior:
     - Place cursor (open-hand) while the user is actively dragging.
     - Arrow cursor at all other times.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * DraggableImageView
 *
 * Displays an NSImage and lets the user click-drag to pan it when it is
 * larger than the visible viewport (typical for full-screen captures
 * displayed at 50% in a smaller window).
 *
 * Cursor behavior:
 *   - Place cursor (open-hand) while pressing and dragging.
 *   - Arrow cursor on mouse release and when the view is not being dragged.
 */
@interface DraggableImageView : NSImageView
NS_ASSUME_NONNULL_END

@end
