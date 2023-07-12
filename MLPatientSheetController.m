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

#import "MLPatientSheetController.h"
#import "MLPatientSheetController+smartCard.h"
#import "MLPersistenceManager.h"

#import "LegacyPatientDBAdapter.h"
#import "MLContacts.h"
#import "MLColors.h"
#import "MLUtilities.h"

@interface MLPatientSheetController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation MLPatientSheetController
{
    @private
    MLPatient *mSelectedPatient;
    NSModalSession mModalSession;
    NSArray *mArrayOfPatients;
    NSMutableArray *mFilteredArrayOfPatients;
    NSString *mPatientUUID;
    BOOL mABContactsVisible;    // These are the contacts in the address book
    BOOL mSearchFiltered;
    BOOL mFemale;
}

@synthesize mPanel;

- (id) init
{
    if (self = [super init]) {
        mArrayOfPatients = [[NSArray alloc] init];;
        mFilteredArrayOfPatients = [[NSMutableArray alloc] init];
        mSearchFiltered = FALSE;
        mPatientUUID = nil;
        
        mABContactsVisible = FALSE;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(controlTextDidChange:)
                                                     name:NSControlTextDidChangeNotification
                                                   object:nil];

        self.resultsController = [[MLPersistenceManager shared] resultsControllerForAllPatients];
        self.resultsController.delegate = self;
        [self.resultsController performFetch:nil];
    }    
    return self;
}

- (void) show:(NSWindow *)window
{
    if (!mPanel) {
        [NSBundle loadNibNamed:@"MLAmiKoPatientSheet" owner:self];
        
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
    [self updateAmiKoAddressBookTableView];
    [mNotification setStringValue:@""];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newHealthCardData:)
                                                 name:@"smartCardDataAcquired"
                                               object:nil];
}

- (void) remove
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"smartCardDataAcquired"
                                                  object:nil];

    [NSApp endModalSession:mModalSession];
    [NSApp endSheet:mPanel];
    [mPanel orderOut:nil];
    [mPanel close];
}

#pragma mark -

- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (void) resetFieldsColors
{
    mFamilyName.backgroundColor = [NSColor clearColor];
    mGivenName.backgroundColor = [NSColor clearColor];
    mBirthDate.backgroundColor = [NSColor clearColor];
    mPostalAddress.backgroundColor = [NSColor clearColor];
    mCity.backgroundColor = [NSColor clearColor];
    mZipCode.backgroundColor = [NSColor clearColor];
    mInsuranceGLN.backgroundColor = [NSColor clearColor];
}

- (void) checkFields
{
    [self resetFieldsColors];
    
    if ([self stringIsNilOrEmpty:[mFamilyName stringValue]]) {
        mFamilyName.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mGivenName stringValue]]) {
        mGivenName.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mBirthDate stringValue]] || ![self validateBirthdayString:[mBirthDate stringValue]]) {
        mBirthDate.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mPostalAddress stringValue]]) {
        mPostalAddress.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mCity stringValue]]) {
        mCity.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mZipCode stringValue]]) {
        mZipCode.backgroundColor = [NSColor lightRed];
    }
    if (![self stringIsNilOrEmpty:[mInsuranceGLN stringValue]] && [[mInsuranceGLN stringValue] length] != 13) {
        mInsuranceGLN.backgroundColor = [NSColor lightRed];
    }
}

- (void) resetAllFields
{
    [self resetFieldsColors];
    
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
    [mFemaleButton setState:NSOnState];
    [mMaleButton setState:NSOffState];
    [mBagNumber setStringValue:@""];
    [mCardNumber setStringValue:@""];
    [mInsuranceGLN setStringValue:@""];
    
    mPatientUUID = nil;
    
    [mNotification setStringValue:@""];
}

