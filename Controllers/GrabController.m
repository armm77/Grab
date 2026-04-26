/*
   Project: Grab
   Module:  GrabController
*/

#import "GrabController.h"
#import <stdlib.h>
#import "GrabSession.h"
#import "GrabPreferencesManager.h"
#import "GrabCaptureManager.h"
#import "GrabDraw.h"

@interface GrabController ()
@property (nonatomic, strong) id helpPanel;
@property (nonatomic, strong) id infoPanel;
@property (nonatomic, strong) id inspectorPanel;
@property (nonatomic, strong) NSPanel  *cursorPanel;
@property (nonatomic, strong) NSMatrix *cursorMatrix;
@property (nonatomic, weak)   IBOutlet NSTextField *verField;
@property (nonatomic, weak)   IBOutlet NSTextField *copyrightField;
@property (nonatomic, weak)   IBOutlet NSTextView  *helpText;
@property (nonatomic, strong) NSPasteboard *pendingServicePasteboard;
@end

@implementation GrabController

// ── NSApplicationDelegate lifecycle ───────────────────────────────────────────

/// Called after the NIB is loaded and all outlets are connected.
/// This is the earliest safe point to update the audio menu title.
- (void)awakeFromNib {
    [self _updateAudioMenuTitle];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    // Inject DISPLAY if not set (for Workspace double-click launch).
    NSString *display = [[NSUserDefaults standardUserDefaults]
                            stringForKey:@"GSDisplayName"];
    if (!display || display.length == 0) display = @":0";
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    if (!env[@"DISPLAY"]) {
        setenv("DISPLAY", [display UTF8String], 0);
        NSLog(@"GrabController: injected DISPLAY=%@", display);
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Register Grab as a services provider.
    [NSApp setServicesProvider:self];
    NSUpdateDynamicServices();
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [[GrabCaptureManager sharedManager] cancelPendingCapture];
    [[GrabPreferencesManager sharedManager] synchronize];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return NO;
}

// ── IBActions: Audio ──────────────────────────────────────────────────────────

- (IBAction)toggleAudio:(id)sender {
    GrabPreferencesManager *prefs = [GrabPreferencesManager sharedManager];
    prefs.audioEnabled = !prefs.audioEnabled;
    [prefs synchronize];
    [self _updateAudioMenuTitle];
}

// ── IBActions: Capture ────────────────────────────────────────────────────────

- (IBAction)captureWindow:(id)sender {
    [[GrabCaptureManager sharedManager] captureWindowFromMenuOrigin:[NSEvent mouseLocation]];
}

- (IBAction)captureFullScreen:(id)sender {
    [[GrabCaptureManager sharedManager] captureFullScreenFromMenuOrigin:[NSEvent mouseLocation]];
}

- (IBAction)captureScreenSection:(id)sender {
    [[GrabCaptureManager sharedManager] captureScreenSection];
}

- (IBAction)startTimedCapture:(id)sender {
    [[GrabCaptureManager sharedManager] startTimedCaptureFromMenuOrigin:[NSEvent mouseLocation]];
}
// ── IBActions: Image operations ───────────────────────────────────────────────

- (IBAction)printImage:(id)sender {
    NSImage *image = [GrabSession sharedSession].capturedImage;
    if (!image) return;
    NSImageView *view = [[NSImageView alloc]
        initWithFrame:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [view setImage:image];
    [[NSPrintOperation printOperationWithView:view] runOperation];
}

- (IBAction)copyImage:(id)sender {
    NSImage *image = [GrabSession sharedSession].capturedImage;
    if (!image) return;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:@[NSPasteboardTypeTIFF] owner:nil];
    [pb setData:[image TIFFRepresentation] forType:NSPasteboardTypeTIFF];
}

- (IBAction)saveImage:(id)sender {
    [GrabDraw saveImageToDisk:[GrabSession sharedSession].capturedImage];
}

// ── IBActions: Panels ─────────────────────────────────────────────────────────

- (IBAction)showHelpPanel:(id)sender {
    if (!_helpPanel) {
        if (![NSBundle loadNibNamed:@"HelpPanel" owner:self]) return;
        NSString *rtfPath = [[NSBundle mainBundle]
                                pathForResource:@"HelpPanel" ofType:@"rtf"];
        NSData *rtfData = [NSData dataWithContentsOfFile:rtfPath];
        if (rtfData && _helpText)
            [_helpText replaceCharactersInRange:NSMakeRange(0, 0) withRTF:rtfData];
        [self _showWindowFirstTime:_helpPanel autosaveName:@"GrabHelpPanel"];
        return;
    }
    [_helpPanel makeKeyAndOrderFront:nil];
}

- (IBAction)showInfoPanel:(id)sender {
    if (!_infoPanel) {
        NSString *plist = [[NSBundle mainBundle]
                              pathForResource:@"GrabInfo" ofType:@"plist"];
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:plist];
        if (!info) {
            NSLog(@"GrabController: could not load GrabInfo.plist.");
            info = @{};
        }
        if (![NSBundle loadNibNamed:@"InfoPanel" owner:self]) return;
        NSString *release = info[@"ApplicationRelease"] ?: @"—";
        [_verField       setStringValue:[NSString stringWithFormat:@"Release %@", release]];
        [_copyrightField setStringValue:info[@"Copyright"] ?: @""];
        [self _showWindowFirstTime:_infoPanel autosaveName:@"GrabInfoPanel"];
        return;
    }
    [_infoPanel makeKeyAndOrderFront:nil];
}

