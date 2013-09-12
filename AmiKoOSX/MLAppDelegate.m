/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
 This file is part of AMiKoOSX.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLAppDelegate.h"
#import "MLMainWindowController.h"

@interface MLAppDelegate()
// @property (nonatomic, strong) IBOutlet MLMasterViewController *masterViewController;
@end

@implementation MLAppDelegate
{
    float m_alpha;
    float m_delta;
}

// It is possible to auto-synthesize the following properties
@synthesize window;

/*
- (void) awakeFromNib
{
    if (!mainWindowController)
        mainWindowController = [[MLMainWindowController alloc] init];
    
    [mainWindowController showWindow:nil];
}
*/

- (void) applicationWillFinishLaunching:(NSNotification *)notification
{
    // Solution 1: launch splashscreen before application starts
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    m_alpha = 1.0;
    m_delta = 0.01;
    
    [NSApp activateIgnoringOtherApps:YES];

    [window center];
    [window makeKeyAndOrderFront:self];
    [window setOrderedIndex:0];
    [window makeKeyAndOrderFront:self];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(fadeOutAndRemove)
                                   userInfo:nil
                                    repeats:NO];
}

- (void) fadeOutAndRemove
{
    if (m_alpha>0.05) {
        m_alpha -= m_delta;
        [[window contentView] setAlphaValue:m_alpha];
        
        [NSTimer scheduledTimerWithTimeInterval:0.02
                                         target:self
                                       selector:@selector(fadeOutAndRemove)
                                       userInfo:nil
                                        repeats:NO];
    } else {
        [window close];
        [self startMainWindow];
    }
}

- (void) startMainWindow
{
    if (!mainWindowController)
        mainWindowController = [[MLMainWindowController alloc] init];
    
    [mainWindowController showWindow:nil];
}


// @synthesize masterViewController;

/*
- (void) applicationDidFinishLaunching: (NSNotification *)aNotification
{
    // Create masterViewController
    // self.masterViewController = [[MLMasterViewController alloc] initWithNibName:@"MLMasterViewController" bundle:nil];
    self.masterViewController = [[MLMasterViewController alloc] init];
    
    // Add view controller to window's content view
    [self.window.contentView addSubview:self.masterViewController.view];
    
    // Makes sure that window can be resized
    [self.masterViewController.view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    // Set background color
    self.window.backgroundColor = NSColor.whiteColor;
    
    // Set frame
    self.masterViewController.view.frame = ((NSView*)self.window.contentView).bounds;
}
*/
 
@end
