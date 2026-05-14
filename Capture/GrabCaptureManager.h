/*
   Project: Grab
   Module:  GrabCaptureManager

   Copyright (C) 2020-2026 Andres Morales

   Handles all screen/window capture operations via X11.
   Writes results exclusively through GrabSession.
   Drives GrabAnimationController during capture sequences.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GrabCaptureManager
 *
 * Encapsulates the three capture modes available in Grab:
 *
 *   - Window capture:       the user clicks a window to capture it.
 *   - Full-screen capture:  the entire screen is captured immediately.
 *   - Section capture:      the user drags a rubber-band rectangle.
 *   - Timed capture:        a countdown fires a full-screen capture.
 *
 * All X11 interaction is contained within this class and GrabImageProcessor.
 * After a successful capture, the image is stored in GrabSession and a
 * result window is displayed via GrabDraw.
 *
 * All capture methods are safe to call from the main thread; they dispatch
 * blocking X11 work onto a background queue internally.
 */
@interface GrabCaptureManager : NSObject

+ (instancetype)sharedManager;

// ── Capture entry points (called from GrabController IBActions / services) ────

/**
 * Initiates a window-capture sequence with panel travel animation.
 * Pass NSZeroPoint from services (no menu click origin available).
 */
- (void)captureWindowFromMenuOrigin:(NSPoint)menuOrigin;

/**
 * Captures the entire screen with panel travel animation.
 * Pass NSZeroPoint from services (no menu click origin available).
 */
- (void)captureFullScreenFromMenuOrigin:(NSPoint)menuOrigin;

/**
 * Initiates a section-capture sequence.
 * The user draws a rubber-band rectangle; the enclosed area is captured.
 */
- (void)captureScreenSection;

/**
 * Cancels any pending capture timers. Call from -applicationWillTerminate:.
 */
- (void)cancelPendingCapture;

/**
 * Shows the timed-capture icon panel with travel animation from `menuOrigin`.
 * Pass NSZeroPoint from services (no menu click origin available).
 */
- (void)startTimedCaptureFromMenuOrigin:(NSPoint)menuOrigin;

NS_ASSUME_NONNULL_END

@end
