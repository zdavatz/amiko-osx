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

#import "MLPatientDBAdapter.h"
#import "MLPatientSheetController.h"
#import "MLMainWindowController.h"
#import "MLContacts.h"
#import "MLColors.h"

@implementation MLPatientSheetController
{
    @private
    MLPatientDBAdapter *mPatientDb;
    NSModalSession mModalSession;
    NSArray *mArrayOfPatients;
    NSMutableArray *mFilteredArrayOfPatients;
    BOOL mFemale;
    BOOL mABContactsVisible;    // These are the contacts in the address book
    BOOL mSearchFiltered;
}

- (id) init
{
    mArrayOfPatients = [[NSArray alloc] init];;
    mFilteredArrayOfPatients = [[NSMutableArray alloc] init];
    mSearchFiltered = FALSE;
    
    // Open patient DB
    mPatientDb = [[MLPatientDBAdapter alloc] init];
    if (![mPatientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        mPatientDb = nil;
    }
    
    mABContactsVisible = FALSE;
    
    if (self = [super init]) {
        return self;
    }    
    return nil;
}

- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (void) resetAllFields
{
    [mFamilyName setStringValue:@""];
    [mGivenName setStringValue:@""];
    [mBirthDate setStringValue:@""];
    [mCity setStringValue:@""];
    [mZipCode setStringValue:@""];
    [mWeight_kg setStringValue:@""];
    [mHeight_cm setStringValue:@""];
    [mPostalAddress setStringValue:@""];
    [mZipCode setStringValue:@""];
    [mCity setStringValue:@""];
    [mCountry setStringValue:@""];
    [mPhone setStringValue:@""];
    [mEmail setStringValue:@""];
    
    [mSavedLabel setStringValue:@""];
}

- (BOOL) validateFields:(MLPatient *)patient
{
    BOOL valid = TRUE;

    mFamilyName.backgroundColor = [NSColor whiteColor];
    mGivenName.backgroundColor = [NSColor whiteColor];
    mBirthDate.backgroundColor = [NSColor whiteColor];
    mPostalAddress.backgroundColor = [NSColor whiteColor];
    mCity.backgroundColor = [NSColor whiteColor];
    mZipCode.backgroundColor = [NSColor whiteColor];
    mGender.backgroundColor = [NSColor whiteColor];
    
    if ([self stringIsNilOrEmpty:patient.familyName]) {
        mFamilyName.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.givenName]) {
        mGivenName.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.birthDate]) {
        mBirthDate.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.city]) {
        mCity.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.zipCode]) {
        mZipCode.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.postalAddress]) {
        mPostalAddress.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.gender]) {
        mGender.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    
    return valid;
}

- (IBAction) onSearchDatabase:(id)sender
{
    NSString *searchKey = [mSearchKey stringValue];
    [mFilteredArrayOfPatients removeAllObjects];
    if (![self stringIsNilOrEmpty:searchKey]) {
        for (MLPatient *p in mArrayOfPatients) {
            if ([p.familyName hasPrefix:searchKey] || [p.givenName hasPrefix:searchKey]) {
                [mFilteredArrayOfPatients addObject:p];
            }
        }
    }
    if (mFilteredArrayOfPatients!=nil && [mFilteredArrayOfPatients count]>0) {
        mSearchFiltered = TRUE;
        [self setNumPatients:[mFilteredArrayOfPatients count]];
    } else {
        [self setNumPatients:[mArrayOfPatients count]];
        mSearchFiltered = FALSE;
    }
    [mTableView reloadData];
}

- (IBAction) onSelectGender:(id)sender
{
    if ([sender isKindOfClass:[NSButton class]]) {
        NSButton *radioButton = (NSButton*)sender;
        if (radioButton.tag==1)
            mFemale = TRUE;
        else if (radioButton.tag==2)
            mFemale = FALSE;
    }
}

- (IBAction) onCancel:(id)sender
{
    [self remove];
}

- (IBAction) onSavePatient:(id)sender
{
    if (mPatientDb!=nil) {
        long largetRowId = [mPatientDb getLargestRowId];

        MLPatient *patient = [[MLPatient alloc] init];
        patient.rowId = largetRowId + 1;
        patient.familyName = [mFamilyName stringValue];
        patient.givenName = [mGivenName stringValue];
        patient.birthDate = [mBirthDate stringValue];
        patient.city = [mCity stringValue];
        patient.zipCode = [mZipCode stringValue];
        patient.postalAddress = [mPostalAddress stringValue];
        patient.gender = mFemale ? @"woman" : @"man";
        patient.weightKg = [mWeight_kg intValue];
        patient.heightCm = [mHeight_cm intValue];
        patient.country = [mCountry stringValue];
        patient.phoneNumber = [mPhone stringValue];
        patient.emailAddress = [mEmail stringValue];
        
        if ([self validateFields:patient]) {
            [mPatientDb insertEntry:patient];
            [mSavedLabel setStringValue:@"Erfolgreich gespeichert!"];
        }
    }
}

