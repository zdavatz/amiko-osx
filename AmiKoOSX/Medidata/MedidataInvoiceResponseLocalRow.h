//
//  MedidataInvoiceResponseLocalRow.h
//  AmiKo
//
//  Created by b123400 on 2021/09/11.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MedidataInvoiceResponseRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface MedidataInvoiceResponseLocalRow : MedidataInvoiceResponseRow

@property (nonatomic, strong) NSURL *fileURL;

- (instancetype)initWithLocalFile:(NSURL *)url
                      amkFilePath:(NSString * _Nullable)amkFilePath
            transmissionReference:(NSString * _Nullable)ref;

@end

NS_ASSUME_NONNULL_END
