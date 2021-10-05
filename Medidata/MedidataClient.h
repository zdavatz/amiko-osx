//
//  MedidataClient.h
//  AmiKo
//
//  Created by b123400 on 2021/07/05.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MedidataDocument.h"
#import "MedidataClientUploadStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface MedidataClient : NSObject

- (void)sendXMLDocumentToMedidata:(NSXMLDocument *)document
                   clientIdSuffix:(NSString *)clientIdSuffix
                       completion:(void (^)(NSError * _Nullable error, NSString * _Nullable ref))callback;
- (void)getMedidataResponsesWithClientIdSuffix:(NSString *)clientIdSuffix
                                    completion:(void (^)(NSError * _Nullable error, NSArray<MedidataDocument*> * _Nullable docs))callback;
- (void)getDocumentStatusWithTransmissionReference:(NSString *)ref
                                    clientIdSuffix:(NSString *)clientIdSuffix
                                        completion:(void (^)(NSError * _Nullable error, MedidataClientUploadStatus * _Nullable status))callback;
- (void)downloadInvoiceResponseWithTransmissionReference:(NSString *)ref
                                                  toFile:(NSURL *)dest
                                          clientIdSuffix:(NSString *)clientIdSuffix
                                              completion:(void (^)(NSError * _Nullable error))callback;
- (void)confirmInvoiceResponseWithTransmissionReference:(NSString *)ref
                                         clientIdSuffix:(NSString *)clientIdSuffix
                                             completion:(void (^)(NSError * _Nullable error, MedidataDocument * _Nullable doc))callback;

@end

NS_ASSUME_NONNULL_END
