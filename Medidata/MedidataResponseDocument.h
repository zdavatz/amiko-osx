//
//  MedidataResponseDocument.h
//  AmiKo
//
//  Created by b123400 on 2021/09/10.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MedidataResponseDocument : NSObject

@property (nonatomic, strong) NSXMLDocument *xmlDocument;

- (instancetype)initWithXMLDocument:(NSXMLDocument *)doc;
- (NSString *)transportToGLN;

@end

NS_ASSUME_NONNULL_END
