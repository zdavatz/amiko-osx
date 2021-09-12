//
//  MedidataInvoiceResponseLocalRow.m
//  AmiKo
//
//  Created by b123400 on 2021/09/11.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataInvoiceResponseLocalRow.h"

@interface MedidataInvoiceResponseLocalRow ()

@property (nonatomic, strong, nullable) NSString *transmissionRef;

@end

@implementation MedidataInvoiceResponseLocalRow

- (instancetype)initWithInvoiceFolder:(NSURL *)invoiceFolderURL
                            localFile:(NSURL *)url
                      amkFilePath:(NSString * _Nullable)amkFilePath
                transmissionReference:(NSString * _Nullable)ref {
    if (self = [super initWithInvoiceFolder:invoiceFolderURL]) {
        self.fileURL = url;
        self.amkFilePath = amkFilePath;
        self.transmissionRef = ref;
    }
    return self;
}

- (NSString *)amkFilename {
    if (self.amkFilePath) {
        return self.amkFilePath.lastPathComponent;
    }
    NSString *xmlFilename = self.fileURL.lastPathComponent;
    if ([xmlFilename hasSuffix:@"-response.xml"]) {
        return [xmlFilename stringByReplacingOccurrencesOfString:@"-response.xml" withString:@".amk"];
    }
    return nil;
}

- (NSString *)transmissionReference {
    if (self.transmissionRef) {
        return self.transmissionRef;
    }
    return nil;
}

- (NSString *)documentReference {
    return nil;
}

- (NSString *)senderGln {
    return nil;
}

- (NSString *)fileSize {
    NSError *error = nil;
    NSDictionary<NSFileAttributeKey, id> *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:self.fileURL.path
                                                                                                   error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
        return nil;
    }
    NSNumber *fileSize = [attrs objectForKey:NSFileSize];
    return [fileSize stringValue];
}

- (NSString *)created {
    return nil;
}

- (NSString *)status {
    return @"DOWNLOADED";
}

- (BOOL)canConfirm {
    return NO;
}

- (NSURL *)localFileToOpen {
    return self.fileURL;
}

@end
