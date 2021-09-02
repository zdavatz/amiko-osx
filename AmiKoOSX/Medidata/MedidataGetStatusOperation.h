//
//  MedidataGetStatusOperation.h
//  AmiKo
//
//  Created by b123400 on 2021/08/18.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MedidataClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface MedidataGetStatusOperation : NSOperation

@property (nonatomic, strong) NSString *transmissionReference;
@property (nonatomic, copy, nullable) void (^callback)(NSError *error, MedidataClientUploadStatus *status);

- (instancetype)initWithTransmissionReference:(NSString *)ref;

@end

NS_ASSUME_NONNULL_END
