# Changelog — Grab

---

## [0.9.0] — 2026-04-25

1. **Panel fly-in animation** — When selecting Window, Screen, or Timed
   Screen, the floating icon panel flies from the cursor position to its
   final corner destination in 0.2 seconds using linear interpolation.

2. **Choose Cursor panel** — New programmatic panel with 10 selectable
   cursors (Arrow, Ibeam, Wait, Help, Copy, Link, Generic, Place, Pointer,
   and the default CameraPointer). The selected cursor is used during
   capture and persisted in `NSUserDefaults`.

3. **Audio OpenShutter / CloseShutter** — `OpenShutter` blocks until
   complete before the result window appears; `CloseShutter` plays
   asynchronously as the window opens. Applied to all four capture modes.

---

## [0.8.0] — 2026-04-23

4. **MRC → ARC migration** — Full migration from Manual Reference Counting
   to Automatic Reference Counting. All `retain`/`release`/`autorelease`
   calls removed. Singletons migrated to `dispatch_once`. Fixed a
   deterministic crash caused by AppKit calls on background capture threads.

---

## [0.7.9] — 2026-04-19

5. **OpenStep-style two-phase capture animation** — Window and Screen
   capture replicate the original OpenStep flow: floating panel →
   click panel → `CameraPointer` cursor + motion-driven eye animation →
   click anywhere → flash + capture.

---

## [0.7.7] — 2026-04-19

6. **Selection capture rebuilt** — L-shaped `SelectCursor.tiff` cursor,
   coordinate label next to the cursor (X,Y when free / W,H when dragging),
   and background restore via `XGetImage` eliminating color artifacts.

---

## [0.7.4] — 2026-04-17

7. **English and Spanish localization** — Full bilingual support for the
   main menu and all runtime strings via `Localizable.strings`.

---

## [0.7.2] — 2026-04-15

8. **Fixed crash on launch from NextSpace Workspace** — Resolved `SIGABRT`
   caused by compiler/runtime mismatch. Migrated to `clang` with
   `-fobjc-runtime=gnustep-2.2`.

---

## [0.7.0] — 2026-04-14

9. **Native NextSpace save dialog and result window** — `NXTSavePanel` for
   saving captured images; `GrabImageWindow` with Save / Don't Save /
   Cancel close dialog.

---

## [0.6.0] — 2026-04-13

10. **Full modularization** — Monolithic `GrabController` split into eight
    focused classes: `GrabPreferencesManager`, `GrabAudioManager`,
    `GrabSession`, `GrabResourceManager`, `GrabCaptureManager`,
    `GrabImageProcessor`, `GrabAnimationController`, and `GrabImageWindow`.

---

## [0.3.1b] — original release

- Original single-file architecture by Andres Morales (armm77).
