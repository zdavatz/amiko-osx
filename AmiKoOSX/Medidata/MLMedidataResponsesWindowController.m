//
//  MLMedidataResponsesWindowController.m
//  AmiKo
//
//  Created by b123400 on 2021/08/16.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MLMedidataResponsesWindowController.h"
#import "MedidataDocument.h"
#import "MLPrescriptionsAdapter.h"
#import "MedidataInvoiceResponseDownloadsRow.h"
#import "MedidataGetUploadStatusOperation.h"
#import "MLPersistenceManager.h"
#import "MedidataResponseDocument.h"
#import "MLMedidataDownloadAndCheckOperation.h"

#import "MedidataInvoiceResponseDownloadsRow.h"
#import "MedidataInvoiceResponseLocalRow.h"
#import "MedidataInvoiceResponseUploadedRow.h"

@interface MLMedidataResponsesWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property (atomic, strong) NSMutableArray<MedidataInvoiceResponseRow*> *rows;
@property (atomic, strong) NSMutableDictionary<NSString *, NSString *> *transmissionReferenceToAMKPath;
@property (atomic, strong) NSMutableSet<NSString *> *latestTransmissionReferences; // The latest refs from each AMK file
@property (atomic, strong) NSMutableSet *confirmingTransmissionReferences;
@property (nonatomic, strong) MLPrescriptionsAdapter *mPrescriptionAdapter;
@property (nonatomic, strong) MLPatient *patient;

@property (nonatomic, strong) NSURL *responseFolderURL;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@end

@implementation MLMedidataResponsesWindowController

// 1. List all local responses
// 1.1. List all amks
// 1.2. Get corresponding invoice response via amk filename or amk's transmission reference
// 1.3. Create MedidataInvoiceResponseLocalRow for local responses
//
// 2. List all remote responses
// 2.1 Create MedidataInvoiceResponseDownloadsRow for remote responses
// 2.2 Merge with some MedidataInvoiceResponseLocalRow,
//     because it possible that the response is already downloaded,
//     but not yet confirmed, which means it still available for download again.
//
// 3. List all remote upload status
// 3.1. If there's any transmission reference from all amk, that we cannot find any response,
//      we need to fetch its upload status.
// 3.2 Create MedidataInvoiceResponseUploadedRow row those rows.

- (instancetype)initWithPatient:(MLPatient *)patient {
    self = [super initWithWindowNibName:@"MLMedidataResponsesWindowController"];
    self.patient = patient;
    self.mPrescriptionAdapter = [[MLPrescriptionsAdapter alloc] init];
    self.rows = [NSMutableArray array];
    self.transmissionReferenceToAMKPath = [NSMutableDictionary dictionary];
    self.latestTransmissionReferences = [NSMutableSet set];
    self.confirmingTransmissionReferences = [NSMutableSet set];
    return self;
}

- (void)dealloc {
    [self.responseFolderURL stopAccessingSecurityScopedResource];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    if (![[MLPersistenceManager shared] hadSetupMedidataInvoiceResponseXMLDirectory]) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseFiles:NO];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanCreateDirectories:YES];
        [openPanel setAllowsMultipleSelection:NO];

        NSModalResponse returnCode = [openPanel runModal];
        if (returnCode == NSFileHandlingPanelOKButton) {
            [[MLPersistenceManager shared] setMedidataInvoiceResponseXMLDirectory:openPanel.URL];
        }
    }
    
    self.responseFolderURL = [[MLPersistenceManager shared] medidataInvoiceResponseXMLDirectory];
    if (![self.responseFolderURL startAccessingSecurityScopedResource]) {
        NSLog(@"Cannot access response's secure URL");
    }
    
    [self.progressIndicator startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self setupWithAMKsAndLocalResponses];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        [[[MedidataClient alloc] init] getMedidataResponses:^(NSError * _Nonnull error, NSArray<MedidataDocument *> * _Nonnull docs) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [[NSAlert alertWithError:error] runModal];
                    return;
                }
                [self didReceivedMedidataDocs:docs];
                [self.progressIndicator stopAnimation:self];
            });
        }];
    });
}

