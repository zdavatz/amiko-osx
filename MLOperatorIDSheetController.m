/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 06/07/2017.
 
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

#import "MLOperatorIDSheetController.h"

#import "MLUtilities.h"
#import "MLColors.h"
#import "MLPersistenceManager.h"

@interface MLOperatorIDSheetController ()

@property (nonatomic, strong) NSMetadataQuery *query;

@end

@implementation MLOperatorIDSheetController
{
    @private
    NSModalSession mModalSession;
}

- (id) init
{
    if (self = [super init]) {
        self.query = [[NSMetadataQuery alloc] init];
        self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        self.query.predicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@",
                                NSMetadataItemURLKey,
                                [[MLPersistenceManager shared] doctorDictionaryURL],
                                NSMetadataItemURLKey,
                                [[MLPersistenceManager shared] doctorSignatureURL]];
        self.query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:NO]];
        [self.query startQuery];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadSettings) name:NSMetadataQueryDidUpdateNotification object:self.query];
    }
    return self;
}

- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (IBAction) onCancel:(id)sender
{
    [self remove];
}

- (IBAction) onSaveOperator:(id)sender
{
    //NSLog(@"%s", __FUNCTION__);
    [self saveSettings];
    [self remove];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MLPrescriptionDoctorChanged" object:nil];
}

- (IBAction) onLoadSignature:(id)sender
{
    // Create a file open dialog class
    NSOpenPanel* openDlgPanel = [NSOpenPanel openPanel];
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"png", @"gif", @"jpg", nil];
    // Enable options in the dialog
    [openDlgPanel setCanChooseFiles:YES];
    [openDlgPanel setAllowedFileTypes:fileTypesArray];
    [openDlgPanel setAllowsMultipleSelection:false];
    [openDlgPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            // Grab reference to what has been selected
            NSURL *fileURL = [[openDlgPanel  URLs] firstObject];
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:fileURL];
            [mSignView setSignature:image];
        }
    }];
}

- (IBAction) onClearSignature:(id)sender
{
    [mSignView clear];
}

- (void) show:(NSWindow *)window
{
    if (!mPanel)
        [NSBundle loadNibNamed:@"MLAmiKoOperatorIDSheet" owner:self];
    
    [NSApp beginSheet:mPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    // Show the dialog
    [mPanel makeKeyAndOrderFront:self];
    
    // Start modal session
    mModalSession = [NSApp beginModalSessionForWindow:mPanel];
    [NSApp runModalSession:mModalSession];
    
    // Other types of initializations go here...
    [self loadSettings];
}

- (void) remove
{
    [NSApp endModalSession:mModalSession];
    [NSApp endSheet:mPanel];
    [mPanel orderOut:nil];
    [mPanel close];
}

- (BOOL) validateFields
{
    BOOL valid = TRUE;
    
    if ([self stringIsNilOrEmpty:[mTitle stringValue]]) {
        mTitle.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:[mFamilyName stringValue]]) {
        mFamilyName.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:[mGivenName stringValue]]) {
        mGivenName.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:[mPostalAddress stringValue]]) {
        mPostalAddress.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:[mZipCode stringValue]]) {
        mZipCode.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:[mCity stringValue]]) {
        mCity.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:[mCountry stringValue]]) {
        mCountry.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:[mPhoneNumber stringValue]]) {
        mPhoneNumber.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:[mEmailAddress stringValue]]) {
        mEmailAddress.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    
    return valid;
}

- (void) saveSettings
{
    // Signature is saved as a PNG to Documents Directory within the app
    NSData *png = [mSignView getSignaturePNG];
    [[MLPersistenceManager shared] setDoctorSignature:png];

    MLOperator *operator = [[MLOperator alloc] init];
    operator.title = [mTitle stringValue];
    operator.familyName = [mFamilyName stringValue];
    operator.givenName = [mGivenName stringValue];
    operator.postalAddress = [mPostalAddress stringValue];
    operator.zipCode = [mZipCode stringValue];
    operator.city = [mCity stringValue];
    operator.country = [mCountry stringValue];
    operator.phoneNumber = [mPhoneNumber stringValue];
    operator.emailAddress = [mEmailAddress stringValue];
    [[MLPersistenceManager shared] setDoctor:operator];
}

- (MLOperator *) loadOperator
{
    return [[MLPersistenceManager shared] doctor];
}

- (void) loadSettings
{
    NSImage *signatureImg = [[MLPersistenceManager shared] doctorSignature];
    [mSignView setSignature:signatureImg];
    
    MLOperator *operator = [self loadOperator];
    
    if ([self stringIsNilOrEmpty:operator.title]==NO)
        mTitle.stringValue = operator.title;

    if ([self stringIsNilOrEmpty:operator.familyName]==NO)
        mFamilyName.stringValue = operator.familyName;

    if ([self stringIsNilOrEmpty:operator.givenName]==NO)
        mGivenName.stringValue = operator.givenName;

    if ([self stringIsNilOrEmpty:operator.postalAddress]==NO)
        mPostalAddress.stringValue = operator.postalAddress;

    if ([self stringIsNilOrEmpty:operator.zipCode]==NO)
        mZipCode.stringValue = operator.zipCode;

    if ([self stringIsNilOrEmpty:operator.city]==NO)
        mCity.stringValue = operator.city;

    if ([self stringIsNilOrEmpty:operator.country]==NO)
        mCountry.stringValue = operator.country;

    if ([self stringIsNilOrEmpty:operator.phoneNumber]==NO)
        mPhoneNumber.stringValue = operator.phoneNumber;

    if ([self stringIsNilOrEmpty:operator.emailAddress]==NO)
        mEmailAddress.stringValue = operator.emailAddress;
}

- (NSString *) retrieveIDAsString
{
    MLOperator *operator = [self loadOperator];
    
    if ([operator.familyName length] && [operator.givenName length])
        return [operator retrieveOperatorAsString];

    return NSLocalizedString(@"Enter the doctor's address", nil);
}

- (NSString *) retrieveCity
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:@"city"];
}

@end
