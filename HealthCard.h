//
//  HealthCard.h
//  AmiKo
//
//  Created by Alex Bettarini on 22 May 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "SmartCard.h"

@interface HealthCard : SmartCard
{
    NSString *familyName;
    NSString *givenName;
    NSString *birthDate;
    NSString *gender;
    NSString *bagNumber;
    NSString *healthCardNumber;
}

- (uint8_t) parseTLV:(NSData *)data;
- (void) parseCardData:(NSData *)data;

@end
