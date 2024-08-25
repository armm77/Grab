#import <AppKit/AppKit.h>

@interface DraggableImageView : NSImageView {
    NSPoint dragStartLocation;
}

- (void)imageSaveCompleted;
- (void)windowWillClose:(NSNotification *)notification;

@end

