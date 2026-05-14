/*
   Project: Grab
   Module:  GrabController

   Copyright (C) 2020-2026 Andres Morales

   Application delegate and central UI coordinator.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GrabController
 *
 * Application delegate and owner of all .gorm NIB files.
 * Instantiated by the AppKit NIB loader from Grab.gorm — not by code.
 *
 * Public outlets (connected in Grab.gorm):
 *   - audioMenuItem   → "Turn Sound On/Off" menu item
 *   - widthField, heightField, depthField, sizeField, alphaCheckbox
 *     → fields in InspectorPanel.gorm (must be public for the NIB loader)
 */
@interface GrabController : NSObject

// ── Menu outlet ───────────────────────────────────────────────────────────────
@property (nonatomic, strong) IBOutlet NSMenuItem *audioMenuItem;

// ── Inspector panel outlets ───────────────────────────────────────────────────
@property (nonatomic, weak) IBOutlet NSTextField *widthField;
@property (nonatomic, weak) IBOutlet NSTextField *heightField;
@property (nonatomic, weak) IBOutlet NSTextField *depthField;
@property (nonatomic, weak) IBOutlet NSTextField *sizeField;
@property (nonatomic, weak) IBOutlet NSButton    *alphaCheckbox;

// ── NSApplicationDelegate lifecycle ───────────────────────────────────────────
- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;

// ── IBActions: Audio ──────────────────────────────────────────────────────────
- (IBAction)toggleAudio:(id)sender;

// ── IBActions: Capture ────────────────────────────────────────────────────────
- (IBAction)captureWindow:(id)sender;
- (IBAction)captureFullScreen:(id)sender;
- (IBAction)captureScreenSection:(id)sender;
- (IBAction)startTimedCapture:(id)sender;

// ── IBActions: Image operations ───────────────────────────────────────────────
- (IBAction)printImage:(id)sender;
- (IBAction)copyImage:(id)sender;
- (IBAction)saveImage:(id)sender;

// ── IBActions: Panels ─────────────────────────────────────────────────────────
- (IBAction)showHelpPanel:(id)sender;
- (IBAction)showInfoPanel:(id)sender;
- (IBAction)showInspectorPanel:(id)sender;
- (IBAction)showCursorPanel:(id)sender;
- (IBAction)changeCursor:(id)sender;

NS_ASSUME_NONNULL_END

// ── Services provider ─────────────────────────────────────────────────────────
// Parameters annotated explicitly because they live outside NS_ASSUME_NONNULL.

- (void)grabScreen:(NSPasteboard * _Nonnull)pb
          userData:(NSString * _Nullable)ud
             error:(NSString * _Nullable * _Nullable)err;

- (void)grabSelection:(NSPasteboard * _Nonnull)pb
             userData:(NSString * _Nullable)ud
                error:(NSString * _Nullable * _Nullable)err;

- (void)grabWindow:(NSPasteboard * _Nonnull)pb
          userData:(NSString * _Nullable)ud
             error:(NSString * _Nullable * _Nullable)err;

@end
