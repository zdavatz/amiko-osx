//
//  MLHINADSwissAuthToken.m
//  AmiKoDesitin
//
//  Created by b123400 on 2023/08/16.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLHINADSwissAuthHandle.h"

@interface MLHINADSwissAuthHandle ()

@property (nonatomic, strong) NSString *sourceForDebug;

@end

@implementation MLHINADSwissAuthHandle

- (instancetype)initWithToken:(NSString *)token {
    if (self = [super init]) {
        self.token = token;
        self.expiresAt = [[NSDate date] dateByAddingTimeInterval:12*60*60];
        self.lastUsedAt = [NSDate date];
        self.sourceForDebug = [MLHINADSwissAuthHandle buildEnvironment];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.token = dict[@"token"];
        self.lastUsedAt = dict[@"lastUsedAt"];
        self.expiresAt = dict[@"expiresAt"];
        self.sourceForDebug = dict[@"source"];
        
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"token": self.token,
        @"lastUsedAt": self.lastUsedAt,
        @"expiresAt": self.expiresAt,
        @"source": self.sourceForDebug ?: @"",
    };
}

- (BOOL)expired {
    return [[NSDate date] compare:self.expiresAt] == NSOrderedDescending
        || [[NSDate date] compare:[self.lastUsedAt dateByAddingTimeInterval:60*60*2]] == NSOrderedDescending; // Expires after 2 hours of idle
}

- (void)updateLastUsedAt {
    self.lastUsedAt = [NSDate date];
}

- (NSString *)token {
    if (self.sourceForDebug.length && ![self.sourceForDebug isEqual:[MLHINADSwissAuthHandle buildEnvironment]]) {
        NSLog(@"WARNING: An auth handle generated in %@ environment is being used in %@ environment", self.sourceForDebug, [MLHINADSwissAuthHandle buildEnvironment]);
    }
    return _token;
}

+ (NSString *)buildEnvironment {
#ifdef DEBUG
        return @"debug";
#else
        return @"release";
#endif
}

@end
