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
@property (atomic, strong) NSMutableSet *confirmingTransmissionReferences;
@property (nonatomic, strong) MLPrescriptionsAdapter *mPrescriptionAdapter;
@property (nonatomic, strong) MLPatient *patient;

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSURL *invoiceFolderURL;
@property (nonatomic, strong) NSURL *invoiceResponseFolderURL;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@end

@implementation MLMedidataResponsesWindowController

// 1. List all local responses
// 1.1. List all amks
// 1.2. Get corresponding invoice response via amk filename or amk's transmission reference
// 1.3. Create MedidataInvoiceResponseLocalRow for local responses
// 1.4. If local response does not exist, it's "Uploaded but not yet receiving response", so create
//      a MedidataInvoiceResponseUploadedRow
//
// 2. List all remote responses
// 2.1 Create MedidataInvoiceResponseDownloadsRow for remote responses
// 2.2 Merge with some MedidataInvoiceResponseLocalRow and MedidataInvoiceResponseUploadedRow,
//     because it possible that the response is already downloaded,
//     but not yet confirmed, which means it still available for download again.
//
// 3. List all remote upload status
// 3.1. If there's any transmission reference from all amk, that we cannot find any response,
//      we need to fetch its upload status.
// 3.2 Create MedidataInvoiceResponseUploadedRow row those rows, or update existing MedidataInvoiceResponseUploadedRows.

- (instancetype)initWithPatient:(MLPatient *)patient {
    self = [super initWithWindowNibName:@"MLMedidataResponsesWindowController"];
    self.patient = patient;
    self.mPrescriptionAdapter = [[MLPrescriptionsAdapter alloc] init];
    self.rows = [NSMutableArray array];
    self.queue = [[NSOperationQueue alloc] init];
    [self.queue setMaxConcurrentOperationCount:10];
    self.transmissionReferenceToAMKPath = [NSMutableDictionary dictionary];
    self.confirmingTransmissionReferences = [NSMutableSet set];
    return self;
}

- (void)dealloc {
    [self.invoiceFolderURL stopAccessingSecurityScopedResource];
    [self.invoiceResponseFolderURL stopAccessingSecurityScopedResource];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    self.invoiceFolderURL = [[MLPersistenceManager shared] medidataInvoiceXMLDirectory];
    if (![self.invoiceFolderURL startAccessingSecurityScopedResource]) {
        NSLog(@"Cannot access invoice's secure URL");
    }
    self.invoiceResponseFolderURL = [[MLPersistenceManager shared] medidataInvoiceResponseXMLDirectory];
    if (![self.invoiceResponseFolderURL startAccessingSecurityScopedResource]) {
        NSLog(@"Cannot access invoice response's secure URL");
    }
    
    [self.progressIndicator startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self setupWithAMKsAndLocalResponses];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        [[[MedidataClient alloc] init] getMedidataResponsesWithClientIdSuffix:[MLPersistenceManager shared].doctor.medidataClientId
                                                                   completion:^(NSError * _Nullable error, NSArray<MedidataDocument *> * _Nullable docs) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [[NSAlert alertWithError:error] runModal];
                    return;
                }
                [self didReceivedMedidataDocs:docs];
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
                [self.rows addObject:[[MedidataInvoiceResponseLocalRow alloc] initWithInvoiceFolder:self.invoiceFolderURL
                                                                                          localFile:[NSURL fileURLWithPath:responseFile]
                                                                                        amkFilePath:path
                                                                              transmissionReference:ref]];
            } else {
                MedidataInvoiceResponseUploadedRow *uploadedRow = [[MedidataInvoiceResponseUploadedRow alloc] initWithInvoiceFolder:self.invoiceFolderURL
                                                                                                                        amkFilePath:path
                                                                                                                       uploadStatus:nil];
                uploadedRow.transmissionRef = ref;
                [self.rows addObject:uploadedRow];
            }
        }
    }
}

- (NSString * _Nullable)findInvoiceResponseFileWithAmkFilePath:(NSString *)path transmissionReference:(NSString *)ref {
    NSString *amkName = path.lastPathComponent.stringByDeletingPathExtension;
    NSString *responseAmkFilename = [NSString stringWithFormat:@"%@-response.xml", amkName];
    NSString *responseAmkPath = [self.invoiceResponseFolderURL.path stringByAppendingPathComponent:responseAmkFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:responseAmkPath]) {
        return responseAmkPath;
    }
    return nil;
}

