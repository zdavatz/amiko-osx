//
//  MLHINADSwissAuthToken.m
//  AmiKoDesitin
//
//  Created by b123400 on 2023/08/16.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLHINADSwissAuthHandle.h"

@implementation MLHINADSwissAuthHandle

- (instancetype)initWithToken:(NSString *)token {
    if (self = [super init]) {
        self.token = token;
        self.expiresAt = [[NSDate date] dateByAddingTimeInterval:12*60*60];
        self.lastUsedAt = [NSDate date];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.token = dict[@"token"];
        self.lastUsedAt = dict[@"lastUsedAt"];
        self.expiresAt = dict[@"expiresAt"];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"token": self.token,
        @"lastUsedAt": self.lastUsedAt,
        @"expiresAt": self.expiresAt,
    };
}

- (BOOL)expired {
    return [[NSDate date] compare:self.expiresAt] == NSOrderedDescending
        || [[NSDate date] compare:[self.lastUsedAt dateByAddingTimeInterval:60*60*2]] == NSOrderedDescending; // Expires after 2 hours of idle
}

- (void)updateLastUsedAt {
    self.lastUsedAt = [NSDate date];
}

@end
