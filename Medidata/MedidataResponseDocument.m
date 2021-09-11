//
//  MedidataResponseDocument.m
//  AmiKo
//
//  Created by b123400 on 2021/09/10.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataResponseDocument.h"

@implementation MedidataResponseDocument

- (instancetype)initWithXMLDocument:(NSXMLDocument *)doc {
    if (self = [super init]) {
        self.xmlDocument = doc;
    }
    return self;
}

- (NSString *)transportToGLN {
    NSXMLElement *root = [self.xmlDocument rootElement];
    NSXMLElement *transportElement = [[[[root elementsForName:@"invoice:processing"] firstObject] elementsForName:@"invoice:transport"] firstObject];
    return [[transportElement attributeForName:@"to"] stringValue];
}

@end
