//
//  MedidataInvoiceResponseRow.m
//  AmiKo
//
//  Created by b123400 on 2021/09/11.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataInvoiceResponseRow.h"
#import "MedidataInvoiceDocument.h"

@interface MedidataInvoiceResponseRow ()

@property (nonatomic, strong) MedidataInvoiceDocument *invoiceDocument;

@end

@implementation MedidataInvoiceResponseRow

- (instancetype)initWithInvoiceFolder:(NSURL *)invoiceFolderURL {
    if (self = [super init]) {
        self.invoiceFolderURL = invoiceFolderURL;
    }
    return self;
}

- (NSString *)amkFilename {
    return nil;
}

- (NSString *)transmissionReference {
    return nil;
}

- (NSString *)documentReference {
    return nil;
}

- (NSString *)correlationReference {
    if (!self.invoiceDocument) {
        NSString *amkFilename = [self.amkFilename stringByAppendingString:@".xml"];
        if (!amkFilename) {
            return nil;
        }
        NSURL *invoiceURL = [self.invoiceFolderURL URLByAppendingPathComponent:amkFilename];
        NSError *error = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:invoiceURL.path]) {
            NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:invoiceURL options:0 error:&error];
            if (error) {
                NSLog(@"Cannot read invoice: %@", [error description]);
                return nil;
            }
            MedidataInvoiceDocument *invoiceDoc = [[MedidataInvoiceDocument alloc] initWithXMLDocument:xmlDoc];
            self.invoiceDocument = invoiceDoc;
        }
    }
    return [self.invoiceDocument requestId];
}

- (NSString *)senderGln {
    return nil;
}

- (NSString *)fileSize {
    return nil;
}

- (NSString *)created {
    return nil;
}

- (NSString *)status {
    return nil;
}

- (BOOL)canConfirm {
    return NO;
}

- (NSURL *)localFileToOpen {
    return nil;
}

@end