- (IBAction)showInspectorPanel:(id)sender {
    if (!_inspectorPanel) {
        if (![NSBundle loadNibNamed:@"InspectorPanel" owner:self]) return;
        [self _refreshInspectorFields];
        [self _showWindowFirstTime:_inspectorPanel autosaveName:@"GrabInspectorPanel"];
        return;
    }
    [self _refreshInspectorFields];
    [_inspectorPanel makeKeyAndOrderFront:nil];
}

- (IBAction)showCursorPanel:(id)sender {
    if (!_cursorPanel) {
        [self _createCursorPanel];
        [self _syncCursorMatrixSelection];
        [self _showWindowFirstTime:_cursorPanel autosaveName:@"GrabCursorPanel"];
        return;
    }
    [self _syncCursorMatrixSelection];
    [_cursorPanel makeKeyAndOrderFront:nil];
}

- (IBAction)changeCursor:(id)sender {
    NSMatrix *matrix = (NSMatrix *)sender;
    GrabCursorType selected = (GrabCursorType)[[matrix selectedCell] tag];
    [GrabPreferencesManager sharedManager].cursorType = selected;
    [[GrabPreferencesManager sharedManager] synchronize];
}

// ── Private cursor-panel helpers ─────────────────────────────────────────────
//
// Layout: 2 rows × 5 columns. Fixed panel size: 209 × 74 px.
// Row 0: [empty/default], Arrow, Ibeam, Wait, Help
// Row 1: Copy, Link, Generic, Place, Pointer
//
// The empty cell (tag=GrabCursorTypeCameraPointer=0) is top-left.
// Selecting it restores the default CameraPointer.tiff from the main bundle.

static const struct { __unsafe_unretained NSString * _Nullable tiff; GrabCursorType type; }
kCursorLayout[2][5] = {
    {
        { nil,              GrabCursorTypeCameraPointer  },  // empty = default
        { @"ArrowCursor",   GrabCursorTypeArrowCursor    },
        { @"IbeamCursor",   GrabCursorTypeIbeamCursor    },
        { @"WaitCursor",    GrabCursorTypeWaitCursor     },
        { @"HelpCursor",    GrabCursorTypeHelpCursor     },
    },
    {
        { @"copyCursor",    GrabCursorTypeCopyCursor     },
        { @"linkCursor",    GrabCursorTypeLinkCursor     },
        { @"genericCursor", GrabCursorTypeGenericCursor  },
        { @"PlaceCursor",   GrabCursorTypePlaceCursor    },
        { @"PointerCursor", GrabCursorTypePointerCursor  },
    },
};

