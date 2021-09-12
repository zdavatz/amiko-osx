//
//  MedidataInvoiceDocument.h
//  AmiKo
//
//  Created by b123400 on 2021/09/12.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MedidataInvoiceDocument : NSObject

@property (nonatomic, strong) NSXMLDocument *xmlDocument;

- (instancetype)initWithXMLDocument:(NSXMLDocument *)doc;

- (NSString *)requestId;

@end

NS_ASSUME_NONNULL_END
