# Grab 0.9.1

Screen capture application for NEXTSPACE on GNU/Linux (X11).
Modular refactoring: clean architecture, ARC, NEXTSPACE integration.

This application is intended to be a recreation of the excellent and original **Grab** application created by **Keith Bernstein** and developed for the [NeXTSTEP](https://en.wikipedia.org/wiki/NeXTSTEP)/[OPENSTEP](https://en.wikipedia.org/wiki/OpenStep).

---

### Capture Options:
* Full screen.
* Full screen with 10 second timer.
* Specific window.
* Screen selection portion.

---

## Platform:
* GNU/Linux (X11)

---

## Requirements

| Dependency | Version | Notes |
|---|---|---|
| SoundKit Back | 0.1 | NEXTSPACE |
| DesktopKit | 0.6 | NEXTSPACE — `NXTSavePanel`, `NXTRunAlertPanel` |
| SystemKit | 0.3 | NEXTSPACE — required at link time |
| libobjc2 | ≥ 2.0 | ARC runtime (`-fobjc-arc`, `dispatch_once`) |
| libdispatch | 6.0.2 | GCD — `dispatch_once`, `dispatch_async`, main queue |
| X11 / libX11 | 21.1.21 | Screen capture |
| libXcursor | 1.2.3 | Custom cursors |

---

## Building

```sh
# Source the NEXTSPACE environment
. /usr/NextSpace/Makefiles/GNUstep.sh

# Build — must use clang (same compiler as all NEXTSPACE apps)
make CC=clang

# Install to /Applications
sudo -E make install
```

### Launching

```sh
# From terminal
openapp Grab.app

# From NEXTSPACE Workspace — double-click works correctly
```

> Running the binary directly (`./Grab.app/Grab`) is not supported. GNUstep
> requires the `.app` bundle so that `NSBundle mainBundle` resolves resources
> correctly.

---

## Architecture

```
Grab/
├── Grab_main.m                  Entry point (NSApplicationMain)
│
├── Controllers/
│   ├── GrabController           Application delegate · UI coordinator.
│   │                            Owns NIB outlets, dispatches IBActions.
│   │                            No X11, no I/O, no preferences logic.
│   └── GrabAnimationController  Floating NSPanel icon + animation timers.
│                                Drives blinking-eye and pie-piece countdown.
│
├── Managers/
│   ├── GrabPreferencesManager   NSUserDefaults wrapper (singleton).
│   │                            Keys: audio enabled, timer duration,
│   │                            cursor type.
│   ├── GrabAudioManager         Sound playback (singleton).
│   ├── GrabSession              Current capture state (singleton).
│   │                            Holds captured NSImage; posts
│   │                            GrabSessionDidUpdateImageNotification.
│   └── GrabResourceManager      .tiff asset loader + compositor (singleton).
│
├── Capture/
│   ├── GrabCaptureManager       Capture orchestrator (singleton).
│   │                            Spawns NSThreads, runs X11 event loops,
│   │                            dispatches UI work to main queue via GCD,
│   │                            writes to GrabSession, calls GrabDraw.
│   └── GrabImageProcessor       Stateless X11 → NSImage converter.
│                                XImage → NSBitmapImageRep → NSImage.
│
├── Views/
│   ├── GrabDraw                 Stateless display + save layer.
│   │                            Creates GrabImageWindow, manages window
│   │                            lifetime via _openWindows array,
│   │                            handles NXTSavePanel + NSData encoding.
│   ├── GrabImageWindow          NSWindow subclass — close button delegate.
│   │                            Shows NXTRunAlertPanel (Save / Don't Save
│   │                            / Cancel) on window close.
│   │                            Calls GrabDraw_releaseWindow on close.
│   └── DraggableImageView       NSImageView with click-drag pan.
│                                Cursor managed via NSTimer polling.
│
├── English.lproj/
│   ├── Grab.gorm                Main menu (English)
│   └── Localizable.strings      Runtime strings
│
├── Spanish.lproj/
│   ├── Grab.gorm                Main menu (Spanish)
│   └── Localizable.strings      Runtime strings
│
└── Resources/                   .gorm, .tiff, .wav, .plist assets.
```

---

## Technical notes

**Memory management — ARC**
This project uses Automatic Reference Counting (`-fobjc-arc`) targeting
libobjc2 ≥ 2.0. All `retain`/`release`/`autorelease` calls are inserted
by the compiler. Background threads use `@autoreleasepool { }` blocks.
See `CHANGELOG.md` [0.8.0] for full migration details.

**Singletons**
All singletons use `dispatch_once_t`. This is thread-safe, executes exactly
once, and has zero overhead after the first call.

**Threading**
Background captures use `NSThread detachNewThreadSelector:`. Each thread
is wrapped in `@autoreleasepool { }`. All AppKit work (window creation,
session update) is dispatched to the main thread via
`dispatch_async(dispatch_get_main_queue(), ^{ ... })` after `XCloseDisplay`.

**Window lifetime under ARC**
`GrabDraw` retains every open result window in a static `NSMutableArray`
(`_openWindows`). With `setReleasedWhenClosed:NO` (required under ARC to
prevent double-free), windows have no implicit AppKit owner; the array
provides the strong reference until `GrabDraw_releaseWindow` is called
from `GrabImageWindow -windowShouldClose:`.

**Workspace launch / DISPLAY**
When launched by double-click from NEXTSPACE Workspace, `$DISPLAY` may not
be inherited. `GrabController -applicationWillFinishLaunching:` reads
`GSDisplayName` from `NSUserDefaults` and injects it via `setenv()` before
any X11 call. `GNUmakefile.postamble` patches `NSMainNibFile` in
`Info-gnustep.plist` if gnustep-make leaves it empty.

**DesktopKit integration**
`GrabDraw` uses `NXTSavePanel` for the save dialog. `GrabImageWindow` uses
`NXTRunAlertPanel` for the close confirmation dialog. Both are linked
directly via `-lDesktopKit` in `GNUmakefile.preamble`.

---

## Capture flow — full-screen example

```
User clicks "Screen" in the Grab menu
        │
        ▼
GrabController -captureFullScreen:
        │  loads resources via GrabResourceManager
        ▼
GrabCaptureManager -captureFullScreenFromMenuOrigin:
        │  animates icon panel from menu origin (GrabAnimationController)
        │  waits for user click on panel
        ▼
User clicks the icon panel button
        │
        ▼
GrabCaptureManager -_activateFullScreenCursor  [main thread]
        │  starts motion-driven eye animation
        │  detaches _fullScreenCaptureThread
        ▼
GrabCaptureManager -_fullScreenCaptureThread  [NSThread]
        │  @autoreleasepool
        │  XOpenDisplay → XGrabPointer → wait ButtonPress
        │  XUngrabPointer · XFreeCursor
        │  shows CameraEyeFlash · sleeps 0.8s · closes panel
        │  XGetWindowAttributes → XGetImage
        │  GrabImageProcessor +captureRect:display:rootWindow: → NSImage
        │  XCloseDisplay
        │  plays OpenShutter sound (blocks until complete)
        │  dispatch_async(main_queue, ^{
        │      GrabSession -setCapturedImage:
        │      GrabDraw +showImage:           ← main thread only
        │      plays CloseShutter (async, non-blocking)
        │  })
        ▼
Result window (GrabImageWindow) appears with the captured image
```

---

## Localization

Grab supports **English** and **Spanish**. The active language is determined
by the system setting (`NSLanguages`).

### Testing a specific language

```sh
# Switch to Spanish
defaults write Grab NSLanguages '(Spanish)'

# Restore to English
defaults write Grab NSLanguages '(English)'
```

### Adding a new language

1. Copy `English.lproj/` to `NewLang.lproj/`
2. Translate `Localizable.strings`
3. Create a localized `Grab.gorm` with translated menu titles
4. Add the language name to `Grab_LANGUAGES` in `GNUmakefile`

---

## Acknowledgments:

* [GNUstep](https://github.com/gnustep): to all the [developers](https://github.com/orgs/gnustep/people) who have contributed to the project and to others who do not appear in the list of members but have still contributed.
* [NEXTSPACE](https://github.com/trunkmaster/nextspace): to [Sergii Stonian](https://github.com/trunkmaster) for his project and recreating the desktop again.

### Examples

![Selection](https://github.com/user-attachments/assets/092957da-948d-40d9-8957-0234be173ebf)

![Window](https://github.com/user-attachments/assets/79dcf2aa-10c9-4d93-ab47-8ba46468b55f)

![Screen](https://github.com/user-attachments/assets/87a1457d-97bb-4f09-8425-e511f194adae)

![Timed Screen](https://github.com/user-attachments/assets/ff5a46fa-ce96-431b-9cdc-b0604fdca9e6)

---

## License

GNU General Public License v2 or later. See `LICENSE`.
