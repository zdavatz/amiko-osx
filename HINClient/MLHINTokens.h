//
//  MLHINTokens.h
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLHINTokens : NSObject

- (instancetype)initWithResponseJSON:(NSDictionary *)dict;

- (BOOL)expired;
- (NSString *)refreshToken;
- (NSString *)accessToken;
- (NSString *)hinId;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END
