/*
   Project: Grab
   Module:  GrabPreferencesManager

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabPreferencesManager.h"

// NSUserDefaults keys — private to this file.
static NSString * const kGrabPrefKeyAudioEnabled  = @"GrabAudioEnabled";
static NSString * const kGrabPrefKeyTimerDuration = @"GrabTimerDuration";
static NSString * const kGrabPrefKeyCursorType    = @"GrabCursorType";

static const BOOL           kDefaultAudioEnabled  = YES;
static const NSInteger      kDefaultTimerDuration = 10;
static const GrabCursorType kDefaultCursorType    = GrabCursorTypeCameraPointer; // = 0

static GrabPreferencesManager *_sharedInstance      = nil;
static dispatch_once_t         _sharedInstanceToken = 0;

@interface GrabPreferencesManager ()
{
    NSUserDefaults *_defaults;
}
@end

@implementation GrabPreferencesManager

+ (instancetype)sharedManager {
    dispatch_once(&_sharedInstanceToken, ^{
        _sharedInstance = [[self alloc] initPrivate];
    });
    return _sharedInstance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _defaults = [NSUserDefaults standardUserDefaults];
        [self _registerDefaults];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Use +[GrabPreferencesManager sharedManager].");
    return nil;
}

- (void)_registerDefaults {
    NSDictionary *defs = @{
        kGrabPrefKeyAudioEnabled  : @(kDefaultAudioEnabled),
        kGrabPrefKeyTimerDuration : @(kDefaultTimerDuration),
        kGrabPrefKeyCursorType    : @(kDefaultCursorType)
    };
    [_defaults registerDefaults:defs];
}

- (BOOL)audioEnabled { return [_defaults boolForKey:kGrabPrefKeyAudioEnabled]; }
- (void)setAudioEnabled:(BOOL)v { [_defaults setBool:v forKey:kGrabPrefKeyAudioEnabled]; }

- (NSInteger)timerDuration { return [_defaults integerForKey:kGrabPrefKeyTimerDuration]; }

- (void)synchronize { [_defaults synchronize]; }

// ── Cursor ────────────────────────────────────────────────────────────────────

- (GrabCursorType)cursorType {
    return (GrabCursorType)[_defaults integerForKey:kGrabPrefKeyCursorType];
}
- (void)setCursorType:(GrabCursorType)v {
    [_defaults setInteger:v forKey:kGrabPrefKeyCursorType];
}

+ (nullable NSString *)tiffNameForCursorType:(GrabCursorType)type {
    switch (type) {
        case GrabCursorTypeArrowCursor:   return @"ArrowCursor";
        case GrabCursorTypeIbeamCursor:   return @"IbeamCursor";
        case GrabCursorTypeWaitCursor:    return @"WaitCursor";
        case GrabCursorTypeHelpCursor:    return @"HelpCursor";
        case GrabCursorTypeGenericCursor: return @"genericCursor";
        case GrabCursorTypePlaceCursor:   return @"PlaceCursor";
        case GrabCursorTypePointerCursor: return @"PointerCursor";
        case GrabCursorTypeLinkCursor:    return @"linkCursor";
        case GrabCursorTypeCopyCursor:    return @"copyCursor";
        default: return nil; // GrabCursorTypeCameraPointer → main bundle
    }
}

@end
