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

- (void)sendXMLDocumentToMedidata:(NSXMLDocument *)document completion:(void (^)(NSError *error, NSString *ref))callback;
- (void)getMedidataResponses:(void (^)(NSError *error, NSArray<MedidataDocument*> *doc))callback;
- (void)downloadInvoiceResponseWithTransmissionReference:(NSString *)ref toFile:(NSURL*)dest completion:(void (^)(NSError *error))callback;
- (void)getDocumentStatusWithTransmissionReference:(NSString *)ref
                                        completion:(void (^)(NSError * _Nullable error, MedidataClientUploadStatus * _Nullable status))callback;
- (void)confirmInvoiceResponseWithTransmissionReference:(NSString *)ref
                                             completion:(void (^)(NSError *error, MedidataDocument *doc))callback;

@end

NS_ASSUME_NONNULL_END
