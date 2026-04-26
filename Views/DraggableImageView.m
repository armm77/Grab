/*
   Project: Grab
   Module:  DraggableImageView

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "DraggableImageView.h"

static NSCursor *_loadCursor(NSString *name, NSPoint hotspot) {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"tiff"];
    if (!path) return nil;
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:path];
    if (!img) return nil;
    return [[NSCursor alloc] initWithImage:img hotSpot:hotspot];
}

@interface DraggableImageView ()
@property (nonatomic, assign) NSPoint   dragStartLocation;
@property (nonatomic, assign) BOOL      isDragging;
@property (nonatomic, strong) NSCursor *placeCursor;
@property (nonatomic, strong) NSCursor *arrowCursor;
@end

@implementation DraggableImageView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _isDragging = NO;

        NSCursor *place = _loadCursor(@"PlaceCursor", NSMakePoint(8, 8));
        _placeCursor = place ?: [NSCursor openHandCursor];

        NSCursor *arrow = _loadCursor(@"ArrowCursor", NSMakePoint(0, 0));
        _arrowCursor = arrow ?: [NSCursor arrowCursor];

        [_arrowCursor set];
    }
    return self;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    // Reset cursor state whenever the view enters or leaves a window.
    if (!_isDragging) [_arrowCursor set];
}

// ── Dragging ──────────────────────────────────────────────────────────────────

- (void)mouseDown:(NSEvent *)event {
    _isDragging        = YES;
    _dragStartLocation = [self convertPoint:[event locationInWindow]
                                   fromView:nil];
    [_placeCursor set];
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint current = [self convertPoint:[event locationInWindow] fromView:nil];
    NSRect  frame   = self.frame;
    frame.origin.x += current.x - _dragStartLocation.x;
    frame.origin.y += current.y - _dragStartLocation.y;
    [self setFrame:frame];
    [self setNeedsDisplay:YES];
    [_placeCursor set];
}

- (void)mouseUp:(NSEvent *)event {
    _isDragging = NO;
    [_arrowCursor set];
}

@end