- (void) setAllFields:(MLPatient *)p
{
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
    if (p.country!=nil)
        [mCountry setStringValue:p.country];
    if (p.postalAddress!=nil)
        [mPostalAddress setStringValue:p.postalAddress];
    if (p.emailAddress!=nil)
        [mEmail setStringValue:p.emailAddress];
    if (p.phoneNumber!=nil)
        [mPhone setStringValue:p.phoneNumber];
    if (p.uniqueId!=nil)
        mPatientUUID = p.uniqueId;
    if (p.gender!=nil) {
        if ([p.gender isEqualToString:@"woman"]) {
            mFemale = TRUE;
            [mFemaleButton setState:NSOnState];
            [mMaleButton setState:NSOffState];
        } else {
            mFemale = FALSE;
            [mFemaleButton setState:NSOffState];
            [mMaleButton setState:NSOnState];
        }
    }
    if (p.bagNumber != nil) {
        [mBagNumber setStringValue:p.bagNumber];
    }
    if (p.healthCardNumber != nil) {
        [mCardNumber setStringValue:p.healthCardNumber];
    }
    if (p.healthCardExpiry != nil) {
        [mCardExpiry setStringValue:p.healthCardExpiry];
    }
    NSString *gln = [p findParticipantGLN];
    if ([gln length]) {
        [mInsuranceGLN setStringValue:gln];
    }
}

- (MLPatient *) getAllFields
{
    MLPatient *patient = [[MLPatient alloc] init];
    patient.familyName = [mFamilyName stringValue];
    patient.givenName = [mGivenName stringValue];
    patient.birthDate = [mBirthDate stringValue];
    patient.city = [mCity stringValue];
    patient.zipCode = [mZipCode stringValue];
    patient.postalAddress = [mPostalAddress stringValue];
    patient.weightKg = [mWeight_kg intValue];
    patient.heightCm = [mHeight_cm intValue];
    patient.country = [mCountry stringValue];
    patient.phoneNumber = [mPhone stringValue];
    patient.emailAddress = [mEmail stringValue];
    patient.gender = [mFemaleButton state]==NSOnState ? @"woman" : @"man";
    patient.bagNumber = [mBagNumber stringValue];
    patient.healthCardNumber = [mCardNumber stringValue];
    patient.healthCardExpiry = [mCardExpiry stringValue];
    patient.insuranceGLN = [mInsuranceGLN stringValue];
    
    return patient;
}

- (void) friendlyNote
{
    [mNotification setStringValue:[NSString stringWithFormat:NSLocalizedString(@"The contact was saved in the %@ address book", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]]];
}

- (void) addPatient:(MLPatient *)patient
{
    mSelectedPatient = patient;
    mPatientUUID = [[MLPersistenceManager shared] addPatient:patient];
    mSearchFiltered = FALSE;
    [mSearchKey setStringValue:@""];
    [self updateAmiKoAddressBookTableView];
    [self friendlyNote];
}

- (void) setSelectedPatient:(MLPatient *)patient
{
    mSelectedPatient = patient;
}

- (MLPatient *) retrievePatient
{
    return mSelectedPatient;
}

- (MLPatient *) retrievePatientWithUniqueID:(NSString *)uniqueID
{
    return [[MLPersistenceManager shared] getPatientWithUniqueID:uniqueID];
}

- (BOOL) patientExistsWithID:(NSString *)uniqueID
{
    MLPatient *p = [self retrievePatientWithUniqueID:uniqueID];
    return p!=nil;
}

- (NSString *) retrievePatientAsString
{
    if (mSelectedPatient)
        return [mSelectedPatient asString];

    return @"";
}

- (NSString *) retrievePatientAsString:(NSString *)searchKey
{
    NSString *p = @"";
    // Retrieves first best match from patient sqlite database
    mArrayOfPatients = [[MLPersistenceManager shared] searchPatientsWithKeyword:searchKey];
    if ([mArrayOfPatients count]>0) {
        MLPatient *r = [mArrayOfPatients objectAtIndex:0];
        return [r asString];
    }
    return p;
}

- (BOOL) validateFields:(MLPatient *)patient
{
    BOOL valid = TRUE;
    
    [self resetFieldsColors];
    
    if ([self stringIsNilOrEmpty:patient.familyName]) {
        mFamilyName.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.givenName]) {
        mGivenName.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.birthDate] || ![self validateBirthdayString:patient.birthDate]) {
        mBirthDate.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.postalAddress]) {
        mPostalAddress.backgroundColor = [NSColor lightRed];
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
    
    return valid;
}

- (BOOL)validateBirthdayString:(NSString*)string {
    if ([string containsString:@" "]) {
        return NO;
    }
    NSArray<NSString*> *parts = [string componentsSeparatedByString:@"."];
    if ([parts count] != 3) {
        return NO;
    }

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSString *dayString = parts[0];
    NSString *monthString = parts[1];
    NSString *yearString = parts[2];
    
    NSNumber *dayNum = [formatter numberFromString:dayString];
    if (dayNum == nil || [dayNum intValue] <= 0 || [dayNum intValue] > 31) {
        return NO;
    }
    NSNumber *monthNum = [formatter numberFromString:monthString];
    if (monthNum == nil || [monthNum intValue] <= 0 || [monthNum intValue] > 12) {
        return NO;
    }
    NSNumber *yearNum = [formatter numberFromString:yearString];
    if (yearNum == nil || [yearString length] != 4) {
        return NO;
    }
    return YES;
}

