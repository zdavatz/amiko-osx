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
#import "MLInteractionsCart.h"
#import "MLFullTextSearch.h"
#import "MLItemCellView.h"
#import "MLSearchWebView.h"
#import "MLDataStore.h"
#import "MLCustomTableRowView.h"
#import "MLCustomView.h"
#import "MLCustomURLConnection.h"

#import "MLUtilities.h"

#import "WebViewJavascriptBridge.h"

#import <mach/mach.h>
#import <unistd.h>

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

static NSString *SEARCH_STRING = @"Suche";
static NSString *SEARCH_TITLE = @"Präparat";
static NSString *SEARCH_AUTHOR = @"Inhaber";
static NSString *SEARCH_ATCCODE = @"Wirkstoff / ATC Code";
static NSString *SEARCH_REGNR = @"Reg. Nr.";
static NSString *SEARCH_THERAPY = @"Therapie";
static NSString *SEARCH_FULLTEXT = @"Volltext";
static NSString *SEARCH_FACHINFO = @"in Fachinformation";

static NSInteger mUsedDatabase = kAips;
static NSInteger mCurrentSearchState = kTitle;
static NSInteger mCurrentWebView = kExpertInfoView;
static NSString *mCurrentSearchKey = @"";

static BOOL mSearchInteractions = false;

@interface DataObject : NSObject

@property NSString *title;
@property NSString *subTitle;
@property long medId;
@property NSString *hashId;

@end

@implementation DataObject

@synthesize title;
@synthesize subTitle;
@synthesize medId;
@synthesize hashId;

@end

@implementation MLMainWindowController
{
    // Instance variable declarations go here
    MLMedication *mMed;
    MLDBAdapter *mDb;
    MLFullTextDBAdapter *mFullTextDb;
    MLInteractionsAdapter *mInteractions;
    MLFullTextEntry *mFullTextEntry;
    MLInteractionsCart *mInteractionsCart;
    MLFullTextSearch *mFullTextSearch;
    
    NSMutableArray *medi;
    NSMutableArray *favoriteKeyData;
    
    NSMutableSet *favoriteMedsSet;
    NSMutableSet *favoriteFTEntrySet;
    
    NSArray *searchResults;
    
    NSArray *mListOfSectionIds;
    NSArray *mListOfSectionTitles;

    NSMutableDictionary *mMedBasket;
    
    NSProgressIndicator *progressIndicator;
    
    NSTextFinder *mTextFinder;
    
    WebViewJavascriptBridge *mJSBridge;
    
    NSString *mAnchor;
    NSString *mFullTextContentStr;
    
    dispatch_queue_t mSearchQueue;
    volatile bool mSearchInProgress;

    float m_alpha;
    float m_delta;
}

@synthesize myView;
@synthesize mySplashScreen;
@synthesize myToolbar;
@synthesize mySearchField;
@synthesize myTableView;
@synthesize mySectionTitles;
@synthesize myTextFinder;

- (id) init
{
    // [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]
    // self = [super initWithNibName:@"MLMasterViewController" bundle:nil];
    if ([APP_NAME isEqualToString:@"AmiKo"])
        self = [super initWithWindowNibName:@"MLAmiKoMainWindow"];
    else if ([APP_NAME isEqualToString:@"AmiKo-zR"])
        self = [super initWithWindowNibName:@"MLAmiKozRMainWindow"];
    else if ([APP_NAME isEqualToString:@"AmiKo-Desitin"])
        self = [super initWithWindowNibName:@"MLAmiKoDesitinMainWindow"];
    else if ([APP_NAME isEqualToString:@"CoMed"])
        self = [super initWithWindowNibName:@"MLCoMedMainWindow"];
    else if ([APP_NAME isEqualToString:@"CoMed-zR"])
        self = [super initWithWindowNibName:@"MLCoMedzRMainWindow"];
    else if ([APP_NAME isEqualToString:@"CoMed-Desitin"])
        self = [super initWithWindowNibName:@"MLCoMedDesitinMainWindow"];
    else return nil;
    
    if (!self)
        return nil;
    
    // Initialize global serial dispatch queue
    mSearchQueue = dispatch_queue_create("com.ywesee.searchdb", nil);
    mSearchInProgress = false;
    
    if ([MLUtilities isGermanApp]) {
        SEARCH_STRING = @"Suche";
        SEARCH_TITLE = @"Präparat";
        SEARCH_AUTHOR = @"Inhaber";
        SEARCH_ATCCODE = @"Wirkstoff / ATC Code";
        SEARCH_REGNR = @"Reg. Nr.";
        SEARCH_THERAPY = @"Therapie";
        SEARCH_FULLTEXT = @"Volltext";
        SEARCH_FACHINFO = @"in Fachinformation";
    } else if ([MLUtilities isFrenchApp]) {
        SEARCH_STRING = @"Recherche";
        SEARCH_TITLE = @"Préparation";
        SEARCH_AUTHOR = @"Titulaire";
        SEARCH_ATCCODE = @"Principe Actif / Code ATC";
        SEARCH_REGNR = @"No d'Autorisation";
        SEARCH_THERAPY = @"Thérapie";
        SEARCH_FULLTEXT = @"Plein Texte";
        SEARCH_FACHINFO = @"Notice Infopro";
    }
    
    m_alpha = 0.0;
    m_delta = 0.01;
    [[self window] setAlphaValue:1.0];//m_alpha];
    [self fadeInAndShow];
    [[self window] center];
    
    // Allocate some variables
    medi = [NSMutableArray array];
    favoriteKeyData = [NSMutableArray array];
    
    // Register applications defaults if necessary
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    if ([[MLUtilities appLanguage] isEqualToString:@"de"]) {
        [appDefaults setValue:[NSDate date] forKey:@"germanDBLastUpdate"];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    } else if ([[MLUtilities appLanguage] isEqualToString:@"fr"]) {
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
    
    // Initialize medication basket
    mMedBasket = [[NSMutableDictionary alloc] init];
    
    // Initialize interactions cart
    mInteractionsCart = [[MLInteractionsCart alloc] init];
    
    // Create bridge between JScript and ObjC
    [self createJSBridge];
    
    // Initialize full text search
    mFullTextSearch = [[MLFullTextSearch alloc] init];
    
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
    
    if ([MLUtilities isGermanApp])
        [[myToolbar items][3] setLabel:@"Drucken"];
    else if ([MLUtilities isFrenchApp])
        [[myToolbar items][3] setLabel:@"Imprimer"];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowResized:)
                                                 name:NSWindowDidResizeNotification
                                               object:nil];
    [[self window] makeFirstResponder:self];

    /*
    [myToolbar setVisible:NO];
    [[self.window contentView] addSubview:mySplashScreen];
    */
    
    [[self window] setBackgroundColor:[NSColor whiteColor]];
    
    return self;
}

