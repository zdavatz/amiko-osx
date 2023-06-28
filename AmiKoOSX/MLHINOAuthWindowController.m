//
//  MLHINOAuthWindowController.m
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "MLHINOAuthWindowController.h"
#import "MLHINClient.h"
#import "MLPersistenceManager.h"

@interface MLHINOAuthWindowController () <WKNavigationDelegate>
@property (weak) IBOutlet WKWebView *webView;
@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;

@end

@implementation MLHINOAuthWindowController

- (instancetype)init {
    return [super initWithWindowNibName:@"MLHINOAuthWindowController"];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSURL *url = [MLHINClient shared].authURL;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (IBAction)closeClicked:(id)sender {
    [self.window.sheetParent endSheet:self.window
                           returnCode:NSModalResponseCancel];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    typeof(self) __weak _self = self;
    if ([url.host isEqualTo:@"localhost"] && [url.port isEqualTo:@(8080)] && [url.path isEqualTo:@"/callback"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.loadingIndicator startAnimation:_self];
        });
        NSLog(@"url: %@", url);
//    http://localhost:8080/callback?state=teststate&code=xxxxxx
        NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                                 resolvingAgainstBaseURL:NO];
        for (NSURLQueryItem *query in [components queryItems]) {
            if ([query.name isEqualTo:@"code"]) {
                [[MLHINClient shared] fetchAccessTokenWithAuthCode:query.value
                                                        completion:^(NSError * _Nullable error, MLHINTokens * _Nullable tokens) {
                    if (error) {
                        [_self displayError:error];
                        return;
                    }
                    if (!tokens) {
                        [_self displayError:[NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                                code:0
                                                            userInfo:@{
                            NSLocalizedDescriptionKey: @"Invalid token response"
                        }]];
                    }
                    [[MLPersistenceManager shared] setHINTokens:tokens];
                    [[MLHINClient shared] fetchSelfWithToken:tokens
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
                        MLOperator *doctor = [[MLPersistenceManager shared] doctor];
                        [_self mergeHINProfile:profile withDoctor:doctor];
                        [[MLPersistenceManager shared] setDoctor:doctor];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_self.window.sheetParent endSheet:_self.window
                                                   returnCode:NSModalResponseOK];
                        });
                    }];
                }];
                break;
            }
        }
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
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

- (void)displayError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSAlert alertWithError:error] runModal];
    });
}

@end
