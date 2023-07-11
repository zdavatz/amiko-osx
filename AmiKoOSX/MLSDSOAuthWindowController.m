//
//  MLSDSOAuthWindowController.m
//  AmiKo
//
//  Created by b123400 on 2023/07/06.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLSDSOAuthWindowController.h"
#import "MLHINClient.h"
#import "MLPersistenceManager.h"

@interface MLSDSOAuthWindowController ()

@end

@implementation MLSDSOAuthWindowController

- (NSURL *)authURL {
    return [[MLHINClient shared] authURLForSDS];
}

- (void)receivedTokens:(id)tokens {
    [[MLPersistenceManager shared] setHINSDSTokens:tokens];
    [self displayStatus:NSLocalizedString(@"Loading: Received Access Token, fetching profile", @"")];
    typeof(self) __weak _self = self;
    [[MLHINClient shared] fetchSDSSelfWithToken:tokens
                                     completion:^(NSError * _Nonnull error, MLHINProfile * _Nonnull profile) {
        if (error) {
            [_self displayError:error];
            return;
        }
        if (!profile) {
            [_self displayError:[NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                    code:0
                                                userInfo:@{
                NSLocalizedDescriptionKey: @"Invalid profile response"
            }]];
            return;
        }
        [_self displayStatus:NSLocalizedString(@"Received profile", @"")];
        MLOperator *doctor = [[MLPersistenceManager shared] doctor];
        [_self mergeHINProfile:profile withDoctor:doctor];
        [[MLPersistenceManager shared] setDoctor:doctor];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.window.sheetParent endSheet:_self.window
                                   returnCode:NSModalResponseOK];
        });
    }];
}

- (void)mergeHINProfile:(MLHINProfile *)profile withDoctor:(MLOperator *)doctor {
    if (!doctor.emailAddress.length) {
        doctor.emailAddress = profile.email;
    }
    if (!doctor.familyName.length) {
        doctor.familyName = profile.lastName;
    }
    if (!doctor.givenName.length) {
        doctor.givenName = profile.firstName;
    }
    if (!doctor.postalAddress.length) {
        doctor.postalAddress = profile.address;
    }
    if (!doctor.zipCode.length) {
        doctor.zipCode = profile.postalCode;
    }
    if (!doctor.city.length) {
        doctor.city = profile.city;
    }
    if (!doctor.country.length) {
        doctor.country = profile.countryCode;
    }
    if (!doctor.phoneNumber.length) {
        doctor.phoneNumber = profile.phoneNr;
    }
    if (!doctor.gln.length) {
        doctor.gln = profile.gln;
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

@end