- (void) windowDidLoad {
    
    [super windowDidLoad];

    // NOTE: These properties are set in NIB file, but to be verbose what we need to do:
    // Set container for NSTextFinder panel (NSScrollView hosting our SHCWebView)
    myTextFinder.findBarContainer = myWebView.enclosingScrollView;
    // Set client to work with the NSTextFinder object
    myTextFinder.client  = myWebView;
    // And vice versa: inform our SHCVebView about which of the NSTextFinder instance to work with
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
    } else if ([MLUtilities isFrenchApp]) {
        NSDate* lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"frenchDBLastUpdate"];
        if (lastUpdated==nil)
            [self updateUserDefaultsForKey:@"frenchDBLastUpdate"];
        else
            [self checkLastDBSync];
    }
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
        if ([MLUtilities isGermanApp]) {
            [alert setMessageText:@"Ihre Datenbank ist älter als 30 Tage. Wir empfehlen eine Aktualisierung auf die tagesaktuellen Daten."];
            [self updateUserDefaultsForKey:@"germanDBLastUpdate"];
        } else if ([MLUtilities isFrenchApp]) {
            [alert setMessageText:@"Votre banque des données est âgé de plus de 30 jours. Nous vous recommandons une mise à jour."];
            [self updateUserDefaultsForKey:@"frenchDBLastUpdate"];
        }
        [alert setAlertStyle:NSInformationalAlertStyle];
        
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
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
    if ([[myWebView mainFrame] dataSource]!=nil) {
        if ([sender isKindOfClass:[NSMenuItem class]] ) {
            NSMenuItem *menuItem = (NSMenuItem*)sender;
            if ([myTextFinder validateAction:menuItem.tag]) {
                if (menuItem.tag == NSTextFinderActionShowFindInterface) {
                    // This is a special tag
                    [myTextFinder performAction:NSTextFinderActionSetSearchString];
                }
                [myTextFinder performAction:menuItem.tag];
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
    NSAlert* jsAlert = [NSAlert alertWithMessageText:@"JavaScript"
                                       defaultButton:@"OK"
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:@"%@", message];
    [jsAlert beginSheetModalForWindow:sender.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
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
    mDb = [[MLDBAdapter alloc] init];
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
    } else if ([MLUtilities isFrenchApp]) {
        if (![mFullTextDb openDatabase:@"amiko_frequency_fr"]) {
            NSLog(@"No French Fulltext database!");
            mFullTextDb = nil;
        }
    }
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
            if ([MLUtilities isGermanApp]) {
                [alert setMessageText:@"AmiKo Datenbank aktualisiert!"];
                [alert setInformativeText:[NSString stringWithFormat:@"Die Datenbank enthält:\n- %ld Produkte\n- %ld Fachinfos\n- %ld Suchbegriffe\n- %d Interaktionen", numProducts, numFachinfos, numSearchTerms, numInteractions]];
            } else if ([MLUtilities isFrenchApp]) {
                [alert setMessageText:@"Banque des donnees CoMed mises à jour!"];
                [alert setInformativeText:[NSString stringWithFormat:@"La banque des données contien:\n- %ld produits\n- %ld notices infopro\n- %ld mot-clés\n- %d interactions", numProducts, numFachinfos, numSearchTerms, numInteractions]];
            }
            [alert setAlertStyle:NSInformationalAlertStyle];
            
            [alert beginSheetModalForWindow:[self window]
                              modalDelegate:self
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                contextInfo:nil];
        }
    } else if ([[notification name] isEqualToString:@"MLStatusCode404"]) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"OK"];
        if ([MLUtilities isGermanApp]) {
            [alert setMessageText:@"Datenbank kann nicht aktualisiert werden!"];
            [alert setInformativeText:[NSString stringWithFormat:@"Bitte wenden Sie sich an:\nzdavatz@ywesee.com\n+41 43 540 05 50"]];
        } else if ([MLUtilities isFrenchApp]) {
            [alert setMessageText:@"Mise à jour n'est pas possible!"];
            [alert setInformativeText:[NSString stringWithFormat:@"S'il vous plaît contacter:\nzdavatz@ywesee.com\n+41 43 540 05 50"]];
        }
        [alert setAlertStyle:NSInformationalAlertStyle];
        
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
    }
}