/// Builds the Choose Cursor panel entirely in code.
/// Fixed size 209×74, 2 rows × 5 columns of compact flat radio cells (33×24).
- (void)_createCursorPanel {
    const NSInteger rows = 2, cols = 5;
    const CGFloat cellW = 33.0, cellH = 24.0;
    // Panel content area derived from fixed total size 209×74.
    // Title bar in GNUstep is ~22px, so content height = 74 - 22 = 52.
    // We center the matrix (2×24=48) with 2px padding top/bottom.
    const CGFloat panelW = 209.0, panelH = 74.0;
    const CGFloat matW   = cols * cellW;  // 165
    const CGFloat matH   = rows * cellH; // 48

    // ── Panel ────────────────────────────────────────────────────────────────
    NSPanel *panel = [[NSPanel alloc]
        initWithContentRect:NSMakeRect(0, 0, panelW, panelH)
                  styleMask:NSTitledWindowMask | NSClosableWindowMask
                    backing:NSBackingStoreBuffered
                      defer:NO];
    [panel setTitle:NSLocalizedString(@"Choose Cursor", @"Panel title")];
    [panel setFloatingPanel:YES];
    [panel setBecomesKeyOnlyIfNeeded:YES];

    // ── Gorm bundle path for TIFF images ─────────────────────────────────────
    NSString *gormPath = [[NSBundle mainBundle] pathForResource:@"CursorTypes"
                                                         ofType:@"gorm"];

    // ── Prototype cell — flat, no bezel, border visible only when selected ───
    NSButtonCell *proto = [[NSButtonCell alloc] init];
    [proto setButtonType:NSPushOnPushOffButton];
    [proto setImagePosition:NSImageOnly];
    [proto setTitle:@""];
    [proto setBordered:YES];
    [proto setBezelStyle:NSNeXTBezelStyle];
    [proto setShowsStateBy:NSContentsCellMask | NSChangeBackgroundCellMask];
    [proto setHighlightsBy:NSContentsCellMask | NSChangeBackgroundCellMask];
    [proto setFocusRingType:NSFocusRingTypeNone];

    // ── NSMatrix in radio mode ────────────────────────────────────────────────
    NSMatrix *matrix = [[NSMatrix alloc]
        initWithFrame:NSMakeRect(23.0, 13.0, matW, matH)
                 mode:NSRadioModeMatrix
            prototype:proto
         numberOfRows:rows
      numberOfColumns:cols];
    [matrix setCellSize:NSMakeSize(cellW, cellH)];
    [matrix setIntercellSpacing:NSMakeSize(0, 0)];
    [matrix setTarget:self];
    [matrix setAction:@selector(changeCursor:)];
    [matrix setFocusRingType:NSFocusRingTypeNone];

    // ── Populate cells ────────────────────────────────────────────────────────
    for (NSInteger r = 0; r < rows; r++) {
        for (NSInteger c = 0; c < cols; c++) {
            NSButtonCell *cell  = [matrix cellAtRow:r column:c];
            NSString     *tiff  = kCursorLayout[r][c].tiff;
            GrabCursorType type = kCursorLayout[r][c].type;

            [cell setTag:(NSInteger)type];
            [cell setButtonType:NSPushOnPushOffButton];
            [cell setImagePosition:NSImageOnly];
            [cell setTitle:@""];
            [cell setBordered:YES];
            [cell setBezelStyle:NSNeXTBezelStyle];
            [cell setShowsStateBy:NSContentsCellMask | NSChangeBackgroundCellMask];
            [cell setHighlightsBy:NSContentsCellMask | NSChangeBackgroundCellMask];
            [cell setFocusRingType:NSFocusRingTypeNone];

            if (tiff && gormPath) {
                NSString *path = [[gormPath stringByAppendingPathComponent:tiff]
                                  stringByAppendingPathExtension:@"tiff"];
                NSImage *img = [[NSImage alloc] initWithContentsOfFile:path];
                if (img) {
                    [cell setImage:img];
                    [cell setAlternateImage:img];
                }
            }
            // nil tiff = empty button (default CameraPointer) — no image set.
        }
    }

    [[panel contentView] addSubview:matrix];
    _cursorPanel = panel;
    _cursorMatrix = matrix;
}

/// Selects the matrix cell whose tag matches the saved cursorType.
- (void)_syncCursorMatrixSelection {
    if (!_cursorMatrix) return;
    NSInteger current = (NSInteger)[GrabPreferencesManager sharedManager].cursorType;
    NSInteger rows = [_cursorMatrix numberOfRows];
    NSInteger cols = [_cursorMatrix numberOfColumns];
    for (NSInteger r = 0; r < rows; r++) {
        for (NSInteger c = 0; c < cols; c++) {
            if ([[_cursorMatrix cellAtRow:r column:c] tag] == current) {
                [_cursorMatrix selectCellAtRow:r column:c];
                return;
            }
        }
    }
    // Fallback: select the empty/default cell.
    [_cursorMatrix selectCellAtRow:0 column:0];
}




// ── Menu validation ───────────────────────────────────────────────────────────

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    BOOL hasImage = [[GrabSession sharedSession] hasImage];
    if (action == @selector(printImage:)         ||
        action == @selector(copyImage:)          ||
        action == @selector(saveImage:)          ||
        action == @selector(showInspectorPanel:)) {
        return hasImage;
    }
    return YES;
}

// ── Private helpers ───────────────────────────────────────────────────────────

