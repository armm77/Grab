#
# GNUmakefile
#
ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif
ifeq ($(GNUSTEP_MAKEFILES),)
 $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
PACKAGE_NAME = Grab
APP_NAME = Grab
Grab_APPLICATION_ICON = Grab.App.tiff

#
# Resource files
#
Grab_RESOURCE_FILES = \
Resources/Grab.gorm \
Resources/InfoPanel.gorm \
Resources/InspectorPanel.gorm \
Resources/CursorTypes.gorm \
Resources/CameraNormal.tiff \
Resources/ArrowCursor.tiff \
Resources/CameraEye1.tiff \
Resources/CameraEye2.tiff \
Resources/CameraEye3.tiff \
Resources/CameraEyeFlash.tiff \
Resources/CameraPointer.tiff \
Resources/CameraWatch.tiff \
Resources/CameraWatchFlash.tiff \
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
Resources/Grab.App.tiff

#
# Header files
#
Grab_HEADER_FILES = \
GrabController.h \
GrabView.h \
stb_image_write.h

#
# Class files
#
Grab_OBJC_FILES = \
GrabController.m \
GrabView.m

#
# Other sources
#
Grab_OBJC_FILES += \
Grab_main.m

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
