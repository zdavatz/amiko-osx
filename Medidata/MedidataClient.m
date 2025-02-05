//
//  MedidataClient.m
//  AmiKo
//
//  Created by b123400 on 2021/07/05.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataClient.h"
#import "MedidataCredential.h"

@interface MedidataClient () <NSURLSessionDelegate>

@end

@implementation MedidataClient

- (void)sendXMLDocumentToMedidata:(NSXMLDocument *)document
                   clientIdSuffix:(NSString *)clientIdSuffix
                       completion:(void (^)(NSError * _Nullable error, NSString * _Nullable ref))callback {
    NSString *clientId = [self clientIdWithSuffix:clientIdSuffix];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://212.51.146.241:8100/md/ela/uploads"]];
    [request setValue:clientId forHTTPHeaderField:@"X-CLIENT-ID"];
    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Basic %@", MEDIDATA_CLIENT_AUTHORIZATION] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    
    NSData *xmlDocumentData = [document XMLDataWithOptions:NSXMLNodePrettyPrint];
    
    NSMutableData *httpBody = [NSMutableData data];

    [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", @"elauploadstream"] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"application/octet-stream"] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:xmlDocumentData];
    [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

//    [request setHTTPBody:httpBody];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                           delegate:self
                                                      delegateQueue:nil];
    NSURLSessionTask *task = [session uploadTaskWithRequest:request fromData:httpBody completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSLog(@"response: %@", response);
        if (error) {
            NSLog(@"error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithError:error];
                if ([error code] == NSURLErrorTimedOut) {
                    [alert setInformativeText:NSLocalizedString(@"The Medidata VA seems to be offline.", nil)];
                }
                [alert runModal];
            });
            callback(error, nil);
            return;
        }
        if (data) {
            NSError *decodeError = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
            NSString *ref = dict[@"transmissionReference"];
            NSLog(@"Medidata ref: %@", ref);
            callback(nil, ref);
        }
    }];
    [task resume];
}

- (void)getMedidataResponsesWithClientIdSuffix:(NSString *)clientIdSuffix
                                    completion:(void (^)(NSError * _Nullable error, NSArray<MedidataDocument*> * _Nullable doc))callback {
    NSString *clientId = [self clientIdWithSuffix:clientIdSuffix];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://212.51.146.241:8100/md/ela/downloads?limit=500"]];
    [request setValue:clientId forHTTPHeaderField:@"X-CLIENT-ID"];
    [request setValue:[NSString stringWithFormat:@"Basic %@", MEDIDATA_CLIENT_AUTHORIZATION] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                           delegate:self
                                                      delegateQueue:nil];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSLog(@"response: %@", response);
        if (error) {
            NSLog(@"error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithError:error];
                if ([error code] == NSURLErrorTimedOut) {
                    [alert setInformativeText:NSLocalizedString(@"The Medidata VA seems to be offline.", nil)];
                }
                [alert runModal];
            });
            callback(error, nil);
            return;
        }
        if (data) {
            NSError *decodeError = nil;
            NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
            NSMutableArray *docs = [NSMutableArray array];
            for (NSDictionary *dict in arr) {
                MedidataDocument *doc = [[MedidataDocument alloc] initWithDictionary:dict];
                [docs addObject:doc];
                NSLog(@"%@", doc);
            }
            callback(nil, docs);
        }
    }];
    [task resume];
}

- (void)getDocumentStatusWithTransmissionReference:(NSString *)ref
                                    clientIdSuffix:(NSString *)clientIdSuffix
                                        completion:(void (^)(NSError * _Nullable error, MedidataClientUploadStatus * _Nullable status))callback {
    NSString *clientId = [self clientIdWithSuffix:clientIdSuffix];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://212.51.146.241:8100/md/ela/uploads/%@/status", ref]]];
    [request setValue:clientId forHTTPHeaderField:@"X-CLIENT-ID"];
    [request setValue:[NSString stringWithFormat:@"Basic %@", MEDIDATA_CLIENT_AUTHORIZATION] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                           delegate:self
                                                      delegateQueue:nil];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSLog(@"response: %@", response);
        if (error) {
            NSLog(@"error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithError:error];
                if ([error code] == NSURLErrorTimedOut) {
                    [alert setInformativeText:NSLocalizedString(@"The Medidata VA seems to be offline.", nil)];
                }
                [alert runModal];
            });
            callback(error, nil);
            return;
        }
        if (data &&
            [response isKindOfClass:[NSHTTPURLResponse class]] &&
            [(NSHTTPURLResponse *)response statusCode] >= 200 &&
            [(NSHTTPURLResponse *)response statusCode] <= 299) {
            NSError *decodeError = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
            if (decodeError) {
                callback(decodeError, nil);
                return;
            }
            MedidataClientUploadStatus *status = [[MedidataClientUploadStatus alloc] initWithDictionary:dict];
            callback(nil, status);
            return;
        }
        callback(nil, nil);
    }];
    [task resume];
}

