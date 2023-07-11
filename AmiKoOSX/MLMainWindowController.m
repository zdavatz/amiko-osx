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

#import "MLMainWindowController.h"
#import "MLDBAdapter.h"
#import "MLFullTextDBAdapter.h"
#import "MLInteractionsAdapter.h"
#import "MLInteractionsHtmlView.h"
#import "MLInteractionsCart.h"
#import "MLFullTextSearch.h"
#import "MLItemCellView.h"
#import "MLSearchWebView.h"
#import "MLDataStore.h"
#import "MLCustomTableRowView.h"
#import "MLCustomView.h"
#import "MLCustomURLConnection.h"
#import "MLEditableTextField.h"
#import "MLPrescriptionsAdapter.h"
#import "MLPatientSheetController.h"
#import "MLOperatorIDSheetController.h"
#import "MLPrescriptionCellView.h"
#import "MLPreferencesWindowController.h"
#import "MLButtonCell.h"
#import "MedidataXMLGenerator.h"
#import "MedidataClient.h"

#import "MLPersistenceManager.h"
#import "MLAbout.h"
#import "MLUtilities.h"

#import "WebViewJavascriptBridge.h"

#import <mach/mach.h>
#import <unistd.h>

#import "MLPrescriptionTextFinderClient.h"
#import "MLPrescriptionTableView.h"
#import "MLMedidataResponsesWindowController.h"
#import "Wait.h"
#import "MLePrescriptionPrepareWindowController.h"

#define DYNAMIC_AMK_SELECTION
#define CSV_SEPARATOR       @";"

// Alternatively implement its own tabview to show the results
#define CSV_EXPORT_RESTORES_PREVIOUS_STATE

NS_ENUM(NSInteger, ToolbarButtonTags) {
    tagToolbarButton_Compendium = 0,
    tagToolbarButton_Favorites = 1,
    tagToolbarButton_Interactions = 2,
    tagToolbarButton_Prescription = 3,
    tagToolbarButton_Export = 4,
    tagToolbarButton_Amiko = 5
};

NS_ENUM(NSInteger, MainButtonTags) {
    tagButton_Preparation = 0,
    tagButton_RegistrationOwner = 1,
    tagButton_ActiveSubstance = 2,
    tagButton_RegistrationNumber = 3,
    tagButton_Therapy = 4,
    tagButton_FullText = 5
};

NS_ENUM(NSInteger, AlertButtonTags) {
    tagAlertButton_Overwrite = 100,
    tagAlertButton_NewFile,
    tagAlertButton_Cancel
};

/**
 Database types
 */
enum {
    kAips=0, kHospital=1, kFavorites=2, kInteractions=4
};

/**
 Search states
 */
enum {
    kTitle=0, kAuthor=1, kAtcCode=2, kRegNr=3, kTherapy=4, kWebView=5, kFullText=6
};

/**
 Webview
 */
enum {
    kExpertInfoView=0, kFullTextSearchView=1, kInteractionsCartView=2
};

static NSInteger mUsedDatabase = kAips;
static NSInteger mCurrentSearchState = kTitle;
static NSInteger mCurrentWebView = kExpertInfoView;
static NSString *mCurrentSearchKey = @"";

static BOOL mSearchInteractions = false;
static BOOL mPrescriptionMode = false;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation DataObject

@synthesize title;
@synthesize subTitle;
@synthesize medId;
@synthesize hashId;

@end

#pragma mark -

@interface MLMainWindowController ()
{
    NSMutableString *csv;
    MLMedication *csvMedication;
}

@property (nonatomic, strong) NSMetadataQuery *query;
@property (nonatomic, strong) MLMedidataResponsesWindowController *medidataResponseWindowController;
@property (nonatomic, strong) MLePrescriptionPrepareWindowController *ePrescriptionPrepareWindowController;

- (void) updateButtons;

@end

@implementation MLMainWindowController
{
    // Instance variable declarations go here
    MLMedication *mMed;
    MLDBAdapter *mDb;
    MLInteractionsAdapter *mInteractions;
    MLInteractionsHtmlView *mInteractionsView;
    MLFullTextDBAdapter *mFullTextDb;
    MLFullTextEntry *mFullTextEntry;
    MLFullTextSearch *mFullTextSearch;
    
    MLPatientSheetController *mPatientSheet;
    MLOperatorIDSheetController *mOperatorIDSheet;
    
    MLPrescriptionsAdapter *mPrescriptionAdapter;
    
    NSMutableArray *medi;
    NSMutableArray *favoriteKeyData;
    
    NSMutableSet *favoriteMedsSet;
    NSMutableSet *favoriteFTEntrySet;
    
    NSArray *searchResults;
    
    NSArray<NSString *> *mListOfSectionIds;  // full paths
    NSArray<NSString *> *mListOfSectionTitles;
    
    NSProgressIndicator *progressIndicator;
    
    NSTextFinder *mTextFinder;
    
    WebViewJavascriptBridge *mJSBridge;
    
    NSString *mAnchor;
    NSString *mFullTextContentStr;
    
    dispatch_queue_t mSearchQueue;
    volatile bool mSearchInProgress;

    float m_alpha;
    float m_delta;

    bool possibleToOverwrite;
    bool modifiedPrescription;  // if true, presenting save/overwrite option makes sense
}

@synthesize myView;
@synthesize mySplashScreen;
@synthesize myToolbar;
@synthesize mySearchField;
@synthesize myTableView;
@synthesize mySectionTitles;
@synthesize myTextFinder;
@synthesize myTabView;
@synthesize myPatientSearchField;
@synthesize myPatientAddressTextField;
@synthesize myPlaceDateField;
@synthesize myOperatorIDTextField;
@synthesize mySignView;
@synthesize prescriptionTextFinder;
@synthesize myPrescriptionsTableView;
@synthesize myPrescriptionsPrintTV;
@synthesize medicineLabelView, labelDoctor, labelPatient, labelMedicine, labelComment, labelPrice, labelSwissmed;

#pragma mark Class methods

#define NUM_ACTIVE_PRESCRIPTIONS   3
static MLPrescriptionsCart *mPrescriptionsCart[NUM_ACTIVE_PRESCRIPTIONS];

+ (MLPrescriptionsCart *) prescriptionsCartWithId:(NSInteger)id
{
    if (id < NUM_ACTIVE_PRESCRIPTIONS) {
        if (mPrescriptionsCart[id].cart == nil) {
            mPrescriptionsCart[id].cart = [[NSMutableArray alloc] init];
            mPrescriptionsCart[id].cartId = id;
        }
        return mPrescriptionsCart[id];
    }
    return nil;
}

#pragma mark Instance methods

- (id) init
{
    // [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]
    // self = [super initWithNibName:@"MLMasterViewController" bundle:nil];
    if ([APP_NAME isEqualToString:@"AmiKo"])
        self = [super initWithWindowNibName:@"MLAmiKoMainWindow"];
    else if ([APP_NAME isEqualToString:@"CoMed"])
        self = [super initWithWindowNibName:@"MLAmiKoMainWindow"];
    else
        return nil;
    
    if (!self)
        return nil;
    
    // Initialize global serial dispatch queue
    mSearchQueue = dispatch_queue_create("com.ywesee.searchdb", nil);
    mSearchInProgress = false;
    
    m_alpha = 0.0;
    m_delta = 0.01;
    [[self window] setAlphaValue:1.0];//m_alpha];
    [self fadeInAndShow];
    [[self window] center];
    
    self.query = [[NSMetadataQuery alloc] init];
    self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
    self.query.predicate = [NSPredicate predicateWithValue:YES];
    [self.query startQuery];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(documentFilesUpdated:) name:NSMetadataQueryDidUpdateNotification object:self.query];

    // Allocate some variables
    medi = [NSMutableArray array];
    favoriteKeyData = [NSMutableArray array];
    
    // Register applications defaults if necessary
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    if ([[MLUtilities appLanguage] isEqualToString:@"de"]) {
        [appDefaults setValue:[NSDate date] forKey:@"germanDBLastUpdate"];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    }
    else if ([[MLUtilities appLanguage] isEqualToString:@"fr"]) {
        [appDefaults setValue:[NSDate date] forKey:@"frenchDBLastUpdate"];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    }
    
    // Start timer to check if database needs to be updatd (checks every hour)
    [NSTimer scheduledTimerWithTimeInterval:3600
                                     target:self
                                   selector:@selector(checkLastDBSync)
                                   userInfo:nil
                                    repeats:YES];
    
    // Open sqlite database
    [self openSQLiteDatabase];
#ifdef DEBUG
    NSLog(@"Number of records in AIPS database = %ld", (long)[mDb getNumRecords]);
#endif
    
    // Open fulltext database
    [self openFullTextDatabase];
#ifdef DEBUG
    NSLog(@"Number of records in fulltext database = %ld", (long)[mFullTextDb getNumRecords]);
#endif
    
    // Open drug interactions csv file
    [self openInteractionsCsvFile];
#ifdef DEBUG
     NSLog(@"Number of records in interaction file = %lu", (unsigned long)[mInteractions getNumInteractions]);
#endif
    
    // Initialize interactions cart
    mInteractionsView = [[MLInteractionsHtmlView alloc] init];
    
    // Create bridge between JScript and ObjC
    [self createJSBridge];
    
    // Initialize full text search
    mFullTextSearch = [[MLFullTextSearch alloc] init];
    
    // Initialize all three prescription baskets
    for (int i=0; i<NUM_ACTIVE_PRESCRIPTIONS; ++i) {
        mPrescriptionsCart[i] = [[MLPrescriptionsCart alloc] init];
        [mPrescriptionsCart[i] setInteractionsAdapter:mInteractions];
    }
    mPrescriptionAdapter = [[MLPrescriptionsAdapter alloc] init];
    
    prescriptionTextFinder = [[NSTextFinder alloc] init];
    prescriptionTextFinder.findBarContainer = self.prescriptionView;
    prescriptionTextFinder.incrementalSearchingEnabled = YES;
    prescriptionTextFinder.incrementalSearchingShouldDimContentView = YES;
    self.prescriptionTextFinderClient = [[MLPrescriptionTextFinderClient alloc] initWithAdapter:mPrescriptionAdapter
                                                                           mainWindowController:self];
    prescriptionTextFinder.client = self.prescriptionTextFinderClient;
    
    // Register drag and drop on prescription table view
    [self.mySectionTitles setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [self.mySectionTitles registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, nil]];
    
    [self.myPrescriptionsTableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [self.myPrescriptionsTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, nil]];
    
    // Initialize webview
    [[myWebView preferences] setJavaScriptEnabled:YES];
    [[myWebView preferences] setJavaScriptCanOpenWindowsAutomatically:YES];
    [myWebView setUIDelegate:self];
    [myWebView setFrameLoadDelegate:self];
    
    // Initialize favorites (articles + full text entries)
    MLDataStore *favorites = [[MLDataStore alloc] init];
    [self loadFavorites:favorites];
    favoriteMedsSet = [[NSMutableSet alloc] initWithSet:favorites.favMedsSet];
    favoriteFTEntrySet = [[NSMutableSet alloc] initWithSet:favorites.favFTEntrySet];
    
    // Set default database
    mUsedDatabase = kAips;
    [myToolbar setSelectedItemIdentifier:@"AIPS"];
    
    // Set search state
    [self setSearchState:kTitle];
    
    // Register observer to notify successful download of new database
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedDownloading:)
                                                 name:@"MLDidFinishLoading"
                                               object:nil];

    // Register observer to notify absence of file on pillbox server
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedDownloading:)
                                                 name:@"MLStatusCode404"
                                               object:nil];

    // Register observer to notify change of window size
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowResized:)
                                                 name:NSWindowDidResizeNotification
                                               object:nil];
    
    // Register observer to notify change of patient selected in prescription module
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(prescriptionPatientChanged:)
                                                 name:@"MLPrescriptionPatientChanged"
                                               object:nil];

    // Register observer to notify change of patient selected in prescription module
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(prescriptionPatientDeleted:)
                                                 name:@"MLPrescriptionPatientDeleted"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(prescriptionDoctorChanged:)
                                                 name:@"MLPrescriptionDoctorChanged"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlTextDidChange:)
                                                 name:NSControlTextDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newHealthCardData:)
                                                 name:@"smartCardDataAcquired"
                                               object:nil];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(darkModeChanged:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    
    healthCard = [[HealthCard alloc] init];

    [[self window] makeFirstResponder:self];
    [[self window] setBackgroundColor:[NSColor windowBackgroundColor]];

    return self;
}

- (void) darkModeChanged:(NSNotification *)notif
{
#ifdef DEBUG
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    NSLog(@"%s %d AppleInterfaceStyle:%@", __FUNCTION__, __LINE__, osxMode);  // null, Dark
#endif

    // reload the web view, not just refresh it

    //[myWebView reload:self]; // presumably reloads, but using existing CSS
    NSArray *toolbarItems = [myToolbar items];
    NSToolbarItemIdentifier identifier = [myToolbar selectedItemIdentifier];
    for (NSToolbarItem *tbi in toolbarItems) {
        if ([tbi.itemIdentifier isEqualToString:identifier]) {
            //NSLog(@"%s %d %@ %@", __FUNCTION__, __LINE__, [tbi class], tbi);
            [self toolbarAction:tbi];
            break;
        }
    }
}

- (void) windowDidLoad
{
    [super windowDidLoad];

    // NOTE: These properties are set in NIB file, but to be verbose what we need to do:
    // Set container for NSTextFinder panel (NSScrollView hosting our SHCWebView)
    myTextFinder.findBarContainer = myWebView.enclosingScrollView;
    // Set client to work with the NSTextFinder object
    myTextFinder.client  = myWebView;
    // And vice versa: inform our SHCWebView about which of the NSTextFinder instance to work with
    myWebView.textFinder = myTextFinder;
    // Configure NSTextFinder
    myTextFinder.incrementalSearchingEnabled = YES;
    myTextFinder.incrementalSearchingShouldDimContentView = YES;
    
    if ([MLUtilities isGermanApp]) {
        NSDate* lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"germanDBLastUpdate"];
        if (lastUpdated==nil)
            [self updateUserDefaultsForKey:@"germanDBLastUpdate"];
        else
            [self checkLastDBSync];
    }
    else if ([MLUtilities isFrenchApp]) {
        NSDate* lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"frenchDBLastUpdate"];
        if (lastUpdated==nil)
            [self updateUserDefaultsForKey:@"frenchDBLastUpdate"];
        else
            [self checkLastDBSync];
    }

    if (@available(macOS 11.0, *)) {
        [self.window setTitleVisibility:NSWindowTitleHidden];
#ifdef __MAC_11_0
        [self.window setToolbarStyle:NSWindowToolbarStyleUnified];
#endif
        [self.myToolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    }
    [self.myToolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    
    for (NSToolbarItem *item in [self.myToolbar items]) {
        if (item.tag == 5) { // Amiko / Comed button that opens the about dialog
            NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
            NSString* productName = infoDict[@"CFBundleName"] ?: infoDict[@"CFBundleExecutable"];
            if (productName) {
                [item setLabel:productName];
            }
        }
    }    

    [sendButton sendActionOn:NSEventMaskLeftMouseDown];
    possibleToOverwrite = false;
    modifiedPrescription = false;
    
    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(setOperatorIdentity:)];
    [self.myOperatorIDTextField addGestureRecognizer:click];
    
    [self updateButtons];
    [self updateExpertInfoView:nil];  // to have an initial dark background in dark mode
}

- (void) updateUserDefaultsForKey:(NSString *)key
{
    // Store current date, and bother user again in a month
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSDate date] forKey:key];
    // Make sure it's saved immediately
    [defaults synchronize];
}

- (void) checkLastDBSync
{
    // Nag user all 30 days! = 60 x 60 x 24 x 30 seconds
    NSLog(@"Time since last interval in seconds = %.1f", [MLUtilities timeIntervalSinceLastDBSync]);
    if ([MLUtilities timeIntervalSinceLastDBSync]>60*60*24*30) {
        // Show alert with OK button
        NSAlert *alert = [[NSAlert alloc] init];

        [alert setMessageText:NSLocalizedString(@"Your data bank is older than 30 days. We recommend an update", nil)];

        if ([MLUtilities isGermanApp]) {
            [self updateUserDefaultsForKey:@"germanDBLastUpdate"];
        }
        else if ([MLUtilities isFrenchApp]) {
            [self updateUserDefaultsForKey:@"frenchDBLastUpdate"];
        }

        [alert setAlertStyle:NSAlertStyleInformational];
        __weak typeof(self) _self = self;
        [alert beginSheetModalForWindow:[self window]
                      completionHandler:^(NSModalResponse returnCode) {
            [_self alertDidEnd:alert returnCode:returnCode];
        }];
    }
}

