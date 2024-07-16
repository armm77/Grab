/*
   Project: Grab
   Author: Andres Morales
   Created: 2021-05-12 16:14:10 +0300 by armm77

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "GrabController.h"

int main(int argc, const char * argv[]) 
{
    NSString *homeDirectory = NSHomeDirectory();
    NSString *folderName = @"Screenshots";
        
    NSString *folderPath = [homeDirectory stringByAppendingPathComponent:folderName];
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
        
    if (![fileManager fileExistsAtPath:folderPath isDirectory:&isDir]) {
        NSError *error = nil;
        if ([fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Folder created in %@", folderPath);
        } else {
            NSLog(@"Error creating folder: %@", error.localizedDescription);
        }
    } else if (isDir) {
              NSLog(@"The folder already exists in %@", folderPath);
           } else {
              NSLog(@"A file with the same name as the folder already exists in %@", folderPath);
    }
    return NSApplicationMain (argc, argv);
}

