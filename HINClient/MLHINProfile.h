//
//  MLHINProfile.h
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLHINProfile : NSObject

- (instancetype)initWithResponseJSON:(NSDictionary *)dict;

@property (nonatomic, strong, nonnull) NSString *loginName;
@property (nonatomic, strong, nonnull) NSString *email;
@property (nonatomic, strong, nullable) NSString *firstName;
@property (nonatomic, strong, nullable) NSString *middleName;
@property (nonatomic, strong, nullable) NSString *lastName;
@property (nonatomic, strong, nullable) NSString *gender; // "M" / "F"
@property (nonatomic, strong, nullable) NSDate *dateOfBirth;
@property (nonatomic, strong, nullable) NSString *address;
@property (nonatomic, strong, nullable) NSString *postalCode;
@property (nonatomic, strong, nullable) NSString *city;
@property (nonatomic, strong, nullable) NSString *countryCode;
@property (nonatomic, strong, nullable) NSString *phoneNr;
@property (nonatomic, strong, nullable) NSString *gln;
@property (nonatomic, strong, nullable) NSString *verificationLevel;

@end

NS_ASSUME_NONNULL_END
