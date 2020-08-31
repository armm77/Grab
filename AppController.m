/*
   Project: Grab

   Author: Andres Morales

   Created: 2020-07-04 16:14:10 +0300 by armm77

   Application Controller
*/

#import "AppController.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

@implementation AppController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */

  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init
{
  if ((self = [super init]))
    {
    }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
// Uncomment if your application is Renaissance-based
//  [NSBundle loadGSMarkupNamed: @"Main" owner: self];
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application: (NSApplication *)application
            openFile: (NSString *)fileName
{
  return NO;
}

- (void) showInfoPanel: (id)sender
{
 if (!infoPanel)
   {
     if (![NSBundle loadNibNamed:@"InfoPanel" owner:self])
       {
         NSLog (@"Faild to load InfoPanel.gorm");
         return;
       }
     [infoPanel center];
   }
 [infoPanel makeKeyAndOrderFront:nil];
}

- (void) showCursorPanel: (id)sender
{
 if (!cursorPanel)
   {
     if (![NSBundle loadNibNamed:@"CursorTypes" owner:self])
       {
         NSLog (@"Faild to load CursorTypes.gorm");
         return;
       }
     [cursorPanel center];
   }
 [cursorPanel makeKeyAndOrderFront:nil];
}

- (void) showInspectorPanel: (id)sender
{
 if (!inspectorPanel)
   {
     if (![NSBundle loadNibNamed:@"InspectorPanel" owner:self])
       {
         NSLog (@"Faild to load InspectorPanel.gorm");
         return;
       }
     [inspectorPanel center];
   }
 [inspectorPanel makeKeyAndOrderFront:nil];
}

- (void) captureSelection: (id)sender
{
  return;
}

- (void) captureWindow: (id)sender
{
  NSLog(@"Entering window capture.");

  NSLog(@"Leaving window capture.");
}


- (void) captureScreen
{
  Display *display = XOpenDisplay(NULL);
  Window root = DefaultRootWindow(display);
  XWindowAttributes gwa;

  XGetWindowAttributes(display, root, &gwa);
  int width = gwa.width;
  int height = gwa.height;

  XImage *image = XGetImage(display,root, 0, 0, width, height, AllPlanes, ZPixmap);
  [self savaAsImage:image];

  XCloseDisplay(display);
  XFree(image);
}

-(void)updateCountDownTime
{
  NSLog (@"Timer:%02d",totalSeconds);
  if (totalSeconds != 1) {
     totalSeconds -= 1;
  } else {
     [self captureScreen];
     [_timer invalidate];
  }
}

- (void) captureTimedScreen: (id)sender
{
  totalSeconds = 10;
  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
  selector:@selector(updateCountDownTime) userInfo:nil repeats:YES];
}

- (void) savaAsImage: (XImage *)image
{
  char *rgb = malloc(image->width * image->height * 3);

  for(int i = 0, j = 0; i <  image->width * image->height * 4; i = i + 4){
     rgb[j] = image->data[i+2];
     rgb[j+1] = image->data[i+1];
     rgb[j+2] = image->data[i];
     j = j + 3;
  }

  int result = stbi_write_png("CaptureScreen.png", image->width, image->height, 3, rgb, image->width *  3);
  NSLog(@"Capture Screen %d\n", result);
}

/*
- (void) saveAsPngWithName:(NSString*) fileName
{
    // Cache the reduced image
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    [imageData writeToFile:fileName atomically:NO];
}
*/

@end
