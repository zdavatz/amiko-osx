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

- (void)sendXMLDocumentToMedidata:(NSXMLDocument *)document completion:(void (^)(NSError *error, NSString *ref))callback {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://212.51.146.241:8100/md/ela/uploads"]];
    [request setValue:@"1000007582" forHTTPHeaderField:@"X-CLIENT-ID"];
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

- (void)getMedidataResponses:(void (^)(NSError *error, NSArray<MedidataDocument*> *doc))callback {
//    NSData *dummy = [@"[{\"transmissionReference\": \"9b364f5c-59f9-4d27-bc6a-0ae4f92568dc\",\"documentReference\": \"doc-1\",\"correlationReference\": \"ABC\",\"senderGln\": \"7600000000000\",\"docType\": \"application/x-fd-geninv-req-v44+xml\",\"fileSize\": 12324,\"modus\": \"Test\",\"status\": \"PENDING\",\"created\": \"2013-03-01T12:00:33+0100\"}]" dataUsingEncoding:NSUTF8StringEncoding];
//    NSError *decodeError = nil;
//    NSArray *arr = [NSJSONSerialization JSONObjectWithData:dummy options:0 error:&decodeError];
//    NSMutableArray *docs = [NSMutableArray array];
//    for (NSDictionary *dict in arr) {
//        MedidataDocument *doc = [[MedidataDocument alloc] initWithDictionary:dict];
//        [docs addObject:doc];
//        NSLog(@"%@", doc);
//    }
//    callback(nil, docs);
//    return;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://212.51.146.241:8100/md/ela/downloads?limit=500"]];
    [request setValue:@"1000007582" forHTTPHeaderField:@"X-CLIENT-ID"];
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

- (void)getDocumentStatusWithTransmissionReference:(NSString *)ref completion:(void (^)(NSError *error, MedidataClientUploadStatus status))callback {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://212.51.146.241:8100/md/ela/uploads/%@/status", ref]]];
//    [request setValue:@"1000007582" forHTTPHeaderField:@"X-CLIENT-ID"];
//    [request setValue:[NSString stringWithFormat:@"Basic %@", MEDIDATA_CLIENT_AUTHORIZATION] forHTTPHeaderField:@"Authorization"];
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
            callback(error, MedidataClientUploadStatusUnknown);
            return;
        }
        if (data) {
            NSError *decodeError = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
            NSString *statusString = dict[@"status"];
            MedidataClientUploadStatus status = [statusString isEqualToString:@"DONE"] ? MedidataClientUploadStatusDone :
            [statusString isEqualToString:@"PROCESSING"] ? MedidataClientUploadStatusProcessing :
            [statusString isEqualToString:@"ERROR"] ? MedidataClientUploadStatusError :
            MedidataClientUploadStatusUnknown;
            if (status != MedidataClientUploadStatusUnknown) {
                callback(nil, status);
            } else {
                callback(
                         [NSError errorWithDomain:@"AmikoMedidata" code:0 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Status is %@", statusString]}],
                         MedidataClientUploadStatusUnknown
                         );
            }
        }
    }];
    [task resume];
}

- (void)downloadInvoiceResponseWithTransmissionReference:(NSString *)ref toFile:(NSURL*)dest completion:(void (^)(NSError *error))callback {
//    curl -kvL -O --resolve --location --request GET "https://212.51.146.241:8100/md/ela/downloads/f95ce87a-1856-4a10-a825-6c01e7c7346c" --header "X-CLIENT-ID: 1000007582" --header "Content-Type: multipart/form-data" --header "Authorization: Basic XXX"
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://212.51.146.241:8100/md/ela/downloads/%@", ref]]];
    [request setValue:@"1000007582" forHTTPHeaderField:@"X-CLIENT-ID"];
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
                                             completion:(void (^)(NSError *error, MedidataDocument *doc))callback {
    //curl -ks -X PUT --header "Content-Type: application/json" -d '{"status":"CONFIRMED"}' https://212.51.146.241:8100/md/ela/downloads/9c0e8433-f5e9f20/status --header "X-CLIENT-ID: 1000007582" --header "Content-Type: multipart/form-data" --header "Authorization: Basic XXXX"
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://212.51.146.241:8100/md/ela/downloads/%@/status", ref]]];
    [request setValue:@"1000007582" forHTTPHeaderField:@"X-CLIENT-ID"];
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
            MedidataDocument *doc = [[MedidataDocument alloc] initWithDictionary:dict];
            NSLog(@"%@", doc);
            callback(nil, doc);
        }
    }];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

//curl --location --request POST -k "https://212.51.146.241:8100/md/ela/uploads" --header "X-CLIENT-ID: 1000007582" --header "Content-Type: multipart/form-data" --header "Authorization: Basic eXd2NzhlU3puRlBzdm5jbDo2cmdPSHduSUE5bDd0d0Zn" -F "elauploadstream=@invoice_payant.xml;type=application/octet-stream"

@end
