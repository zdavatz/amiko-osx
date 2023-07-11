//
//  MLHINADSwissSaml.h
//  AmiKo
//
//  Created by b123400 on 2023/07/06.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLHINTokens.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLHINADSwissSaml : NSObject

- (instancetype)initWithResponseJSON:(NSDictionary *)dict token:(MLHINTokens*)tokens;

@property (nonatomic, strong) MLHINTokens *tokens;
@property (nonatomic, strong) NSString *epdAuthUrl;
@property (nonatomic, strong) NSString *url;

@end

NS_ASSUME_NONNULL_END
