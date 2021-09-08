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
#import "MedidataInvoiceResponse.h"
#import "MedidataGetStatusOperation.h"
#import "MLPersistenceManager.h"

@interface MLMedidataResponsesWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property (atomic, strong) NSMutableArray<MedidataInvoiceResponse*> *invoiceResponses;
@property (atomic, strong) NSDictionary<NSString *, NSString *> *transmissionReferenceToAMKPath;
@property (atomic, strong) NSMutableSet<NSString *> *latestTransmissionReferences; // The latest refs from each AMK file
@property (atomic, strong) NSMutableSet *loadingResponses;
@property (nonatomic, strong) MLPrescriptionsAdapter *mPrescriptionAdapter;
@property (nonatomic, strong) MLPatient *patient;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@end

@implementation MLMedidataResponsesWindowController

- (instancetype)initWithPatient:(MLPatient *)patient {
    self = [super initWithWindowNibName:@"MLMedidataResponsesWindowController"];
    self.patient = patient;
    self.mPrescriptionAdapter = [[MLPrescriptionsAdapter alloc] init];
    self.invoiceResponses = [NSMutableArray array];
    self.transmissionReferenceToAMKPath = @{};
    self.loadingResponses = [NSMutableSet set];
    self.latestTransmissionReferences = [NSMutableSet set];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.progressIndicator startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self.transmissionReferenceToAMKPath = [self buildTranmissionReferenceToAMKPathDict];

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

- (NSDictionary<NSString*, NSString*>*)buildTranmissionReferenceToAMKPathDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray<NSString *> *paths = [self.mPrescriptionAdapter listOfPrescriptionsForPatient:self.patient];
    for (NSString *path in paths) {
        [self.mPrescriptionAdapter loadPrescriptionFromURL:[NSURL fileURLWithPath:path]];
        NSArray<NSString *> *refs = [self.mPrescriptionAdapter medidataRefs];
        for (NSString *ref in refs) {
            [dict setObject:path forKey:ref];
        }
        NSString *last = [refs lastObject];
        if (last) {
            [self.latestTransmissionReferences addObject:last];
        }
    }
    return dict;
}

- (void)didReceivedMedidataDocs:(NSArray<MedidataDocument*> *)docs {
    NSMutableArray <MedidataInvoiceResponse*> *responses = [NSMutableArray array];
    for (MedidataDocument *doc in docs) {
        if ([doc.senderGln isEqualToString:[[[MLPersistenceManager shared] doctor] gln]]) {
            NSString *amkFilePath = self.transmissionReferenceToAMKPath[doc.transmissionReference];
            MedidataInvoiceResponse *r = [[MedidataInvoiceResponse alloc] init];
            r.amkFilePath = amkFilePath;
            r.document = doc;
            r.canConfirm = YES;
            [responses addObject:r];
        }
    }
    self.invoiceResponses = responses;
    [self.tableView reloadData];
    [self fetchUploadStatuses];
}