- (void) updateAmiKoAddressBookTableView
{
    mArrayOfPatients = [[MLPersistenceManager shared] getAllPatients];
    mABContactsVisible=NO;
    [mTableView reloadData];
    [self setNumPatients:[mArrayOfPatients count]];
}

#pragma mark - Notifications

// NSControlTextDidChangeNotification
- (void) controlTextDidChange:(NSNotification *)notification {
    /*
     NSTextField *textField = [notification object];
     if (textField==mFamilyName)
     NSLog(@"%@", [textField stringValue]);
     */
    [self checkFields];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAmiKoAddressBookTableView];
        MLPatient *p = [[MLPersistenceManager shared] getPatientWithUniqueID:mPatientUUID];
        [self resetAllFields];
        [self setAllFields:p];
    });
}

#pragma mark - Actions

- (IBAction) onSearchDatabase:(id)sender
{
    NSString *searchKey = [mSearchKey stringValue];
    [mFilteredArrayOfPatients removeAllObjects];
    if (![self stringIsNilOrEmpty:searchKey]) {
        for (MLPatient *p in mArrayOfPatients) {
            NSString *searchKeyLower = [searchKey lowercaseString];
            if ([[p.familyName lowercaseString] hasPrefix:searchKeyLower] || [[p.givenName lowercaseString] hasPrefix:searchKeyLower] ||
                [[p.postalAddress lowercaseString] hasPrefix:searchKeyLower] || [p.zipCode hasPrefix:searchKeyLower]) {
                [mFilteredArrayOfPatients addObject:p];
            }
        }
    }
    if (mFilteredArrayOfPatients!=nil) {
        if ([mFilteredArrayOfPatients count]>0) {
            [self setNumPatients:[mFilteredArrayOfPatients count]];
            mSearchFiltered = TRUE;
        } else {
            if ([searchKey length]>0) {
                [self setNumPatients:0];
                mSearchFiltered = TRUE;
            } else {
                [self setNumPatients:[mArrayOfPatients count]];
                mSearchFiltered = FALSE;
            }
        }
    } else {
        [self setNumPatients:[mArrayOfPatients count]];
        mSearchFiltered = FALSE;
    }
    [mTableView reloadData];
}

- (IBAction) onSelectFemale:(id)sender
{
    if ([sender isKindOfClass:[NSButton class]]) {
        mFemale = TRUE;
        [mFemaleButton setState:NSOnState];
        [mMaleButton setState:NSOffState];
    }
}

- (IBAction) onSelectMale:(id)sender
{
    if ([sender isKindOfClass:[NSButton class]]) {
        mFemale = FALSE;
        [mFemaleButton setState:NSOffState];
        [mMaleButton setState:NSOnState];
    }
}

- (IBAction) onCancel:(id)sender
{
    [self remove];
}

- (IBAction) onSavePatient:(id)sender
{
    MLPatient *patient = [self getAllFields];
    if (![self validateFields:patient]) {
        return;
    }

    if (mPatientUUID!=nil && [mPatientUUID length]>0) {
        patient.uniqueId = mPatientUUID;
    }

    if ([[MLPersistenceManager shared] getPatientWithUniqueID:mPatientUUID]==nil) {
        mPatientUUID = [[MLPersistenceManager shared] addPatient:patient];
    }
    else {
        mPatientUUID = [[MLPersistenceManager shared] upsertPatient:patient];
    }

    mSearchFiltered = FALSE;
    [mSearchKey setStringValue:@""];
    [self updateAmiKoAddressBookTableView];
    [self friendlyNote];
}

- (IBAction) onNewPatient:(id)sender
{
    [self resetAllFields];
    [self updateAmiKoAddressBookTableView];
}

