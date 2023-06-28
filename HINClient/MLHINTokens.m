//
//  MLHINTokens.m
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLHINTokens.h"

@interface MLHINTokens ()

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, strong) NSDate *expiresAt;
@property (nonatomic, strong) NSString *hinId;
@property (nonatomic, strong) NSString *tokenType;

@end

@implementation MLHINTokens

- (instancetype)initWithResponseJSON:(NSDictionary *)dict {
    // {"access_token":"xxxxxx","expires_in":2592000,"hin_id":"xxxxx","refresh_token":"xxxxxxx","token_type":"Bearer"}%
    if (self = [super init]) {
        self.accessToken = dict[@"access_token"];
        if (!self.accessToken) return nil;
        self.refreshToken = dict[@"refresh_token"];
        NSNumber *expiresIn = dict[@"expires_in"];
        if (![expiresIn isKindOfClass:[NSNumber class]]) {
            @throw [NSException exceptionWithName:@"Unexpected expires_in type" reason:@"expires_in is not a number" userInfo:@{@"value": expiresIn}];
        }
        self.expiresAt = [[NSDate date] dateByAddingTimeInterval:[expiresIn doubleValue]];
        self.hinId = dict[@"hin_id"];
        self.tokenType = dict[@"token_type"];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.accessToken = dict[@"accessToken"];
        self.refreshToken = dict[@"refreshToken"];
        self.expiresAt = dict[@"expiresAt"];
        self.hinId = dict[@"hinId"];
        self.tokenType = dict[@"tokenType"];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"accessToken": self.accessToken,
        @"refreshToken": self.refreshToken,
        @"expiresAt": self.expiresAt,
        @"hinId": self.hinId,
        @"tokenType": self.tokenType,
    };
}

- (BOOL)expired {
    return [[NSDate date] compare:self.expiresAt] == NSOrderedDescending;
}

@end