- (void) alertDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
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
}

- (void) windowResized: (NSNotification *)notification;
{
    /*
     [self.mySplashScreen removeFromSuperview];
     [myToolbar setVisible:YES];
     */
}

- (IBAction) tappedOnStar: (id)sender
{
    NSInteger row = [self.myTableView rowForView:sender];
#ifdef DEBUG
    NSLog(@"Tapped on star: %ld", row);
#endif
    if (mCurrentSearchState!=kFullText) {
        NSString *medRegnrs = [NSString stringWithString:[favoriteKeyData objectAtIndex:row]];
        if ([favoriteMedsSet containsObject:medRegnrs])
            [favoriteMedsSet removeObject:medRegnrs];
        else
            [favoriteMedsSet addObject:medRegnrs];
    } else {
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
                if ([searchText length]>0)
                    searchResults = [scopeSelf searchAnyDatabasesWith:searchText];
                else {
                    if (mUsedDatabase == kFavorites)
                        searchResults = [scopeSelf retrieveAllFavorites];
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
        case 0:
            [self setSearchState:kTitle];
            break;
        case 1:
            [self setSearchState:kAuthor];
            break;
        case 2:
            [self setSearchState:kAtcCode];
            break;
        case 3:
            [self setSearchState:kRegNr];
            break;
        case 4:
            [self setSearchState:kTherapy];
            break;
        case 5:
            [self setSearchState:kFullText];
            mCurrentWebView = kFullTextSearchView;
            break;
    }
    
    if (prevState == kFullText || mCurrentSearchState == kFullText)
        [self updateSearchResults];
    
    if (searchResults) {
        [self updateTableView];
        [self.myTableView reloadData];
    }
}

- (IBAction) toolbarAction: (id)sender
{
    [self launchProgressIndicator];
    
    NSToolbarItem *item = (NSToolbarItem *)sender;
    [self performSelector:@selector(switchDatabases:) withObject:item afterDelay:0.01];
}

- (IBAction) printDocument:(id)sender
{
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

- (IBAction) printSearchResult: (id)sender
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
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"OK"];
        if ([[MLUtilities appLanguage] isEqualToString:@"de"]) {
            [alert setMessageText:@"Für die Aktualisierung der Datenbank benötigen Sie eine aktive Internetverbindung."];
        } else if ([[MLUtilities appLanguage] isEqualToString:@"fr"]) {
            [alert setMessageText:@"Pour la mise à jour de la banque des données vous devez disposer d’une connexion Internet active."];
        }
        [alert setAlertStyle:NSInformationalAlertStyle];
        
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
    }
}

- (IBAction) loadAipsDatabase:(id)sender
{
    // Create a file open dialog class
    NSOpenPanel* openDlgPanel = [NSOpenPanel openPanel];
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"db",@"html",@"csv",nil];
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

- (IBAction) showAboutFile:(id)sender
{
    // A. Check first users documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Get documents directory
    NSString *documentsDir = [MLUtilities documentsDirectory];
    if ([MLUtilities isGermanApp]) {
        NSString *filePath = [[documentsDir stringByAppendingPathComponent:@"amiko_report_de"] stringByAppendingPathExtension:@"html"];
        if ([fileManager fileExistsAtPath:filePath]) {
            // Starts Safari            
            [[NSWorkspace sharedWorkspace] openFile:filePath];
        } else {
            NSURL *aboutFile = [[NSBundle mainBundle] URLForResource:@"amiko_report_de" withExtension:@"html"];
            // Starts Safari
            [[NSWorkspace sharedWorkspace] openURL:aboutFile];
        }
    } else if ([MLUtilities isFrenchApp]) {
        NSString *filePath = [[documentsDir stringByAppendingPathComponent:@"amiko_report_fr"] stringByAppendingPathExtension:@"html"];
        if ([fileManager fileExistsAtPath:filePath]) {
            // Starts Safari
            [[NSWorkspace sharedWorkspace] openFile:filePath];
        } else {
            NSURL *aboutFile = [[NSBundle mainBundle] URLForResource:@"amiko_report_fr" withExtension:@"html"];
            // Starts Safari
            [[NSWorkspace sharedWorkspace] openURL:aboutFile];
        }
    }
}

