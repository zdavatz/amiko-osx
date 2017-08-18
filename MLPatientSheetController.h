/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 21/06/2017.
 
 This file is part of AmiKo for OSX.
 
 AmiKo for OSX is free software: you can redistribute it and/or modify
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

@interface MLPatientSheetController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
    @private
    IBOutlet NSWindow *mPanel;
    IBOutlet NSTableView *mTableView;
    IBOutlet NSTextField *mNumPatients;
    IBOutlet NSTextField *mNotification;
    IBOutlet NSSearchField *mSearchKey;
    IBOutlet NSTextField *mFamilyName;
    IBOutlet NSTextField *mGivenName;
    IBOutlet NSTextField *mBirthDate;
    IBOutlet NSTextField *mWeight_kg;
    IBOutlet NSTextField *mHeight_cm;
    IBOutlet NSTextField *mZipCode;
    IBOutlet NSTextField *mPostalAddress;
    IBOutlet NSTextField *mCity;
    IBOutlet NSTextField *mCountry;
    IBOutlet NSTextField *mPhone;
    IBOutlet NSTextField *mEmail;
    IBOutlet NSButton *mFemaleButton;
    IBOutlet NSButton *mMaleButton;
}

- (IBAction) onSelectFemale:(id)sender;
- (IBAction) onSelectMale:(id)sender;
- (IBAction) onCancel:(id)sender;
- (IBAction) onSavePatient:(id)sender;
- (IBAction) onNewPatient:(id)sender;
- (IBAction) onDeletePatient:(id)sender;
- (IBAction) onShowContacts:(id)sender;
- (IBAction) onSelectPatient:(id)sender;

- (NSString *) retrievePatientAsString;
- (NSString *) retrievePatientAsString:(NSString *)searchKey;
- (void) show:(NSWindow *)window;
- (void) remove;

@end
