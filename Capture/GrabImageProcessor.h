/*
   Project: Grab
   Module:  GrabImageProcessor

   Copyright (C) 2020-2026 Andres Morales

   Low-level X11 → NSImage conversion utilities.
   This class has no knowledge of GrabSession, preferences, or the UI.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <X11/Xlib.h>
#import <X11/Xutil.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GrabImageProcessor
 *
 * Stateless utility class (all methods are class methods).
 * Responsible for capturing screen regions and windows via X11 and
 * converting the raw pixel data to NSImage.
 *
 * Callers must pass valid (non-NULL) Display* pointers.
 */
@interface GrabImageProcessor : NSObject

/**
 * Captures a rectangular region of the root window.
 *
 * @param rect        Origin and size in X11 coordinates.
 * @param display     An open X11 Display connection. Must not be NULL.
 * @param rootWindow  The root Window handle.
 * @return            A new NSImage, or nil on failure.
 */
+ (nullable NSImage *)captureRect:(NSRect)rect
                          display:(Display *)display
                       rootWindow:(Window)rootWindow;

/**
 * Captures a single window by its X11 Window ID.
 *
 * @param window   The Window to capture.
 * @param display  An open X11 Display connection. Must not be NULL.
 * @return         A new NSImage, or nil on failure.
 */
+ (nullable NSImage *)captureWindow:(Window)window
                            display:(Display *)display;

@end

NS_ASSUME_NONNULL_END