// A small custom about box
- (IBAction) showAboutPanel:(id)sender
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *creditsPath = nil;
    if ([MLUtilities isGermanApp])
        creditsPath = [mainBundle pathForResource:@"Credits-de" ofType:@"rtf"];
    else if ([MLUtilities isFrenchApp])
        creditsPath = [mainBundle pathForResource:@"Credits-fr" ofType:@"rtf"];
    NSAttributedString *credits = [[NSAttributedString alloc] initWithPath:creditsPath documentAttributes:nil];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd.MM.yyyy"];
    NSString *compileDate = [dateFormat stringFromDate:today];
    
    NSString *versionString = [NSString stringWithFormat:@"%@", compileDate];
   
    NSDictionary *optionsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 credits, @"Credits",
                                 [mainBundle objectForInfoDictionaryKey:@"CFBundleName"], @"ApplicationName",
                                 [mainBundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"], @"Copyright",
                                 [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], @"ApplicationVersion",
                                 versionString, @"Version",
                                 nil];
    
    [NSApp orderFrontStandardAboutPanelWithOptions:optionsDict];
}

- (IBAction) sendFeedback:(id)sender
{
    NSString *subject = [NSString stringWithFormat:@"%@ Feedback", APP_NAME];
    NSString *encodedSubject = [NSString stringWithFormat:@"mailto:zdavatz@ywesee.com?subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *helpFile = [NSURL URLWithString:encodedSubject];
    // Starts mail client
    [[NSWorkspace sharedWorkspace] openURL:helpFile];
}

- (IBAction) shareApp:(id)sender
{
    // Starts mail client
    NSString* subject = [NSString stringWithFormat:@"%@ OS X", APP_NAME];
    NSString* body = nil;
    if ([MLUtilities isGermanApp])
        body = [NSString stringWithFormat:@"%@ OS X: Schweizer Arzneimittelkompendium\r\n\n"
                "Get it now: https://itunes.apple.com/us/app/amiko/id%@?mt=12\r\n\nEnjoy!\r\n", APP_NAME, APP_ID];
    else if ([MLUtilities isFrenchApp])
        body = [NSString stringWithFormat:@"%@ OS X: Compendium des Médicaments Suisse\r\n\n"
                "Get it now: https://itunes.apple.com/us/app/amiko/id%@?mt=12\r\n\nEnjoy!\r\n", APP_NAME, APP_ID];
    NSString *encodedSubject = [NSString stringWithFormat:@"subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedBody = [NSString stringWithFormat:@"body=%@", [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:?%@&%@", encodedSubject, encodedBody];

    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

- (IBAction) rateApp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", APP_ID]]];
}

- (IBAction) clickedTableView: (id)sender
{
    if (mCurrentSearchState == kFullText) {
        mCurrentWebView = kFullTextSearchView;
        [self updateFullTextSearchView:mFullTextContentStr];
    }
}

- (void) showHelp: (id)sender
{
    // Starts Safari
    if ([[MLUtilities appOwner] isEqualToString:@"zurrose"]) {
        NSURL *helpFile = [NSURL URLWithString:@"http://www.zurrose.ch/amiko"];
        [[NSWorkspace sharedWorkspace] openURL:helpFile];
    } else if ([[MLUtilities appOwner] isEqualToString:@"ywesee"]) {
        NSURL *helpFile = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/amiko/id%@?mt=12", APP_ID]];
        [[NSWorkspace sharedWorkspace] openURL:helpFile];
    } else if ([[MLUtilities appOwner] isEqualToString:@"desitin"]) {
        NSURL *helpFile = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/amiko/id%@?mt=12", APP_ID]];
        [[NSWorkspace sharedWorkspace] openURL:helpFile];
    }
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

- (void) switchDatabases: (NSToolbarItem *)item
{
    switch (item.tag) {
        case 0:
        {
            NSLog(@"AIPS Database");
            mUsedDatabase = kAips;
            mSearchInteractions = false;
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
                        searchResults = [scopeSelf searchAnyDatabasesWith:mCurrentSearchKey];
                    } else {
                        searchResults = [scopeSelf searchAnyDatabasesWith:mCurrentSearchKey];
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
            break;
        }
        case 1:
        {
            NSLog(@"Favorites");
            mUsedDatabase = kFavorites;
            mSearchInteractions = false;
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
            break;
        }
        case 2:
        {
            NSLog(@"Interactions");
            mUsedDatabase = kAips;
            mSearchInteractions = true;
            [self stopProgressIndicator];
            [self setSearchState:kTitle];            
            [self pushToMedBasket];
            [self updateInteractionsView];
        }
        default:
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
    } else {
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
        NSLog(@"%ld Favoriten in %dms", [medList count], (int)(1000*execTime+0.5));
#endif
    
    return medList;
}

- (void) saveFavorites
{
    NSString *path = @"~/Library/Preferences/data";
    path = [path stringByExpandingTildeInPath];
    
    NSMutableDictionary *rootObject = [NSMutableDictionary dictionary];
    
    if (favoriteMedsSet!=nil)
        [rootObject setValue:favoriteMedsSet forKey:@"kFavMedsSet"];
    
    if (favoriteFTEntrySet!=nil)
        [rootObject setValue:favoriteFTEntrySet forKey:@"kFavFTEntrySet"];
    
    // Save contents of rootObject by key, value must conform to NSCoding protocolw
    [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
}

- (void) loadFavorites:(MLDataStore *)favorites
{
    NSString *path = @"~/Library/Preferences/data";
    path = [path stringByExpandingTildeInPath];
    
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
    switch (searchState) {
        case kTitle:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kTitle;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, SEARCH_TITLE]];
             break;
        case kAuthor:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kAuthor;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, SEARCH_AUTHOR]];
            break;
        case kAtcCode:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kAtcCode;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, SEARCH_ATCCODE]];
            break;
        case kRegNr:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kRegNr;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, SEARCH_REGNR]];
            break;
        case kTherapy:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kTherapy;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, SEARCH_THERAPY]];
            break;
        case kWebView:
            // Hide textfinder
            [self hideTextFinder];
            // NOTE: Commented because we're using SHCWebView now (02.03.2015)
            /*
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kWebView;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, SEARCH_FACHINFO]];
            */
            break;
        case kFullText:
            [[mySearchField cell] setStringValue:@""];
            mCurrentSearchState = kFullText;
            [[mySearchField cell] setPlaceholderString:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, SEARCH_FULLTEXT]];
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
        m.title = [MLUtilities notSpecified]; // @"k.A.";
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
                    [m_atccode_str setString:[MLUtilities notSpecified]];
                if ([m_atcclass_str isEqual:[NSNull null]])
                    [m_atcclass_str setString:[MLUtilities notSpecified]];
                m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_atccode_str, m_atcclass_str];
            }
        } else
            m.subTitle = [MLUtilities notSpecified]; // @"k.A.";
    } else
        m.subTitle = [MLUtilities notSpecified]; // @"k.A.";
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title andAuthor:(NSString *)author andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLUtilities notSpecified]; // @"k.A.";
    if (![author isEqual:[NSNull null]]) {
        if ([author length]>0)
            m.subTitle = author;
        else
            m.subTitle = [MLUtilities notSpecified]; // @"k.A.";
    } else
        m.subTitle = [MLUtilities notSpecified]; // @"k.A.";
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title andAtcCode:(NSString *)atccode andAtcClass:(NSString *)atcclass andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLUtilities notSpecified]; // @"k.A.";
    
    if ([atccode isEqual:[NSNull null]])
        atccode = [MLUtilities notSpecified];
    if ([atcclass isEqual:[NSNull null]])
        atcclass = [MLUtilities notSpecified];

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
        m_atccode_str = [NSMutableString stringWithString:[MLUtilities notSpecified]];
    }
    if ([m_atccode_str isEqual:[NSNull null]])
        [m_atccode_str setString:[MLUtilities notSpecified]];
    if ([m_atcclass_str isEqual:[NSNull null]])
        [m_atcclass_str setString:[MLUtilities notSpecified]];
    
    NSMutableString *m_atcclass = nil;
    if ([m_class count] == 2) {  // *** Ver.<1.2
        m_atcclass = [NSMutableString stringWithString:[m_class objectAtIndex:1]];
        if ([m_atcclass isEqual:[NSNull null]])
            [m_atcclass setString:[MLUtilities notSpecified]];
        m.subTitle = [NSString stringWithFormat:@"%@ - %@\n%@", m_atccode_str, m_atcclass_str, m_atcclass];
    } else if ([m_class count] == 3) {  // *** Ver.>=1.2
        NSArray *m_atc_class_l4_and_l5 = [m_class[2] componentsSeparatedByString:@"#"];
        int n = (int)[m_atc_class_l4_and_l5 count];
        if (n>1)
            m_atcclass = [NSMutableString stringWithString:[m_atc_class_l4_and_l5 objectAtIndex:n-2]];
        if ([m_atcclass isEqual:[NSNull null]])
            [m_atcclass setString:[MLUtilities notSpecified]];
        m.subTitle = [NSString stringWithFormat:@"%@ - %@\n%@\n%@", m_atccode_str, m_atcclass_str, m_atcclass, m_class[1]];
    } else {
        m_atcclass = [NSMutableString stringWithString:[MLUtilities notSpecified]];
        m.subTitle = [MLUtilities notSpecified];
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
        m.title = [MLUtilities notSpecified]; // @"k.A.";
    NSMutableString *m_regnrs = [NSMutableString stringWithString:regnrs];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_regnrs isEqual:[NSNull null]])
        [m_regnrs setString:[MLUtilities notSpecified]];
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:[MLUtilities notSpecified]];
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
        m.title = [MLUtilities notSpecified]; // @"k.A.";
    NSMutableString *m_title = [NSMutableString stringWithString:title];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_title isEqual:[NSNull null]])
        [m_title setString:[MLUtilities notSpecified]];
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:[MLUtilities notSpecified]];
    m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_title, m_auth];
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle: (NSString *)title andApplications: (NSString *)applications andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLUtilities notSpecified]; // @"k.A.";
    NSArray *m_applications = [applications componentsSeparatedByString:@";"];
    NSMutableString *m_swissmedic = nil;
    NSMutableString *m_bag = nil;
    if ([m_applications count]>0) {
        if (![[m_applications objectAtIndex:0] isEqual:nil])
            m_swissmedic = [NSMutableString stringWithString:[m_applications objectAtIndex:0]];
        if ([m_applications count]>1) {
            if (![[m_applications objectAtIndex:1] isEqual:nil])
                m_bag = [NSMutableString stringWithString:[m_applications objectAtIndex:1]];
        }
    }
    if ([m_swissmedic isEqual:[NSNull null]])
        [m_swissmedic setString:[MLUtilities notSpecified]];
    if ([m_bag isEqual:[NSNull null]])
        [m_bag setString:[MLUtilities notSpecified]]; // @"k.A.";
    m.subTitle = [NSString stringWithFormat:@"%@\n%@", m_swissmedic, m_bag];
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addKeyword: (NSString *)keyword andNumHits: (unsigned long)numHits andHash: (NSString *)hash
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![keyword isEqual:[NSNull null]])
        m.title = keyword;
    else
        m.title = [MLUtilities notSpecified]; // @"k.A.";
    m.subTitle = [NSString stringWithFormat:@"%ld Treffer", numHits];
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
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        if (mSearchInteractions == false)
                            [self addTitle:m.title andPackInfo:m.packInfo andMedId:m.medId];
                        else
                            [self addTitle:m.title andPackInfo:m.atccode andMedId:m.medId];
                    }
                }
            } else if (mUsedDatabase == kFavorites) {
                for (MLMedication *m in searchResults) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title andPackInfo:m.packInfo andMedId:m.medId];
                        }
                    }
                }
            }
        } else if (mCurrentSearchState == kAuthor) {
            for (MLMedication *m in searchResults) {
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
        } else if (mCurrentSearchState == kAtcCode) {
            for (MLMedication *m in searchResults) {
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
        } else if (mCurrentSearchState == kRegNr) {
            for (MLMedication *m in searchResults) {
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
        } else if (mCurrentSearchState == kTherapy) {
            for (MLMedication *m in searchResults) {
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
        } else if (mCurrentSearchState == kFullText) {
            for (MLFullTextEntry *e in searchResults) {
                if (mUsedDatabase == kAips || mUsedDatabase == kFavorites) {
                    if (![e.hash isEqual:[NSNull null]]) {
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
- (void) pushToMedBasket
{
    if (mMed!=nil) {
        NSString *title = [mMed title];
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([title length]>30) {
            title = [title substringToIndex:30];
            title = [title stringByAppendingString:@"..."];
        }
    
        // Add med to medication basket
        [mMedBasket setObject:mMed forKey:title];
        // Update the interactions cart's med basket -> could be replaced by a signal/slot mechanism!!
        [mInteractionsCart updateMedBasket:mMedBasket];
    }
}

/**
 The following function intercepts messages sent from javascript to objective C and acts
 acts as a bridge between JS and ObjC
 */
- (void) createJSBridge
{
    mJSBridge = [WebViewJavascriptBridge bridgeForWebView:myWebView];
    
    [mJSBridge registerHandler:@"JSToObjC_" handler:^(id msg, WVJBResponseCallback responseCallback) {
        if ([msg count]==3) {
            // --- Interactions ---
            if ([msg[0] isEqualToString:@"interactions_cb"]) {
                if ([msg[1] isEqualToString:@"notify_interaction"])
                    [mInteractionsCart sendInteractionNotice];
                else if ([msg[1] isEqualToString:@"delete_all"])
                    [mMedBasket removeAllObjects];
                else if ([msg[1] isEqualToString:@"delete_row"])
                    [mMedBasket removeObjectForKey:msg[2]];
                
                // Update med basket
                mCurrentWebView = kInteractionsCartView;
                [mInteractionsCart updateMedBasket:mMedBasket];
                [self updateInteractionsView];
            }
        } else if ([msg count]==4) {
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
    // Load style sheet from file
    NSString *amikoCssPath = [[NSBundle mainBundle] pathForResource:@"amiko_stylesheet" ofType:@"css"];
    NSString *amikoCss = @"";
    if ([amikoCssPath isNotEqualTo:[NSNull null]])
        amikoCss = [NSString stringWithContentsOfFile:amikoCssPath encoding:NSUTF8StringEncoding error:nil];
    else
        amikoCss = [NSString stringWithString:mMed.styleStr];
    
    // Load javascript from file
    NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"main_callbacks" ofType:@"js"];
    NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath encoding:NSUTF8StringEncoding error:nil];
    
    // Generate html string
    NSString *htmlStr = mMed.contentStr;
    htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"<html>"
                                                 withString:@"<!DOCTYPE html><html><head><meta charset=\"utf-8\" />"];
    htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"<head></head>"
                                                 withString:[NSString stringWithFormat:@"<script type=\"text/javascript\">%@</script><style type=\"text/css\">%@</style></head>", jscriptStr, amikoCss]];

    if (mCurrentSearchState == kFullText) {
        NSString *keyword = [mFullTextEntry keyword];
        if ([keyword isNotEqualTo:[NSNull null]]) {
            htmlStr = [htmlStr stringByReplacingOccurrencesOfString:keyword
                                                         withString:[NSString stringWithFormat:@"<span class=\"mark\" style=\"background-color: yellow\">%@</span>", keyword]];
        }
        mAnchor = anchor;
    }
    
    NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    [[myWebView mainFrame] loadHTMLString:htmlStr baseURL:mainBundleURL];
    
    // [[myWebView preferences] setDefaultFontSize:14];
    // [self setSearchState:kWebView];
    
    // Extract section ids
    if (![mMed.sectionIds isEqual:[NSNull null]])
        mListOfSectionIds = [mMed listOfSectionIds];
    // Extract section titles
    if (![mMed.sectionTitles isEqual:[NSNull null]])
        mListOfSectionTitles = [mMed listOfSectionTitles];
    [mySectionTitles reloadData];
}

- (void) updateInteractionsView
{
    // --> OPTIMIZE!! Pre-load the following files!
    
    // Load style sheet from file
    NSString *interactionsCssPath = [[NSBundle mainBundle] pathForResource:@"interactions_css" ofType:@"css"];
    NSString *interactionsCss = [NSString stringWithContentsOfFile:interactionsCssPath encoding:NSUTF8StringEncoding error:nil];
    
    // Load javascript from file
    NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"interactions_callbacks" ofType:@"js"];
    NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath encoding:NSUTF8StringEncoding error:nil];
    
    // Generate main interaction table
    NSString *htmlStr = [NSString stringWithFormat:@"<html><head><meta charset=\"utf-8\" />"];
    htmlStr = [htmlStr stringByAppendingFormat:@"<script type=\"text/javascript\">%@</script><style type=\"text/css\">%@</style></head><body><div id=\"interactions\">%@<br><br>%@<br>%@</body></div></html>",
               jscriptStr,
               interactionsCss,
               [mInteractionsCart medBasketHtml],
               [mInteractionsCart interactionsHtml:mInteractions],
               [mInteractionsCart footNoteHtml]];
    
    // With the following implementation, the images are not loaded
    // NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    // [[myWebView mainFrame] loadHTMLString:htmlStr baseURL:mainBundleURL];
    
    [[myWebView mainFrame] loadHTMLString:htmlStr baseURL:[[NSBundle mainBundle] resourceURL]];
    
    // Update section title anchors
    mListOfSectionIds = mInteractionsCart.listofSectionIds;
    // Update section titles (here: identical to anchors)
    mListOfSectionTitles = mInteractionsCart.listofSectionTitles;
    
    [mySectionTitles reloadData];
}

- (void) updateFullTextSearchView:(NSString *)contentStr
{
    // Load style sheet from file
    NSString *fullTextCssPath = [[NSBundle mainBundle] pathForResource:@"fulltext_style" ofType:@"css"];
    NSString *fullTextCss = [NSString stringWithContentsOfFile:fullTextCssPath encoding:NSUTF8StringEncoding error:nil];
    
    // Load javascript from file
    NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"main_callbacks" ofType:@"js"];
    NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *htmlStr = [NSString stringWithFormat:@"<html><head><meta charset=\"utf-8\" />"];
    htmlStr = [htmlStr stringByAppendingFormat:@"<script type=\"text/javascript\">%@</script><style type=\"text/css\">%@</style></head><body><div id=\"fulltext\">%@</body></div></html>",
               jscriptStr,
               fullTextCss,
               contentStr];
  
    [[myWebView mainFrame] loadHTMLString:htmlStr baseURL:[[NSBundle mainBundle] resourceURL]];
    
    // Update middle pane (section titles)
    if (![mFullTextSearch.listOfSectionIds isEqual:[NSNull null]])
        mListOfSectionIds = mFullTextSearch.listOfSectionIds;
    if (![mFullTextSearch.listOfSectionTitles isEqual:[NSNull null]])
        mListOfSectionTitles = mFullTextSearch.listOfSectionTitles;
    
    [mySectionTitles reloadData];
}

/**
 - NSTableViewDataSource -
 Get number of rows of a table view
 */
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
    if (tableView == self.myTableView) {
        if (mUsedDatabase == kAips) {
            // NSLog(@"table entries (aips): %ld", (unsigned long)[medi count]);
            return [medi count];
        } else if (mUsedDatabase == kFavorites) {
            // NSLog(@"table entries (favs): %ld", (unsigned long)[favoriteKeyData count]);
            return [favoriteKeyData count];
        }
    } else if (tableView == self.mySectionTitles) {
        // NSLog(@"num sections: %ld", (unsigned long)[listofSectionTitles count]);
        return [mListOfSectionTitles count];
    }

    return 0;
}

/**
 - NSTableViewDataDelegate -
 Update tableviews (search result and section titles)
*/
- (NSView *) tableView: (NSTableView *)tableView viewForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
    if (tableView == self.myTableView) {
        /*
         * Check if table is search result (=myTableView)
        */
        MLItemCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

        if ([tableColumn.identifier isEqualToString:@"MLSimpleCell"]) {
            cellView.textField.stringValue = [medi[row] title];
            cellView.packagesStr = [medi[row] subTitle];
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
                } else {
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
    } else if (tableView == self.mySectionTitles) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        /*
         * Check if table is list of chapter titles (=mySectionTitles)
        */
        if ([tableColumn.identifier isEqualToString:@"MLSimpleCell"]) {
            cellView.textField.stringValue = mListOfSectionTitles[row];
            return cellView;
        }
    }
    return nil;
}

/*
 Update webview
 */
- (NSTableRowView *) tableView: (NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    MLCustomTableRowView *rowView = [[MLCustomTableRowView alloc] initWithFrame:NSZeroRect];
    [rowView setRowIndex:row];   
    return rowView;
    /*
    NSTableRowView *rowView = [[NSTableRowView alloc] initWithFrame:NSZeroRect];
    return rowView;
    */
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    if ([notification object] == self.myTableView) {
        /*
         * Check if table is search result (=myTableView)
         * Left-most pane
        */
        NSInteger row = [[notification object] selectedRow];
        
        NSTableRowView *myRowView = [self.myTableView rowViewAtRow:row makeIfNecessary:NO];
        [myRowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
       
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
                [self pushToMedBasket];
                [self updateInteractionsView];
            }
        } else {
            /* Search in full text search DB
             */
            NSString *hashId = [medi[row] hashId];
            // Get entry
            mFullTextEntry = [mFullTextDb searchHash:hashId];
            // Hide text finder
            [self hideTextFinder];
            
            NSArray *listOfRegnrs = [mFullTextEntry getRegnrsAsArray];
            NSArray *listOfArticles = [mDb searchRegnrsFromList:listOfRegnrs];
            NSDictionary *dict = [mFullTextEntry getRegChaptersDict];
            
            mFullTextContentStr = [mFullTextSearch tableWithArticles:listOfArticles
                                                   andRegChaptersDict:dict
                                                            andFilter:@""];
            mCurrentWebView = kFullTextSearchView;
            [self updateFullTextSearchView:mFullTextContentStr];
        }
    } else if ([notification object] == self.mySectionTitles) {
        /* 
         * Check if table is list of chapter titles (=mySectionTitles)
         * Right-most pane
        */
        NSInteger row = [[notification object] selectedRow];
       
        NSTableRowView *myRowView = [self.mySectionTitles rowViewAtRow:row makeIfNecessary:NO];
        [myRowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        
        if (mCurrentSearchState!=kFullText || mCurrentWebView!=kFullTextSearchView) {
            NSString *javaScript = [NSString stringWithFormat:@"window.location.hash='#%@'", mListOfSectionIds[row]];
            [myWebView stringByEvaluatingJavaScriptFromString:javaScript];
        } else {
            // Update webviewer's content without changing anything else
            NSString *contentStr = [mFullTextSearch tableWithArticles:nil
                                                   andRegChaptersDict:nil
                                                            andFilter:mListOfSectionIds[row]];
            [self updateFullTextSearchView:contentStr];
        }
    }
    
#ifdef DEBUG
    report_memory();
#endif
}

/*
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    
}

- (void) tableViewColumnDidResize:(NSNotification *)notification
{
    NSLog(@"Column resized");
}
*/

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
    } else if (tableView == mySectionTitles) {
        NSString *text = mListOfSectionTitles[row];
        NSFont *textFont = [NSFont boldSystemFontOfSize:11.0f];
        CGSize textSize = NSSizeFromCGSize([text sizeWithAttributes:[NSDictionary dictionaryWithObject:textFont
                                                                                                forKey:NSFontAttributeName]]);        
        return (textSize.height + 5.0f);
    }
    
    return 0.0f;
}

void report_memory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in bytes): %lu", info.resident_size);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}

@end