- (NSInteger)indexOfRowForCorrelationReference:(NSString *)ref {
    for (NSInteger i = 0; i < self.rows.count; i++) {
        MedidataInvoiceResponseRow *row = self.rows[i];
        if ([[row correlationReference] isEqualToString:ref]) {
            return i;
        }
    }
    return -1;
}

- (void)didReceivedMedidataDocs:(NSArray<MedidataDocument*> *)docs {
    NSString *doctorGLN = [[[MLPersistenceManager shared] doctor] gln];
    __typeof(self) __weak _self = self;
    for (MedidataDocument *doc in docs) {
        NSInteger indexOfExistingLocalRow = [self indexOfRowForCorrelationReference:doc.correlationReference];
        if (indexOfExistingLocalRow == -1) {
            continue;
        }
        // We already have an entry for that, either
        // 1. Already downloaded as a LocalRow, or
        // 2. Uploaded as a Uploaded row.
        MedidataInvoiceResponseRow *existingRow = self.rows[indexOfExistingLocalRow];
        NSString *amkFilePath = [existingRow isKindOfClass:[MedidataInvoiceResponseLocalRow class]]
            ? [(MedidataInvoiceResponseLocalRow*)existingRow amkFilePath]
            : [existingRow isKindOfClass:[MedidataInvoiceResponseUploadedRow class]]
            ? [(MedidataInvoiceResponseUploadedRow*)existingRow amkFilePath]
            : nil;
        MedidataInvoiceResponseDownloadsRow *row = [[MedidataInvoiceResponseDownloadsRow alloc] initWithInvoiceFolder:self.invoiceFolderURL
                                                                                                          amkFilePath:amkFilePath];
        row.document = doc;
        row.existingRow = existingRow;
        [self.rows replaceObjectAtIndex:indexOfExistingLocalRow withObject:row];
        if ([existingRow isKindOfClass:[MedidataInvoiceResponseUploadedRow class]]) {
            NSString *outputFilename = [NSString stringWithFormat:@"%@-response.xml", amkFilePath.lastPathComponent.stringByDeletingPathExtension];
            NSURL *destURL = [self.invoiceResponseFolderURL URLByAppendingPathComponent:outputFilename];
            MLMedidataDownloadAndCheckOperation *operation = [[MLMedidataDownloadAndCheckOperation alloc] initWithTransmissionReference:doc.transmissionReference
                                                                                                                           preferredGLN:doctorGLN
                                                                                                                         andDestination:destURL];
            operation.callback = ^(NSError * _Nullable error, NSURL * _Nullable downloadedURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        [[NSAlert alertWithError:error] runModal];
                        return;
                    }
                    MedidataInvoiceResponseLocalRow *localRow = [[MedidataInvoiceResponseLocalRow alloc] initWithInvoiceFolder:_self.invoiceFolderURL
                                                                                                                     localFile:downloadedURL
                                                                                                                   amkFilePath:row.amkFilePath
                                                                                                         transmissionReference:row.transmissionReference];
                    row.existingRow = localRow;
                    [_self.tableView reloadData];
                });
            };
            [self.queue addOperation:operation];
        }
    }
    [self.tableView reloadData];
    [self fetchUploadStatuses];
}

// Find upload statuses of documents that are in upload state (not yet in download state)
- (void)fetchUploadStatuses {
    __typeof(self) __weak _self = self;
    for (MedidataInvoiceResponseRow *row in self.rows) {
        if (![row isKindOfClass:[MedidataInvoiceResponseUploadedRow class]]) {
            continue;
        }
        MedidataInvoiceResponseUploadedRow *uploadedRow = (MedidataInvoiceResponseUploadedRow*)row;
        if (uploadedRow.uploadStatus) {
            continue;
        }
        MedidataGetUploadStatusOperation *op = [[MedidataGetUploadStatusOperation alloc] initWithTransmissionReference:[uploadedRow transmissionReference]];
        op.callback = ^(NSError * _Nonnull error, MedidataClientUploadStatus * _Nonnull status) {
            if (status != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    uploadedRow.uploadStatus = status;
                    [_self.tableView reloadData];
                });
            }
        };
        [self.queue addOperation:op];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.queue waitUntilAllOperationsAreFinished];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.progressIndicator stopAnimation:_self];
        });
    });
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
                                                                    clientIdSuffix:[MLPersistenceManager shared].doctor.medidataClientId
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
