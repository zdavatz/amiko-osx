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

- (instancetype)initWithAMKFilePath:(NSString *)amkFilePath uploadStatus:(MedidataClientUploadStatus *)uploadStatus;

@end

NS_ASSUME_NONNULL_END