- (void) hideTextFinder
{
    // Inform NSTextFinder the text is going to change
    [myTextFinder noteClientStringWillChange];
    // Hide text finder
    [myTextFinder performAction:NSTextFinderActionHideFindInterface];
    // Discard previous data structures
    [myWebView invalidateTextRanges];
}

#pragma mark - NSTextFinder actions

- (IBAction) performFindAction:(id)sender
{
    /*
    NSTextFinderActionShowFindInterface = 1,
    NSTextFinderActionNextMatch = 2,
    NSTextFinderActionPreviousMatch = 3,
    NSTextFinderActionSetSearchString = 7,
    NSTextFinderActionHideFindInterface = 11,
    */
    NSTextFinder *textFinder = nil;
    if (mPrescriptionMode) {
        textFinder = prescriptionTextFinder;
        [(MLPrescriptionTextFinderClient*)self.prescriptionTextFinderClient reloadSearchString];
        [self.prescriptionView setFindBarVisible:YES];
    } else if ([[myWebView mainFrame] dataSource]!=nil) {
        textFinder = myTextFinder;
    }
    if (textFinder != nil) {
        if ([sender isKindOfClass:[NSMenuItem class]] ) {
            NSMenuItem *menuItem = (NSMenuItem*)sender;
            if ([textFinder validateAction:menuItem.tag]) {
                if (menuItem.tag == NSTextFinderActionShowFindInterface) {
                    // This is a special tag
                    [textFinder performAction:NSTextFinderActionSetSearchString];
                }
                [textFinder performAction:menuItem.tag];
            }
        }
    }
}

- (IBAction) makeTextStandardSize:(id)sender
{
    [myWebView makeTextStandardSize:sender];
}

- (IBAction) makeTextLarger:(id)sender
{
    [myWebView makeTextLarger:sender];
}

- (IBAction) makeTextSmaller:(id)sender
{
    [myWebView makeTextSmaller:sender];
}

/**
 In order for window alert to work with javascript two steps are necessary:
 - setUIDelegate
 - add the following function
 */
- (void) webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message
{
    NSAlert *jsAlert = [[NSAlert alloc] init];
    [jsAlert setMessageText:@"JavaScript"];
    [jsAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
    [jsAlert setInformativeText:message];
    [jsAlert beginSheetModalForWindow:sender.window completionHandler:^(NSModalResponse returnCode) {
        
    }];
}

- (void) fadeInAndShow
{
    if (m_alpha<1.0) {
        m_alpha += m_delta;
        [[self window] setAlphaValue:1.0f]; // m_alpha
        
        [NSTimer scheduledTimerWithTimeInterval:0.01
                                         target:self
                                       selector:@selector(fadeInAndShow)
                                       userInfo:nil
                                        repeats:NO];
    } else {
        [[self window] setAlphaValue:1.0];
        // Test
        [self resetDataInTableView];
    }
}

- (void) updateDatabase:(NSString *)language for:(NSString *)owner
{
    // Initialize custom URL connections for files that will be downloaded...
    MLCustomURLConnection *reportConn = [[MLCustomURLConnection alloc] init];
    MLCustomURLConnection *dbConn = [[MLCustomURLConnection alloc] init];
    MLCustomURLConnection *interConn = [[MLCustomURLConnection alloc] init];
    MLCustomURLConnection *fulltextConn = [[MLCustomURLConnection alloc] init];
    
    if ([language isEqualToString:@"de"]) {
        if ([owner isEqualToString:@"ywesee"] || [owner isEqualToString:@"zurrose"] || [owner isEqualToString:@"desitin"]) {
            [reportConn downloadFileWithName:@"amiko_report_de.html" andModal:NO];
            [interConn downloadFileWithName:@"drug_interactions_csv_de.zip" andModal:NO];
            [fulltextConn downloadFileWithName:@"amiko_frequency_de.db.zip" andModal:NO];
            [dbConn downloadFileWithName:@"amiko_db_full_idx_de.zip" andModal:YES];
        }
    } else if ([language isEqualToString:@"fr"]) {
        if ([owner isEqualToString:@"ywesee"] || [owner isEqualToString:@"zurrose"] || [owner isEqualToString:@"desitin"]) {
            [reportConn downloadFileWithName:@"amiko_report_fr.html" andModal:NO];
            [interConn downloadFileWithName:@"drug_interactions_csv_fr.zip" andModal:NO];
            [fulltextConn downloadFileWithName:@"amiko_frequency_fr.db.zip" andModal:NO];
            [dbConn downloadFileWithName:@"amiko_db_full_idx_fr.zip" andModal:YES];
        }
    }
}

- (void) openInteractionsCsvFile
{
    mInteractions = [[MLInteractionsAdapter alloc] init];
    if ([MLUtilities isGermanApp]) {
        if (![mInteractions openInteractionsCsvFile:@"drug_interactions_csv_de"]) {
            NSLog(@"No German drug interactions file!");
        }
    } else if ([MLUtilities isFrenchApp]) {
        if (![mInteractions openInteractionsCsvFile:@"drug_interactions_csv_fr"]) {
            NSLog(@"No French drug interactions file!");
        }
    }
}

- (void) openSQLiteDatabase
{
    mDb = [[MLDBAdapter alloc] initWithQueue:mSearchQueue];
    if ([MLUtilities isGermanApp]) {
        if (![mDb openDatabase:@"amiko_db_full_idx_de"]) {
            NSLog(@"No German AIPS database!");
            mDb = nil;
        }
    } else if ([MLUtilities isFrenchApp]) {
        if (![mDb openDatabase:@"amiko_db_full_idx_fr"]) {
            NSLog(@"No French AIPS database!");
            mDb = nil;
        }
    }
}

- (void) openFullTextDatabase
{
    mFullTextDb = [[MLFullTextDBAdapter alloc] init];
    if ([MLUtilities isGermanApp]) {
        if (![mFullTextDb openDatabase:@"amiko_frequency_de"]) {
            NSLog(@"No German Fulltext database!");
            mFullTextDb = nil;
        }
    }
    else if ([MLUtilities isFrenchApp]) {
        if (![mFullTextDb openDatabase:@"amiko_frequency_fr"]) {
            NSLog(@"No French Fulltext database!");
            mFullTextDb = nil;
        }
    }
}

#pragma mark - Notifications

/*
 if not visible && exists in patient_db
    update patient text in main window
 else
    launch patient panel
 */
- (void) newHealthCardData:(NSNotification *)notification
{
    NSDictionary *d = [notification object];
    //NSLog(@"%s NSNotification:%@", __FUNCTION__, d);

    MLPatient *incompletePatient = [[MLPatient alloc] init];
    [incompletePatient importFromDict:d];
    //NSLog(@"patient %@", incompletePatient);
    
    MLPatient *existingPatient = [[MLPersistenceManager shared] getPatientWithUniqueID:incompletePatient.uniqueId];
    //NSLog(@"%s Existing patient from DB:%@", __FUNCTION__, existingPatient);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!mPatientSheet)
            mPatientSheet = [[MLPatientSheetController alloc] init];

        if (![mPatientSheet.mPanel isVisible] && existingPatient) {
            [mPatientSheet setSelectedPatient:existingPatient];
            [mPrescriptionAdapter setPatient:existingPatient];
            
            if ([[[myTabView selectedTabViewItem] identifier] intValue] != 2) {
                [myTabView selectTabViewItemAtIndex:2];
                [myToolbar setSelectedItemIdentifier:@"Rezept"];
            }

            myPatientAddressTextField.stringValue = [mPatientSheet retrievePatientAsString];
            
            // Update prescription history in right most pane
            mPrescriptionMode = true;
            [self updatePrescriptionHistory];
        
        } else {
            if (![mPatientSheet.mPanel isVisible]) {
                // UI API must be called on the main thread
                [mPatientSheet show:[NSApp mainWindow]];
                [mPatientSheet onNewPatient:nil];
                [mPatientSheet setSelectedPatient:incompletePatient];
                [mPatientSheet setAllFields:incompletePatient];
            }
        }
    });
}

- (void) prescriptionDoctorChanged:(NSNotification *)notification
{
    //NSLog(@"%s NSNotification:%@", __FUNCTION__, [notification name]);
    [self setOperatorID];   // issue #5
}

- (void) prescriptionPatientChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"MLPrescriptionPatientChanged"]) {
        if (!mPatientSheet) {
            mPatientSheet = [[MLPatientSheetController alloc] init];
        }
        myPatientAddressTextField.stringValue = [mPatientSheet retrievePatientAsString];
        // If prescription cart is not empty, generate new hash
        if (mPrescriptionsCart[0].cart)
            [mPrescriptionsCart[0] makeNewUniqueHash];
        [mPrescriptionAdapter setPatient:mPatientSheet.retrievePatient];
        
        modifiedPrescription = true;
        [self updateButtons];
    }

    mPrescriptionMode = true;

    // Update prescription history in right most pane
    [self updatePrescriptionHistory];

    // Switch tab view
    [myTabView selectTabViewItemAtIndex:2];
    [myToolbar setSelectedItemIdentifier:@"Rezept"];
}

- (void) prescriptionPatientDeleted:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"MLPrescriptionPatientDeleted"]) {
        myPatientAddressTextField.stringValue = @"";
        [self setOperatorID];
        [mPrescriptionsCart[0] clearCart];
        [myPrescriptionsTableView reloadData];
        [self resetPrescriptionHistory];
    }
}

- (void)documentFilesUpdated:(NSNotification *)notification {
    NSString *tabId = [[myTabView selectedTabViewItem] identifier];
    if (![tabId isEqualToString:@"TabPrescription1"]) return;

    NSDictionary *dict = [notification userInfo];
    NSArray<NSMetadataItem *> *addedItems = dict[NSMetadataQueryUpdateAddedItemsKey];
    if ([addedItems count]) {
        for (NSMetadataItem *addedItem in addedItems) {
            NSURL *url = [addedItem valueForAttribute:NSMetadataItemURLKey];
            if ([[url path] hasPrefix:[[[MLPersistenceManager shared] amkBaseDirectory] path]]) {
                [self updatePrescriptionHistory];
                break;
            }
        }
    }
    NSArray<NSMetadataItem *> *changedItems = dict[NSMetadataQueryUpdateChangedItemsKey];
    if (changedItems) {
        for (NSMetadataItem *changedItem in changedItems) {
            NSURL *url = [changedItem valueForAttribute:NSMetadataItemURLKey];
            if ([[url path] hasPrefix:[[[MLPersistenceManager shared] amkBaseDirectory] path]] &&
                [[url pathExtension] isEqualToString:@"amk"]) {
                [self loadPrescription:url andRefreshHistory:NO];
                [self updatePrescriptionsView];
                break;
            }
        }
    }
    NSArray<NSMetadataItem *> *removedItems = dict[NSMetadataQueryUpdateRemovedItemsKey];
    if (removedItems) {
        for (NSMetadataItem *removedItem in removedItems) {
            NSURL *url = [removedItem valueForAttribute:NSMetadataItemURLKey];
            if ([[url path] hasPrefix:[[[MLPersistenceManager shared] amkBaseDirectory] path]]) {
                [self updatePrescriptionHistory];
                break;
            }
        }
    }
}

#pragma mark -

- (void) resetPrescriptionHistory
{
    mListOfSectionTitles = [[NSArray alloc] init];
    mListOfSectionIds = [[NSArray alloc] init];
    [mySectionTitles reloadData];
}

- (void) updatePrescriptionHistory
{
    if (!mPrescriptionMode) {
#ifdef DEBUG
        NSLog(@"%s not prescription mode", __FUNCTION__);
#endif
        return;
    }

    // Extract section ids
    if (![mMed.sectionIds isEqual:[NSNull null]]) {
        NSArray<NSString *> *listOfPrescriptions = [mPrescriptionAdapter listOfPrescriptionsForPatient:[mPatientSheet retrievePatient]];
        mListOfSectionIds = listOfPrescriptions;  // array of full paths
    }

    // Extract section titles
    if (![mMed.sectionTitles isEqual:[NSNull null]]) {
        NSArray<NSString *> *listOfPrescriptions = [mPrescriptionAdapter listOfPrescriptionsForPatient:[mPatientSheet retrievePatient]];
        mListOfSectionTitles = [listOfPrescriptions valueForKeyPath:@"lastPathComponent.stringByDeletingPathExtension"];
    }

    [mySectionTitles reloadData];
}

/**
 Notification called when updates have been downloaded
 */
- (void) finishedDownloading:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"MLDidFinishLoading"]) {
        if (mDb!=nil && mFullTextDb!=nil && mInteractions!=nil) {
            // Close database
            [mDb closeDatabase];
            // Re-open database
            [self openSQLiteDatabase];
            
            // Close fulltext database
            [mFullTextDb closeDatabase];
            // Re-open database
            [self openFullTextDatabase];
            
            // Close interaction database
            [mInteractions closeInteractionsCsvFile];
            // Re-open interaction database
            [self openInteractionsCsvFile];
            
            // Reload table
            NSInteger _mySearchState = mCurrentSearchState;
            NSString *_mySearchKey = mCurrentSearchKey;
            // Reset data in table view and get number of rows in table (=searchResults)
            [self resetDataInTableView];
            mCurrentSearchState = _mySearchState;
            mCurrentSearchKey = _mySearchKey;
            
            // Update
            if ([MLUtilities isGermanApp])
                [self updateUserDefaultsForKey:@"germanDBLastUpdate"];
            else if ([MLUtilities isFrenchApp])
                [self updateUserDefaultsForKey:@"frenchDBLastUpdate"];

            // Display friendly message
            NSBeep();
            // Get number of products/search terms/interactions in databases
            long numProducts = [mDb getNumProducts];
            long numFachinfos = [searchResults count];
            long numSearchTerms = [mFullTextDb getNumRecords];
            int numInteractions = (int)[mInteractions getNumInteractions];
            
            NSAlert *alert = [[NSAlert alloc] init];
            
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:NSLocalizedString(@"AmiKo Database Updated!", nil)];
            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The database contains:\n- %ld Products\n- %ld Specialist information\n- %ld Keywords\n- %d Interactions", nil), numProducts, numFachinfos, numSearchTerms, numInteractions]];

            [alert setAlertStyle:NSAlertStyleInformational];
            __weak typeof(self) _self = self;
            [alert beginSheetModalForWindow:[self window]
                          completionHandler:^(NSModalResponse returnCode) {
                [_self alertDidEnd:alert returnCode:returnCode];
            }];
        }
    }
    else if ([[notification name] isEqualToString:@"MLStatusCode404"]) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:NSLocalizedString(@"Update is not possible", nil)];
        [alert setInformativeText:NSLocalizedString(@"Please contact", nil)];
        [alert setAlertStyle:NSAlertStyleInformational];
        __weak typeof(self) _self = self;
        [alert beginSheetModalForWindow:[self window]
                      completionHandler:^(NSModalResponse returnCode) {
            [_self alertDidEnd:alert returnCode:returnCode];
        }];
    }
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
{
    if (returnCode==NSAlertFirstButtonReturn) {
        NSLog(@"Database successfully updated!");
        // Resume table
        [self restoreDataInTableView];
    }
}

/**
 */
- (void) updateSearchResults
{
    if (mUsedDatabase==kAips)
        searchResults = [self searchAnyDatabasesWith:mCurrentSearchKey];
    else if (mUsedDatabase==kFavorites)
        searchResults = [self retrieveAllFavorites];
}

/**
 Resets search state and data in search results table
 */
- (void) resetDataInTableView
{
    // Reset search state
    [self setSearchState:kTitle];
    
    mCurrentSearchKey = @"";
    searchResults = [self searchAnyDatabasesWith:mCurrentSearchKey];

    if (searchResults) {
        [self updateTableView];
        [self.myTableView reloadData];
        [self.myTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1)];
    }
}

/**
 Restores search state and data in search results table
 */
- (void) restoreDataInTableView
{
    // Restore search state
    [self setSearchState:mCurrentSearchState];
    // Search
    if (mCurrentSearchState!=kWebView) {
        [self updateSearchResults];
        if (searchResults) {
            [[mySearchField cell] setStringValue:mCurrentSearchKey];
            [self updateTableView];
            [self.myTableView reloadData];
        }
    } else {
        // [[mySearchField cell] setStringValue:mCurrentSearchKey];
    }
}

/**
 Restores html in webview
 */
- (void) restoreWebView
{
    // Restore 
}

- (void) awakeFromNib
{    
    // Important for capturing actions from menus
    // [[self window] makeFirstResponder:self];
    
    // Problem with this function is that it is called multiple times...
    // because we pass 'owner:self' when we create 'MLPrescriptionCellView *cellView'

    // Issue #108
    NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    [[self window] setTitle:bundleName];
}

- (void) windowResized: (NSNotification *)notification;
{
    /*
     [self.mySplashScreen removeFromSuperview];
     [myToolbar setVisible:YES];
     */
}

