//
//  MedidataResponseStatus.m
//  AmiKo
//
//  Created by b123400 on 2021/08/18.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataInvoiceResponseDownloadsRow.h"

@implementation MedidataInvoiceResponseDownloadsRow

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
    return self.localRow == nil;
}

- (NSURL *)localFileToOpen {
    return [self.localRow localFileToOpen];
}

@end
