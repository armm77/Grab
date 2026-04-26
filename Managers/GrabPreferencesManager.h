/*
   Project: Grab
   Module:  GrabPreferencesManager

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Cursor shown while the user aims at the screen during capture.
/// The raw value is persisted in NSUserDefaults.
/// The string name of each value matches the NSImage name used in CursorTypes.gorm.
typedef NS_ENUM(NSInteger, GrabCursorType) {
    GrabCursorTypeCameraPointer  = 0,   ///< Custom CameraPointer.tiff from bundle (default)
    GrabCursorTypeArrowCursor    = 1,   ///< "ArrowCursor"    → XC_left_ptr
    GrabCursorTypeIbeamCursor    = 2,   ///< "IbeamCursor"    → XC_xterm
    GrabCursorTypeWaitCursor     = 3,   ///< "WaitCursor"     → XC_watch
    GrabCursorTypeHelpCursor     = 4,   ///< "HelpCursor"     → XC_question_arrow
    GrabCursorTypeGenericCursor  = 5,   ///< "genericCursor"  → XC_crosshair
    GrabCursorTypePlaceCursor    = 6,   ///< "PlaceCursor"    → XC_tcross
    GrabCursorTypePointerCursor  = 7,   ///< "PointerCursor"  → XC_hand2
    GrabCursorTypeLinkCursor     = 8,   ///< "linkCursor"     → XC_hand1
    GrabCursorTypeCopyCursor     = 9,   ///< "copyCursor"     → XC_plus
};

/**
 * GrabPreferencesManager
 *
 * Singleton that wraps all persistent user preferences for the Grab app.
 * All reads/writes go through this class; no other class should call
 * NSUserDefaults directly.
 */
@interface GrabPreferencesManager : NSObject

/// Returns the shared instance.
+ (instancetype)sharedManager;

// ── Audio ─────────────────────────────────────────────────────────────────────

/// Whether shutter/timer sounds are enabled. Default: YES.
@property (nonatomic, assign) BOOL audioEnabled;

// ── Timer ─────────────────────────────────────────────────────────────────────

/// Countdown duration in seconds for timed captures. Default: 10.
/// Read-only — no UI to change this value yet.
@property (nonatomic, assign, readonly) NSInteger timerDuration;

// ── Cursor ────────────────────────────────────────────────────────────────────

/// Cursor displayed while the user aims during screen/window capture.
/// Default: GrabCursorTypeCameraPointer (custom CameraPointer.tiff).
@property (nonatomic, assign) GrabCursorType cursorType;

/// Returns the TIFF filename (without extension) inside CursorTypes.gorm
/// for the given cursor type, or nil for GrabCursorTypeCameraPointer
/// (which uses the main bundle's CameraPointer.tiff instead).
+ (nullable NSString *)tiffNameForCursorType:(GrabCursorType)type;

// ── Persistence ───────────────────────────────────────────────────────────────

/// Writes all pending changes to disk immediately.
- (void)synchronize;

@end

NS_ASSUME_NONNULL_END
