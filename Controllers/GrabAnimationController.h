/*
   Project: Grab
   Module:  GrabAnimationController

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GrabAnimationController
 *
 * Controls the floating NSPanel that shows camera-icon animations in the
 * corner of the screen during a capture sequence. Owns the NSPanel, the
 * NSButton inside it, and the timers that drive the animations.
 *
 * Not a singleton — owned as a stored property by GrabCaptureManager.
 */
@interface GrabAnimationController : NSObject

/**
 * Creates the floating icon panel and animates it from `origin` to the
 * final corner position (top-right of screen), then attaches the button
 * action. The eye animation starts only after the travel completes.
 *
 * @param image   Initial button image.
 * @param target  Target for the button action.
 * @param action  Selector called when the button is clicked.
 * @param origin  Screen-coordinate point where the panel appears (e.g. mouse location).
 */
- (void)createPanelWithImage:(NSImage *)image
                      target:(id)target
                      action:(SEL)action
                 originPoint:(NSPoint)origin;

/**
 * Creates the floating icon panel with the given image and attaches
 * action (on target) to the button inside it.
 * Panel appears directly at its final position with no travel animation.
 *
 * @param image   Initial button image.
 * @param target  Target for the button action.
 * @param action  Selector called when the button is clicked.
 */
- (void)createPanelWithImage:(NSImage *)image
                      target:(id)target
                      action:(SEL)action;

/// Closes the panel and releases it. Safe to call if already closed.
- (void)closePanel;

/// Returns the screen point where the panel rests in its final position
/// (bottom-left corner of the panel frame). Used by callers that need to
/// place the panel directly at the destination when no origin is available.
- (NSPoint)_finalPanelOrigin;

// ── Motion-driven eye animation (Screen and Window capture mode) ─────────────

/**
 * Starts a polling timer that advances the CameraEye1/2/3 animation
 * frames only when the cursor has moved since the last tick.
 * Must be called from the main thread.
 */
- (void)startMotionDrivenEyeAnimation;

// ── Countdown pie animation (Timed Screen mode) ───────────────────────────────

/// Shows the camera-watch icon at step 0 (no pie filled).
- (void)showWatchIcon;

/**
 * Advances the pie-piece indicator to the given step.
 * @param frameIndex  Current countdown step (0–9).
 */
- (void)updatePieFrame:(NSInteger)frameIndex;

/// Shows the camera-watch flash overlay, then schedules panel close.
- (void)showWatchFlashThenClose;

@end

NS_ASSUME_NONNULL_END
