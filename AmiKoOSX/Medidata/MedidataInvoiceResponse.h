//
//  MedidataResponseStatus.h
//  AmiKo
//
//  Created by b123400 on 2021/08/18.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MedidataClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface MedidataInvoiceResponse : NSObject

@property (nonatomic, strong) NSString *transmissionReference;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong, nullable) MedidataDocument *document;

@end

NS_ASSUME_NONNULL_END
