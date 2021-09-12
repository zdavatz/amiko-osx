//
//  MedidataResponseStatus.m
//  AmiKo
//
//  Created by b123400 on 2021/08/18.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataInvoiceResponseDownloadsRow.h"
#import "MedidataInvoiceResponseUploadedRow.h"

@implementation MedidataInvoiceResponseDownloadsRow

- (instancetype)initWithInvoiceFolder:(NSURL *)invoiceFolderURL amkFilePath:(NSString *)amkFilePath {
    if (self = [super initWithInvoiceFolder:invoiceFolderURL]) {
        self.amkFilePath = amkFilePath;
    }
    return self;
}

- (NSString *)amkFilename {
    return self.amkFilePath.lastPathComponent;
}

- (NSString *)transmissionReference {
    return self.document.transmissionReference;
}

- (NSString *)documentReference {
    return self.document.documentReference;
}

- (NSString *)correlationReference {
    return self.document.correlationReference;
}

- (NSString *)senderGln {
    return self.document.senderGln;
}

- (NSString *)fileSize {
    return [self.document.fileSize stringValue];
}

- (NSString *)created {
    return self.document.created;
}

- (NSString *)status {
    return self.document.status;
}

- (BOOL)canConfirm {
    return [self.status isEqualToString:@"PENDING"];
}

- (BOOL)isDownloading {
    return [self.existingRow isKindOfClass:[MedidataInvoiceResponseUploadedRow class]];
}

- (NSURL *)localFileToOpen {
    return [self.existingRow localFileToOpen];
}

@end
