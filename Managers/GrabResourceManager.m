/*
   Project: Grab
   Module:  GrabResourceManager

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabResourceManager.h"

static GrabResourceManager *_sharedInstance      = nil;
static dispatch_once_t      _sharedInstanceToken = 0;

@interface GrabResourceManager ()
@property (nonatomic, strong, readwrite) NSImage *backgroundImage;
@property (nonatomic, strong, readwrite) NSImage *cameraNormalImage;
@property (nonatomic, strong, readwrite) NSImage *cameraEyeFlashImage;
@property (nonatomic, strong, readwrite) NSArray<NSImage *> *cameraEyeImages;
@property (nonatomic, strong, readwrite) NSImage *piePiecesImage;
@property (nonatomic, strong, readwrite) NSImage *cameraWatchImage;
@property (nonatomic, strong, readwrite) NSImage *cameraWatchFlashImage;
@property (nonatomic, strong, readwrite) NSImage *cameraPointerImage;
// Tracks which asset groups loaded successfully so retry is per-group.
@property (nonatomic, assign) BOOL coreAssetsLoaded;
@property (nonatomic, assign) BOOL timedCaptureAssetsLoaded;
@property (nonatomic, assign) BOOL pointerAssetLoaded;
@end

@implementation GrabResourceManager

+ (instancetype)sharedManager {
    dispatch_once(&_sharedInstanceToken, ^{
        _sharedInstance = [[self alloc] initPrivate];
    });
    return _sharedInstance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _coreAssetsLoaded        = NO;
        _timedCaptureAssetsLoaded = NO;
        _pointerAssetLoaded      = NO;
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Use +[GrabResourceManager sharedManager].");
    return nil;
}

- (BOOL)loadResources {
    // Each asset group is loaded independently. A failure in an optional
    // group does not block groups that are already loaded.
    // Order: ok && [loader] — the loader is always called (the if-guard above
    // ensures this only runs when the group is not yet loaded), and ok
    // accumulates failures without short-circuiting the other groups.
    BOOL ok = YES;
    if (!_coreAssetsLoaded)          ok = ok && [self _loadCoreAssets];
    if (!_timedCaptureAssetsLoaded)  ok = ok && [self _loadTimedCaptureAssets];
    if (!_pointerAssetLoaded)        ok = ok && [self _loadPointerAsset];
    return ok;
}

// ── Asset group loaders ───────────────────────────────────────────────────────

// Critical assets: required by Screen and Window capture.
// Returns NO and leaves _coreAssetsLoaded = NO if any of these fail.
- (BOOL)_loadCoreAssets {
    NSImage *bg = [self _imageNamed:@"common_Tile"];
    if (!bg) {
        NSLog(@"GrabResourceManager: CRITICAL — could not load 'common_Tile.tiff'.");
        return NO;
    }
    _backgroundImage = bg;

    NSArray *eyeNames = @[@"CameraEye1", @"CameraEye2", @"CameraEye3"];
    NSMutableArray *eyeFrames = [NSMutableArray arrayWithCapacity:eyeNames.count];
    BOOL eyeOk = YES;
    for (NSString *name in eyeNames) {
        NSImage *frame = [self _imageNamed:name];
        if (frame) {
            NSImage *composite = [self _compositeBase:bg withOverlay:frame];
            if (composite) [eyeFrames addObject:composite];
        } else {
            NSLog(@"GrabResourceManager: could not load '%@.tiff'.", name);
            eyeOk = NO;
        }
    }
    if (!eyeOk) return NO;
    _cameraEyeImages = [eyeFrames copy];

    BOOL ok = YES;
    _cameraEyeFlashImage = [self _loadComposite:@"CameraEyeFlash" success:&ok];
    _cameraNormalImage   = [self _loadComposite:@"CameraNormal"   success:&ok];
    if (!ok) return NO;

    _coreAssetsLoaded = YES;
    return YES;
}

// Optional assets: required only by Timed Screen capture.
// A failure here disables the timed capture mode but does not affect
// Screen or Window capture.
- (BOOL)_loadTimedCaptureAssets {
    BOOL ok = YES;
    _cameraWatchImage      = [self _loadComposite:@"CameraWatch"      success:&ok];
    _cameraWatchFlashImage = [self _loadComposite:@"CameraWatchFlash" success:&ok];
    _piePiecesImage        = [self _imageNamed:@"PiePieces"];
    if (!_piePiecesImage) {
        NSLog(@"GrabResourceManager: could not load 'PiePieces.tiff'.");
        ok = NO;
    }
    if (ok) _timedCaptureAssetsLoaded = YES;
    return ok;
}

// Optional asset: required only for the custom CameraPointer X11 cursor.
// A failure here falls back to XC_hand2 in GrabCaptureManager.
- (BOOL)_loadPointerAsset {
    _cameraPointerImage = [self _imageNamed:@"CameraPointer"];
    if (!_cameraPointerImage) {
        NSLog(@"GrabResourceManager: could not load 'CameraPointer.tiff' "
              @"— will use fallback cursor.");
        return NO;
    }
    _pointerAssetLoaded = YES;
    return YES;
}

// ── Private helpers ───────────────────────────────────────────────────────────

- (NSImage *)_compositeBase:(NSImage *)background withOverlay:(NSImage *)overlay {
    if (!background || !overlay) return nil;
    NSImage *result = [[NSImage alloc] initWithSize:background.size];
    NSRect rect = NSMakeRect(0, 0, background.size.width, background.size.height);
    [result lockFocus];
    [background drawInRect:rect fromRect:NSZeroRect
                 operation:NSCompositeSourceOver fraction:1.0];
    [overlay    drawInRect:NSMakeRect(0, 0, overlay.size.width, overlay.size.height)
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver fraction:1.0];
    [result unlockFocus];
    return result;
}

- (nullable NSImage *)_imageNamed:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"tiff"];
    if (!path) return nil;
    return [[NSImage alloc] initWithContentsOfFile:path];
}

- (nullable NSImage *)_loadComposite:(NSString *)name success:(BOOL *)success {
    NSImage *overlay = [self _imageNamed:name];
    if (!overlay) {
        NSLog(@"GrabResourceManager: could not load '%@.tiff'.", name);
        if (success) *success = NO;
        return nil;
    }
    return [self _compositeBase:_backgroundImage withOverlay:overlay];
}

@end
