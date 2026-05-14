/*
   Project: Grab
   Module:  GrabAudioManager

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Named sound resources bundled with the app.
typedef NS_ENUM(NSInteger, GrabSound) {
    GrabSoundOpenShutter  = 0,  ///< Played when a capture begins.
    GrabSoundCloseShutter = 1,  ///< Played when a capture completes (reserved).
    GrabSoundTimerDone    = 2   ///< Played when the countdown timer fires.
};

/**
 * GrabAudioManager
 *
 * Singleton responsible for all audio feedback in the Grab application.
 * Checks GrabPreferencesManager.audioEnabled before playing; callers do
 * not need to guard the call themselves.
 *
 * -playSound: blocks the calling thread for the sound duration.
 * Always call from a background thread when inside a capture sequence.
 *
 * Usage:
 *   [[GrabAudioManager sharedManager] playSound:GrabSoundOpenShutter];
 */
@interface GrabAudioManager : NSObject

/// Returns the shared instance.
+ (instancetype)sharedManager;

/**
 * Plays the specified sound if audio is enabled.
 * Blocks the calling thread for the sound duration.
 *
 * @param sound  One of the GrabSound enum values.
 */
- (void)playSound:(GrabSound)sound;

/**
 * Plays CloseShutter asynchronously on a background thread.
 * Returns immediately — use after showImage: so the window appears
 * without delay while the shutter-close sound plays in parallel.
 */
- (void)playCloseShutterAsync;

@end

NS_ASSUME_NONNULL_END