- (void)downloadInvoiceResponseWithTransmissionReference:(NSString *)ref
                                                  toFile:(NSURL*)dest
                                          clientIdSuffix:(NSString *)clientIdSuffix
                                              completion:(void (^)(NSError * _Nullable error))callback {
//    curl -kvL -O --resolve --location --request GET "https://212.51.146.241:8100/md/ela/downloads/f95ce87a-1856-4a10-a825-6c01e7c7346c" --header "X-CLIENT-ID: 1000007582" --header "Content-Type: multipart/form-data" --header "Authorization: Basic XXX"
    NSString *clientId = [self clientIdWithSuffix:clientIdSuffix];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://212.51.146.241:8100/md/ela/downloads/%@", ref]]];
    [request setValue:clientId forHTTPHeaderField:@"X-CLIENT-ID"];
    [request setValue:[NSString stringWithFormat:@"Basic %@", MEDIDATA_CLIENT_AUTHORIZATION] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                           delegate:self
                                                      delegateQueue:nil];
    NSURLSessionTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"response: %@", response);
        if (error) {
            NSLog(@"error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithError:error];
                if ([error code] == NSURLErrorTimedOut) {
                    [alert setInformativeText:NSLocalizedString(@"The Medidata VA seems to be offline.", nil)];
                }
                [alert runModal];
            });
            callback(error);
            return;
        }
        if (location) {
            NSError *moveError = nil;
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:dest error:&moveError];
            if (moveError) {
                callback(moveError);
                return;
            }
        }
        callback(nil);
    }];
    [task resume];
}

- (void)confirmInvoiceResponseWithTransmissionReference:(NSString *)ref
                                         clientIdSuffix:(NSString *)clientIdSuffix
                                             completion:(void (^)(NSError * _Nullable error, MedidataDocument * _Nullable doc))callback {
    //curl -ks -X PUT --header "Content-Type: application/json" -d '{"status":"CONFIRMED"}' https://212.51.146.241:8100/md/ela/downloads/9c0e8433-f5e9f20/status --header "X-CLIENT-ID: 1000007582" --header "Content-Type: multipart/form-data" --header "Authorization: Basic XXXX"
    NSString *clientId = [self clientIdWithSuffix:clientIdSuffix];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://212.51.146.241:8100/md/ela/downloads/%@/status", ref]]];
    [request setValue:clientId forHTTPHeaderField:@"X-CLIENT-ID"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Basic %@", MEDIDATA_CLIENT_AUTHORIZATION] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:[@"{\"status\":\"CONFIRMED\"}" dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                           delegate:self
                                                      delegateQueue:nil];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSLog(@"response: %@", response);
        if (error) {
            NSLog(@"error: %@", error);
            if ([error code] == NSURLErrorTimedOut) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert setInformativeText:NSLocalizedString(@"The Medidata VA seems to be offline.", nil)];
                    [alert runModal];
                });
            }
            callback(error, nil);
            return;
        }
        if (data) {
            NSError *decodeError = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
            MedidataDocument *doc = [[MedidataDocument alloc] initWithDictionary:dict];
            NSLog(@"%@", doc);
            callback(nil, doc);
            return;
        }
    }];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

- (NSString *)clientIdWithSuffix:(NSString*)suffix {
    if (![suffix length]) {
        return MEDIDATA_CLIENT_CLIENT_ID_PREFIX;
    }
    return [NSString stringWithFormat:@"%@_%@", MEDIDATA_CLIENT_CLIENT_ID_PREFIX, suffix];
}

@end