- (IBAction) onDeletePatient:(id)sender
{
    NSInteger row = [mTableView selectedRow];
    if (row == -1) return;
    if (mABContactsVisible==NO) {
        MLPatient *p = nil;
        if (mSearchFiltered) {
            p = mFilteredArrayOfPatients[row];
        }
        else {
            p = mArrayOfPatients[row];
        }
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:NSLocalizedString(@"Delete contact?", nil)];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete this contact from the %@ Address Book?", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]]];

        [alert setAlertStyle:NSAlertStyleInformational];
        __weak typeof(self) _self = self;
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            [_self alertDidEnd:alert returnCode:returnCode contextInfo:p];
        }];
    }
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(MLPatient *)contextInfo
{
    if (returnCode==NSAlertSecondButtonReturn) {
        MLPatient *p = contextInfo;
        if ([[MLPersistenceManager shared] deletePatient:p]) {
            [self resetAllFields];
            [self updateAmiKoAddressBookTableView];
            [mNotification setStringValue:[NSString stringWithFormat:NSLocalizedString(@"The contact has been removed from the %@ Address Book", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MLPrescriptionPatientDeleted" object:self];
        }
    }
}

- (IBAction) onShowContacts:(id)sender
{
    [self resetAllFields];
    mSearchFiltered = FALSE;
    [mSearchKey setStringValue:@""];
    
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (![CNContactStore class]) {
        return;
    }
    if (mABContactsVisible==NO) {
        CNContactStore *addressBook = [[CNContactStore alloc] init];
        if (status != CNAuthorizationStatusAuthorized) {
            [addressBook requestAccessForEntityType:CNEntityTypeContacts
                                  completionHandler:^(BOOL granted, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        [[NSAlert alertWithError:error] runModal];
                    }
                    if (granted) {
                        [self onShowContacts:sender];
                    }
                });
            }];
        } else {
            // Need to be in background queue because it may be slow to takes contacts
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^{
                MLContacts *contacts = [[MLContacts alloc] init];
                // Retrieves contacts from address book
                mArrayOfPatients = [contacts getAllContacts];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [mTableView reloadData];
                    mABContactsVisible = YES;
                    [self setNumPatients:[mArrayOfPatients count]];
                });
            });
        }
    }
    else {
        // Retrieves contacts from local patient database
        [self updateAmiKoAddressBookTableView];
    }
}

// Double clicked a patient in the table view
- (IBAction) onSelectPatient:(id)sender
{
    NSInteger row = [mTableView selectedRow];
    mSelectedPatient = nil;
    if (mSearchFiltered) {
        mSelectedPatient = mFilteredArrayOfPatients[row];
    }
    else {
        mSelectedPatient = mArrayOfPatients[row];
    }

    if (mSelectedPatient) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MLPrescriptionPatientChanged" object:self];
    }

    [self remove];
}


- (void) setNumPatients:(NSInteger)numPatients
{
    if (mABContactsVisible) {
        [mNumPatients setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Address Book Mac (%ld)", nil), numPatients]];
    }
    else {
        [mNumPatients setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Address Book App", nil),
                                      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
                                      numPatients]];
    }
}

- (MLPatient *) getContactAtRow:(NSInteger)row
{
    if (mSearchFiltered)
        return mFilteredArrayOfPatients[row];

    if (mArrayOfPatients!=nil)
        return mArrayOfPatients[row];

    return nil;
}

/**
 - NSTableViewDataSource -
 */
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
    if (mSearchFiltered)
        return [mFilteredArrayOfPatients count];

    if (mArrayOfPatients!=nil)
        return [mArrayOfPatients count];

    return 0;
}

/**
 - NSTableViewDataDelegate -
 */
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    MLPatient *p = [self getContactAtRow:row];
    if (p!=nil) {
        NSString *cellStr = [NSString stringWithFormat:@"%@ %@", p.familyName, p.givenName];
        cellView.textField.stringValue = cellStr;
        if (p.databaseType==eAddressBook) {
            cellView.textField.textColor = [NSColor grayColor];
        } else {
            cellView.textField.textColor = [NSColor textColor];
        }
        return cellView;
    }
    return nil;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    if ([notification object] == mTableView) {       
        NSInteger row = [[notification object] selectedRow];
        if (row < 0) return;
        NSTableRowView *rowView = [mTableView rowViewAtRow:row makeIfNecessary:NO];
        
        MLPatient *p = [self getContactAtRow:row];
        mPatientUUID = p.uniqueId;
        
        [self resetAllFields];
        [self setAllFields:p];
        
        [rowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];

        [mNotification setStringValue:@""];
    }
}

@end
