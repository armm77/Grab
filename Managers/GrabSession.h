/*
   Project: Grab
   Module:  GrabSession

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Posted on the main thread whenever the captured image changes (including
/// being set to nil). The notification object is the GrabSession instance.
extern NSString * const GrabSessionDidUpdateImageNotification;

/**
 * GrabSession
 *
 * Singleton model object that owns the currently-captured image.
 *
 * Writing policy: only GrabCaptureManager should call -setCapturedImage:.
 * All other consumers should treat this as read-only and observe
 * GrabSessionDidUpdateImageNotification for changes.
 *
 * Thread-safety: -setCapturedImage: may be called from a background thread;
 * the notification is always dispatched to the main thread.
 */
@interface GrabSession : NSObject

/// Returns the shared session instance.
+ (instancetype)sharedSession;

/// The most recently captured image, or nil if no capture has been made yet.
@property (nonatomic, strong, readonly, nullable) NSImage *capturedImage;

/**
 * Sets the captured image and posts GrabSessionDidUpdateImageNotification.
 * Pass nil to clear the session.
 */
- (void)setCapturedImage:(nullable NSImage *)image;

/// Returns YES if a captured image is currently held.
- (BOOL)hasImage;

@end

NS_ASSUME_NONNULL_END
