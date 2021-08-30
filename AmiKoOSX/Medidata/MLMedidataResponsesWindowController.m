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

@property (atomic, strong) NSArray<MedidataInvoiceResponse*> *invoiceResponses;
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
    self.invoiceResponses = @[];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.progressIndicator startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSArray<MedidataInvoiceResponse *> *arr = [self buildBaseInvoiceResponsesFromPatient];

        [[[MedidataClient alloc] init] getMedidataResponses:^(NSError * _Nonnull error, NSArray<MedidataDocument *> * _Nonnull docs) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [[NSAlert alertWithError:error] runModal];
                    return;
                }
                [self mergeResponsesWithDocs:docs];
                [self.progressIndicator stopAnimation:self];
            });
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.invoiceResponses = arr;
            [self.tableView reloadData];
        });
    });
}

- (NSArray<MedidataInvoiceResponse *> *)buildBaseInvoiceResponsesFromPatient {
    NSArray<NSString *> *paths = [self.mPrescriptionAdapter listOfPrescriptionsForPatient:self.patient];
    NSMutableArray <MedidataInvoiceResponse*> *statuses = [NSMutableArray array];
    for (NSString *path in paths) {
        [self.mPrescriptionAdapter loadPrescriptionFromURL:[NSURL fileURLWithPath:path]];
        NSArray<NSString *> *refs = [self.mPrescriptionAdapter medidataRefs];
        for (NSString *ref in refs) {
            MedidataInvoiceResponse *s = [[MedidataInvoiceResponse alloc] init];
            s.name = [NSString stringWithFormat:@"%@ - %@", [path lastPathComponent], [self.mPrescriptionAdapter placeDate]];
            s.transmissionReference = ref;
            s.amkFilePath = path;
            [statuses addObject:s];
        }
    }
    return statuses;
}

- (void)mergeResponsesWithDocs:(NSArray<MedidataDocument*> *)docs {
    for (MedidataDocument *doc in docs) {
        for (MedidataInvoiceResponse *response in self.invoiceResponses) {
            if ([response.transmissionReference isEqualToString:doc.transmissionReference]) {
                response.document = doc;
            }
        }
    }
    [self.tableView reloadData];
}

# pragma mark - Table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.invoiceResponses count];
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        return [self.invoiceResponses[row] name];
    } else if ([[tableColumn identifier] isEqualToString:@"status"]) {
        MedidataDocument *doc = [self.invoiceResponses[row] document];
        if (!doc) {
            return @"...";
        }
        return doc.status;
    }
    return nil;
}
- (IBAction)tableViewDoubleAction:(id)sender {
    NSInteger selected = [self.tableView selectedRow];
    if (selected == -1) return;
    MedidataInvoiceResponse *response = self.invoiceResponses[selected];
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"%@.txt", response.amkFilePath.lastPathComponent.stringByDeletingPathExtension]];
    NSModalResponse returnCode = [savePanel runModal];
    if (returnCode == NSFileHandlingPanelOKButton) {
        [[[MedidataClient alloc] init] downloadInvoiceResponseWithTransmissionReference:response.transmissionReference
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

@end
