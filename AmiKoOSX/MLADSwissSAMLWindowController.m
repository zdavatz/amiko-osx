//
//  MLADSwissSAMLWindowController.m
//  AmiKo
//
//  Created by b123400 on 2023/07/09.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLADSwissSAMLWindowController.h"
#import "MLPersistenceManager.h"
#import "MLHINClient.h"
#import <WebKit/WebKit.h>
#import "MLHINADSwissAuthHandle.h"

@interface MLADSwissSAMLWindowController () <WKNavigationDelegate>

@property (weak) IBOutlet WKWebView *webView;
@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;
@property (weak) IBOutlet NSTextField *statusLabel;

@end

@implementation MLADSwissSAMLWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"MLADSwissSAMLWindowController"]) {
        
    }
    return self;
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
            [_self displayStatus:NSLocalizedString(@"Loading: Received callback, fetching Auth handle", @"")];
        });
        NSLog(@"url: %@", url);
//    http://localhost:8080/callback?auth_code=xxxxxx
        NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                                 resolvingAgainstBaseURL:NO];
        for (NSURLQueryItem *query in [components queryItems]) {
            if ([query.name isEqualTo:@"auth_code"]) {
                [[MLHINClient shared] fetchADSwissAuthHandleWithToken:[[MLPersistenceManager shared] HINADSwissTokens]
                                                             authCode:query.value
                                                           completion:^(NSError * _Nullable error, NSString * _Nullable authHandle) {
                    NSLog(@"received Auth Handle1 %@ %@", error, authHandle);
                    if (error) {
                        [_self displayError:error];
                        return;
                    }
                    if (!authHandle) {
                        [_self displayError:[NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                                code:0
                                                            userInfo:@{
                            NSLocalizedDescriptionKey: @"Invalid authHandle"
                        }]];
                        return;
                    }
                    [_self displayStatus:NSLocalizedString(@"Received Auth Handle", @"")];
                    MLHINADSwissAuthHandle *handle = [[MLHINADSwissAuthHandle alloc] initWithToken:authHandle];
                    [[MLPersistenceManager shared] setHINADSwissAuthHandle:handle];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_self.window.sheetParent endSheet:_self.window returnCode:NSModalResponseOK];
                    });
                }];
                break;
            }
        }
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self.loadingIndicator stopAnimation:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self displayStatus:NSLocalizedString(@"Loading SAML URL", @"")];
    [self.loadingIndicator startAnimation:self];
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINADSwissTokens];
    if (!tokens) {
        NSLog(@"Token not found, not loading SAML");
        return;
    }
    typeof(self) __weak _self = self;
    [[MLHINClient shared] fetchADSwissSAMLWithToken:tokens
                                         completion:^(NSError * _Nullable error, MLHINADSwissSaml * _Nonnull result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [[NSAlert alertWithError:error] runModal];
                return;
            }
            [_self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:result.epdAuthUrl]]];
        });
    }];
}

- (IBAction)closeClicked:(id)sender {
    [self.window.sheetParent endSheet:self.window
                           returnCode:NSModalResponseCancel];
}

- (void)displayError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSAlert alertWithError:error] runModal];
    });
}

- (void)displayStatus:(NSString *)status {
    if ([NSThread isMainThread]) {
        self.statusLabel.stringValue = status;
    } else {
        typeof(self) __weak _self = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            _self.statusLabel.stringValue = status;
        });
    }
}

@end
