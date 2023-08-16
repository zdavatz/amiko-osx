//
//  MLHINADSwissAuthToken.h
//  AmiKoDesitin
//
//  Created by b123400 on 2023/08/16.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLHINADSwissAuthHandle : NSObject

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSDate *expiresAt;
@property (nonatomic, strong) NSDate *lastUsedAt;

- (instancetype)initWithToken:(NSString *)token;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)dictionaryRepresentation;

- (BOOL)expired;

- (void)updateLastUsedAt;

@end

NS_ASSUME_NONNULL_END
