# Changelog — Grab

---

## [0.9.1] — 2026-05-25

11. **Fast pixel conversion in GrabImageProcessor** — Replaced the
    per-pixel `XGetPixel()` loop with direct pointer arithmetic over
    `xImage->data`. Channel byte offsets are derived dynamically from the
    `red_mask`/`green_mask`/`blue_mask` fields and adjusted for host byte
    order (`LSBFirst`/`MSBFirst`), so the fast path is correct on both
    little-endian (x86, aarch64) and big-endian hosts. Active when the
    `XImage` is `ZPixmap` format with 32 bpp and 8-bit channel masks
    (the universal case on modern X11 servers). Falls back to `XGetPixel()`
    automatically for any other format, logging the format details.
    Measured improvement: ~10–20× faster conversion on full-screen captures.

12. **Occluded window capture** — Window capture now correctly captures the
    target window's own pixels even when another window is stacked on top.
    Without an active compositor, `XCompositeNameWindowPixmap` is unavailable,
    so the previous `XGetImage` fallback returned on-screen pixels verbatim —
    including whatever was drawn on top. The new approach temporarily raises
    the target window to the top of the Z-order (`XRaiseWindow`), waits 50 ms
    for the server to flush exposure events and the window to repaint, captures
    with `XGetImage`, then restores the original stacking position precisely
    using `XConfigureWindow` with `CWSibling + Below`.
    The `XComposite` dependency has been removed from `GrabImageProcessor.h`.

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