- (void)setupWithAMKsAndLocalResponses {
    NSArray<NSString *> *paths = [self.mPrescriptionAdapter listOfPrescriptionsForPatient:self.patient];
    for (NSString *path in paths) {
        [self.mPrescriptionAdapter loadPrescriptionFromURL:[NSURL fileURLWithPath:path]];
        NSArray<NSString *> *refs = [self.mPrescriptionAdapter medidataRefs];
        for (NSString *ref in refs) {
            [self.transmissionReferenceToAMKPath setObject:path forKey:ref];
            
            NSString *responseFile = [self findInvoiceResponseFileWithAmkFilePath:path transmissionReference:ref];
            if (responseFile) {
                [self.rows addObject:[[MedidataInvoiceResponseLocalRow alloc] initWithLocalFile:[NSURL fileURLWithPath:responseFile]
                                                                                    amkFilePath:path
                                                                          transmissionReference:ref]];
            }
        }
        NSString *last = [refs lastObject];
        if (last) {
            [self.latestTransmissionReferences addObject:last];
        }
    }
}

- (NSString * _Nullable)findInvoiceResponseFileWithAmkFilePath:(NSString *)path transmissionReference:(NSString *)ref {
    NSString *amkName = path.lastPathComponent.stringByDeletingPathExtension;
    NSString *responseAmkFilename = [NSString stringWithFormat:@"%@-response.xml", amkName];
    NSString *responseAmkPath = [self.responseFolderURL.path stringByAppendingPathComponent:responseAmkFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:responseAmkPath]) {
        return responseAmkPath;
    }
    NSString *responseRefFilename = [ref stringByAppendingPathExtension:@"xml"];
    NSString *responseRefPath = [self.responseFolderURL.path stringByAppendingPathComponent:responseRefFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:responseRefPath]) {
        return responseRefPath;
    }
    return nil;
}

- (NSInteger)indexOfLocalRowForTransmissionReference:(NSString *)ref {
    for (NSInteger i = 0; i < self.rows.count; i++) {
        MedidataInvoiceResponseRow *row = self.rows[i];
        if ([row isKindOfClass:[MedidataInvoiceResponseLocalRow class]]) {
            MedidataInvoiceResponseLocalRow *localRow = (MedidataInvoiceResponseLocalRow*)row;
            if ([[localRow transmissionReference] isEqualToString:ref]) {
                return i;
            }
        }
    }
    return -1;
}

- (void)didReceivedMedidataDocs:(NSArray<MedidataDocument*> *)docs {
    NSString *doctorGLN = [[[MLPersistenceManager shared] doctor] gln];
    __typeof(self) __weak _self = self;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:10];
    for (MedidataDocument *doc in docs) {
        NSString *amkFilePath = self.transmissionReferenceToAMKPath[doc.transmissionReference];

        MedidataInvoiceResponseDownloadsRow *row = [[MedidataInvoiceResponseDownloadsRow alloc] init];
        row.amkFilePath = amkFilePath;
        row.document = doc;
        
        NSInteger indexOfExistingLocalRow = [self indexOfLocalRowForTransmissionReference:doc.transmissionReference];
        if (indexOfExistingLocalRow >= 0) {
            // Already downloaded
            MedidataInvoiceResponseLocalRow *localRow = (MedidataInvoiceResponseLocalRow*)self.rows[indexOfExistingLocalRow];
            row.localRow = localRow;
            [self.rows replaceObjectAtIndex:indexOfExistingLocalRow withObject:row];
        } else {
            NSString *amkName = amkFilePath.lastPathComponent.stringByDeletingPathExtension;
            NSString *outputFilename = amkName ? [NSString stringWithFormat:@"%@-response.xml", amkName] : [doc.transmissionReference stringByAppendingPathExtension:@"xml"];
            NSURL *destURL = [self.responseFolderURL URLByAppendingPathComponent:outputFilename];
            if ([[NSFileManager defaultManager] fileExistsAtPath:destURL.path]) {
                MedidataInvoiceResponseLocalRow *localRow = [[MedidataInvoiceResponseLocalRow alloc] initWithLocalFile:destURL
                                                                                                           amkFilePath:nil
                                                                                                 transmissionReference:doc.transmissionReference];
                row.localRow = localRow;
            } else {
                MLMedidataDownloadAndCheckOperation *operation = [[MLMedidataDownloadAndCheckOperation alloc] initWithTransmissionReference:doc.transmissionReference
                                                                                                                               preferredGLN:doctorGLN
                                                                                                                             andDestination:destURL];
                operation.callback = ^(NSError * _Nullable error, NSURL * _Nullable downloadedURL) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            [[NSAlert alertWithError:error] runModal];
                            return;
                        }
                        MedidataInvoiceResponseLocalRow *localRow = [[MedidataInvoiceResponseLocalRow alloc] initWithLocalFile:downloadedURL
                                                                                                                   amkFilePath:row.amkFilePath
                                                                                                         transmissionReference:row.transmissionReference];
                        row.localRow = localRow;
                        [_self.tableView reloadData];
                    });
                };
                [queue addOperation:operation];
            }
            [self.rows addObject:row];
        }
    }
    [self.tableView reloadData];
    [self fetchUploadStatuses];
}

