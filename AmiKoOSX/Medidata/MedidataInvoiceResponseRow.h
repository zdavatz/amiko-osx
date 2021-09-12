//
//  MedidataInvoiceResponseRow.h
//  AmiKo
//
//  Created by b123400 on 2021/09/11.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MedidataInvoiceResponseRow : NSObject

@property (nonatomic, strong) NSURL *invoiceFolderURL;

- (instancetype)initWithInvoiceFolder:(NSURL *)invoiceFolderURL;

- (NSString *)amkFilename;
- (NSString *)transmissionReference;
- (NSString *)documentReference;
- (NSString *)correlationReference;
- (NSString *)senderGln;
- (NSString *)fileSize;
- (NSString *)created;
- (NSString *)status;
- (BOOL)canConfirm;
- (NSURL *)localFileToOpen;

@end

NS_ASSUME_NONNULL_END
