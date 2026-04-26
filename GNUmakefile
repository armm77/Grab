#
# GNUmakefile — Grab Application
# ARC build (Automatic Reference Counting)
#
# Requires: gnustep-make 2.x, libobjc2 >= 2.0, libX11, libXcomposite,
#           libdispatch (libkqueue on Linux)
#
# Build:        make
# Install:      make install
# Clean:        make clean
#

GNUSTEP_INSTALLATION_DOMAIN = LOCAL

include $(GNUSTEP_MAKEFILES)/common.make

# ── App metadata ───────────────────────────────────────────────────────────────
VERSION      = 0.9.0
PACKAGE_NAME = Grab
APP_NAME     = Grab

Grab_APPLICATION_ICON = Grab.App.tiff

Grab_MAIN_MODEL_FILE = Grab.gorm
Grab_PRINCIPAL_CLASS = NSApplication


# ── Header files ───────────────────────────────────────────────────────────────
Grab_HEADER_FILES = \
	Controllers/GrabController.h \
	Controllers/GrabAnimationController.h \
	Capture/GrabCaptureManager+Private.h \
	Managers/GrabPreferencesManager.h \
	Managers/GrabAudioManager.h \
	Managers/GrabSession.h \
	Managers/GrabResourceManager.h \
	Capture/GrabCaptureManager.h \
	Capture/GrabImageProcessor.h \
	Views/GrabDraw.h \
	Views/GrabImageWindow.h \
	Views/DraggableImageView.h

# ── Objective-C source files ───────────────────────────────────────────────────
Grab_OBJC_FILES = \
	Grab_main.m \
	Controllers/GrabController.m \
	Controllers/GrabAnimationController.m \
	Managers/GrabPreferencesManager.m \
	Managers/GrabAudioManager.m \
	Managers/GrabSession.m \
	Managers/GrabResourceManager.m \
	Capture/GrabCaptureManager.m \
	Capture/GrabImageProcessor.m \
	Views/GrabDraw.m \
	Views/GrabImageWindow.m \
	Views/DraggableImageView.m

# ── Resource files ─────────────────────────────────────────────────────────────
Grab_RESOURCE_FILES = \
	Resources/GrabInfo.plist \
	Resources/InfoPanel.gorm \
	Resources/InspectorPanel.gorm \
	Resources/CursorTypes.gorm \
	Resources/HelpPanel.gorm \
	Resources/CameraNormal.tiff \
	Resources/ArrowCursor.tiff \
	Resources/CameraEye1.tiff \
	Resources/CameraEye2.tiff \
	Resources/CameraEye3.tiff \
	Resources/CameraEyeFlash.tiff \
	Resources/CameraPointer.tiff \
	Resources/CameraWatch.tiff \
	Resources/CameraWatchFlash.tiff \
	Resources/common_Tile.tiff \
	Resources/copyCursor.tiff \
	Resources/genericCursor.tiff \
	Resources/HelpCursor.tiff \
	Resources/IbeamCursor.tiff \
	Resources/linkCursor.tiff \
	Resources/PiePieces.tiff \
	Resources/PlaceCursor.tiff \
	Resources/PointerCursor.tiff \
	Resources/SelectCursor.tiff \
	Resources/WaitCursor.tiff \
	Resources/Grab.App.tiff \
	Resources/HelpPanel.rtf \
	Resources/CloseShutter.wav \
	Resources/OpenShutter.wav \
	Resources/TimerDone.wav \

# ── Localized resource files ───────────────────────────────────────────────────
Grab_LOCALIZED_RESOURCE_FILES = Localizable.strings Grab.gorm
Grab_LANGUAGES = English Spanish

# ── gnustep-make rules ─────────────────────────────────────────────────────────
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