// Find upload statuses of documents that are in upload state (not yet in download state)
- (void)fetchUploadStatuses {
    __typeof(self) __weak _self = self;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:10];
    NSSet *downloadedRefs = [NSSet setWithArray:[self.invoiceResponses valueForKeyPath:@"document.transmissionReference"]];
    for (NSString *tranmissionReference in self.latestTransmissionReferences) {
        NSString *amkFilePath = self.transmissionReferenceToAMKPath[tranmissionReference];
        if (![downloadedRefs containsObject:tranmissionReference]) {
            MedidataGetStatusOperation *op = [[MedidataGetStatusOperation alloc] initWithTransmissionReference:tranmissionReference];
            op.callback = ^(NSError * _Nonnull error, MedidataClientUploadStatus * _Nonnull status) {
                if (status != nil) {
                    MedidataDocument *uploadDoc = [[MedidataDocument alloc] init];
                    uploadDoc.transmissionReference = tranmissionReference;
                    uploadDoc.created = status.created;
                    uploadDoc.status = status.status;
                    MedidataInvoiceResponse *r = [[MedidataInvoiceResponse alloc] init];
                    r.amkFilePath = amkFilePath;
                    r.document = uploadDoc;
                    r.canConfirm = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_self.invoiceResponses addObject:r];
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
    return [self.invoiceResponses count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    MedidataInvoiceResponse *response = self.invoiceResponses[row];
    NSTextField *textField = [[NSTextField alloc] init];
    textField.bezeled = NO;
    textField.drawsBackground = NO;
    textField.editable = NO;
    textField.selectable = YES;
    textField.cell.truncatesLastVisibleLine = YES;
    [textField setRefusesFirstResponder: YES];

    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        textField.stringValue = [[response amkFilePath] lastPathComponent] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"transmissionReference"]) {
        textField.stringValue = [[response document] transmissionReference] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"documentReference"]) {
        textField.stringValue = [[response document] documentReference] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"correlationReference"]) {
        textField.stringValue = [[response document] correlationReference] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"senderGln"]) {
        textField.stringValue = [[response document] senderGln] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"fileSize"]) {
        textField.stringValue = [[[response document] fileSize] stringValue] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"created"]) {
        textField.stringValue = [[[response document] created] description] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"status"]) {
        textField.stringValue = [[response document] status] ?: @"";
    } else if ([[tableColumn identifier] isEqualToString:@"confirm"]) {
        if (!response.canConfirm) {
            return nil;
        }
        NSButton *button = [NSButton buttonWithTitle:NSLocalizedString(@"Confirm",@"")
                                              target:self
                                              action:@selector(confirmButtonDidPress:)];
        if ([self.loadingResponses containsObject:response.document.transmissionReference]) {
            [button setTitle:NSLocalizedString(@"Loading", @"")];
            [button setEnabled:NO];
        }
        [button setTag:row];
        return button;
    }

    return textField;
}

- (IBAction)tableViewDoubleAction:(id)sender {
    NSInteger selected = [self.tableView selectedRow];
    if (selected == -1) return;
    MedidataInvoiceResponse *response = self.invoiceResponses[selected];
    if (!response.canConfirm) {
        return;
    }
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
    
    if ([[MLPersistenceManager shared] hadSetupMedidataInvoiceResponseXMLDirectory]) {
        NSURL *folderURL = [[MLPersistenceManager shared] medidataInvoiceResponseXMLDirectory];
        if ([folderURL startAccessingSecurityScopedResource]) {
            NSString *filename = response.amkFilePath.lastPathComponent ?: response.document.transmissionReference;
            NSURL *fileURL = [folderURL URLByAppendingPathComponent:[filename stringByAppendingString:@".xml"]];
            [[[MedidataClient alloc] init]
             downloadInvoiceResponseWithTransmissionReference:response.document.transmissionReference
             toFile:fileURL
             completion:^(NSError * _Nonnull error) {
                [folderURL stopAccessingSecurityScopedResource];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        [[NSAlert alertWithError:error] runModal];
                    } else {
                        NSAlert *alert = [[NSAlert alloc] init];
                        [alert setMessageText:NSLocalizedString(@"Downloaded", @"")];
                        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Downloaded to %@", @""), fileURL.path]];
                        [alert runModal];
                    }
                });
            }];
        } else {
            NSLog(@"Cannot access invoice response's secure URL");
        }
    }
}

- (void)confirmButtonDidPress:(id)sender {
    __typeof(self) __weak _self = self;
    MedidataInvoiceResponse *response = self.invoiceResponses[[sender tag]];
    [self.loadingResponses addObject: response.document.transmissionReference];
    [[[MedidataClient alloc] init] confirmInvoiceResponseWithTransmissionReference:response.document.transmissionReference
                                                                        completion:^(NSError * _Nonnull error, MedidataDocument * _Nonnull doc) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self.loadingResponses removeObject:doc.transmissionReference];
                for (int i = 0; i < self.invoiceResponses.count; i++) {
                    MedidataInvoiceResponse *r = _self.invoiceResponses[i];
                    if ([r.document.transmissionReference isEqual:doc.transmissionReference]) {
                        r.document = doc;
                        r.canConfirm = NO;
                        break;
                    }
                }
                [_self.tableView reloadData];
            });
        }
    }];
    [self.tableView reloadData];
}

@end