- (MLMedication *) getShortMediWithId:(long)mid
{
    if (mDb != nil)
        return [mDb getShortMediWithId:mid];
    else
        return nil;
}

- (MLMedication *) getMediWithId:(long)mid
{
    if (mDb != nil)
        return [mDb getMediWithId:mid];
    else
        return nil;
}


- (IBAction) tappedOnStar: (id)sender
{
    NSInteger row = [self.myTableView rowForView:sender];
#ifdef DEBUG
    //NSLog(@"%s row: %ld", __FUNCTION__, row);
#endif
    if (mCurrentSearchState!=kFullText) {
        NSString *medRegnrs = [NSString stringWithString:[favoriteKeyData objectAtIndex:row]];
        if ([favoriteMedsSet containsObject:medRegnrs])
            [favoriteMedsSet removeObject:medRegnrs];
        else
            [favoriteMedsSet addObject:medRegnrs];
    }
    else {
        NSString *hashId = [NSString stringWithString:[favoriteKeyData objectAtIndex:row]];
        if ([favoriteFTEntrySet containsObject:hashId])
            [favoriteFTEntrySet removeObject:hashId];
        else
            [favoriteFTEntrySet addObject:hashId];
    }
    
    [self saveFavorites];
}

- (IBAction) searchNow: (id)sender
{
    NSString *searchText = [mySearchField stringValue];
    
    if (mCurrentSearchState != kWebView ) {
        searchResults = [NSArray array];
        
        // MLMainWindowController* __weak weakSelf = self;  // best solution but works only for > 10.8
        MLMainWindowController* __unsafe_unretained weakSelf = self; // works also in 10.7 (Lion)
        
        // dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.searchdb", nil);
        dispatch_async(mSearchQueue, ^(void) {
            MLMainWindowController* scopeSelf = weakSelf;
            while (mSearchInProgress) {
                [NSThread sleepForTimeInterval:0.005];  // Wait for 5ms
            }

            if (!mSearchInProgress) {
                @synchronized(self) {
                    mSearchInProgress = true;
                }
                if ([searchText length] == 0 && mUsedDatabase == kFavorites) {
                    searchResults = [scopeSelf retrieveAllFavorites];
                } else {
                    searchResults = [scopeSelf searchAnyDatabasesWith:searchText];
                }
                // Update tableview
                dispatch_async(dispatch_get_main_queue(), ^{
                    [scopeSelf updateTableView];
                    [self.myTableView reloadData];
                    @synchronized(self) {
                        mSearchInProgress = false;
                    }
                });
            }
        });
    } else {
        /*
        if ([searchText length] > 2)
            [myWebView highlightAllOccurencesOfString:searchText];
        else
            [myWebView removeAllHighlights];
        */
    }
}

- (IBAction) onButtonPressed: (id)sender
{
    NSButton *btn = (NSButton *)sender;
    
    NSInteger prevState = mCurrentSearchState;
    
    switch (btn.tag) {
        case tagButton_Preparation:
            [self setSearchState:kTitle];
            break;

        case tagButton_RegistrationOwner:
            [self setSearchState:kAuthor];
            break;

        case tagButton_ActiveSubstance:
            [self setSearchState:kAtcCode];
            break;

        case tagButton_RegistrationNumber:
            [self setSearchState:kRegNr];
            break;

        case tagButton_Therapy:
            [self setSearchState:kTherapy];
            break;

        case tagButton_FullText:
            [self setSearchState:kFullText];
            break;
    }
    
    if (prevState == kFullText || mCurrentSearchState == kFullText)
        [self updateSearchResults];
    
    if (searchResults) {
        [self updateTableView];
        [self.myTableView reloadData];
    }
}

- (IBAction) toolbarAction:(id)sender
{
    //NSLog(@"%s %d %@ %@", __FUNCTION__, __LINE__, [sender class], sender);
    [self launchProgressIndicator];
    
    NSToolbarItem *item = (NSToolbarItem *)sender;
    [self performSelector:@selector(switchTabs:) withObject:item afterDelay:0.01];
}

- (IBAction) printTechInfo:(id)sender
{
//    NSString *tabId = [[myTabView selectedTabViewItem] identifier];
//    if (![tabId isEqualToString:@"TabWebView"]) {
//        [myTabView selectTabViewItemAtIndex:0];
//    }
    
    WebFrame *webFrame = [myWebView mainFrame];
    WebFrameView *webFrameView = [webFrame frameView];
    NSView <WebDocumentView> *webDocumentView = [webFrameView documentView];
    
    NSPrintInfo *printInfo = [[NSPrintInfo alloc] init];
    [printInfo setOrientation:NSPaperOrientationPortrait];
    [printInfo setHorizontalPagination:NSFitPagination];
    NSPrintOperation *printJob = [NSPrintOperation printOperationWithView:webDocumentView printInfo:printInfo];
    // [printJob setPrintPanel:myPrintPanel]; --> needs to be subclassed
    [printJob runOperation];
}

// With subclass of tableview and custom header
// Problem: because of the big top margin, the table view is pushed down to span two pages
// and two pages appear in the preview even if there is a single medicine. This should be fixed with issue #15
- (IBAction) printPrescription:(id)sender
{
    NSInteger row = [mySectionTitles selectedRow];
    if (row == -1) {
        NSLog(@"%s no AMK is selected, aborting print operation", __FUNCTION__);
        return;
    }
    BOOL signPrescription = NO;
    if ([MLePrescriptionPrepareWindowController applicable]) {
        if ([MLePrescriptionPrepareWindowController canPrintWithoutAuth]) {
            signPrescription = YES;
        } else {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString(@"Do you want to sign your prescription?", @"")];
            [alert addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
            [alert addButtonWithTitle:NSLocalizedString(@"No", @"")];
            NSModalResponse response = [alert runModal];
            if (response == NSAlertFirstButtonReturn) {
                signPrescription = YES;
            }
        }
    }
    if (signPrescription) {
        MLPatient *p = [mPrescriptionAdapter patient];
        MLOperator *o = [mPrescriptionAdapter doctor];
        self.ePrescriptionPrepareWindowController = [[MLePrescriptionPrepareWindowController alloc] initWithPatient:p
                                                                                                             doctor:o
                                                                                                              items:[mPrescriptionAdapter cart]];
        typeof(self) __weak _self = self;
        [self.window beginSheet:self.ePrescriptionPrepareWindowController.window
              completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSModalResponseOK) {
                NSImage *qrCode = _self.ePrescriptionPrepareWindowController.outQRCode;
                _self.ePrescriptionPrepareWindowController = nil;
                // Need to give time for modal to close
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_self printPrescription:sender withQRCode:qrCode];
                });
            }
        }];
    } else {
        [self printPrescription:sender withQRCode:nil];
    }
}
- (void) printPrescription:(id)sender withQRCode:(NSImage * _Nullable)qrCode {
    NSInteger row = [mySectionTitles selectedRow];
    if (row == -1) {
        NSLog(@"%s no AMK is selected, aborting print operation", __FUNCTION__);
        return;
    }
    NSView *printView;
    
    NSPrintInfo *sharedInfo = [NSPrintInfo sharedPrintInfo];
    NSMutableDictionary *sharedDict = [sharedInfo dictionary];
    NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionaryWithDictionary:sharedDict];
#ifdef METHOD_2
    [printInfoDict setObject:@NO forKey:NSPrintHeaderAndFooter];
#else
    [printInfoDict setObject:@YES forKey:NSPrintHeaderAndFooter];
#endif
    [printInfoDict setObject:@NO forKey:NSPrintVerticallyCentered];
    
    NSPrintInfo *printInfo = [[NSPrintInfo alloc] initWithDictionary:printInfoDict];
    [printInfo setOrientation:NSPaperOrientationPortrait];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setVerticalPagination: NSAutoPagination];

#if 1
    NSRect imageableBounds = [printInfo imageablePageBounds];
    //NSLog(@"%s %d imageableBounds:%@", __FUNCTION__, __LINE__, NSStringFromRect(imageableBounds));
    NSSize paperSize = [printInfo paperSize];
    if (NSWidth(imageableBounds) > paperSize.width) {
        imageableBounds.origin.x = 0;
        imageableBounds.size.width = paperSize.width;
    }
    if (NSHeight(imageableBounds) > paperSize.height) {
        imageableBounds.origin.y = 0;
        imageableBounds.size.height = paperSize.height;
    }
    
    [printInfo setBottomMargin:NSMinY(imageableBounds)];
    [printInfo setTopMargin:paperSize.height - NSMinY(imageableBounds) - NSHeight(imageableBounds)];
    [printInfo setLeftMargin:NSMinX(imageableBounds)];
    [printInfo setRightMargin:paperSize.width - NSMinX(imageableBounds) - NSWidth(imageableBounds)];
#endif

#ifdef METHOD_2
    [printInfo setTopMargin: mm2pix(110)];
#else
    [printInfo setTopMargin: 440];
#endif
    
    [self.myPrescriptionsPrintTV setPatient:myPatientAddressTextField.stringValue];
    [self.myPrescriptionsPrintTV setDoctor:myOperatorIDTextField.stringValue];
    [self.myPrescriptionsPrintTV setPlaceDate:myPlaceDateField.stringValue];
    [self.myPrescriptionsPrintTV setEPrescriptionQRCode:qrCode];
    
    NSImage *signature = [[NSImage alloc] initWithData:[mySignView getSignaturePNG]];
#ifndef METHOD_2
    [signature setFlipped:YES];
#endif
    [self.myPrescriptionsPrintTV setSignature:signature];
    [self.myPrescriptionsPrintTV reloadData];  // height will change
    
    //NSLog(@"%d myPrescriptionsPrintTV frame:%@", __LINE__, NSStringFromRect([myPrescriptionsPrintTV frame]));
    printView = self.myPrescriptionsPrintTV;
    
    NSPrintOperation *printJob = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];

    [printJob setJobTitle:mListOfSectionTitles[row]];

#ifdef DEBUG
    NSRange range1;
    if ([printView knowsPageRange:&range1])// Returns NO if the view uses the default auto-pagination mechanism
        NSLog(@"%s %d knowsPageRange, %@", __FUNCTION__, __LINE__, NSStringFromRange(range1));
    
    NSRange range2 = [printJob pageRange];
    NSLog(@"%s pageRange %@", __FUNCTION__, NSStringFromRange(range2));
#endif
    
    [printJob runOperation];
}

- (IBAction) printDocument:(id)sender
{
    NSString *tabId = [[myTabView selectedTabViewItem] identifier];
    if ([tabId isEqualToString:@"TabPrescription1"]) {
        [self printPrescription:sender];
    }
    else {
        [self printTechInfo:sender];
    }
}

- (IBAction) printSearchResult:(id)sender
{
    NSPrintInfo *printInfo = [[NSPrintInfo alloc] init];
    [printInfo setOrientation:NSPaperOrientationPortrait];
    [printInfo setHorizontalPagination:NSFitPagination];
    NSPrintOperation *printJob = [NSPrintOperation printOperationWithView:myTableView printInfo:printInfo];
    [printJob runOperation];
}

- (IBAction) updateAipsDatabase:(id)sender
{
    // Check if there is an active internet connection
    if ([MLUtilities isConnected]) {
        // Update database
        if ([MLUtilities isGermanApp])
            [self updateDatabase:@"de" for:[MLUtilities appOwner]];
        else if ([MLUtilities isFrenchApp])
            [self updateDatabase:@"fr" for:[MLUtilities appOwner]];
    }
    else {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:NSLocalizedString(@"To update the database you must have an active internet connection", nil)];

        [alert setAlertStyle:NSAlertStyleInformational];
        __weak typeof(self) _self = self;
        [alert beginSheetModalForWindow:[self window]
                      completionHandler:^(NSModalResponse returnCode) {
            [_self alertDidEnd:alert returnCode:returnCode];
        }];
    }
}

- (IBAction) loadAipsDatabase:(id)sender
{
    // Create a file open dialog class
    NSOpenPanel* openDlgPanel = [NSOpenPanel openPanel];
    // Set array of file types
    NSArray *fileTypesArray = [NSArray arrayWithObjects:@"db",@"html",@"csv",nil];
    // Enable options in the dialog
    [openDlgPanel setCanChooseFiles:YES];
    [openDlgPanel setAllowedFileTypes:fileTypesArray];
    [openDlgPanel setAllowsMultipleSelection:false];
    [openDlgPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            // Grab reference to what has been selected
            NSURL *fileURL = [[openDlgPanel  URLs] firstObject];
            NSString *fileName = [fileURL lastPathComponent];
            // Check if file is in the list of allowed files
            if ([MLUtilities checkFileIsAllowed:fileName]) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                // Get documents directory                
                NSString *documentsDir = [MLUtilities documentsDirectory];
                NSString *dstPath = [documentsDir stringByAppendingPathComponent:fileName];
                // Extract source file path
                NSString *srcPath = [NSString stringWithFormat:@"%@", [fileURL path]];
                if (srcPath!=nil && dstPath!=nil) {
                    // If it exists, remove old file
                    if ([fileManager fileExistsAtPath:dstPath])
                        [fileManager removeItemAtPath:dstPath error:nil];
                    // Now copy new file and notify
                    if ([fileManager copyItemAtPath:srcPath toPath:dstPath error:nil]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"MLDidFinishLoading" object:self];
                    }
                }
            }
        }
    }];
}

- (IBAction) managePatients:(id)sender
{
    if (!mPatientSheet)
        mPatientSheet = [[MLPatientSheetController alloc] init];

    [mPatientSheet show:[NSApp mainWindow]];
}

- (IBAction) setOperatorIdentity:(id)sender
{
    //NSLog(@"%s", __FUNCTION__);
    if (!mOperatorIDSheet) {
        mOperatorIDSheet = [[MLOperatorIDSheetController alloc] init];
        NSLog(@"%s %d, MLOperatorIDSheetController:%p", __FUNCTION__, __LINE__, mOperatorIDSheet);
    }

    [mOperatorIDSheet show:[NSApp mainWindow]];
}

- (void) setOperatorID
{
    //NSLog(@"%s", __FUNCTION__);
    if (!mOperatorIDSheet) {
        mOperatorIDSheet = [[MLOperatorIDSheetController alloc] init];
        //NSLog(@"%s %d, MLOperatorIDSheetController:%p", __FUNCTION__, __LINE__, mOperatorIDSheet);
    }
    
    [mPrescriptionAdapter setDoctor:[mOperatorIDSheet loadOperator]];
    [self updateOperatorFields];
}

- (void) updateOperatorFields
{
    NSString *operatorIDStr;
    MLOperator *doctor = [mPrescriptionAdapter doctor];
    
    if ([doctor.familyName length] && [doctor.givenName length]) {
        operatorIDStr = [doctor retrieveOperatorAsString];
    } else {
        operatorIDStr = NSLocalizedString(@"Enter the doctor's address", nil);
    }
    
    NSString *operatorPlace = [[mPrescriptionAdapter doctor] city];
    myOperatorIDTextField.stringValue = operatorIDStr;
    myPlaceDateField.stringValue = [NSString stringWithFormat:@"%@, %@", operatorPlace, [MLUtilities prettyTime]];

    [mySignView setSignature:[[MLPersistenceManager shared] doctorSignature]];
}

#pragma mark - Actions

- (IBAction) findPatient:(id)sender
{
    if (!mPatientSheet) {
        mPatientSheet = [[MLPatientSheetController alloc] init];
    }
    NSString *searchKey = [myPatientSearchField stringValue];
    NSString *patientStr = [mPatientSheet retrievePatientAsString:searchKey];
    myPatientAddressTextField.stringValue = patientStr;
}

- (IBAction) removeItemFromPrescription:(id)sender
{
    NSInteger row = [self.myPrescriptionsTableView rowForView:sender];
#ifdef DEBUG
    NSLog(@"Removing item %ld from prescription", row);
#endif
    // Get item with index
    MLPrescriptionItem *item = [mPrescriptionsCart[0] getItemAtIndex:row];
    if (item!=nil) {
        [mPrescriptionsCart[0] removeItemFromCart:item];

        // If prescription cart is not empty, generate new hash
        if (mPrescriptionsCart[0].cart!=nil && [mPrescriptionsCart[0] size]>0)
            [mPrescriptionsCart[0] makeNewUniqueHash];

        [self.myPrescriptionsTableView reloadData];
        modifiedPrescription = true;
        [self updateButtons];
    }
}

