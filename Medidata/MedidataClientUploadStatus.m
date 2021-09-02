//
//  MedidataClientUploadStatus.m
//  AmiKo
//
//  Created by b123400 on 2021/09/03.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataClientUploadStatus.h"

@implementation MedidataClientUploadStatus

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.transmissionReference = dict[@"transmissionReference"];
        self.created = dict[@"created"];
        self.modified = dict[@"modified"];
        self.status = dict[@"status"];
    }
    return self;
}

@end
