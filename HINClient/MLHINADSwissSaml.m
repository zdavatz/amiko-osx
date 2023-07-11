//
//  MLHINADSwissSaml.m
//  AmiKo
//
//  Created by b123400 on 2023/07/06.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLHINADSwissSaml.h"

@implementation MLHINADSwissSaml

- (instancetype)initWithResponseJSON:(NSDictionary *)dict token:(nonnull MLHINTokens *)tokens {
    // ( {"url":"https://ci-prep.adswiss.hin.ch/samlService/saml/authenticate?guid=_1f115509-92b2-4a3f-beea-7b2332fd35dc","epdAuthUrl":"https://ci-prep.adswiss.hin.ch/samlService/saml/authenticate?guid=_1f115509-92b2-4a3f-beea-7b2332fd35dc"})
    if (self = [super init]) {
        self.tokens = tokens;
        self.url = dict[@"url"];
        self.epdAuthUrl = dict[@"epdAuthUrl"];
    }
    return self;
}

@end
