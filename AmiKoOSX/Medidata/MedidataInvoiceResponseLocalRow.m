//
//  MedidataInvoiceResponseLocalRow.m
//  AmiKo
//
//  Created by b123400 on 2021/09/11.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataInvoiceResponseLocalRow.h"

@interface MedidataInvoiceResponseLocalRow ()

@property (nonatomic, strong, nullable) NSString *amkFilePath;
@property (nonatomic, strong, nullable) NSString *ref;

@end

@implementation MedidataInvoiceResponseLocalRow

- (instancetype)initWithLocalFile:(NSURL *)url amkFilePath:(NSString * _Nullable)amkFilePath transmissionReference:(NSString * _Nullable)ref {
    if (self = [super init]) {
        self.fileURL = url;
        self.amkFilePath = amkFilePath;
        self.ref = ref;
    }
    return self;
}

- (NSString *)amkFilename {
    if (self.amkFilePath) {
        return self.amkFilename.lastPathComponent;
    }
    NSString *xmlFilename = self.fileURL.lastPathComponent;
    if ([xmlFilename hasSuffix:@"-response.xml"]) {
        return [xmlFilename stringByReplacingOccurrencesOfString:@"-response.xml" withString:@".amk"];
    }
    return nil;
}

- (NSString *)transmissionReference {
    if (self.ref) {
        return self.ref;
    }
    NSString *xmlFilename = self.fileURL.lastPathComponent;
    if (![xmlFilename hasSuffix:@"-response.xml"]) {
        return [xmlFilename stringByDeletingPathExtension];
    }
    return nil;
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
