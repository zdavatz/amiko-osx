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

@interface MLMedidataResponsesWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property (atomic, strong) NSMutableArray<MedidataInvoiceResponse*> *invoiceResponses;
@property (atomic, strong) NSDictionary<NSString *, NSString *> *transmissionReferenceToAMKPath;
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
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.progressIndicator startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        NSArray<MedidataInvoiceResponse *> *arr = [self buildBaseInvoiceResponsesFromPatient];
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
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.invoiceResponses = arr;
//            [self.tableView reloadData];
//        });
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
    }
    return dict;
}

- (void)didReceivedMedidataDocs:(NSArray<MedidataDocument*> *)docs {
    NSMutableArray <MedidataInvoiceResponse*> *responses = [NSMutableArray array];
    for (MedidataDocument *doc in docs) {
        NSString *amkFilePath = self.transmissionReferenceToAMKPath[doc.transmissionReference];
        MedidataInvoiceResponse *r = [[MedidataInvoiceResponse alloc] init];
        r.amkFilePath = amkFilePath;
        r.document = doc;
        [responses addObject:r];
    }
    self.invoiceResponses = responses;
    [self.tableView reloadData];
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
        NSButton *button = [NSButton buttonWithTitle:NSLocalizedString(@"Confirm",@"")
                                              target:self
                                              action:@selector(confirmButtonDidPress:)];
        if ([self.loadingResponses containsObject:response.document.transmissionReference]) {
            [button setTitle:NSLocalizedString(@"Loading", @"")];
            [button setEnabled:NO];
        }
        if (response.confirmed) {
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
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"%@.txt", response.amkFilePath.lastPathComponent.stringByDeletingPathExtension]];
    NSModalResponse returnCode = [savePanel runModal];
    if (returnCode == NSFileHandlingPanelOKButton) {
        [[[MedidataClient alloc] init]
         downloadInvoiceResponseWithTransmissionReference:response.document.transmissionReference
         toFile:savePanel.URL
         completion:^(NSError * _Nonnull error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSAlert alertWithError:error] runModal];
                });
            }
        }];
    }
}

- (void)confirmButtonDidPress:(id)sender {
    MedidataInvoiceResponse *response = self.invoiceResponses[[sender tag]];
    [self.loadingResponses addObject: response.document.transmissionReference];
    [[[MedidataClient alloc] init] confirmInvoiceResponseWithTransmissionReference:response.document.transmissionReference
                                                                        completion:^(NSError * _Nonnull error, MedidataDocument * _Nonnull doc) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loadingResponses removeObject:doc.transmissionReference];
                for (int i = 0; i < self.invoiceResponses.count; i++) {
                    MedidataInvoiceResponse *r = self.invoiceResponses[i];
                    if ([r.document.transmissionReference isEqual:doc.transmissionReference]) {
                        r.document = doc;
                        r.confirmed = YES;
                        break;
                    }
                }
                [self.tableView reloadData];
            });
        }
    }];
    [self.tableView reloadData];
}

@end
