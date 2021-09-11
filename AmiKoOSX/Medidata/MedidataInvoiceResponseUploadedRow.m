//
//  MedidataInvoiceResponseUploadedRow.m
//  AmiKo
//
//  Created by b123400 on 2021/09/11.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataInvoiceResponseUploadedRow.h"

@interface MedidataInvoiceResponseUploadedRow ()

@property (nonatomic, strong) NSString *amkFilePath;
@property (nonatomic, strong) MedidataClientUploadStatus *uploadStatus;

@end

@implementation MedidataInvoiceResponseUploadedRow

- (instancetype)initWithAMKFilePath:(NSString *)amkFilePath uploadStatus:(MedidataClientUploadStatus *)uploadStatus {
    if (self = [super init]) {
        self.amkFilePath = amkFilePath;
        self.uploadStatus = uploadStatus;
    }
    return self;
}

- (NSString *)amkFilename {
    return self.amkFilePath.lastPathComponent;
}

- (NSString *)transmissionReference {
    return self.uploadStatus.transmissionReference;
}

- (NSString *)documentReference {
    return nil;
}

- (NSString *)correlationReference {
    return nil;
}

- (NSString *)senderGln {
    return nil;
}

- (NSString *)fileSize {
    return nil;
}

- (NSString *)created {
    return self.uploadStatus.created;
}

- (NSString *)status {
    return [NSString stringWithFormat:@"Uploaded: %@", self.uploadStatus.status];
}

- (BOOL)canConfirm {
    return NO;
}

@end
