//
//  MLMedidataDownloadAndCheckOperation.h
//  AmiKo
//
//  Created by b123400 on 2021/09/10.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLMedidataDownloadAndCheckOperation : NSOperation

@property (nonatomic, copy, nullable) void (^callback)(NSError * _Nullable error, NSURL * _Nullable downloadedURL);

- (instancetype)initWithTransmissionReference:(NSString *)ref preferredGLN:(NSString *)gln andDestination:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
