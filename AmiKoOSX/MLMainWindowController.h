/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
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
#import <WebKit/WebKit.h>

#import "SHCWebView.h"
#import "MLCustomWebView.h"
#import "MLSignatureView.h"
#import "MLPrescriptionsCart.h"

#if defined (AMIKO)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (AMIKO_ZR)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (AMIKO_DESITIN)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (COMED)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (COMED_ZR)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (COMED_DESITIN)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#else
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#endif

#import "MLPrescriptionTableView.h"
#import "HealthCard.h"
#import "MLFullTextEntry.h"

#pragma mark -

@interface MLMainWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, WebUIDelegate, WebFrameLoadDelegate, NSTabViewDelegate, NSDraggingDestination, NSSharingServicePickerDelegate>
{
    IBOutlet NSButton *saveButton;
    IBOutlet NSButton *sendButton;
    IBOutlet NSView *myView;
    IBOutlet NSView *mySplashScreen;
    IBOutlet NSToolbar *myToolbar;
    IBOutlet NSSearchField *mySearchField;
    IBOutlet NSTableView *myTableView;
    IBOutlet NSTableView *mySectionTitles;
    IBOutlet SHCWebView *myWebView;
    HealthCard *healthCard;
}

@property (nonatomic, retain) IBOutlet NSView *myView;
@property (nonatomic, retain) IBOutlet NSView *mySplashScreen;
@property (nonatomic, retain) IBOutlet NSToolbar *myToolbar;
@property (nonatomic, retain) IBOutlet NSSearchField *mySearchField;
@property (nonatomic, retain) IBOutlet NSTableView *myTableView;
@property (nonatomic, retain) IBOutlet NSTableView *mySectionTitles;
@property (nonatomic, retain) IBOutlet NSTextFinder *myTextFinder;
@property (nonatomic, retain) IBOutlet NSTabView *myTabView;
@property (nonatomic, retain) IBOutlet NSSearchField *myPatientSearchField;
@property (nonatomic, retain) IBOutlet NSTextField *myPatientAddressTextField;
@property (nonatomic, retain) IBOutlet NSTextField *myPlaceDateField;
@property (nonatomic, retain) IBOutlet NSTextField *myOperatorIDTextField;
@property (nonatomic, retain) IBOutlet MLSignatureView *mySignView;
@property (nonatomic, retain) IBOutlet MLPrescriptionTableView *myPrescriptionsTableView;
@property (nonatomic, retain) IBOutlet MLPrescriptionTableView *myPrescriptionsPrintTV;

@property (nonatomic, retain) IBOutlet NSView *medicineLabelView;
@property (nonatomic, retain) IBOutlet NSTextField *labelDoctor;
@property (nonatomic, retain) IBOutlet NSTextField *labelPatient;
@property (nonatomic, retain) IBOutlet NSTextField *labelMedicine;
@property (nonatomic, retain) IBOutlet NSTextField *labelComment;
@property (nonatomic, retain) IBOutlet NSTextField *labelPrice;
@property (nonatomic, retain) IBOutlet NSTextField *labelSwissmed;

- (IBAction) performFindAction:(id)sender;
- (IBAction) clickedTableView:(id)sender;
- (IBAction) tappedOnStar:(id)sender;
- (IBAction) searchNow:(id)sender;
- (IBAction) onButtonPressed:(id)sender;
- (IBAction) toolbarAction:(id)sender;
- (IBAction) printSearchResult:(id)sender;
- (IBAction) makeTextStandardSize:(id)sender;
- (IBAction) makeTextLarger:(id)sender;
- (IBAction) makeTextSmaller:(id)sender;
// Update database
- (IBAction) updateAipsDatabase:(id)sender;
- (IBAction) loadAipsDatabase:(id)sender;
// Prescription function
- (IBAction) managePatients:(id)sender;
- (IBAction) setOperatorIdentity:(id)sender;
- (IBAction) findPatient:(id)sender;
- (IBAction) removeItemFromPrescription:(id)sender;
- (IBAction) printMedicineLabel:(id)sender;
- (IBAction) onNewPrescription:(id)sender;
- (IBAction) onSearchPatient:(id)sender;
- (IBAction) onCheckForInteractions:(id)sender;
- (IBAction) onLoadPrescription:(id)sender;
- (IBAction) onSavePrescription:(id)sender;
- (IBAction) onSendPrescription:(id)sender;
- (IBAction) onDeletePrescription:(id)sender;
- (IBAction) printTechInfo:(id)sender;
- (IBAction) printPrescription:(id)sender;

// Help
- (IBAction) showReportFile:(id)sender;
- (IBAction) showAboutPanel:(id)sender;
- (IBAction) sendFeedback:(id)sender;
- (IBAction) shareApp:(id)sender;
- (IBAction) rateApp:(id)sender;

- (void) addItem:(MLPrescriptionItem *)med toPrescriptionCartWithId:(NSInteger)n;
- (void) loadPrescription:(NSString *)filename andRefreshHistory:(bool)refresh;
- (MLMedication *) getShortMediWithId:(long)mid;
- (void) newHealthCardData:(NSNotification *)notification;

- (void) searchParagraphInHTML:(NSString *)html
                      chapters:(NSSet *)ch
                       keyword:(NSString *)aKeyword
                         regnr:(NSString *)rn;
- (void) exportWordListSearchResults;

@end
