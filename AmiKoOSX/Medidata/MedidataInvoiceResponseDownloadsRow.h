//
//  MedidataResponseStatus.h
//  AmiKo
//
//  Created by b123400 on 2021/08/18.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MedidataClient.h"
#import "MedidataInvoiceResponseRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface MedidataInvoiceResponseDownloadsRow : MedidataInvoiceResponseRow

@property (nonatomic, strong, nullable) MedidataDocument *document;
@property (nonatomic, strong) NSString *amkFilePath;

// If it's both local and downloadable at the same time
@property (nonatomic, strong, nullable) MedidataInvoiceResponseRow *existingRow;

- (instancetype)initWithInvoiceFolder:(NSURL *)invoiceFolderURL amkFilePath:(NSString *)amkFilePath;

- (BOOL)isDownloading;

@end

NS_ASSUME_NONNULL_END
