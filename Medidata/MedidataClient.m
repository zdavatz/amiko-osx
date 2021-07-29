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

- (void)sendXMLDocumentToMedidata:(NSXMLDocument *)document {
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
        NSLog(@"error: %@", error);
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithError:error];
                if ([error code] == NSURLErrorTimedOut) {
                    [alert setInformativeText:NSLocalizedString(@"The Medidata VA seems to be offline.", nil)];
                }
                [alert runModal];
            });
            return;
        }
        if (data) {
            NSError *decodeError = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
            NSString *ref = dict[@"transmissionReference"];
            // TODO: past ref to amk
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
