//
//  MLHINClient.m
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLHINClient.h"
#import "MLHINClientCredential.h"
#import "MLPersistenceManager.h"

@implementation MLHINClient

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static MLHINClient *shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[MLHINClient alloc] init];
    });
    return shared;
}

- (NSURL*)authURLWithApplication:(NSString *)applicationName {
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://apps.hin.ch/REST/v1/OAuth/GetAuthCode/%@?response_type=code&client_id=%@&redirect_uri=http://localhost:8080/callback&state=teststate", applicationName, HIN_CLIENT_ID]];
}

- (NSURL*)authURLForSDS {
    return [self authURLWithApplication:@"hin_sds"];
}

- (NSURL *)authURLForADSwiss {
    return [self authURLWithApplication:
#ifdef DEBUG
            @"ADSwiss_CI-Test"
#else
            @"ADSwiss_CI"
#endif
    ];
}

- (void)fetchAccessTokenWithAuthCode:(NSString *)authCode
                          completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://oauth2.hin.ch/REST/v1/OAuth/GetAccessToken"]];
    [request setAllHTTPHeaderFields:@{
        @"Accept": @"application/json",
        @"Content-Type": @"application/x-www-form-urlencoded",
    }];
    [request setHTTPMethod:@"POST"];
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"grant_type" value:@"authorization_code"],
        [NSURLQueryItem queryItemWithName:@"redirect_uri" value:@"http://localhost:8080/callback"],
        [NSURLQueryItem queryItemWithName:@"code" value:authCode],
        [NSURLQueryItem queryItemWithName:@"client_id" value:HIN_CLIENT_ID],
        [NSURLQueryItem queryItemWithName:@"client_secret" value:HIN_CLIENT_SECRET],
    ];
    [request setHTTPBody:[components.query dataUsingEncoding:NSUTF8StringEncoding]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            callback(error, nil);
            return;
        }
        NSError *jsonError = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil) {
            NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            callback(jsonError, nil);
            return;
        }
        MLHINTokens *tokens = [[MLHINTokens alloc] initWithResponseJSON:jsonObj];
        if (!tokens) {
            NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        callback(nil, tokens);
    }] resume];
    //curl -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept:application/json' --data 'grant_type=authorization_code&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fcallback&code=xxxxxx&client_id=xxxxx&client_secret=xxxxx' https://oauth2.hin.ch/REST/v1/OAuth/GetAccessToken
}

- (void)renewTokenIfNeededWithToken:(MLHINTokens *)token
                         completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback {
    if (!token.expired) {
        callback(nil, token);
        return;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://oauth2.hin.ch/REST/v1/OAuth/GetAccessToken"]];
    [request setAllHTTPHeaderFields:@{
        @"Accept": @"application/json",
        @"Content-Type": @"application/x-www-form-urlencoded",
    }];
    [request setHTTPMethod:@"POST"];
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"grant_type" value:@"refresh_token"],
        [NSURLQueryItem queryItemWithName:@"redirect_uri" value:@"http://localhost:8080/callback"],
        [NSURLQueryItem queryItemWithName:@"refresh_token" value:token.refreshToken],
        [NSURLQueryItem queryItemWithName:@"client_id" value:HIN_CLIENT_ID],
        [NSURLQueryItem queryItemWithName:@"client_secret" value:HIN_CLIENT_SECRET],
    ];
    [request setHTTPBody:[components.query dataUsingEncoding:NSUTF8StringEncoding]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            callback(error, nil);
            return;
        }
        NSError *jsonError = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil) {
            NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            callback(jsonError, nil);
            return;
        }
        MLHINTokens *newTokens = [[MLHINTokens alloc] initWithResponseJSON:jsonObj];
        if (!newTokens) {
            NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        if (token.application == MLHINTokensApplicationSDS) {
            [[MLPersistenceManager shared] setHINSDSTokens:newTokens];
        } else if (token.application == MLHINTokensApplicationADSwiss) {
            [[MLPersistenceManager shared] setHINADSwissTokens:newTokens];
        }
        callback(nil, newTokens);
    }] resume];
//    curl -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept:application/json' --data 'grant_type=refresh_token&refresh_token=xxxxxx&client_id=xxxxx&client_secret=xxxxx' https://oauth2.hin.ch/REST/v1/OAuth/GetAccessToken
}

- (void)fetchSDSSelfWithToken:(MLHINTokens *)token completion:(void (^_Nonnull)(NSError *error, MLHINProfile *profile))callback {
    [self renewTokenIfNeededWithToken:token
                           completion:^(NSError * _Nullable error, MLHINTokens * _Nullable tokens) {
        if (error != nil) {
            callback(error, nil);
            return;
        }
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://oauth2.sds.hin.ch/api/public/v1/self/"]];
        [request setAllHTTPHeaderFields:@{
            @"Accept": @"application/json",
            @"Authorization": [NSString stringWithFormat:@"Bearer %@", token.accessToken],
        }];
        [request setHTTPMethod:@"GET"];
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error != nil) {
                callback(error, nil);
                return;
            }
            NSError *jsonError = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError != nil) {
                NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                callback(jsonError, nil);
                return;
            }
            MLHINProfile *profile = [[MLHINProfile alloc] initWithResponseJSON:jsonObj];
            if (!profile) {
                NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
            callback(nil, profile);
        }] resume];
        //curl -H 'Authorization: Bearer xxxxx' https://oauth2.sds.hin.ch/api/public/v1/self/
    }];
}

@end