/// Shows `window` for the first time, centered on screen.
/// Assigns `autosaveName` so AppKit/GNUstep persists the position in
/// NSUserDefaults automatically — subsequent opens restore the last position.
/// Centers before assigning the autosave name so GNUstep cannot override the
/// centered position with a previously saved frame.
- (void)_showWindowFirstTime:(NSWindow *)window autosaveName:(NSString *)name {
    // Check for a saved position BEFORE setting autosaveName.
    // Once setFrameAutosaveName: is called, GNUstep may immediately apply
    // the saved frame (including 0,0 from a previous bad save).
    NSString *key = [NSString stringWithFormat:@"NSWindow Frame %@", name];
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:key];

    // Center first, then assign the autosave name so GNUstep does not
    // override our centered position with a stale/zero saved frame.
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect windowFrame = [window frame];
    CGFloat cx = screenFrame.origin.x +
                 (screenFrame.size.width  - windowFrame.size.width)  / 2.0;
    CGFloat cy = screenFrame.origin.y +
                 (screenFrame.size.height - windowFrame.size.height) / 2.0;

    if (!saved || saved.length == 0) {
        // No saved position — center the window.
        [window setFrameOrigin:NSMakePoint(cx, cy)];
    }

    // Assign autosave name after positioning so future moves are tracked.
    [window setFrameAutosaveName:name];

    // If the restored position is off-screen, re-center.
    NSRect restored = [window frame];
    if (!NSContainsRect(screenFrame, restored)) {
        [window setFrameOrigin:NSMakePoint(cx, cy)];
    }

    [window makeKeyAndOrderFront:nil];
}

- (void)_updateAudioMenuTitle {
    BOOL enabled = [GrabPreferencesManager sharedManager].audioEnabled;
    NSString *title = enabled
        ? NSLocalizedString(@"Turn Sound Off", @"")
        : NSLocalizedString(@"Turn Sound On",  @"");
    [self.audioMenuItem setTitle:title];
}

- (void)_refreshInspectorFields {
    NSImage *image = [GrabSession sharedSession].capturedImage;
    if (!image) {
        [_widthField    setStringValue:@"0000"];
        [_heightField   setStringValue:@"0000"];
        [_depthField    setStringValue:@"0000"];
        [_sizeField     setStringValue:@"0"];
        [_alphaCheckbox setState:NSControlStateValueOff];
        return;
    }
    NSBitmapImageRep *bm = [[image representations] firstObject];
    if (!bm) {
        NSLog(@"GrabController: captured image has no bitmap representation.");
        return;
    }
    [_widthField  setStringValue:
        [NSString stringWithFormat:@"%04ld", (long)bm.pixelsWide]];
    [_heightField setStringValue:
        [NSString stringWithFormat:@"%04ld", (long)bm.pixelsHigh]];
    [_depthField  setStringValue:
        [NSString stringWithFormat:@"%04ld", (long)bm.bitsPerPixel]];
    [_sizeField   setStringValue:
        [NSString stringWithFormat:@"%lu",
         (unsigned long)[[image TIFFRepresentation] length]]];
    [_alphaCheckbox setState:bm.hasAlpha
                            ? NSControlStateValueOn
                            : NSControlStateValueOff];
}

// ── Services provider ─────────────────────────────────────────────────────────

- (void)_serviceCaptureDone:(NSNotification *)note {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:[note name]
                                                  object:nil];
    NSImage *image = [GrabSession sharedSession].capturedImage;
    NSPasteboard *pb = _pendingServicePasteboard;
    self.pendingServicePasteboard = nil;

    if (!image || !pb) return;
    NSData *tiff = [image TIFFRepresentation];
    if (tiff) {
        [pb declareTypes:@[@"NSTIFFPboardType"] owner:nil];
        [pb setData:tiff forType:@"NSTIFFPboardType"];
    }
}

- (void)_startServiceCapture:(NSPasteboard *)pb {
    self.pendingServicePasteboard = pb;
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(_serviceCaptureDone:)
               name:GrabSessionDidUpdateImageNotification
             object:nil];
}

- (void)grabScreen:(NSPasteboard * _Nonnull)pb
          userData:(NSString * _Nullable)ud
             error:(NSString * _Nullable __autoreleasing * _Nullable)err {
    [self _startServiceCapture:pb];
    [[GrabCaptureManager sharedManager] captureFullScreenFromMenuOrigin:NSZeroPoint];
}

- (void)grabSelection:(NSPasteboard * _Nonnull)pb
             userData:(NSString * _Nullable)ud
                error:(NSString * _Nullable __autoreleasing * _Nullable)err {
    [self _startServiceCapture:pb];
    [[GrabCaptureManager sharedManager] captureScreenSection];
}

- (void)grabWindow:(NSPasteboard * _Nonnull)pb
          userData:(NSString * _Nullable)ud
             error:(NSString * _Nullable __autoreleasing * _Nullable)err {
    [self _startServiceCapture:pb];
    [[GrabCaptureManager sharedManager] captureWindowFromMenuOrigin:NSZeroPoint];
}

@end
