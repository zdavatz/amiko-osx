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
#import "MLOperator.h"

@implementation MLOperatorIDSheetController
{
    @private
    NSModalSession mModalSession;
}

- (id) init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
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
    [self saveSettings];
    [self remove];
}

- (IBAction) onLoadSignature:(id)sender
{
    // Create a file open dialog class
    NSOpenPanel* openDlgPanel = [NSOpenPanel openPanel];
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"png",@"gif",@"jpg",nil];
    // Enable options in the dialog
    [openDlgPanel setCanChooseFiles:YES];
    [openDlgPanel setAllowedFileTypes:fileTypesArray];
    [openDlgPanel setAllowsMultipleSelection:false];
    [openDlgPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
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
    if (!mPanel) {
        // Load xib file
        if ([APP_NAME isEqualToString:@"AmiKo"]) {
            [NSBundle loadNibNamed:@"MLAmiKoOperatorIDSheet" owner:self];
        } else if ([APP_NAME isEqualToString:@"CoMed"]) {
            [NSBundle loadNibNamed:@"MLCoMedOperatorIDSheet" owner:self];
        }
    }
    
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
    NSString *documentsDirectory = [MLUtilities documentsDirectory];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"op_signature.png"];
    NSData *png = [mSignView getSignaturePNG];
    [png writeToFile:filePath atomically:YES];
    
    // All other settings are saved using NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[mTitle stringValue] forKey:@"title"];
    [defaults setObject:[mFamilyName stringValue] forKey:@"familyname"];
    [defaults setObject:[mGivenName stringValue] forKey:@"givenname"];
    [defaults setObject:[mPostalAddress stringValue] forKey:@"postaladdress"];
    [defaults setObject:[mZipCode stringValue] forKey:@"zipcode"];
    [defaults setObject:[mCity stringValue] forKey:@"city"];
    [defaults setObject:[mCountry stringValue] forKey:@"country"];
    [defaults setObject:[mPhoneNumber stringValue] forKey:@"phonenumber"];
    [defaults setObject:[mEmailAddress stringValue] forKey:@"emailaddress"];
    // Writes mods to persistent storage
    [defaults synchronize];
}

- (MLOperator *) loadOperator
{
    // Load from user defaults
    MLOperator *operator = [[MLOperator alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    operator.title = [defaults stringForKey:@"title"];
    operator.familyName = [defaults stringForKey:@"familyname"];
    operator.givenName = [defaults stringForKey:@"givenname"];
    operator.postalAddress = [defaults stringForKey:@"postaladdress"];
    operator.zipCode = [defaults stringForKey:@"zipcode"];
    operator.city = [defaults stringForKey:@"city"];
    operator.country = [defaults stringForKey:@"country"];
    operator.phoneNumber = [defaults stringForKey:@"phonenumber"];
    operator.emailAddress = [defaults stringForKey:@"emailaddress"];
    
    return operator;
}

- (void) loadSettings
{
    NSString *documentsDirectory = [MLUtilities documentsDirectory];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"op_signature.png"];
    if (filePath!=nil) {
        NSImage *signatureImg = [[NSImage alloc] initWithContentsOfFile:filePath];
        [mSignView setSignature:signatureImg];
    }
    
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
    
    if (operator.familyName!=nil && operator.givenName!=nil) {
        return [operator retrieveOperatorAsString];
    } else {
        if ([MLUtilities isGermanApp])
            return @"Bitte Arztstempel ergänzen";
        else if ([MLUtilities isFrenchApp])
            return @"Saisir l'adresse du médecin";
        else
            return @"Nirvana";
    }
}

- (NSString *) retrieveCity
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:@"city"];
}

@end
