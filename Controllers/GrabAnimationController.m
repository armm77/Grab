/*
   Project: Grab
   Module:  GrabAnimationController

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/


#import "GrabAnimationController.h"
#import "GrabResourceManager.h"

static const CGFloat kPanelSize = 64.0;

// Travel animation constants
static const NSTimeInterval kTravelDuration     = 0.2;    // seconds — linear slide
static const NSTimeInterval kTravelTickInterval = 0.016;  // ~60 fps

@interface GrabAnimationController ()
@property (nonatomic, strong) NSPanel  *iconPanel;
@property (nonatomic, strong) NSButton *iconButton;
@property (nonatomic, strong) NSTimer  *motionTimer;
@property (nonatomic, strong) NSTimer  *flashTimer;
@property (nonatomic, strong) NSTimer  *travelTimer;
@property (nonatomic, assign) NSInteger currentEyeFrame;
@property (nonatomic, assign) NSPoint   lastMousePosition;
// Travel animation state
@property (nonatomic, assign) NSPoint   travelOrigin;
@property (nonatomic, assign) NSPoint   travelDestination;
@property (nonatomic, assign) NSTimeInterval travelStartTime;
@property (nonatomic, weak)   id        pendingTarget;
@property (nonatomic, assign) SEL       pendingAction;
@end

@implementation GrabAnimationController

/// Returns the destination point (bottom-left of the panel at its final position).
- (NSPoint)_finalPanelOrigin {
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    return NSMakePoint(
        screenFrame.origin.x + screenFrame.size.width  - kPanelSize - 3,
        screenFrame.origin.y + screenFrame.size.height - kPanelSize);
}

- (void)createPanelWithImage:(NSImage *)image
                      target:(id)target
                      action:(SEL)action
                 originPoint:(NSPoint)origin {
    [self closePanel];

    // Create panel at origin point.
    NSRect startFrame = NSMakeRect(origin.x - kPanelSize / 2.0,
                                   origin.y - kPanelSize / 2.0,
                                   kPanelSize, kPanelSize);

    NSPanel *panel = [[NSPanel alloc] initWithContentRect:startFrame
                                                styleMask:NSWindowStyleMaskBorderless
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    [panel makeKeyAndOrderFront:nil];
    [panel setLevel:NSStatusWindowLevel];

    NSButton *button = [[NSButton alloc]
        initWithFrame:NSMakeRect(0, 0, kPanelSize, kPanelSize)];
    [button setBordered:NO];
    [button setImage:image];
    // Target/action assigned after travel completes.
    [[panel contentView] addSubview:button];

    _iconPanel         = panel;
    _iconButton        = button;
    _pendingTarget     = target;
    _pendingAction     = action;
    _travelOrigin      = startFrame.origin;
    _travelDestination = [self _finalPanelOrigin];
    _travelStartTime   = [NSDate timeIntervalSinceReferenceDate];

    // Start travel timer on main thread.
    [_travelTimer invalidate];
    _travelTimer = [NSTimer scheduledTimerWithTimeInterval:kTravelTickInterval
                                                    target:self
                                                  selector:@selector(_travelTick)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)createPanelWithImage:(NSImage *)image
                      target:(id)target
                      action:(SEL)action {
    [self closePanel];

    NSRect panelFrame = NSMakeRect([self _finalPanelOrigin].x,
                                   [self _finalPanelOrigin].y,
                                   kPanelSize, kPanelSize);

    NSPanel *panel = [[NSPanel alloc] initWithContentRect:panelFrame
                                                styleMask:NSWindowStyleMaskBorderless
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    [panel setLevel:NSStatusWindowLevel];

    NSButton *button = [[NSButton alloc]
        initWithFrame:NSMakeRect(0, 0, kPanelSize, kPanelSize)];
    [button setBordered:NO];
    [button setImage:image];
    [button setTarget:target];
    [button setAction:action];

    [[panel contentView] addSubview:button];
    [panel makeKeyAndOrderFront:nil];

    _iconPanel  = panel;
    _iconButton = button;
}

/// Linear interpolation — constant speed, no easing.
static CGFloat linearstep(CGFloat t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    return t;
}

- (void)_travelTick {
    if (!_iconPanel) { [_travelTimer invalidate]; _travelTimer = nil; return; }

    NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - _travelStartTime;
    CGFloat t = linearstep((CGFloat)(elapsed / kTravelDuration));

    CGFloat x = _travelOrigin.x + (_travelDestination.x - _travelOrigin.x) * t;
    CGFloat y = _travelOrigin.y + (_travelDestination.y - _travelOrigin.y) * t;
    [_iconPanel setFrameOrigin:NSMakePoint(x, y)];

    if (t >= 1.0) {
        // Travel complete — snap to exact destination and activate button.
        [_iconPanel setFrameOrigin:_travelDestination];
        [_travelTimer invalidate];
        _travelTimer = nil;
        [_iconButton setTarget:_pendingTarget];
        [_iconButton setAction:_pendingAction];
        _pendingTarget = nil;
        _pendingAction = NULL;
    }
}

- (void)closePanel {
    [_travelTimer invalidate];
    _travelTimer = nil;

    [_motionTimer invalidate];
    _motionTimer = nil;

    [_flashTimer invalidate];
    _flashTimer = nil;

    [_iconPanel close];
    _iconPanel       = nil;
    _iconButton      = nil;
    _currentEyeFrame = 0;
    _pendingTarget   = nil;
    _pendingAction   = NULL;
}

// ── Motion-driven eye animation ───────────────────────────────────────────────

- (void)startMotionDrivenEyeAnimation {
    GrabResourceManager *res = [GrabResourceManager sharedManager];
    if (res.cameraEyeImages.count == 0) return;

    _currentEyeFrame   = 0;
    _lastMousePosition = [NSEvent mouseLocation];
    [_iconButton setImage:res.cameraEyeImages[0]];

    [_motionTimer invalidate];
    // 74 ms per frame — matches the original OpenStep 4.2 reference timing.
    _motionTimer = [NSTimer scheduledTimerWithTimeInterval:0.231
                                                    target:self
                                                  selector:@selector(_motionTick)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)stopMotionDrivenEyeAnimation:(BOOL)showFlash {
    [_motionTimer invalidate];
    _motionTimer = nil;
    if (showFlash) {
        NSImage *flash = [GrabResourceManager sharedManager].cameraEyeFlashImage;
        if (flash) [_iconButton setImage:flash];
    }
}

// Called via -performSelectorOnMainThread: from GrabCaptureManager threads.
- (void)_stopMotionAndShowFlash {
    [self stopMotionDrivenEyeAnimation:YES];
}

- (void)_motionTick {
    if (!_iconPanel) return;

    NSPoint mouse = [NSEvent mouseLocation];
    CGFloat dx = mouse.x - _lastMousePosition.x;
    CGFloat dy = mouse.y - _lastMousePosition.y;
    if ((dx * dx + dy * dy) >= 0.25) {
        NSArray *frames = [GrabResourceManager sharedManager].cameraEyeImages;
        if (frames.count > 0) {
            _currentEyeFrame = (_currentEyeFrame + 1) % (NSInteger)frames.count;
            [_iconButton setImage:frames[_currentEyeFrame]];
        }
        _lastMousePosition = mouse;
    }
}

// ── Countdown pie animation ───────────────────────────────────────────────────

- (void)showWatchIcon {
    [self _drawWatchWithPieFrameIndex:-1];
}

- (void)updatePieFrame:(NSInteger)frameIndex {
    [self _drawWatchWithPieFrameIndex:frameIndex];
}

- (void)showWatchFlashThenClose {
    GrabResourceManager *res = [GrabResourceManager sharedManager];
    [self _compositeBase:res.backgroundImage
                 overlay:res.cameraWatchFlashImage
               piePieces:nil
             pieFrameIdx:-1];

    // Keep a strong reference to the timer so closePanel can invalidate it
    // if the capture is aborted before the 1 s delay expires.
    [_flashTimer invalidate];
    _flashTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                   target:self
                                                 selector:@selector(closePanel)
                                                 userInfo:nil
                                                  repeats:NO];
}

- (void)_drawWatchWithPieFrameIndex:(NSInteger)frameIndex {
    GrabResourceManager *res = [GrabResourceManager sharedManager];
    [self _compositeBase:res.backgroundImage
                 overlay:res.cameraWatchImage
               piePieces:(frameIndex >= 0 ? res.piePiecesImage : nil)
             pieFrameIdx:frameIndex];
}

- (void)_compositeBase:(NSImage *)base
               overlay:(NSImage *)overlay
             piePieces:(nullable NSImage *)piePieces
           pieFrameIdx:(NSInteger)frameIdx {

    // Guard against nil base (resources not loaded). Drawing nil would crash.
    if (!base) {
        NSLog(@"GrabAnimationController: backgroundImage is nil — skipping composite.");
        return;
    }

    NSImage *composite = [[NSImage alloc]
        initWithSize:NSMakeSize(kPanelSize, kPanelSize)];
    [composite lockFocus];
    NSRect fullRect = NSMakeRect(0, 0, kPanelSize, kPanelSize);
    [base drawInRect:fullRect
            fromRect:NSZeroRect
           operation:NSCompositeSourceOver
            fraction:1.0];
    if (overlay)
        [overlay drawInRect:fullRect
                   fromRect:NSZeroRect
                  operation:NSCompositeSourceOver
                   fraction:1.0];
    if (piePieces && frameIdx >= 0 && frameIdx < 10) {
        NSRect srcRect  = NSMakeRect(frameIdx * 17.0, 0, 17, 17);
        NSRect destRect = NSMakeRect(41, 40, 17, 17);
        [piePieces drawInRect:destRect
                     fromRect:srcRect
                    operation:NSCompositeSourceOver
                     fraction:1.0];
    }
    [composite unlockFocus];
    [_iconButton setImage:composite];
}

@end
