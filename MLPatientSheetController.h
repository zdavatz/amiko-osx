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

#import "MLPatient.h"
#import "MLPatientDBAdapter.h"

@interface MLPatientSheetController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate>
{
@public
    MLPatientDBAdapter *mPatientDb; // public for access by category
    IBOutlet NSTableView *mTableView;

@private
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

@property (nonatomic, weak) IBOutlet NSWindow *mPanel;

- (IBAction) onSelectFemale:(id)sender;
- (IBAction) onSelectMale:(id)sender;
- (IBAction) onCancel:(id)sender;
- (IBAction) onSavePatient:(id)sender;
- (IBAction) onNewPatient:(id)sender;
- (IBAction) onDeletePatient:(id)sender;
- (IBAction) onShowContacts:(id)sender;
- (IBAction) onSelectPatient:(id)sender;

- (void) addPatient:(MLPatient *)patient;
- (void) setSelectedPatient:(MLPatient *)patient;
- (MLPatient *) retrievePatient;
- (MLPatient *) retrievePatientWithUniqueID:(NSString *)uniqueID;
- (BOOL) patientExistsWithID:(NSString *)uniqueID;
- (NSString *) retrievePatientAsString;
- (NSString *) retrievePatientAsString:(NSString *)searchKey;
- (void) show:(NSWindow *)window;
- (void) remove;
- (MLPatient *) getAllFields;
- (void) resetAllFields;
- (void) setAllFields:(MLPatient *)p;
- (MLPatient *) getContactAtRow:(NSInteger)row;

@end
