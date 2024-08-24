#import <AppKit/AppKit.h>
#import "ImageProviding.h"

@interface DraggableImageView : NSImageView {
    NSPoint dragStartLocation;
}

- (void)imageSaveCompleted;
- (void)windowWillClose:(NSNotification *)notification;

@end