- (IBAction) onNewPatient:(id)sender
{
    [self resetAllFields];
}

- (IBAction) onDeletePatient:(id)sender
{
    
}

- (IBAction) onShowContacts:(id)sender
{
    [self resetAllFields];

    if (mABContactsVisible==NO) {
        MLContacts *contacts = [[MLContacts alloc] init];
        // Retrieves contacts from address book
        mArrayOfPatients = [contacts getAllContacts];
        [mTableView reloadData];
        mABContactsVisible = YES;
    } else {
        // Retrieves contacts from local patient database
        mArrayOfPatients = [mPatientDb getAllPatients];
        [mTableView reloadData];
        mABContactsVisible = NO;
    }
    
    [self setNumPatients:[mArrayOfPatients count]];
}

- (void) show:(NSWindow *)window
{
    if (!mPanel) {
        // Load xib file
        [NSBundle loadNibNamed:@"MLPatientSheet" owner:self];
        // Set formatters
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [mWeight_kg setFormatter:formatter];
        [mHeight_cm setFormatter:formatter];
    }
    
    [NSApp beginSheet:mPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
   
    // Show the dialog
    [mPanel makeKeyAndOrderFront:self];
    
    // Start modal session
    mModalSession = [NSApp beginModalSessionForWindow:mPanel];
    [NSApp runModalSession:mModalSession];
    
    // Retrieves contacts from local patient database
    mArrayOfPatients = [mPatientDb getAllPatients];
    [mTableView reloadData];
    [self setNumPatients:[mArrayOfPatients count]];
    [mSavedLabel setStringValue:@""];
}

- (void) remove
{
    [NSApp endModalSession:mModalSession];
    [NSApp endSheet:mPanel];
    [mPanel orderOut:nil];
    [mPanel close];
}

- (void) setNumPatients:(NSInteger)numPatients
{
    if (numPatients>1) {
        [mNumPatients setStringValue:[NSString stringWithFormat:@"%ld Einträge", numPatients]];
    } else if (numPatients==1) {
        [mNumPatients setStringValue:@"1 Eintrag"];
    } else {
        [mNumPatients setStringValue:@"kein Eintrag"];
    }
}

/**
 - NSTableViewDataSource -
 */
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
    if (mSearchFiltered) {
        return [mFilteredArrayOfPatients count];
    }
    if (mArrayOfPatients!=nil) {
        return [mArrayOfPatients count];
    }
    return 0;
}

/**
 - NSTableViewDataDelegate -
 */
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (mArrayOfPatients!=nil) {
        MLPatient *p = nil;
        if (mSearchFiltered) {
            p = mFilteredArrayOfPatients[row];
        } else {
            p = mArrayOfPatients[row];
        }
        NSString *cellStr = [NSString stringWithFormat:@"%@ %@", p.familyName, p.givenName];
        cellView.textField.stringValue = cellStr;
        if (p.databaseType==eAddressBook) {
            cellView.textField.textColor = [NSColor grayColor];
        } else {
            cellView.textField.textColor = [NSColor blackColor];
        }
        return cellView;
    }
    return nil;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    if ([notification object] == mTableView) {
        NSInteger row = [[notification object] selectedRow];
        NSTableRowView *rowView = [mTableView rowViewAtRow:row makeIfNecessary:NO];
        MLPatient *p = mArrayOfPatients[row];
        if (p.familyName!=nil)
            [mFamilyName setStringValue:p.familyName];
        if (p.givenName!=nil)
            [mGivenName setStringValue:p.givenName];
        if (p.birthDate!=nil)
            [mBirthDate setStringValue:p.birthDate];
        if (p.city!=nil)
            [mCity setStringValue:p.city];
        if (p.zipCode!=nil)
            [mZipCode setStringValue:p.zipCode];
        if (p.weightKg>0)
            [mWeight_kg setStringValue:[NSString stringWithFormat:@"%d", p.weightKg]];
        if (p.heightCm>0)
            [mHeight_cm setStringValue:[NSString stringWithFormat:@"%d", p.heightCm]];
        if (p.phoneNumber!=nil)
            [mPhone setStringValue:p.phoneNumber];
        if (p.country!=nil)
            [mCity setStringValue:p.city];
        if (p.postalAddress!=nil)
            [mPostalAddress setStringValue:p.postalAddress];
        if (p.emailAddress!=nil)
            [mEmail setStringValue:p.emailAddress];
        if (p.phoneNumber!=nil)
            [mPhone setStringValue:p.phoneNumber];
        
        [rowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];

        [mSavedLabel setStringValue:@""];
    }
}

@end