- (IBAction) printMedicineLabel:(id)sender
{
    NSInteger row = [self.myPrescriptionsTableView rowForView:sender];
    //NSLog(@"%s row:%ld", __FUNCTION__, (long)row);

    NSPrintInfo *printInfo = [[NSPrintInfo alloc] init];
    [printInfo setOrientation:NSPaperOrientationPortrait];
    [printInfo setHorizontalPagination:NSFitPagination];
    
    [printInfo setPaperSize:NSMakeSize(mm2pix(36), mm2pix(89))];
    [printInfo setOrientation:NSPaperOrientationLandscape];
    [printInfo setBottomMargin:0];
    [printInfo setTopMargin:0];
    [printInfo setLeftMargin:0];
    [printInfo setRightMargin:0];
    [printInfo setPrinter: [NSPrinter printerWithName:@"DYMO LabelWriter 450"]];
    //NSLog(@"%s %d printInfo: %@", __FUNCTION__, __LINE__, printInfo);
    
    MLOperator *d = [mOperatorIDSheet loadOperator];
    //NSLog(@"doctor title: %@, zip %@, city %@", d.title, d.zipCode, d.city);
    NSString * firstLine = @"";
    if (d.title.length > 0)
        firstLine = [NSString stringWithFormat:@"%@ ", d.title];

    firstLine = [firstLine stringByAppendingString:[NSString stringWithFormat:@"%@ ", d.givenName]];
    firstLine = [firstLine stringByAppendingString:[NSString stringWithFormat:@"%@ - ", d.familyName]];
    firstLine = [firstLine stringByAppendingString:[NSString stringWithFormat:@"%@ ", d.zipCode]];
    //firstLine = [firstLine stringByAppendingString:[NSString stringWithFormat:@"%@ ", d.city]]; // included in placeDate

    NSString *placeDate = myPlaceDateField.stringValue; // TODO: trim trailing time
    NSArray *placeDateArray = [placeDate componentsSeparatedByString:@" ("];
//    NSLog(@"operatorPlace: <%@>", placeDate);
//    NSLog(@"placeDateArray: %lu <%@>", (unsigned long)placeDateArray.count, placeDateArray);

    firstLine = [firstLine stringByAppendingString:[NSString stringWithFormat:@"%@", [placeDateArray objectAtIndex:0]]];

    labelDoctor.stringValue = firstLine;

    
    NSString *patient = myPatientAddressTextField.stringValue;  // TODO: it doesn't contain the birthday
    NSArray *patientArray = [patient componentsSeparatedByString:@"\r\n"];
//    NSLog(@"patient: <%@>", patient);
//    NSLog(@"patientArray: %lu <%@>", (unsigned long)patientArray.count, patientArray);
    MLPatient *p = [mPatientSheet getAllFields];
    labelPatient.stringValue = [NSString stringWithFormat:@"%@, %@ %@",
                                [patientArray objectAtIndex:0],
                                NSLocalizedString(@"born", nil),
                                p.birthDate];

    NSArray *prescriptionBasket = mPrescriptionsCart[0].cart;

    NSString *package = [prescriptionBasket[row] fullPackageInfo];
    NSArray *packageArray = [package componentsSeparatedByString:@", "];
//    NSLog(@"package: <%@>", package);
//    NSLog(@"packageArray: %lu <%@>", (unsigned long)packageArray.count, packageArray);
    labelMedicine.stringValue = [packageArray objectAtIndex:0];

    labelComment.stringValue = [prescriptionBasket[row] comment];
    
    NSArray *swissmedArray = [package componentsSeparatedByString:@" ["];
    //NSLog(@"swissmedArray: %lu <%@>", (unsigned long)swissmedArray.count, swissmedArray);
    labelSwissmed.stringValue = @"";
    if (swissmedArray.count >= 2)
        labelSwissmed.stringValue = [NSString stringWithFormat:@"[%@", [swissmedArray objectAtIndex:1]];

    labelPrice.stringValue = @"";
    if (packageArray.count >= 2) {
        NSArray *priceArray = [[packageArray objectAtIndex:2] componentsSeparatedByString:@" "];
        //NSLog(@"expected PP: <%@>", [priceArray objectAtIndex:0]);
        if ([[priceArray objectAtIndex:0] isEqualToString:@"PP"])
            labelPrice.stringValue = [NSString stringWithFormat:@"CHF\t%@", [priceArray objectAtIndex:1]];
    }

    NSPrintOperation *printJob = [NSPrintOperation printOperationWithView:self.medicineLabelView printInfo:printInfo];
    //[printJob setShowsPrintPanel:NO]; // skip preview

    [printJob runOperation];
}

- (IBAction) onNewPrescription:(id)sender
{
    [self setOperatorID];
    [mPrescriptionsCart[0] clearCart];
    [mPrescriptionAdapter setMedidataRefs:@[]];
    [self.myPrescriptionsTableView reloadData];
    possibleToOverwrite = false;
    modifiedPrescription = false;
    [self updateButtons];
}

- (IBAction) onSearchPatient:(id)sender
{
    [self managePatients:sender];
}

- (IBAction) onCheckForInteractions:(id)sender
{
    [mInteractionsView clearMedBasket];
    // Array of MLPrescriptionItems
    NSArray *prescriptionMeds = mPrescriptionsCart[0].cart;
    for (MLPrescriptionItem *item in prescriptionMeds) {
        [mInteractionsView pushToMedBasket:item.med];
    }

    [self updateInteractionsView];

    // Switch tab view
    mUsedDatabase = kAips;
    mSearchInteractions = true;
    [self setSearchState:kTitle];
    [myToolbar setSelectedItemIdentifier:@"Interaktionen"];
    [myTabView selectTabViewItemAtIndex:0];
}

- (IBAction) onLoadPrescription:(id)sender
{
    // Create a file open dialog class
    NSOpenPanel* openDlgPanel = [NSOpenPanel openPanel];

    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"amk",nil];

    // Enable options in the dialog
    [openDlgPanel setCanChooseFiles:YES];
    [openDlgPanel setAllowedFileTypes:fileTypesArray];
    [openDlgPanel setAllowsMultipleSelection:false];
    [openDlgPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            // Grab reference to what has been selected
            NSURL *fileURL = [[openDlgPanel  URLs] firstObject];
            [self loadPrescription:fileURL andRefreshHistory:YES];
        }
    }];
}

- (IBAction) onSavePrescription:(id)sender
{
    [self savePrescription];
}

- (IBAction) onSendPrescription:(id)sender
{
    [self storeAllPrescriptionComments]; // detect if any comment has been modified
    MLPatient *patient = [mPatientSheet retrievePatient];

    if ([mPrescriptionsCart[0].cart count] < 1) {
        // The send button should be disabled to prevent coming here
#ifdef DEBUG
        NSLog(@"%s cart is empty", __FUNCTION__);
#endif
        return;
    }

    NSURL *url = nil;
    // Skip the following if the prescription has not been edited
    if (modifiedPrescription)
    {
        [mPrescriptionsCart[0] makeNewUniqueHash];  // Issue #9
        mPrescriptionAdapter.cart = mPrescriptionsCart[0].cart;
        
        // Handle the decision automatically
        if (possibleToOverwrite) {
            url = [mPrescriptionAdapter savePrescriptionForPatient:patient
                                                    withUniqueHash:mPrescriptionsCart[0].uniqueHash
                                                      andOverwrite:YES];
        }
        else {
            url = [mPrescriptionAdapter savePrescriptionForPatient:patient
                                                    withUniqueHash:mPrescriptionsCart[0].uniqueHash
                                                      andOverwrite:NO];
            possibleToOverwrite = true;
        }
    }
    else {
        // We have skipped storing the prescription to file,
        // but we still need to define which file URL to "share"
        url = [mPrescriptionAdapter getPrescriptionUrl];  // currentFileName
    }
    
    NSString *filePath = [[url absoluteURL] absoluteString];
    if (!filePath) {
        //NSLog(@"%s %d, URL not defined", __FUNCTION__, __LINE__);
        return;
    }
    
    [self sendPrescription:filePath];

    if (modifiedPrescription) {
        [self updatePrescriptionHistory];
        modifiedPrescription = false;
        [self updateButtons];
    }

    // TODO: maybe we should temporarily disable the send button,
    // unless we want to send the prescription again to another recipient
}

- (IBAction)onSendPrescriptionToMedidata:(id)sender {
    MLPatient *amkPatient = [mPatientSheet retrievePatient];
    MLPatient *dbPatient = [mPatientSheet retrievePatientWithUniqueID:amkPatient.uniqueId];
    NSXMLDocument *doc = [MedidataXMLGenerator xmlInvoiceRequestDocumentWithOperator:[mOperatorIDSheet loadOperator]
                                                                             patient:dbPatient
                                                                   prescriptionItems:mPrescriptionsCart[0].cart];
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"medi.xml"];
    NSData *data = [doc XMLDataWithOptions:NSXMLNodePrettyPrint];
    [data writeToFile:tempPath atomically:YES];
    
    NSString *xsdPath = [[NSBundle mainBundle] pathForResource:@"generalInvoiceRequest_450" ofType:@"xsd"];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/xmllint"];
    [task setArguments:@[
        @"--noout",
        @"--schema",
        xsdPath,
        tempPath,
    ]];
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardError:outputPipe];
    [task launch];
    [task waitUntilExit];
    int exitCode = [task terminationStatus];
    NSData *lintData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *lintResult = [[NSString alloc] initWithData:lintData encoding:NSUTF8StringEncoding];
    
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    
    if (exitCode != 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Error with XML Lint", nil)];
        [alert setInformativeText:lintResult];
        [alert runModal];
        return;
    }
    
    if (![[MLPersistenceManager shared] hadSetupMedidataInvoiceXMLDirectory]) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setMessage:NSLocalizedString(@"Where to save Invoices?", @"")];
        [openPanel setCanChooseFiles:NO];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanCreateDirectories:YES];
        [openPanel setAllowsMultipleSelection:NO];

        NSModalResponse returnCode = [openPanel runModal];
        if (returnCode != NSFileHandlingPanelOKButton) {
            return;
        }
        [[MLPersistenceManager shared] setMedidataInvoiceXMLDirectory:openPanel.URL];
    }
    
    __weak typeof(self) _self = self;
    [[[MedidataClient alloc] init] sendXMLDocumentToMedidata:doc
                                              clientIdSuffix:[MLPersistenceManager shared].doctor.medidataClientId
                                                  completion:^(NSError * _Nullable error, NSString * _Nullable ref) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [[NSAlert alertWithError:error] runModal];
            }
            if (ref) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:NSLocalizedString(@"Sent to Medidata", @"")];
                [alert runModal];
            }
            if (ref) {
                [mPrescriptionAdapter setMedidataRefs:@[ref]];
            } else {
                [mPrescriptionAdapter setMedidataRefs:@[]];
            }
            
            [mPrescriptionsCart[0] makeNewUniqueHash];
            mPrescriptionAdapter.cart = mPrescriptionsCart[0].cart;
            
            // Handle the decision automatically
            [self storeAllPrescriptionComments];
            NSURL *savedFile = [mPrescriptionAdapter savePrescriptionForPatient:[mPatientSheet retrievePatient]
                                                                 withUniqueHash:mPrescriptionsCart[0].uniqueHash
                                                                   andOverwrite:NO];
            possibleToOverwrite = true;
            modifiedPrescription = false;
            [_self updateButtons];
            [_self updatePrescriptionHistory];
            NSURL *folderURL = [[MLPersistenceManager shared] medidataInvoiceXMLDirectory];
            if ([folderURL startAccessingSecurityScopedResource]) {
                NSURL *fileURL = [folderURL URLByAppendingPathComponent: [savedFile.lastPathComponent stringByAppendingString:@".xml"]];
                NSError *writeError = nil;
                [data writeToURL:fileURL options:NSDataWritingAtomic error:&writeError];
                if (writeError) {
                    [[NSAlert alertWithError:writeError] runModal];
                }
                [folderURL stopAccessingSecurityScopedResource];
            } else {
                NSLog(@"Cannot access secure url");
            }
        });
    }];
    
}
- (IBAction)onOepnMedidataResponseWindow:(id)sender {
    MLPatient *p = [mPatientSheet retrievePatient];
    if (!p) return;
    if (![[MLPersistenceManager shared] hadSetupMedidataInvoiceResponseXMLDirectory]) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setMessage:NSLocalizedString(@"Where to save Invoice responses?", @"")];
        [openPanel setCanChooseFiles:NO];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanCreateDirectories:YES];
        [openPanel setAllowsMultipleSelection:NO];

        NSModalResponse returnCode = [openPanel runModal];
        if (returnCode != NSFileHandlingPanelOKButton) {
            return;
        }
        [[MLPersistenceManager shared] setMedidataInvoiceResponseXMLDirectory:openPanel.URL];
    }
    MLMedidataResponsesWindowController *controller = [[MLMedidataResponsesWindowController alloc] initWithPatient:p];
    self.medidataResponseWindowController = controller;
    [controller showWindow:self];
}

- (IBAction) onDeletePrescription:(id)sender
{
    if (mPrescriptionMode) {
        NSInteger row = [mySectionTitles selectedRow];
        if (row > -1) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
            [alert setMessageText:NSLocalizedString(@"Delete prescription?",nil)];
            [alert setInformativeText:NSLocalizedString(@"Do you really want to delete this prescription?",nil)];
            [alert setAlertStyle:NSAlertStyleInformational];
            __weak typeof(self) _self = self;
            [alert beginSheetModalForWindow:[self window]
                          completionHandler:^(NSModalResponse returnCode) {
                [_self deletePrescription:alert returnCode:returnCode];
            }];
        }
    }
}

- (void) deletePrescription:(NSAlert *)alert returnCode:(NSInteger)returnCode
{
    if (returnCode==NSAlertFirstButtonReturn) {
        if (mPrescriptionMode) {
            NSInteger row = [mySectionTitles selectedRow];
            [mPrescriptionAdapter deletePrescriptionWithName:mListOfSectionTitles[row]
                                                  forPatient:[mPatientSheet retrievePatient]];
            [self updatePrescriptionHistory];
            [mPrescriptionsCart[0] clearCart];
            [self.myPrescriptionsTableView reloadData];
        }
    }
}

- (IBAction) showReportFile:(id)sender
{
    [MLAbout showReportFile];
}

- (IBAction) showAboutPanel:(id)sender
{
    [MLAbout showAboutPanel];
}

- (IBAction) showPreferences:(id)sender
{
    MLPreferencesWindowController *preferenceController = [[MLPreferencesWindowController alloc] initWithWindowNibName:@"MLPreferencesWindowController"];
    [preferenceController showWindow:sender];
}

- (IBAction) sendFeedback:(id)sender
{
    [MLAbout sendFeedback];
}

- (IBAction) shareApp:(id)sender
{
    [MLAbout shareApp];
}

- (IBAction) rateApp:(id)sender
{
    [MLAbout rateApp];
}

- (IBAction) clickedTableView:(id)sender
{
    if (mCurrentSearchState == kFullText && !mSearchInteractions) {
        mCurrentWebView = kFullTextSearchView;
        [self updateFullTextSearchView:mFullTextContentStr];
    }
}

#pragma mark -

- (void) showHelp:(id)sender
{
    [MLAbout showHelp];
}

// 'filename' contains the full path
- (void) loadPrescription:(NSURL *)url
        andRefreshHistory:(bool)refresh
{
    [myTabView selectTabViewItemAtIndex:2];
    
    NSString *hash = [mPrescriptionAdapter loadPrescriptionFromURL:url];
#ifdef DEBUG
    NSLog(@"%s hash: %@", __FUNCTION__, hash);
#endif
    mPrescriptionsCart[0].cart = [mPrescriptionAdapter.cart mutableCopy];
    mPrescriptionsCart[0].uniqueHash = hash;

    // Set patient found in prescription
    MLPatient *p = [mPrescriptionAdapter patient];
    if (p!=nil) {
        NSString *patientHash = [p uniqueId];
        if (!mPatientSheet) {
            mPatientSheet = [[MLPatientSheetController alloc] init];
        }

        if (![mPatientSheet patientExistsWithID:patientHash]) {
            // Import patient...
            [mPatientSheet addPatient:p];
        }

        myPatientAddressTextField.stringValue = [p asString];
        [mPatientSheet setSelectedPatient:p];
    }
    
    // Update views
    [self updatePrescriptionsView];
    [self updateOperatorFields];
    if (refresh)
        [self updatePrescriptionHistory];
    
    // Set operator / doctor found in prescription
    /*
    MLOperator *o = [mPrescriptionAdapter doctor];
    if (o!=nil) {
        myOperatorIDTextField.stringValue = [o retrieveOperatorAsString];
    }
    */
    NSURL *baseURL = [[MLPersistenceManager shared] amkBaseDirectory];
    if ([[url path] hasPrefix:baseURL.path]) {
        possibleToOverwrite = true;
        modifiedPrescription = false;
    } else {
        // If it's not in the base directory, we should allow user to save to prescription
        possibleToOverwrite = true;
        modifiedPrescription = true;
    }
    [self updateButtons];
}

/*
 Save button
 A) not possible to overwrite: no alert panel, just save
 
 B) possible to overwrite: 3 buttons [Cancel], [Save], [Overwrite]
    1) Overwrite —> new hash
    3) New file —> new hash
 */
