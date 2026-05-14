/*
   Project: Grab
   Module:  GrabResourceManager

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
 * GrabResourceManager
 *
 * Loads all .tiff image resources from the main bundle and composites
 * them onto the tiled background. Results are cached after the first
 * successful call to -loadResources.
 *
 * All images are read-only; consumers must not mutate them.
 * Properties are nullable until -loadResources is called.
 */
@interface GrabResourceManager : NSObject

/// Returns the shared instance.
+ (instancetype)sharedManager;

// ── Loaded images (nil until -loadResources succeeds) ─────────────────────────

@property (nonatomic, strong, readonly, nullable) NSImage *backgroundImage;
@property (nonatomic, strong, readonly, nullable) NSImage *cameraNormalImage;
@property (nonatomic, strong, readonly, nullable) NSImage *cameraEyeFlashImage;
@property (nonatomic, strong, readonly, nullable) NSArray<NSImage *> *cameraEyeImages;
@property (nonatomic, strong, readonly, nullable) NSImage *piePiecesImage;
@property (nonatomic, strong, readonly, nullable) NSImage *cameraWatchImage;
@property (nonatomic, strong, readonly, nullable) NSImage *cameraWatchFlashImage;
/// Raw CameraPointer.tiff — used to build the X11 window-capture cursor.
@property (nonatomic, strong, readonly, nullable) NSImage *cameraPointerImage;

// ── Loading ───────────────────────────────────────────────────────────────────

/**
 * Loads all image resources from the main bundle.
 * Safe to call multiple times — subsequent calls are no-ops if already loaded.
 * Returns YES on full success, NO if any required asset failed to load.
 */
- (BOOL)loadResources;

@end

NS_ASSUME_NONNULL_END
