/*
   Project: Grab
   Module:  GrabCaptureManager+Private

   Copyright (C) 2020-2026 Andres Morales

   Private interface for GrabAnimationController methods called via
   -performSelectorOnMainThread: from GrabCaptureManager background threads.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabAnimationController.h"

@interface GrabAnimationController (GrabCaptureManagerPrivate)

/// Stops the motion-driven eye animation and shows the flash frame.
/// Safe to call via -performSelectorOnMainThread: from a background thread.
- (void)_stopMotionAndShowFlash;

@end
