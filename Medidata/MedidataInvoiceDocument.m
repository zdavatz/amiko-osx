//
//  MedidataInvoiceDocument.m
//  AmiKo
//
//  Created by b123400 on 2021/09/12.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataInvoiceDocument.h"

@implementation MedidataInvoiceDocument

- (instancetype)initWithXMLDocument:(NSXMLDocument *)doc {
    if (self = [super init]) {
        self.xmlDocument = doc;
    }
    return self;
}

- (NSString *)requestId {
    NSXMLElement *invoiceElement = [[self.xmlDocument.rootElement elementsForName:@"invoice:payload"].firstObject elementsForName:@"invoice:invoice"].firstObject;
    return [[invoiceElement attributeForName:@"request_id"] stringValue];
}

@end
