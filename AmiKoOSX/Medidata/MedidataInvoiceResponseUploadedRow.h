//
//  MedidataInvoiceResponseUploadedRow.h
//  AmiKo
//
//  Created by b123400 on 2021/09/11.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MedidataInvoiceResponseRow.h"
#import "MedidataClientUploadStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface MedidataInvoiceResponseUploadedRow : MedidataInvoiceResponseRow

@property (nonatomic, strong) NSString *amkFilePath;
@property (nonatomic, strong, nullable) MedidataClientUploadStatus *uploadStatus;
@property (nonatomic, strong, nullable) NSString *transmissionRef;

- (instancetype)initWithInvoiceFolder:(NSURL *)invoiceFolderURL
                          amkFilePath:(NSString *)amkFilePath
                         uploadStatus:(MedidataClientUploadStatus * _Nullable)uploadStatus;

@end

NS_ASSUME_NONNULL_END
