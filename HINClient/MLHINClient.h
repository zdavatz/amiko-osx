//
//  MLHINClient.h
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLHINTokens.h"
#import "MLHINProfile.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLHINClient : NSObject

+ (instancetype)shared;

- (NSURL *)authURL;

- (void)fetchAccessTokenWithAuthCode:(NSString *)authCode
                          completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback;

- (void)renewTokenIfNeededWithToken:(MLHINTokens *)token
                         completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback;

- (void)fetchSelfWithToken:(MLHINTokens *)token completion:(void (^_Nonnull)(NSError *error, MLHINProfile *profile))callback;

@end

NS_ASSUME_NONNULL_END