- (void) savePrescription
{
    if (!mPatientSheet)
        mPatientSheet = [[MLPatientSheetController alloc] init];

    mPrescriptionAdapter.cart = mPrescriptionsCart[0].cart;

    [self storeAllPrescriptionComments];
    MLPatient *patient = [mPatientSheet retrievePatient];
    
    if ([mPrescriptionsCart[0].cart count] < 1) {
        // TODO: maybe the save button should be disabled to prevent coming here
#ifdef DEBUG
        NSLog(@"%s cart is empty", __FUNCTION__);
#endif
        return;
    }

    if (!possibleToOverwrite) {
        [mPrescriptionAdapter savePrescriptionForPatient:patient
                                          withUniqueHash:mPrescriptionsCart[0].uniqueHash
                                            andOverwrite:NO];
        possibleToOverwrite = true;
        modifiedPrescription = false;
        [self updateButtons];
        [self updatePrescriptionHistory];

#ifdef DYNAMIC_AMK_SELECTION
        // Select the topmost entry
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [mySectionTitles selectRowIndexes:indexSet byExtendingSelection:NO];
#endif

        return;
    }
    
    NSAlert *alert = [[NSAlert alloc] init]; // Buttons are added from right to left

    [alert addButtonWithTitle:NSLocalizedString(@"Overwrite", nil)];
    [[alert.buttons lastObject] setTag:tagAlertButton_Overwrite];
    
    [alert setMessageText:NSLocalizedString(@"Overwrite prescription?", nil)];
    [alert setInformativeText:NSLocalizedString(@"Do you really want to overwrite the existing prescription or generate a new one?", nil)];

    [alert addButtonWithTitle:NSLocalizedString(@"New prescription", nil)];
    [[alert.buttons lastObject] setTag:tagAlertButton_NewFile];

    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [[alert.buttons lastObject] setTag:tagAlertButton_Cancel];

    //NSLog(@"Alert buttons: %ld", [alert.buttons count]);

    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {

        //NSLog(@"returnCode: %ld", returnCode);

        // Create a new hash for both "overwrite" and "new file"
        if (returnCode != tagAlertButton_Cancel)
            [mPrescriptionsCart[0] makeNewUniqueHash];  // Issue #9

        NSURL *url = nil;

        if (returnCode == tagAlertButton_Overwrite) {
            url = [mPrescriptionAdapter savePrescriptionForPatient:patient
                                                    withUniqueHash:mPrescriptionsCart[0].uniqueHash
                                                      andOverwrite:YES];
            modifiedPrescription = false;
            [self updateButtons];
        }
        else if (returnCode == tagAlertButton_NewFile) {
            url = [mPrescriptionAdapter savePrescriptionForPatient:patient
                                                    withUniqueHash:mPrescriptionsCart[0].uniqueHash
                                                      andOverwrite:NO];
            possibleToOverwrite = true;
            modifiedPrescription = false;
            [self updateButtons];
        }

        [self updatePrescriptionHistory];

#ifdef DYNAMIC_AMK_SELECTION
        // Select the topmost entry
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [mySectionTitles selectRowIndexes:indexSet byExtendingSelection:NO];
#endif
    }];
}

- (void) sendPrescription:(NSString *)filePath
{
    NSString *mailBody = [NSString stringWithFormat:@"%@\n\niOS: %@\nAndroid: %@\n",
                          NSLocalizedString(@"Open with", nil),
                          @"https://itunes.apple.com/ch/app/generika/id520038123?mt=8",
                          @"https://play.google.com/store/apps/details?id=org.oddb.generika"];

    NSURL *urlAttachment = [NSURL fileURLWithPath:filePath];
    NSArray *objectsToShare = @[mailBody, urlAttachment];
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:objectsToShare];
    sharingServicePicker.delegate = self;
    
    [sharingServicePicker showRelativeToRect:[sendButton bounds]
                                      ofView:sendButton
                               preferredEdge:NSMinYEdge];
}

- (void) launchProgressIndicator
{
    if (progressIndicator!=nil) {
        [progressIndicator stopAnimation:self];
        [progressIndicator removeFromSuperview];
    }
    
    CGFloat viewWidth = myView.bounds.size.width;
    CGFloat viewHeight = myView.bounds.size.height;
    progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(viewWidth/2-16, viewHeight/2-16, 32, 32)];
    [progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
    [progressIndicator startAnimation:self];
    
    [myView addSubview:progressIndicator];
}

- (void) stopProgressIndicator
{
    [progressIndicator stopAnimation:self];
    [progressIndicator removeFromSuperview];
}

/**
 Switch app state
 */
- (void) switchTabs:(NSToolbarItem *)item
{
    switch (item.tag) {
        case tagToolbarButton_Compendium:
        {
            // NSLog(@"AIPS Database");
            mUsedDatabase = kAips;
            mSearchInteractions = false;
            mPrescriptionMode = false;
            //
            searchResults = [NSArray array];
            // MLMainWindowController* __weak weakSelf = self;
            MLMainWindowController* __unsafe_unretained weakSelf = self;
            //
            // dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.searchdb", nil);
            dispatch_async(mSearchQueue, ^(void) {
                MLMainWindowController* scopeSelf = weakSelf;
                while (mSearchInProgress) {
                   [NSThread sleepForTimeInterval:0.005];  // Wait for 5ms
                }
                if (!mSearchInProgress) {
                    @synchronized(self) {
                        mSearchInProgress = true;
                    }
                    
                    if (mCurrentSearchState!=kFullText) {
                        mCurrentSearchState = kTitle;
                        mCurrentSearchKey = @"";
                    }
                    searchResults = [scopeSelf searchAnyDatabasesWith:mCurrentSearchKey];
                    // Update tableview
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [scopeSelf updateTableView];
                        [self.myTableView reloadData];
                        @synchronized(self) {
                            mSearchInProgress = false;
                        }
                    });
                }
            });
            // Switch tab view
            [self updateExpertInfoView:nil];
            [myTabView selectTabViewItemAtIndex:0];
            break;
        }

        case tagToolbarButton_Favorites:
        {
            // NSLog(@"Favorites");
            mUsedDatabase = kFavorites;
            mSearchInteractions = false;
            mPrescriptionMode = false;
            //
            searchResults = [NSArray array];
            // MLMainWindowController* __weak weakSelf = self;
            MLMainWindowController* __unsafe_unretained weakSelf = self;
            //
            // dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.searchdb", nil);
            dispatch_async(mSearchQueue, ^(void) {
                MLMainWindowController* scopeSelf = weakSelf;
                while (mSearchInProgress) {
                   [NSThread sleepForTimeInterval:0.005];  // Wait for 5ms
                }
                if (!mSearchInProgress) {
                    @synchronized(self) {
                        mSearchInProgress = true;
                    }
                    // mCurrentSearchState = kTitle;
                    searchResults = [scopeSelf retrieveAllFavorites];

                    // Update tableview
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [scopeSelf updateTableView];
                        [self.myTableView reloadData];
                        @synchronized(self) {
                            mSearchInProgress = false;
                        }
                    });
                }
            });
            // Switch tab view
            [self updateExpertInfoView:nil];
            [myTabView selectTabViewItemAtIndex:0];
            break;
        }

        case tagToolbarButton_Interactions:
        {
            // NSLog(@"Interactions");
            mUsedDatabase = kAips;
            mSearchInteractions = true;
            mPrescriptionMode = false;
            [self stopProgressIndicator];
            [self updateInteractionsView];
            // Switch tab view
            [myTabView selectTabViewItemAtIndex:0];
            break;
        }

        case tagToolbarButton_Prescription:
            // NSLog(@"Rezept");
            mUsedDatabase = kAips;
            mSearchInteractions = false;
            mPrescriptionMode = true;
            [self stopProgressIndicator];
            [self updatePrescriptionsView];
            [self updatePrescriptionHistory];
            // Switch tab view
            [myTabView selectTabViewItemAtIndex:2];
            break;

        case tagToolbarButton_Export:
        {
            mUsedDatabase = kAips;
            [self stopProgressIndicator];
            [self setSearchState:kFullText];

#ifdef CSV_EXPORT_RESTORES_PREVIOUS_STATE
            NSInteger savedState = mCurrentSearchState;
            NSInteger savedTabIndex = [myTabView indexOfTabViewItem:[myTabView selectedTabViewItem]];
#endif

            [self exportWordListSearchResults:item];
            
#ifdef CSV_EXPORT_RESTORES_PREVIOUS_STATE
            [self setSearchState:savedState];
            [myTabView selectTabViewItemAtIndex:savedTabIndex];
#endif
        }
            break;

        default:
        case tagToolbarButton_Amiko:
            break;
    }
}

- (NSArray *) retrieveAllFavorites
{
    NSMutableArray *medList = [NSMutableArray array];

#ifdef DEBUG
    NSDate *startTime = [NSDate date];
#endif
    
    if (mCurrentSearchState!=kFullText) {
        if (mDb!=nil) {
            for (NSString *regnrs in favoriteMedsSet) {
                NSArray *med = [mDb searchRegNr:regnrs];
                if (med!=nil && [med count]>0)
                    [medList addObject:med[0]];
            }
        }
    }
    else {
        if (mFullTextDb!=nil) {
            for (NSString *hashId in favoriteFTEntrySet) {
                MLFullTextEntry *entry = [mFullTextDb searchHash:hashId];
                if (entry!=nil)
                    [medList addObject:entry];
            }
        }
    }

#ifdef DEBUG
        NSDate *endTime = [NSDate date];
        NSTimeInterval execTime = [endTime timeIntervalSinceDate:startTime];
        NSLog(@"%ld favorites in %dms", [medList count], (int)(1000*execTime+0.5));
#endif
    
    return medList;
}

- (void) saveFavorites
{
    NSMutableDictionary *rootObject = [NSMutableDictionary dictionary];
    
    if (favoriteMedsSet!=nil)
        [rootObject setValue:favoriteMedsSet forKey:@"kFavMedsSet"];
    
    if (favoriteFTEntrySet!=nil)
        [rootObject setValue:favoriteFTEntrySet forKey:@"kFavFTEntrySet"];

    // Save contents of rootObject by key, value must conform to NSCoding protocolw
    [NSKeyedArchiver archiveRootObject:rootObject toFile:[[MLPersistenceManager shared] favouritesFile].path];
}

- (void) loadFavorites:(MLDataStore *)favorites
{
    NSString *path = [[MLPersistenceManager shared] favouritesFile].path;
    
    // Retrieves unarchived dictionary into rootObject
    NSMutableDictionary *rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    if ([rootObject valueForKey:@"kFavMedsSet"]) {
        favorites.favMedsSet = (NSSet *)[rootObject valueForKey:@"kFavMedsSet"];
    }
    
    if ([rootObject valueForKey:@"kFavFTEntrySet"]) {
        favorites.favFTEntrySet = (NSSet *)[rootObject valueForKey:@"kFavFTEntrySet"];
    }
}

- (void) setSearchState: (NSInteger)searchState
{
    NSArray<NSButton*> *buttons = @[
        self.preparationButton,
        self.registrationOwnerButton,
        self.atcButton,
        self.registrationNumberButton,
        self.therapyButton,
        self.fullTextButton
    ];
    
    for (NSButton *button in buttons) {
        MLButtonCell *cell = [button cell];
        [cell setSelected:NO];
        [button updateCell:cell];
    }
    
    switch (searchState) {
        case kTitle:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kTitle;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@",
                                                        NSLocalizedString(@"Search", nil),
                                                        NSLocalizedString(@"Preparation", nil)]];
            [(MLButtonCell*)self.preparationButton.cell setSelected:YES];
            [self.preparationButton updateCell:self.preparationButton.cell];
            break;
        case kAuthor:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kAuthor;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@",
                                                        NSLocalizedString(@"Search", nil),
                                                        NSLocalizedString(@"Owner", nil)]];
            [(MLButtonCell*)self.registrationOwnerButton.cell setSelected:YES];
            [self.registrationOwnerButton updateCell:self.registrationOwnerButton.cell];
            break;
        case kAtcCode:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kAtcCode;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@",
                                                        NSLocalizedString(@"Search", nil),
                                                        NSLocalizedString(@"ATC Code", nil)]];
            [(MLButtonCell*)self.atcButton.cell setSelected:YES];
            [self.atcButton updateCell:self.atcButton.cell];
            break;
        case kRegNr:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kRegNr;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@",
                                                        NSLocalizedString(@"Search", nil),
                                                        NSLocalizedString(@"Reg. No", nil)]];
            [(MLButtonCell*)self.registrationNumberButton.cell setSelected:YES];
            [self.registrationNumberButton updateCell:self.registrationNumberButton.cell];
            break;
        case kTherapy:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kTherapy;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@",
                                                        NSLocalizedString(@"Search", nil),
                                                        NSLocalizedString(@"Therapy", nil)]];
            [(MLButtonCell*)self.therapyButton.cell setSelected:YES];
            [self.therapyButton updateCell:self.therapyButton.cell];
            break;
        case kWebView:
            // Hide textfinder
            [self hideTextFinder];
            // NOTE: Commented out because we're using SHCWebView now (02.03.2015)
            /*
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kWebView;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@",
             NSLocalizedString(@"Search", nil),
             @"in Fachinformation"]]; // fr: @"Notice Infopro"
            */
            break;
        case kFullText:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kFullText;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@",
                                                        NSLocalizedString(@"Search", nil),
                                                        NSLocalizedString(@"Full Text", nil)]];
            [(MLButtonCell*)self.fullTextButton.cell setSelected:YES];
            [self.fullTextButton updateCell:self.fullTextButton.cell];
            break;
    }
    mCurrentSearchKey = @"";
    mCurrentSearchState = searchState;
}

- (NSArray *) searchAnyDatabasesWith:(NSString *)searchQuery
{
    NSArray *searchRes = [NSArray array];
    
#ifdef DEBUG
    NSDate *startTime = [NSDate date];
#endif
    
    if (mCurrentSearchState == kTitle)
        searchRes = [mDb searchTitle:searchQuery];  // NSArray of MLMedication
    else if (mCurrentSearchState == kAuthor)
        searchRes = [mDb searchAuthor:searchQuery];
    else if (mCurrentSearchState == kAtcCode)
        searchRes = [mDb searchATCCode:searchQuery];
    else if (mCurrentSearchState == kRegNr)
        searchRes = [mDb searchRegNr:searchQuery];
    else if (mCurrentSearchState == kTherapy)
        searchRes = [mDb searchApplication:searchQuery];
    else if (mCurrentSearchState == kFullText) {
        if ([searchQuery length]>2)
            searchRes = [mFullTextDb searchKeyword:searchQuery];    // NSArray of FullTextEntry
    }

    mCurrentSearchKey = searchQuery;
    
#ifdef DEBUG    
    NSDate *endTime = [NSDate date];
    NSTimeInterval execTime = [endTime timeIntervalSinceDate:startTime];

    int timeForSearch_ms = (int)(1000*execTime+0.5);
    NSLog(@"%ld Treffer in %dms", (unsigned long)[searchRes count], timeForSearch_ms);
#endif
    return searchRes;
}

