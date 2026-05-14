/*
   Project: Grab
   Module:  GrabAudioManager

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabAudioManager.h"
#import "GrabPreferencesManager.h"

static NSString * const kSoundNames[] = {
    [GrabSoundOpenShutter]  = @"OpenShutter",
    [GrabSoundCloseShutter] = @"CloseShutter",
    [GrabSoundTimerDone]    = @"TimerDone"
};

static GrabAudioManager *_sharedInstance      = nil;
static dispatch_once_t   _sharedInstanceToken = 0;

@interface GrabAudioManager ()
- (void)_playSoundWithName:(NSString *)soundName;
@end

@implementation GrabAudioManager

+ (instancetype)sharedManager {
    dispatch_once(&_sharedInstanceToken, ^{
        _sharedInstance = [[self alloc] initPrivate];
    });
    return _sharedInstance;
}

- (instancetype)initPrivate { return [super init]; }

- (instancetype)init {
    NSAssert(NO, @"Use +[GrabAudioManager sharedManager].");
    return nil;
}

- (void)playSound:(GrabSound)sound {
    NSUInteger count = sizeof(kSoundNames) / sizeof(kSoundNames[0]);
    if ((NSUInteger)sound >= count) return;
    [self _playSoundWithName:kSoundNames[sound]];
}

- (void)_playSoundWithName:(NSString *)soundName {
    if (!soundName.length) return;
    if (![GrabPreferencesManager sharedManager].audioEnabled) return;
    NSString *path = [[NSBundle mainBundle] pathForResource:soundName ofType:@"wav"];
    if (!path) return;
    NSSound *sound = [[NSSound alloc] initWithContentsOfFile:path byReference:NO];
    if (!sound) return;
    [sound play];
    // Guard: a corrupt or empty WAV file can report duration == 0 or a
    // negative value. sleepForTimeInterval: with a non-positive argument
    // returns immediately but is misleading at the call site, so we skip
    // the sleep entirely in that case.
    if (sound.duration > 0) {
        [NSThread sleepForTimeInterval:sound.duration];
    }
}

/// Fires CloseShutter on a background thread so the image window can
/// appear immediately without waiting for the sound to finish.
- (void)playCloseShutterAsync {
    if (![GrabPreferencesManager sharedManager].audioEnabled) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self playSound:GrabSoundCloseShutter];
    });
}

@end
