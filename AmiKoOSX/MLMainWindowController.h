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

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface MLMainWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet NSView *myView;
    IBOutlet NSView *mySplashScreen;
    IBOutlet NSToolbar *myToolbar;
    IBOutlet NSSearchField *mySearchField;
    IBOutlet NSTableView *myTableView;
    IBOutlet NSTableView *mySectionTitles;
    IBOutlet WebView *myWebView;
}

@property (nonatomic, retain) IBOutlet NSView *myView;
@property (nonatomic, retain) IBOutlet NSView *mySplashScreen;
@property (nonatomic, retain) IBOutlet NSToolbar *myToolbar;
@property (nonatomic, retain) IBOutlet NSSearchField *mySearchField;
@property (nonatomic, retain) IBOutlet NSTableView *myTableView;
@property (nonatomic, retain) IBOutlet NSTableView *mySectionTitles;

- (IBAction) tappedOnStar: (id)sender;
- (IBAction) searchNow: (id)sender;
- (IBAction) onButtonPressed: (id)sender;
- (IBAction) toolbarAction:(id)sender;
- (IBAction) printSearchResult:(id)sender;
- (IBAction) showAboutFile: (id)sender;

@end
