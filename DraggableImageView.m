#import "DraggableImageView.h"

@implementation DraggableImageView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [[NSCursor openHandCursor] set];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[self window]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidResignKey:)
                                                     name:NSWindowDidResignKeyNotification
                                                   object:[self window]];
        
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(checkMousePosition)
                                       userInfo:nil
                                        repeats:YES];
    }
    return self;
}

- (NSImage *)selectedImage {
    return [self image];
}

- (void)updateCursorToHand {
    [[NSCursor openHandCursor] set];
}

- (void)checkMousePosition {
    NSPoint mouseLocation = [self.window mouseLocationOutsideOfEventStream];
    NSRect menuRect = NSMakeRect(0, self.frame.size.height - 30, self.frame.size.width, 30);

    if (NSMouseInRect(mouseLocation, menuRect, [self isFlipped])) {
        [[NSCursor arrowCursor] set];
    } else if ([self mouse:[self convertPoint:mouseLocation fromView:nil] inRect:self.bounds]) {
        [self updateCursorToHand];
    } else {
        [[NSCursor arrowCursor] set];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self updateCursorToHand];
}

- (void)mouseMoved:(NSEvent *)event {
    [self updateCursorToHand];
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint locationInWindow = [event locationInWindow];
    dragStartLocation = [self convertPoint:locationInWindow fromView:nil];
    [self updateCursorToHand];
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint locationInWindow = [event locationInWindow];
    NSPoint currentLocation = [self convertPoint:locationInWindow fromView:nil];

    NSPoint newOrigin = self.frame.origin;
    newOrigin.x += currentLocation.x - dragStartLocation.x;
    newOrigin.y += currentLocation.y - dragStartLocation.y;

    NSRect newFrame = self.frame;
    newFrame.origin = newOrigin;
    [self setFrame:newFrame];
    [self setNeedsDisplay:YES];

    [self updateCursorToHand];
}

- (void)mouseUp:(NSEvent *)event {
    [self updateCursorToHand];
}

- (void)mouseExited:(NSEvent *)event {
    [[NSCursor arrowCursor] set];
}

- (void)imageSaveCompleted {
    [[NSCursor arrowCursor] set];
}

- (void)windowWillClose:(NSNotification *)notification {
    [[NSCursor arrowCursor] set];
}

- (void)windowDidResignKey:(NSNotification *)notification {
    [[NSCursor arrowCursor] set];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end

