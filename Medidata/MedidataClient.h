//
//  MedidataClient.h
//  AmiKo
//
//  Created by b123400 on 2021/07/05.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MedidataClient : NSObject

- (void)sendXMLDocumentToMedidata:(NSXMLDocument *)document;

@end

NS_ASSUME_NONNULL_END
