//
//  MLHINProfile.m
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLHINProfile.h"

@interface MLHINProfile ()
@end

@implementation MLHINProfile

- (instancetype)initWithResponseJSON:(NSDictionary *)dict {
//    {"loginName":"xxxxxx","email":"xxxxx@hin.ch","contactId":{"firstName":"xxxx","middleName":"xxxx","lastName":"xxxxx","gender":"M","dateOfBirth":"1900-01-01T00:00:00Z","address":"xxxxx","postalCode":"123","city":"Zürich","countryCode":"CH","phoneNr":"+41 11 111 11 11","verificationLevel":"10"}}
    if (self = [super init]) {
        self.loginName = dict[@"loginName"];
        self.email = dict[@"email"];
        NSDictionary *contact = dict[@"contactId"];
        self.firstName = contact[@"firstName"];
        self.middleName = contact[@"middleName"];
        self.lastName = contact[@"lastName"];
        self.gender = contact[@"gender"]; // "M" / "F"
        NSString *dobString = contact[@"dateOfBirth"];
        if (!dobString) {
            return nil;
        }
        self.dateOfBirth = [[[NSISO8601DateFormatter alloc] init] dateFromString:dobString];
        self.address = contact[@"address"];
        self.postalCode = contact[@"postalCode"];
        self.city = contact[@"city"];
        self.countryCode = contact[@"countryCode"];
        self.phoneNr = contact[@"phoneNr"];
        self.gln = contact[@"gln"];
        self.verificationLevel = contact[@"verificationLevel"];
    }
    return self;
}

@end
