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
#import "MLHINADSwissSaml.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLHINClient : NSObject

+ (instancetype)shared;

- (NSURL *)authURLForSDS;
- (NSURL *)authURLForADSwiss;

- (void)fetchAccessTokenWithAuthCode:(NSString *)authCode
                          completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback;

- (void)renewTokenIfNeededWithToken:(MLHINTokens *)token
                         completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback;

- (void)fetchSDSSelfWithToken:(MLHINTokens *)token completion:(void (^_Nonnull)(NSError *error, MLHINProfile *profile))callback;

- (void)fetchADSwissSAMLWithToken:(MLHINTokens *)token completion:(void (^_Nonnull)(NSError *_Nullable error, MLHINADSwissSaml *result))callback;

- (void)fetchADSwissAuthHandleWithToken:(MLHINTokens *)token
                               authCode:(NSString *)authCode
                             completion:(void (^_Nonnull)(NSError *_Nullable error, NSString *_Nullable authHandle))callback;

@end

NS_ASSUME_NONNULL_END
