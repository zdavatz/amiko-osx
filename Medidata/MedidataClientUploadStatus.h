//
//  MedidataClientUploadStatus.h
//  AmiKo
//
//  Created by b123400 on 2021/09/03.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MedidataClientUploadStatus : NSObject

@property (nonatomic, strong) NSString *transmissionReference;
@property (nonatomic, strong) NSString *created;
@property (nonatomic, strong) NSString *modified;
@property (nonatomic, strong) NSString *status;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
