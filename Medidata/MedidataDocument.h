//
//  MedidataDocument.h
//  AmiKo
//
//  Created by b123400 on 2021/08/17.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MedidataDocument : NSObject

@property (nonatomic, strong) NSString *transmissionReference;
@property (nonatomic, strong) NSString *documentReference;
@property (nonatomic, strong) NSString *correlationReference;
@property (nonatomic, strong) NSString *senderGln;
@property (nonatomic, strong) NSString *docType;
@property (nonatomic, strong) NSNumber *fileSize;
@property (nonatomic, strong) NSString *modus;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *created;

- (id)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