- (void) addTitle:(NSString *)title andPackInfo:(NSString *)packinfo andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = NSLocalizedString(@"Not specified", nil);

    if (![packinfo isEqual:[NSNull null]]) {
        if ([packinfo length]>0) {
            if (mSearchInteractions==false)
                m.subTitle = packinfo;
            else {
                // We pass atccode instead, which needs to be unpacked
                NSArray *m_atc = [packinfo componentsSeparatedByString:@";"];
                NSMutableString *m_atccode_str = nil;
                NSMutableString *m_atcclass_str = nil;
                if ([m_atc count] > 1) {
                    if (![[m_atc objectAtIndex:0] isEqual:nil])
                        m_atccode_str = [NSMutableString stringWithString:[m_atc objectAtIndex:0]];
                    if (![[m_atc objectAtIndex:1] isEqual:nil])
                        m_atcclass_str = [NSMutableString stringWithString:[m_atc objectAtIndex:1]];
                }
                if ([m_atccode_str isEqual:[NSNull null]])
                    [m_atccode_str setString:NSLocalizedString(@"Not specified", nil)];
                if ([m_atcclass_str isEqual:[NSNull null]])
                    [m_atcclass_str setString:NSLocalizedString(@"Not specified", nil)];
                m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_atccode_str, m_atcclass_str];
            }
        } else
            m.subTitle = NSLocalizedString(@"Not specified", nil);
    } else
        m.subTitle = NSLocalizedString(@"Not specified", nil);

    m.medId = medId;
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title andAuthor:(NSString *)author andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = NSLocalizedString(@"Not specified", nil);

    if (![author isEqual:[NSNull null]]) {
        if ([author length]>0)
            m.subTitle = author;
        else
            m.subTitle = NSLocalizedString(@"Not specified", nil); // @"k.A.";
    } else
        m.subTitle = NSLocalizedString(@"Not specified", nil);

    m.medId = medId;
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title andAtcCode:(NSString *)atccode andAtcClass:(NSString *)atcclass andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = NSLocalizedString(@"Not specified", nil);
    
    if ([atccode isEqual:[NSNull null]])
        atccode = NSLocalizedString(@"Not specified", nil);

    if ([atcclass isEqual:[NSNull null]])
        atcclass = NSLocalizedString(@"Not specified", nil);

    NSArray *m_atc = [atccode componentsSeparatedByString:@";"];
    NSArray *m_class = [atcclass componentsSeparatedByString:@";"];
    NSMutableString *m_atccode_str = nil;
    NSMutableString *m_atcclass_str = nil;
    if ([m_atc count] > 1) {
        if (![[m_atc objectAtIndex:0] isEqual:nil])
            m_atccode_str = [NSMutableString stringWithString:[m_atc objectAtIndex:0]];
        if (![[m_atc objectAtIndex:1] isEqual:nil])
            m_atcclass_str = [NSMutableString stringWithString:[m_atc objectAtIndex:1]];
    } else {
        m_atccode_str = [NSMutableString stringWithString:NSLocalizedString(@"Not specified", nil)];
    }

    if ([m_atccode_str isEqual:[NSNull null]])
        [m_atccode_str setString:NSLocalizedString(@"Not specified", nil)];

    if ([m_atcclass_str isEqual:[NSNull null]])
        [m_atcclass_str setString:NSLocalizedString(@"Not specified", nil)];
    
    NSMutableString *m_atcclass = nil;
    if ([m_class count] == 2) {  // *** Ver.<1.2
        m_atcclass = [NSMutableString stringWithString:[m_class objectAtIndex:1]];
        if ([m_atcclass isEqual:[NSNull null]])
            [m_atcclass setString:NSLocalizedString(@"Not specified", nil)];

        m.subTitle = [NSString stringWithFormat:@"%@ - %@\n%@", m_atccode_str, m_atcclass_str, m_atcclass];
    }
    else if ([m_class count] == 3) {  // *** Ver.>=1.2
        NSArray *m_atc_class_l4_and_l5 = [m_class[2] componentsSeparatedByString:@"#"];
        int n = (int)[m_atc_class_l4_and_l5 count];
        if (n>1)
            m_atcclass = [NSMutableString stringWithString:[m_atc_class_l4_and_l5 objectAtIndex:n-2]];

        if ([m_atcclass isEqual:[NSNull null]])
            [m_atcclass setString:NSLocalizedString(@"Not specified", nil)];

        m.subTitle = [NSString stringWithFormat:@"%@ - %@\n%@\n%@", m_atccode_str, m_atcclass_str, m_atcclass, m_class[1]];
    }
    else {
        m_atcclass = [NSMutableString stringWithString:NSLocalizedString(@"Not specified", nil)];
        m.subTitle = NSLocalizedString(@"Not specified", nil);
    }
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title andRegnrs:(NSString *)regnrs andAuthor:(NSString *)author andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = NSLocalizedString(@"Not specified", nil);

    NSMutableString *m_regnrs = [NSMutableString stringWithString:regnrs];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_regnrs isEqual:[NSNull null]])
        [m_regnrs setString:NSLocalizedString(@"Not specified", nil)];

    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:NSLocalizedString(@"Not specified", nil)];

    m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_regnrs, m_auth];
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addSubstances:(NSString *)substances andTitle:(NSString *)title andAuthor:(NSString *)author andMedId:(long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![substances isEqual:[NSNull null]]) {
        // Unicode for character 'alpha' = &#593;
        substances = [substances stringByReplacingOccurrencesOfString:@"&alpha;" withString:@"ɑ"];
        m.title = substances;
    }
    else
        m.title = NSLocalizedString(@"Not specified", nil);

    NSMutableString *m_title = [NSMutableString stringWithString:title];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_title isEqual:[NSNull null]])
        [m_title setString:NSLocalizedString(@"Not specified", nil)];
    
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:NSLocalizedString(@"Not specified", nil)];
    
    m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_title, m_auth];
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle: (NSString *)title
  andApplications: (NSString *)applications
         andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = NSLocalizedString(@"Not specified", nil);

    NSArray *m_applications = [applications componentsSeparatedByString:@";"];
    NSString *m_swissmedic = [m_applications firstObject];
    NSString *m_bag = nil;
    if ([m_applications count] > 1) {
        m_bag = [m_applications objectAtIndex:1];
    }
    if (!m_swissmedic) {
        m_swissmedic = NSLocalizedString(@"Not specified", nil);
    }
    if (!m_bag) {
        m_bag = NSLocalizedString(@"Not specified", nil); // @"k.A.";
    }

    m.subTitle = [NSString stringWithFormat:@"%@\n%@", m_swissmedic, m_bag];
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addKeyword: (NSString *)keyword
         andNumHits: (unsigned long)numHits
            andHash: (NSString *)hash
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![keyword isEqual:[NSNull null]])
        m.title = keyword;
    else
        m.title = NSLocalizedString(@"Not specified", nil);

    m.subTitle = [NSString stringWithFormat:@"%ld Treffer", numHits];  // TODO: localize
    m.hashId = hash;
    
    [medi addObject:m];
}

- (void) updateTableView
{
    if (searchResults) {
        if (medi != nil)
            [medi removeAllObjects];
        
        if (favoriteKeyData != nil)
            [favoriteKeyData removeAllObjects];
        
        if (mCurrentSearchState == kTitle) {
            if (mUsedDatabase == kAips) {
                for (MLMedication *m in searchResults) {
                    if (![m isKindOfClass:[MLMedication class]]) {
                        continue;
                    }
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        if (mSearchInteractions == false)
                            [self addTitle:m.title andPackInfo:m.packInfo andMedId:m.medId];
                        else
                            [self addTitle:m.title andPackInfo:m.atccode andMedId:m.medId];
                    }
                }
            }
            else if (mUsedDatabase == kFavorites) {
                for (MLMedication *m in searchResults) {
                    if (![m isKindOfClass:[MLMedication class]]) {
                        continue;
                    }
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title andPackInfo:m.packInfo andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kAuthor) {
            for (MLMedication *m in searchResults) {
                if (![m isKindOfClass:[MLMedication class]]) {
                    continue;
                }
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title andAuthor:m.auth andMedId:m.medId];
                    }
                } else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title andAuthor:m.auth andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kAtcCode) {
            for (MLMedication *m in searchResults) {
                if (![m isKindOfClass:[MLMedication class]]) {
                    continue;
                }
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title andAtcCode:m.atccode andAtcClass:m.atcClass andMedId:m.medId];
                    }
                } else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title andAtcCode:m.atccode andAtcClass:m.atcClass andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kRegNr) {
            for (MLMedication *m in searchResults) {
                if (![m isKindOfClass:[MLMedication class]]) {
                    continue;
                }
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title andRegnrs:m.regnrs andAuthor:m.auth andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title andRegnrs:m.regnrs andAuthor:m.auth andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kTherapy) {
            for (MLMedication *m in searchResults) {
                if (![m isKindOfClass:[MLMedication class]]) {
                    continue;
                }
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title andApplications:m.application andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title andApplications:m.application andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kFullText) {
            for (MLFullTextEntry *e in searchResults) {
                if (![e isKindOfClass:[MLFullTextEntry class]]) {
                    continue;
                }
                if (mUsedDatabase == kAips || mUsedDatabase == kFavorites) {
                    if (e.hash != nil && ![e.hash isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:e.hash];
                        [self addKeyword:e.keyword andNumHits:e.numHits andHash:e.hash];
                    }
                }
            }
        }

        // Sort alphabetically
        if (mUsedDatabase == kFavorites) {            
            NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
            [medi sortUsingDescriptors:[NSArray arrayWithObject:titleSort]];
        }        
    }
    
    [self stopProgressIndicator];
}

/**
 Add med in the buffer to the interaction basket
 */
- (void) pushToMedBasket:(MLMedication *)med
{
    [mInteractionsView pushToMedBasket:med];
}

/**
 The following function intercepts messages sent from javascript to objective C and
 acts as a bridge between JS and ObjC
 */
- (void) createJSBridge
{
    mJSBridge = [WebViewJavascriptBridge bridgeForWebView:myWebView];
    
    [mJSBridge registerHandler:@"JSToObjC_"
                       handler:^(id msg, WVJBResponseCallback responseCallback) {
        if ([msg count]==3) {
            // --- Interactions ---
            if ([msg[0] isEqualToString:@"interactions_cb"]) {
                if ([msg[1] isEqualToString:@"notify_interaction"]) {
                    [mInteractionsView sendInteractionNotice];
                } else if ([msg[1] isEqualToString:@"delete_all"]) {
                    [mInteractionsView clearMedBasket];
                } else if ([msg[1] isEqualToString:@"delete_row"]) {
                    [mInteractionsView removeFromMedBasketForKey:msg[2]];
                } else if ([msg[1] isEqualToString:@"open_link"]) {
                    NSURL *url = [NSURL URLWithString:msg[2]];
                    [[NSWorkspace sharedWorkspace] openURL:url];
                }
                // Update med basket
                mCurrentWebView = kInteractionsCartView;
                [self updateInteractionsView];
            }
        }
        else if ([msg count]==4) {
            // --- Full text search ---
            if ([msg[0] isEqualToString:@"main_cb"]) {
                if ([msg[1] isEqualToString:@"display_fachinfo"]) {
                    NSString *ean = msg[2];
                    NSString *anchor = msg[3];
                    if ([ean isNotEqualTo:[NSNull null]]) {
                        mCurrentWebView = kExpertInfoView;
                        mMed = [mDb getMediWithRegnr:ean];
                        [self updateExpertInfoView:anchor];
                    }
                }
            }
        }
    }];
}

#pragma mark - WebFrameLoadDelegate

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    // Inject JS into webview
    if ([mAnchor isNotEqualTo:[NSNull null]]) {
        NSString *jsCallback = [NSString stringWithFormat:@"moveToHighlight('%@')", mAnchor];
        [myWebView stringByEvaluatingJavaScriptFromString:jsCallback];
    }
}

- (void) updateExpertInfoView:(NSString *)anchor
{
    NSString *colorCss = [MLUtilities getColorCss];
    
    // Load style sheet from file
    NSString *amikoCssPath = [[NSBundle mainBundle] pathForResource:@"amiko_stylesheet" ofType:@"css"];
    NSString *amikoCss = @"";
    if (amikoCssPath != nil)
        amikoCss = [NSString stringWithContentsOfFile:amikoCssPath encoding:NSUTF8StringEncoding error:nil];
    else
        amikoCss = [NSString stringWithString:mMed.styleStr];
    
    // Load javascript from file
    NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"main_callbacks" ofType:@"js"];
    NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath encoding:NSUTF8StringEncoding error:nil];
    
    // Generate html string
    NSString *htmlStr = mMed.contentStr;
    if (!htmlStr) {
        htmlStr = @"<html><head></head><body></body></html>";
    }
    htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"<html>"
                                                 withString:@"<!DOCTYPE html><html><head><meta charset=\"utf-8\" /><meta name=\"supported-color-schemes\" content=\"light dark\" />"];
    htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"<head></head>"
                                                 withString:[NSString stringWithFormat:@"<script type=\"text/javascript\">%@</script><style type=\"text/css\">%@</style><style type=\"text/css\">%@</style></head>", jscriptStr, colorCss, amikoCss]];

    // Some tables have the color set in the HTML string (not set with CSS)
    htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"background-color: #EEEEEE"
                                                 withString:@"background-color: var(--background-color-gray)"];
    
    if (mCurrentSearchState == kFullText) {
        NSString *keyword = [mFullTextEntry keyword];
        if ([keyword isNotEqualTo:[NSNull null]]) {
            // Instead of appending like in the Windows version,
            // insert before "</body>"
            NSString *jsCode = [NSString stringWithFormat:@"highlightText(document.body,'%@')", keyword];
            NSString *extraHtmlCode = [NSString stringWithFormat:@"<script>%@</script>\n </body>", jsCode];
            htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"</body>"
                                                         withString:extraHtmlCode];
        }
        mAnchor = anchor;
    }
    
    NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    [[myWebView mainFrame] loadHTMLString:htmlStr
                                  baseURL:mainBundleURL];
    
    if (mPrescriptionMode == false) {
        // Extract section ids
        if (![mMed.sectionIds isEqual:[NSNull null]])
            mListOfSectionIds = [mMed listOfSectionIds];
        // Extract section titles
        if (![mMed.sectionTitles isEqual:[NSNull null]])
            mListOfSectionTitles = [mMed listOfSectionTitles];
        
        [mySectionTitles reloadData];
    }
}

- (void) updateInteractionsView
{
    // Generate main interaction table
    [mInteractionsView fullInteractionsHtml:mInteractions withCompletion:^(NSString *htmlStr) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // With the following implementation, the images are not loaded
            // NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
            // [[myWebView mainFrame] loadHTMLString:htmlStr baseURL:mainBundleURL];
            
            [[myWebView mainFrame] loadHTMLString:htmlStr
                                          baseURL:[[NSBundle mainBundle] resourceURL]];
            
            if (mPrescriptionMode == false) {
                // Update section title anchors
                if (![mInteractionsView.listofSectionIds isEqual:[NSNull null]])
                    mListOfSectionIds = mInteractionsView.listofSectionIds;
                // Update section titles (here: identical to anchors)
                if (![mInteractionsView.listofSectionTitles isEqual:[NSNull null]])
                    mListOfSectionTitles = mInteractionsView.listofSectionTitles;
                
                [mySectionTitles reloadData];
            }
        });
    }];
}

- (void) updatePrescriptionsView
{
    // Switch tab view
    [myTabView selectTabViewItemAtIndex:2];
    // Update date
    NSString *placeDate = [mPrescriptionAdapter placeDate];
    if (placeDate!=nil)
        myPlaceDateField.stringValue = placeDate;
    [self.myPrescriptionsTableView reloadData];
    mPrescriptionMode = true;
    [myToolbar setSelectedItemIdentifier:@"Rezept"];
    // [self.mySectionTitles reloadData];
}

- (void) updateFullTextSearchView:(NSString *)contentStr
{
    NSString *colorCss = [MLUtilities getColorCss];

    // Load style sheet from file
    NSString *fullTextCssPath = [[NSBundle mainBundle] pathForResource:@"fulltext_style" ofType:@"css"];
    NSString *fullTextCss = [NSString stringWithContentsOfFile:fullTextCssPath encoding:NSUTF8StringEncoding error:nil];
    
    // Load javascript from file
    NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"main_callbacks" ofType:@"js"];
    NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *htmlStr = [NSString stringWithFormat:@"<html><head><meta charset=\"utf-8\" /><meta name=\"supported-color-schemes\" content=\"light dark\" />"];
    htmlStr = [htmlStr stringByAppendingFormat:@"<script type=\"text/javascript\">%@</script><style type=\"text/css\">%@</style><style type=\"text/css\">%@</style></head><body><div id=\"fulltext\">%@</div></body></html>",
               jscriptStr,
               colorCss,
               fullTextCss,
               contentStr];
  
    [[myWebView mainFrame] loadHTMLString:htmlStr
                                  baseURL:[[NSBundle mainBundle] resourceURL]];
    
    // Update right pane (section titles)
    if (![mFullTextSearch.listOfSectionIds isEqual:[NSNull null]])
        mListOfSectionIds = mFullTextSearch.listOfSectionIds;
    if (![mFullTextSearch.listOfSectionTitles isEqual:[NSNull null]])
        mListOfSectionTitles = mFullTextSearch.listOfSectionTitles;
    
    [mySectionTitles reloadData];
}

// Also, possibly set the flag for a modified prescription
- (void) storeAllPrescriptionComments
{
    // Get all comments
    NSMutableArray *comments = [[NSMutableArray alloc] init];
    NSInteger numRows = [self.myPrescriptionsTableView numberOfRows];
    for (int r=0; r<numRows; ++r) {
        MLPrescriptionCellView *cellView = [self.myPrescriptionsTableView viewAtColumn:0 row:r makeIfNecessary:YES];
        NSTextField *textField = [cellView editableTextField];
        [comments addObject:[textField stringValue]];
    }

    int row = 0;
    for (MLPrescriptionItem *item in mPrescriptionsCart[0].cart) {
        if (row < numRows) {
            //NSLog(@"%d <%@> <%@>", __LINE__, item.comment, [comments objectAtIndex:row]);
            if (![item.comment isEqualToString:[comments objectAtIndex:row]]) {
                item.comment = [comments objectAtIndex:row];
                modifiedPrescription = true;
            }
        }

        row++;
    }
    [self updateButtons];
}

