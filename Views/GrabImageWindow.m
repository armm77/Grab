/*
   Project: Grab
   Module:  GrabImageWindow

   Copyright (C) 2020-2026 Andres Morales

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import "GrabImageWindow.h"
#import "GrabDraw.h"
#import <DesktopKit/NXTAlert.h>

@implementation GrabImageWindow

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender {
    NSString *msg = [NSString stringWithFormat:
                     NSLocalizedString(@"Save changes to %@?",
                                       @"Close alert message"), [self title]];

    NSInteger result = NXTRunAlertPanel(
        NSLocalizedString(@"Close",       @"Close alert title"),
        msg,
        NSLocalizedString(@"Save",        @"Save button"),
        NSLocalizedString(@"Don't Save",  @"Don't Save button"),
        NSLocalizedString(@"Cancel",      @"Cancel button"));

    if (result == NSAlertDefaultReturn) {
        // Save — keep window open if user cancels the save panel.
        BOOL saved = [GrabDraw saveImageToDisk:_capturedImage];
        if (saved) {
            // User completed the save: drop our retain so ARC can free the window.
            GrabDraw_releaseWindow(self);
        }
        return saved;
    } else if (result == NSAlertAlternateReturn) {
        // Don't Save — release our retain and close.
        GrabDraw_releaseWindow(self);
        return YES;
    } else {
        // Cancel — keep window open, do not release.
        return NO;
    }
}

@end
