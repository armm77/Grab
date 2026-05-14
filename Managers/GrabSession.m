/*
   Project: Grab
   Module:  GrabSession

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabSession.h"

NSString * const GrabSessionDidUpdateImageNotification = @"GrabSessionDidUpdateImageNotification";

static GrabSession     *_sharedInstance      = nil;
static dispatch_once_t  _sharedInstanceToken = 0;

@interface GrabSession ()
@property (nonatomic, strong, readwrite) NSImage *capturedImage;
@end

@implementation GrabSession

+ (instancetype)sharedSession {
    dispatch_once(&_sharedInstanceToken, ^{
        _sharedInstance = [[self alloc] initPrivate];
    });
    return _sharedInstance;
}

- (instancetype)initPrivate {
    return [super init];
}

- (instancetype)init {
    NSAssert(NO, @"Use +[GrabSession sharedSession].");
    return nil;
}

- (void)setCapturedImage:(NSImage *)image {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(setCapturedImage:)
                               withObject:image
                            waitUntilDone:NO];
        return;
    }
    _capturedImage = image;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:GrabSessionDidUpdateImageNotification
                      object:self
                    userInfo:nil];
}

- (BOOL)hasImage {
    return _capturedImage != nil;
}

@end