- (void) addAllPackagesOfMedToPrescriptionCart:(MLMedication*)med {
    NSArray *listOfPackInfos = [[med packInfo] componentsSeparatedByString:@"\n"];
    for (int i = 0; i < listOfPackInfos.count; i++) {
        [self addPackageAtIndex:i ofMedToPrescriptionCart:med];
    }
}

- (void) addPackageAtIndex:(NSInteger)index ofMedToPrescriptionCart:(MLMedication*)med {
    NSArray *listOfPackInfos = [[med packInfo] componentsSeparatedByString:@"\n"];
    NSArray *listOfPacks = [[med packages] componentsSeparatedByString:@"\n"];
    NSString *s = listOfPackInfos[index];
    NSString *package = listOfPacks[index];
    NSArray *p = [package componentsSeparatedByString:@"|"];
    NSString *eanCode = [p objectAtIndex:9];
    
    MLPrescriptionItem *item = [[MLPrescriptionItem alloc] init];
    item.eanCode = eanCode;
    item.fullPackageInfo = s;
    item.mid = med.medId;

    if (item.title) {
        [self addItem:item toPrescriptionCartWithId:0];
    }
}

- (void) addItem:(MLPrescriptionItem *)item toPrescriptionCartWithId:(NSInteger)n
{
    if (n < NUM_ACTIVE_PRESCRIPTIONS)
    {
        if (mPrescriptionsCart[n].cart == nil) {
            mPrescriptionsCart[n].cart = [[NSMutableArray alloc] init];
            mPrescriptionsCart[n].cartId = n;
        }

        // Get all prescription comments from table
        [self storeAllPrescriptionComments];
        
        // Get medi
        dispatch_async(mSearchQueue, ^(void) {
            item.med = [mDb getShortMediWithId:item.mid];
            dispatch_async(dispatch_get_main_queue(), ^{
                [mPrescriptionsCart[n] addItemToCart:item];
                [self.myPrescriptionsTableView reloadData];
                
                modifiedPrescription = true;
                [self updateButtons];
            });
        });
    }
}

- (void) removeItem:(MLPrescriptionItem *)item fromPrescriptionCartWithId:(NSInteger)n
{
    if (n < NUM_ACTIVE_PRESCRIPTIONS) {
        [mPrescriptionsCart[n] removeItemFromCart:item];
        [self.myPrescriptionsTableView reloadData];
        modifiedPrescription = true;
        [self updateButtons];
    }
}

- (BOOL) validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
    if ([responder isKindOfClass:[MLEditableTextField class]]) {
        //NSLog(@"%s", __FUNCTION__);
        return YES;
    }
    
    return [super validateProposedFirstResponder:responder forEvent:event];
}

#pragma mark - NSTabViewDelegate

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSString *tabId = (NSString *)tabViewItem.identifier;
    if ([tabId isEqualToString:@"TabWebview"]) {
        
    }
    else if ([tabId isEqualToString:@"TabInteractions"]) {
        
    }
    else if ([tabId isEqualToString:@"TabPrescription1"]) {
        [self setOperatorID];
        [myPrescriptionsTableView reloadData];
        [myPrescriptionsPrintTV reloadData];
        [self updateButtons];
    }
}

#pragma mark - NSTableViewDelegate

- (CGFloat) tableView: (NSTableView *)tableView heightOfRow: (NSInteger)row
{
    if (tableView == self.myTableView) {
        NSString *text = [medi[row] title];
        NSFont *textFont = [NSFont boldSystemFontOfSize:13.0f];
        CGSize textSize = NSSizeFromCGSize([text sizeWithAttributes:[NSDictionary dictionaryWithObject:textFont
                                                                                                forKey:NSFontAttributeName]]);
        NSString *subText = [medi[row] subTitle];
        NSFont *subTextFont = [NSFont boldSystemFontOfSize:12.0f];
        CGSize subTextSize = NSSizeFromCGSize([subText sizeWithAttributes:[NSDictionary dictionaryWithObject:subTextFont
                                                                                                      forKey:NSFontAttributeName]]);
        return (textSize.height + subTextSize.height + 12.0f);
    }
    else if (tableView == mySectionTitles) {
        NSString *text = mListOfSectionTitles[row];
        NSFont *textFont = [NSFont boldSystemFontOfSize:11.0f];
        CGSize textSize = NSSizeFromCGSize([text sizeWithAttributes:[NSDictionary dictionaryWithObject:textFont
                                                                                                forKey:NSFontAttributeName]]);
        return (textSize.height + 5.0f);
    }
    else if (tableView == myPrescriptionsTableView || tableView.tag == 3) {
        // Fixed height
        return 44.0f;
    }
    
    return 0.0f;
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
    if (tableView == self.myTableView)
    {
        if (mUsedDatabase == kAips) {
            return [medi count];
        }
        else if (mUsedDatabase == kFavorites) {
            return [favoriteKeyData count];
        }
    }
    else if (tableView == self.mySectionTitles)
    {
        return [mListOfSectionTitles count];
    }
    else if (tableView == self.myPrescriptionsTableView || tableView.tag == 3)
    {
        return mPrescriptionsCart[0].size;
    }
    
    return 0;
}

- (NSTableRowView *) tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    if (tableView == self.myTableView || tableView == self.mySectionTitles) {
        MLCustomTableRowView *rowView = [[MLCustomTableRowView alloc] initWithFrame:NSZeroRect];
        [rowView setRowIndex:row];
        return rowView;
    }
    
    return nil;
}

- (NSView *) tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row
{
    if (tableView == self.myTableView) { // search results
        if ([tableColumn.identifier isEqualToString:@"MLSimpleCell"]) {
            MLItemCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
            DataObject *dataObject = medi[row];

            cellView.textField.stringValue = [dataObject title];
            cellView.selectedMedi = dataObject;
            cellView.packagesStr = [dataObject subTitle];
            if (mCurrentSearchState == kTitle) {
                cellView.showContextualMenu = true;
                cellView.onSubtitlePressed = nil;
            } else if (mCurrentSearchState == kAuthor) {
                cellView.showContextualMenu = false;
                cellView.onSubtitlePressed = ^(NSInteger _row) {
                    if (mSearchInteractions || mPrescriptionMode) {
                        dispatch_async(mSearchQueue, ^(void) {
                            NSArray<MLMedication *> *searchRes = [mDb searchAuthor:dataObject.subTitle];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (mSearchInteractions) {
                                    for (MLMedication *med in searchRes) {
                                        [self pushToMedBasket:med];
                                    }
                                    [self updateInteractionsView];
                                } else if (mPrescriptionMode) {
                                    for (MLMedication *med in searchRes) {
                                        [self addAllPackagesOfMedToPrescriptionCart:med];
                                    }
                                }
                            });
                        });
                    }
                    
                    [[mySearchField cell] setStringValue:dataObject.subTitle];
                    [self searchNow:nil];
                };
            } else if (mCurrentSearchState == kAtcCode) {
                cellView.showContextualMenu = false;
                cellView.onSubtitlePressed = ^(NSInteger _row) {
                    long mId = [dataObject medId];
                    MLMedication *med = [mDb getMediWithId:mId];
                    NSString *atcString = med.atccode;
                    NSArray<NSString *> *atc = [atcString componentsSeparatedByString:@";"];
                    if (atc.count >= 1) {
                        dispatch_async(mSearchQueue, ^(void) {
                            if (mSearchInteractions) {
                                NSArray *meds = [mDb searchATCCode:atc[0]];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    for (MLMedication *med in meds) {
                                        [self pushToMedBasket:med];
                                    }
                                    [self updateInteractionsView];
                                });
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[mySearchField cell] setStringValue:atc[0]];
                                [self searchNow:nil];
                            });
                        });
                    }
                };
            } else if (mCurrentSearchState == kTherapy) {
                cellView.showContextualMenu = NO;
                cellView.onSubtitlePressed = ^(NSInteger row) {
                    long mId = [dataObject medId];
                    MLMedication *med = [mDb getMediWithId:mId];
                    NSArray *applications = [med.application componentsSeparatedByString:@";"];
                    NSString *application = nil;
                    
                    if (row == 0) {
                        NSString *swissmedic = [applications firstObject];
                        application = [[[swissmedic componentsSeparatedByString:@"("] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    } else if (row == 1) {
                        NSString *bag = applications.count > 1 ? applications[1] : nil;
                        application = [[[bag componentsSeparatedByString:@"("] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    }
                    
                    if (mSearchInteractions) {
                        [self pushToMedBasket:med];
                        [self updateInteractionsView];
                    } else if (mPrescriptionMode) {
                        [self addAllPackagesOfMedToPrescriptionCart:med];
                    }
                    if (application) {
                        [[mySearchField cell] setStringValue:application];
                        [self searchNow:nil];
                    }
                };
            } else {
                cellView.showContextualMenu = false;
                cellView.onSubtitlePressed = nil;
            }

            [cellView.packagesView reloadData];
            
            // Check if cell.textLabel.text is in starred NSSet
            if (favoriteKeyData!=nil) {
                if (mCurrentSearchState!=kFullText) {
                    NSString *regnrStr = favoriteKeyData[row];
                    if ([favoriteMedsSet containsObject:regnrStr])
                        cellView.favoritesCheckBox.state = 1;
                    else
                        cellView.favoritesCheckBox.state = 0;
                    cellView.favoritesCheckBox.tag = row;
                }
                else {
                    NSString *hashId = favoriteKeyData[row];
                    if ([favoriteFTEntrySet containsObject:hashId])
                        cellView.favoritesCheckBox.state = 1;
                    else
                        cellView.favoritesCheckBox.state = 0;
                    cellView.favoritesCheckBox.tag = row;
                }
            }
            
            return cellView;
        }
    }
    else if (tableView == self.mySectionTitles) { // list of chapter titles
        if ([tableColumn.identifier isEqualToString:@"MLSimpleCell"]) {
            NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
            cellView.textField.stringValue = mListOfSectionTitles[row];
            return cellView;
        }
    }
    else if (tableView == self.myPrescriptionsTableView || tableView.tag == 3) { // prescription

        // Get an existing cell with the specified identifier if it exists
        MLPrescriptionCellView *cellView;
        cellView = (MLPrescriptionCellView*)[tableView makeViewWithIdentifier:tableColumn.identifier
                                                                        owner:self]; // 'owner' gets an 'awakeFromNib:' call

        NSArray *prescriptionBasket = mPrescriptionsCart[0].cart;

        if ([tableColumn.identifier isEqualToString:@"PrescriptionMedCounter"]) {  // Unused ?
            cellView.textField.stringValue = [NSString stringWithFormat:@"%ld", row+1];
        }
        else if ([tableColumn.identifier isEqualToString:@"PrescriptionRegisteredName"]) {
            cellView.textField.stringValue = [prescriptionBasket[row] fullPackageInfo];
            NSString *comment = [prescriptionBasket[row] comment];
            if (comment==nil)
                comment = @"";

            cellView.editableTextField.stringValue = comment;
        }
        else if ([tableColumn.identifier isEqualToString:@"PrescriptionPrice"]) {   // Unused ?
            if ([prescriptionBasket[row] price] != nil)
                cellView.textField.stringValue = [prescriptionBasket[row] price];
        }
       
        return cellView;
    }
    
    return nil;
}

- (BOOL) tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if (mPrescriptionMode) {
        if (tableView == self.mySectionTitles) {
            NSMutableArray *dragFiles = [[NSMutableArray alloc] init];
            NSString *path = mListOfSectionIds[[rowIndexes lastIndex]];
            [dragFiles addObject:path];
            
            NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
            NSArray *types = [NSArray arrayWithObject:NSFilenamesPboardType];
            [pboard declareTypes:types owner:self];
            [pboard setPropertyList:dragFiles forType:NSFilenamesPboardType];
            
            return YES;
        }
    }
    return NO;
}

- (NSDragOperation) tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    // Highlight table
    [self.myPrescriptionsTableView setDropRow:-1 dropOperation:NSTableViewDropOn];
    
    return NSDragOperationEvery;
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *classes = [NSArray arrayWithObject:[NSURL class]];
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                        forKey:NSPasteboardURLReadingFileURLsOnlyKey];
    NSArray *fileURLs = [pboard readObjectsForClasses:classes options:options];
    if ([fileURLs count]>0) {
        NSURL *fileURL = [fileURLs objectAtIndex:0];
        if ([[fileURL pathExtension] isEqualToString:@"amk"]) {
            // Load prescription
            [self loadPrescription:fileURL andRefreshHistory:YES];
        }
    }
    
    // Move the specified row to its new location...
    return YES;
}

#pragma mark - Notifications