// Find upload statuses of documents that are in upload state (not yet in download state)
- (void)fetchUploadStatuses {
    __typeof(self) __weak _self = self;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:10];
    NSSet *downloadedRefs = [NSSet setWithArray:[self.rows valueForKeyPath:@"transmissionReference"]];
    for (NSString *tranmissionReference in self.latestTransmissionReferences) {
        NSString *amkFilePath = self.transmissionReferenceToAMKPath[tranmissionReference];
        if (![downloadedRefs containsObject:tranmissionReference]) {
            MedidataGetUploadStatusOperation *op = [[MedidataGetUploadStatusOperation alloc] initWithTransmissionReference:tranmissionReference];
            op.callback = ^(NSError * _Nonnull error, MedidataClientUploadStatus * _Nonnull status) {
                if (status != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        MedidataInvoiceResponseUploadedRow *row = [[MedidataInvoiceResponseUploadedRow alloc] initWithAMKFilePath:amkFilePath
                                                                                                                     uploadStatus:status];
                        [_self.rows addObject:row];
                        [_self.tableView reloadData];
                    });
                }
            };
            [queue addOperation:op];
        }
    }
}

# pragma mark - Table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.rows count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    MedidataInvoiceResponseRow *row = self.rows[rowIndex];

    NSTextField *textField = [[NSTextField alloc] init];
    textField.bezeled = NO;
    textField.drawsBackground = NO;
    textField.editable = NO;
    textField.selectable = YES;
    textField.cell.truncatesLastVisibleLine = YES;
    [textField setRefusesFirstResponder: YES];

    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        textField.stringValue = [row amkFilename] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"transmissionReference"]) {
        textField.stringValue = [row transmissionReference] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"documentReference"]) {
        textField.stringValue = [row documentReference] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"correlationReference"]) {
        textField.stringValue = [row correlationReference] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"senderGln"]) {
        textField.stringValue = [row senderGln] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"fileSize"]) {
        textField.stringValue = [row fileSize] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"created"]) {
        textField.stringValue = [row created] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"status"]) {
        textField.stringValue = [row status] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"confirm"]) {
        if (!row.canConfirm) {
            return nil;
        }
        NSButton *button = [NSButton buttonWithTitle:NSLocalizedString(@"Confirm",@"")
                                              target:self
                                              action:@selector(confirmButtonDidPress:)];
        if ([self.confirmingTransmissionReferences containsObject:row.transmissionReference]) {
            [button setTitle:NSLocalizedString(@"Loading", @"")];
            [button setEnabled:NO];
        }
        [button setTag:rowIndex];
        return button;
    }

    return textField;
}

- (IBAction)tableViewDoubleAction:(id)sender {
    NSInteger selected = [self.tableView selectedRow];
    if (selected == -1) return;
    MedidataInvoiceResponseRow *row = self.rows[selected];
    NSURL *fileURL = [row localFileToOpen];
    if (!fileURL) {
        return;
    }
    [[NSWorkspace sharedWorkspace] openURL:fileURL];
}

- (void)confirmButtonDidPress:(id)sender {
    __typeof(self) __weak _self = self;
    MedidataInvoiceResponseRow *row = self.rows[[sender tag]];
    if (![row isKindOfClass:[MedidataInvoiceResponseDownloadsRow class]]) {
        return;
    }
    MedidataInvoiceResponseDownloadsRow *downloadRow = (MedidataInvoiceResponseDownloadsRow*)row;
    [self.confirmingTransmissionReferences addObject: downloadRow.transmissionReference];
    [[[MedidataClient alloc] init] confirmInvoiceResponseWithTransmissionReference:downloadRow.transmissionReference
                                                                        completion:^(NSError * _Nonnull error, MedidataDocument * _Nonnull doc) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self.confirmingTransmissionReferences removeObject:doc.transmissionReference];
                downloadRow.document = doc;
                [_self.tableView reloadData];
            });
        }
    }];
    [self.tableView reloadData];
}

@end
