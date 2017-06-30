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
#import "MLColors.h"

@implementation MLPatientSheetController
{
    @private
    MLPatientDBAdapter *mPatientDb;
    NSModalSession mModalSession;
    NSArray *nameArray;
    BOOL mFemale;
}

- (id) init
{
    nameArray = [NSArray arrayWithObjects: @"Jill Valentine", @"Peter Griffin", @"Meg Griffin", @"Jack Lolwut",
                        @"Mike Roflcoptor", @"Cindy Woods", @"Jessica Windmill", @"Alexander The Great",
                        @"Sarah Peterson", @"Scott Scottland", @"Geoff Fanta", @"Amanda Pope", @"Michael Meyers",
                        @"Richard Biggus", @"Montey Python", @"Mike Wut", @"Fake Person", @"Chair",
                        nil];

    // Open patient DB
    mPatientDb = [[MLPatientDBAdapter alloc] init];
    if (![mPatientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        mPatientDb = nil;
    }
    
    if (self = [super init]) {
        return self;
    }    
    return nil;
}



- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (BOOL) validateFields:(MLPatient *)patient
{
    BOOL valid = TRUE;

    mFamilyName.backgroundColor = [NSColor whiteColor];
    mGivenName.backgroundColor = [NSColor whiteColor];
    mBirthDate.backgroundColor = [NSColor whiteColor];
    mCity.backgroundColor = [NSColor whiteColor];
    mZipCode.backgroundColor = [NSColor whiteColor];
    mStreet.backgroundColor = [NSColor whiteColor];
    mHouseNumber.backgroundColor = [NSColor whiteColor];
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
    if ([self stringIsNilOrEmpty:patient.address]) {
        mStreet.backgroundColor = [NSColor lightRed];
        mHouseNumber.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.gender]) {
        mGender.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    
    return valid;
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

- (IBAction) onAddPatient:(id)sender
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
        if (![self stringIsNilOrEmpty:[mStreet stringValue]]) {
            if (![self stringIsNilOrEmpty:[mHouseNumber stringValue]])
                patient.address = [NSString stringWithFormat:@"%@, %@", [mStreet stringValue], [mHouseNumber stringValue]];
            else
                patient.address = [NSString stringWithFormat:@"%@", [mStreet stringValue]];
        }
        patient.gender = mFemale ? @"woman" : @"man";
        patient.weightKg = [mWeight_kg intValue];
        patient.heightCm = [mHeight_cm intValue];
        patient.country = [mCountry stringValue];
        patient.phone = [mPhone stringValue];
        patient.email = [mEmail stringValue];
        
        if ([self validateFields:patient])
            [mPatientDb insertEntry:patient];
    }
}

- (IBAction) onEditPatient:(id)sender
{
    
}

- (IBAction) onDeletePatient:(id)sender
{
    
}

- (IBAction) onCancel:(id)sender
{
    [self remove];
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
}

- (void) remove
{
    [NSApp endModalSession:mModalSession];
    [NSApp endSheet:mPanel];
    [mPanel orderOut:nil];
    [mPanel close];
}

/**
 - NSTableViewDataSource -
 */
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
    return [nameArray count];
}

/**
 - NSTableViewDataDelegate -
 */
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    cellView.textField.stringValue = nameArray[row];
    return cellView;
}

@end