// NSControlTextDidChangeNotification
- (void)controlTextDidChange:(NSNotification *)notification
{
    modifiedPrescription = true;
    [self updateButtons];
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    id notifier = [notification object];
    
    NSInteger row = [notifier selectedRow];
    
    if (row >= 0) {
        if (notifier == self.myTableView) {
            /*
             * Check if table is search result (=myTableView)
             * Left-most pane
             */
            NSTableRowView *myRowView = [self.myTableView rowViewAtRow:row makeIfNecessary:NO];
            [myRowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
            
            // [[self window] makeFirstResponder:myRowView];
            
            // Colors whole row red... useless
            // [myRowView setBackgroundColor:[NSColor redColor]];
            
            if (mCurrentSearchState!=kFullText) {
                /* Search in Aips DB or Interactions DB
                 */
                long mId = [medi[row] medId];
                // Get medi
                mMed = [mDb getMediWithId:mId];
                // Hide textfinder
                [self hideTextFinder];
                
                if (mSearchInteractions==false) {
                    [self updateExpertInfoView:nil];
                } else {
                    [self pushToMedBasket:mMed];
                    [self updateInteractionsView];
                }
            }
            else {
                /* Search in full text search DB
                 */
                NSString *hashId = [medi[row] hashId];
                // Get entry
                mFullTextEntry = [mFullTextDb searchHash:hashId];
                // Hide text finder
                [self hideTextFinder];
                
                NSArray *listOfRegnrs = [mFullTextEntry getRegnrsAsArray];
                NSArray<MLMedication*> *listOfArticles = [mDb searchRegnrsFromList:listOfRegnrs];
                NSDictionary *dict = [mFullTextEntry getRegChaptersDict];
                
                if (mSearchInteractions) {
                    // https://github.com/zdavatz/amiko-osx/issues/81
                    // > Actually here we could just always add the first product of each ATC-Code,
                    // > as the interactions are based on ATC-Codes.
                    NSMutableSet<NSString*> *uniqueATCs = [[NSMutableSet alloc] init];
                    for (MLMedication *m in listOfArticles) {
                        if ([uniqueATCs containsObject:m.atccode]) continue;
                        [uniqueATCs addObject:m.atccode];
                        [self pushToMedBasket:m];
                    }
                    [self updateInteractionsView];
                } else {
                    mFullTextContentStr = [mFullTextSearch tableWithArticles:listOfArticles
                                                          andRegChaptersDict:dict
                                                                   andFilter:@""];
                    mCurrentWebView = kFullTextSearchView;
                    [self updateFullTextSearchView:mFullTextContentStr];
                }
            }
        }
        else if (notifier == self.mySectionTitles) {
            /*
             * Check if table is list of chapter titles (=mySectionTitles)
             * Right-most pane
             */
            NSTableRowView *myRowView = [self.mySectionTitles rowViewAtRow:row makeIfNecessary:NO];
            [myRowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
            
            if (mPrescriptionMode) {
                //NSLog(@"%s row:%ld, %@", __FUNCTION__, row, mListOfSectionIds[row]);
                [self loadPrescription:[NSURL fileURLWithPath:mListOfSectionIds[row]] andRefreshHistory:NO];
            }
            else if (mCurrentWebView!=kFullTextSearchView) {
                // NSString *javaScript = [NSString stringWithFormat:@"window.location.hash='#%@'", mListOfSectionIds[row]];
                NSString *javaScript = [NSString stringWithFormat:@"var hashElement=document.getElementById('%@');if(hashElement) {hashElement.scrollIntoView();}", mListOfSectionIds[row]];
                [myWebView stringByEvaluatingJavaScriptFromString:javaScript];
            }
            else {
                // Update webviewer's content without changing anything else
                NSString *contentStr = [mFullTextSearch tableWithArticles:nil
                                                       andRegChaptersDict:nil
                                                                andFilter:mListOfSectionIds[row]];
                [self updateFullTextSearchView:contentStr];
            }
        }
        else if (notifier == self.myPrescriptionsTableView) {
            NSTableRowView *myRowView = [self.myPrescriptionsTableView rowViewAtRow:row makeIfNecessary:NO];
            [myRowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
        }

        [self updateButtons];
    }

#ifdef DEBUG
    [MLUtilities reportMemory];
#endif
}

#pragma mark - NSSharingServiceDelegate

- (NSArray<NSSharingService *> *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker
                              sharingServicesForItems:(NSArray *)items
                              proposedSharingServices:(NSArray<NSSharingService *> *)proposedServices
{
    NSMutableArray *result = [proposedServices mutableCopy];
    [result addObject:[NSSharingService sharingServiceNamed:NSSharingServiceNameSendViaAirDrop]];

    return result;
}

- (nullable id <NSSharingServiceDelegate>)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker
                                     delegateForSharingService:(NSSharingService *)sharingService
{
    if ([sharingService respondsToSelector:@selector(setSubject:)]) {
        MLPatient *p = [mPrescriptionAdapter patient];
        MLOperator *o = [mPrescriptionAdapter doctor];
        
        NSString * subjectLine =
        [NSString stringWithFormat:NSLocalizedString(@"Prescription to patient from doctor",nil),
                  p.givenName,
                  p.familyName,
                  p.birthDate,
                  o.title,
                  o.givenName,
                  o.familyName];
        
        [sharingService setSubject:subjectLine];
     }

     return nil;
}

#pragma mark -

- (void) updateButtons
{
#if 1
    bool doctorDefined = (myOperatorIDTextField.stringValue.length > 0) &&
    ![myOperatorIDTextField.stringValue isEqualToString:NSLocalizedString(@"Enter the doctor's address", nil)];
    bool patientDefined = (myPatientAddressTextField.stringValue.length > 0);
#else
    bool doctorDefined = [mPrescriptionAdapter doctor];
    bool patientDefined = [mPrescriptionAdapter patient];
#endif
    
    if (doctorDefined &&
        patientDefined &&
        [mPrescriptionsCart[0].cart count] > 0)
    {
        if (modifiedPrescription) {
            saveButton.enabled = YES;
#ifdef DYNAMIC_AMK_SELECTION
            // Unselect AMK
            [mySectionTitles deselectAll:nil];
#endif
        } else {
            saveButton.enabled = NO;
        }
        
        sendButton.enabled = [mPrescriptionAdapter getPrescriptionUrl] != nil;
    }
    else {
        saveButton.enabled = NO;
        sendButton.enabled = NO;
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];
    if (action == @selector(printPrescription:)) {
        // Enabling logic for the "print prescription" menu item is the same as for the "Send" button
        bool doctorDefined = (myOperatorIDTextField.stringValue.length > 0) &&
        ![myOperatorIDTextField.stringValue isEqualToString:NSLocalizedString(@"Enter the doctor's address", nil)];
        bool patientDefined = (myPatientAddressTextField.stringValue.length > 0);
        
        if (doctorDefined &&
            patientDefined &&
            [mPrescriptionsCart[0].cart count] > 0)
        {
            return YES;
        }
        return NO;
    } else if (action == @selector(onSendPrescriptionToMedidata:)) {
        MLPatient *patient = [mPrescriptionAdapter patient];
        if (mPrescriptionMode && patient && [mPrescriptionsCart[0].cart count]) {
            return YES;
        }
        return NO;
    } else if (action == @selector(onOepnMedidataResponseWindow:)) {
        MLPatient *p = [mPatientSheet retrievePatient];
        if (p
//            && [[mPrescriptionAdapter medidataRefs] count]
            ) {
            return YES;
        }
        return NO;
    }

    return [menuItem isEnabled];
}

#pragma mark - Export CSV

// Read the file containing the list of keywords
- (NSArray *) csvGetInputListFromFile
{
    NSOpenPanel* oPanel = [NSOpenPanel openPanel];
    [oPanel setCanChooseFiles:YES];
    [oPanel setAllowedFileTypes:@[@"csv", @"txt"]];
    [oPanel setAllowsMultipleSelection:false];
    [oPanel setPrompt:NSLocalizedString(@"Open", nil)];
    [oPanel setMessage:NSLocalizedString(@"Please select text file with one word or two words per line. The file can be created into a text editor. Encoding is UTF-8", nil)];

    if ([oPanel runModal] != NSFileHandlingPanelOKButton) {
        NSLog(@"%s canceled", __FUNCTION__);
        return nil;
    }

    NSURL *fileURL = [[oPanel  URLs] firstObject];
    NSString *fileContents = [NSString stringWithContentsOfURL:fileURL
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];

    return [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void) searchKeyword:(NSString *)aKeyword
          inMedication:(MLMedication *)med
              chapters:(NSSet *)chSet
                 regnr:(NSString *)rn
{
    NSString *html = med.contentStr;
    NSString *atc = med.atccode;
    
#ifdef DEBUG
    //NSLog(@"%s %d, html %p lenght:%lu", __FUNCTION__, __LINE__, html, (unsigned long)[html length]);
    //NSLog(@"%s %d, html %@", __FUNCTION__, __LINE__, html);
    NSLog(@"%s %d, chapters %@", __FUNCTION__, __LINE__, chSet);
#endif

    if ([chSet count] == 0) {
        NSLog(@"WARNING: Keyword <%@> has no chapters", aKeyword);
    }
    else {
        for (NSString *el in chSet) {
            if (el.length == 0) {
                NSLog(@"WARNING: keyword <%@> has empty chapter set", aKeyword);
            }
        }
    }

#if 1
    NSError *err = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithXMLString:html
                                                             options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
                                                               error:&err];
    if (!xmlDoc) {
        NSLog(@"%s %d %@", __FUNCTION__, __LINE__, [err localizedDescription]);
        xmlDoc = [[NSXMLDocument alloc] initWithXMLString:html
                                                  options:NSXMLDocumentTidyHTML
                                                    error:&err];
    }

    if (!xmlDoc) {
        NSLog(@"%s %d %@", __FUNCTION__, __LINE__, [err localizedDescription]);
        return;
    }

    if (![xmlDoc validateAndReturnError:&err])
        NSLog(@"%s %d %@", __FUNCTION__, __LINE__, [err localizedDescription]);
#endif

    NSXMLElement *rootElement = [xmlDoc rootElement];
    //NSLog(@"rootElement %@", rootElement);
    //NSLog(@"Line %d HTML root children count %lu", __LINE__, (unsigned long)[rootElement childCount]);

#if 0
    NSArray *children = [rootElement children];
    //NSLog(@"children %@", children);  // "head" and "body" (body trunctaed in the printout)
    for (id child in children)
        NSLog(@"child %@ %@", [child class], [child name]); // NSXMLFidelityElement "head" and "body"
#endif
    
#if 0
    NSXMLNode *nodeBody = children[1];
    NSLog(@"Line %d, class:%@, name:%@, %lu children", __LINE__,
          [nodeBody class],
          [nodeBody name],
          (unsigned long)[nodeBody childCount]);

    NSXMLNode *nodeBodyDiv = [nodeBody childAtIndex:0];
    NSLog(@"Line %d, class:%@, name:%@, %lu children", __LINE__,
          [nodeBodyDiv class],
          [nodeBodyDiv name],
          (unsigned long)[nodeBodyDiv childCount]);
#endif

//    NSArray *shortTitles = [csvMedication listOfSectionTitles];  // they are hardcoded into the app
    
    NSArray *atcArray = [atc componentsSeparatedByString:@";"];
    NSString *activeSubstance;
    NSString *atcCode;
    if ([atcArray count] > 0) atcCode = atcArray[0];
    if ([atcArray count] > 1) activeSubstance = atcArray[1];

    NSString *brandName;
    NSArray *pBodyElem = [rootElement nodesForXPath:@"/html/body/div/div" error:nil];
    //NSLog(@"pBodyElem %lu elements", (unsigned long)[pBodyElem count]);
    for (NSXMLElement *el in pBodyElem) {
        NSString *divClass = [[el attributeForName:@"class"] stringValue];
        NSString *divId = [[el attributeForName:@"id"] stringValue];
        if ([divClass isEqualToString:@"MonTitle"]) {
            brandName = [el stringValue];
            // sanitize:
            brandName = [brandName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            continue;
        }

        if (![divClass isEqualToString:@"paragraph"]) {
#ifdef DEBUG
            NSLog(@"Line %d skip class:%@ id:%@", __LINE__, divClass, divId);  // [el name] is "div2
#endif
            continue;
        }

        // Extract section number and skip if not in NSSet
        
        NSScanner *scanner = [NSScanner scannerWithString:divId];
        NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        
        // Throw away characters before the first number.
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        
        // Collect numbers.
        NSString* numberString;
        [scanner scanCharactersFromSet:numbers intoString:&numberString];
        if (![chSet member:numberString])
            continue;   // skip this section

        NSString *chapterName;
#if 0
        // It's not as simple as this:
        NSInteger chNumber = numberString.integerValue;
        chapterName = shortTitles[chNumber - 1];  // subtract 1 because chpater 1 has index 0
#else
        // See how it's done in file 'MLFullTextSeaerch.m' function 'tableWithArticles'

        //NSLog(@"Line %d, kw:%@ index:%ld of %lu", __LINE__, aKeyword, (long)chNumber, (unsigned long)[shortTitles count]);
        NSDictionary *indexToTitlesDict = [csvMedication indexToTitlesDict];
        //NSLog(@"Line %d, indexToTitlesDict:%@", __LINE__, indexToTitlesDict);
        chapterName = indexToTitlesDict[numberString];
        //NSLog(@"Line %d, cStr:%@", __LINE__, chapterName);
#endif

        NSArray *paragraphs = [el children];
#ifdef DEBUG
        NSLog(@"Line %d, use section (%d) with %lu paragraphs", __LINE__,
              numberString.intValue,
              (unsigned long)[paragraphs count]);
#endif
        for (NSXMLElement *p in paragraphs) {
            // [p name]          is "div"
            // [p stringValue]   content of tag
            //NSLog(@"Line %d, %lu children", __LINE__, (unsigned long)[p childCount]);
            
            if ([[p stringValue] containsString:aKeyword]) {
                //NSLog(@"TODO: for %@ output this:\n\n%@\n", aKeyword, [p stringValue]);
                NSString *link = [NSString stringWithFormat:@"https://amiko.oddb.org/de/fi?gtin=%@&highlight=%@&anchor=%@", rn, aKeyword, divId];
                [csv appendFormat:@"\n%@%@%@%@\"%@\"%@\"%@\"%@%@%@\"%@\"%@%@",
                 aKeyword, CSV_SEPARATOR,
                 activeSubstance, CSV_SEPARATOR,
                 brandName, CSV_SEPARATOR,
                 atcCode, CSV_SEPARATOR,
                 chapterName, CSV_SEPARATOR,
                 [p stringValue], CSV_SEPARATOR,
                 link];

                //NSLog(@"Line %d, csv:%@", __LINE__, csv);
            }
        }
    }
    
#if 0
    NSXMLNode *pNode = [rootElement attributeForName:@"body:div"];
    NSLog(@"pNode %@", [pNode name]);
#endif
}

// It runs in a separate thread
- (void) csvOutputResult
{
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy.MM.dd_HHmm"];
    NSString * dateSuffix = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.csv", NSLocalizedString(@"word_analysis", "CSV filename prefix"), dateSuffix];

    dispatch_async(dispatch_get_main_queue(), ^{
    
        // Select the directory
        NSOpenPanel* oPanel = [NSOpenPanel openPanel];
        [oPanel setCanChooseFiles:NO];
        [oPanel setCanChooseDirectories:YES];
        [oPanel setMessage:NSLocalizedString(@"Please select a directory where to save the file", nil)];
        NSURL *desktopURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDesktopDirectory
                                                                      inDomains:NSUserDomainMask] lastObject];
        [oPanel setDirectoryURL:desktopURL];
        [oPanel setPrompt:NSLocalizedString(@"Choose directory and save file", nil)];
        [oPanel setCanCreateDirectories:YES];

        [oPanel beginWithCompletionHandler:^(NSInteger result) {
            if (result != NSModalResponseOK) {
                //NSLog(@"%s %d", __FUNCTION__, __LINE__);
                return;
            }

            NSURL *dirUrl = [oPanel URL];
            NSString *fullPathCSV = [[dirUrl path] stringByAppendingPathComponent:fileName];
            //NSLog(@"%s %d fullPathCSV:<%@>", __FUNCTION__, __LINE__, fullPathCSV);

            NSError *error;
            BOOL res = [csv writeToFile:fullPathCSV atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if (!res) {
                NSLog(@"Error %@ while writing to file %@", [error localizedDescription], fileName );
                return;
            }

            [[NSWorkspace sharedWorkspace] openFile:fullPathCSV];
        }];
    });
}

// It runs in a separate thread
- (void) csvProcessKeywords:(NSArray *)keywords
{
    __block Wait *wait;

    dispatch_async(dispatch_get_main_queue(), ^{
        wait = [[Wait alloc] initWithString:NSLocalizedString(@"Looking up keywords. Please wait...", nil)];
        [wait setCancel:YES];
        [[wait progress] setMaxValue:[keywords count]];
        [wait setSponsorTitle:NSLocalizedString(@"This feature is provided by", nil)];
        [wait showWindow:self];
    });
    
    for (NSString *kw in keywords) {
        if (kw.length < 3) // this also takes care of the empty line at the end of file
            continue;
        
#if 0
        NSArray *resultDb1 = [self searchAnyDatabasesWith:kw];  // amiko_frequency_de.db
#else
        NSArray *resultDb1 = [mFullTextDb searchKeyword:kw];
#endif
        
#ifdef DEBUG
        NSLog(@"Line %d ========= search keyword: <%@> in DB1 frequency table, %lu hit(s)", __LINE__, kw, (unsigned long)[resultDb1 count]);
        //NSLog(@"Line %d, resultDb1:%@", __LINE__, resultDb1);
#endif
        for (MLFullTextEntry *entry in resultDb1) {
            if (![[entry keyword] isEqualToString:kw]) {
                // Make the search case sensitive. Easier to do it this way than through SQL
#ifdef DEBUG
                NSLog(@"Line %d --------- skip: %@", __LINE__, [entry keyword]);
#endif
                continue;
            }
            
#ifdef DEBUG
            NSLog(@"Line %d --------- use: %@", __LINE__, entry);
#endif
            //NSLog(@"%d getRegChaptersDict: %@", __LINE__, [entry getRegChaptersDict]);
            //NSLog(@"getRegnrs: %@", [entry getRegnrs]);  // as string
            NSArray *rnArray = [entry getRegnrsAsArray];
            //NSLog(@"Line %d, getRegnrsAsArray: %@", __LINE__, rnArray);
            for (NSString *rn in rnArray) {
                
                //NSDictionary *dic2 = [entry getRegChaptersDict];    // One or more lines like:
                //NSLog(@"Line %d, chapter dic: %@", __LINE__, dic2); // 65161 = "{(\n    14\n)}"
                
                NSSet *chapterSet = [entry getChaptersForKey:rn];
#ifdef DEBUG
                NSLog(@"Line %d, rn: %@ has chapter set: %@", __LINE__, rn, chapterSet);
#endif
                
                csvMedication = [mDb getMediWithRegnr:rn];
                if (csvMedication) {
                    [self searchKeyword:kw inMedication:csvMedication chapters:chapterSet regnr:rn];
                } else {
                    // https://github.com/zdavatz/amiko-osx/issues/251
                    // When the medicine isn't found in DB, we put the Regnr in link.
                    [csv appendFormat:@"\n%@%@%@%@\"%@\"%@\"%@\"%@%@%@\"%@\"%@%@",
                     @"", CSV_SEPARATOR,
                     @"", CSV_SEPARATOR,
                     @"", CSV_SEPARATOR,
                     @"", CSV_SEPARATOR,
                     @"", CSV_SEPARATOR,
                     @"", CSV_SEPARATOR,
                     rn];
                }
            }
        }  // for

        dispatch_async(dispatch_get_main_queue(), ^{
            [wait incrementBy: 1];
            [wait setSubtitle:kw];
        });
    } // for keywords
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [wait close];
    });
}

- (IBAction) exportWordListSearchResults:(id)sender
{
    //NSLog(@"%s %@ %ld", __FUNCTION__, [sender class], (long)[sender tag]);

    NSArray *keywords = [self csvGetInputListFromFile];
    if (!keywords)
        return;  // canceled

    //NSLog(@"%@", keywords);

    NSArray *csvHeader = @[NSLocalizedString(@"Search Term from Uploaded file", "CSV header"),
                           NSLocalizedString(@"Active Substance", "CSV header"),
                           NSLocalizedString(@"Brand-Name of the drug", "CSV header"),
                           NSLocalizedString(@"ATC-Code", "CSV header"),
                           NSLocalizedString(@"Chapter name", "CSV header"),
                           NSLocalizedString(@"Sentence that contains the word", "CSV header"),
                           NSLocalizedString(@"Link to the online reference", "CSV header")];
    csv = [[csvHeader componentsJoinedByString:CSV_SEPARATOR] mutableCopy];
    
    // Run in a separate thread
    dispatch_async(dispatch_get_global_queue(0, 0),
                   ^ {
                       [self csvProcessKeywords:keywords];
                       [self csvOutputResult];
                   });
}
@end
