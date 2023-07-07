//
//  MLHINOAuthWindowController.m
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "MLHINOAuthWindowController.h"
#import "MLPersistenceManager.h"

@interface MLHINOAuthWindowController () <WKNavigationDelegate>
@property (weak) IBOutlet WKWebView *webView;
@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;
@property (weak) IBOutlet NSTextField *statusLabel;

@end

@implementation MLHINOAuthWindowController

- (instancetype)init {
    return [super initWithWindowNibName:@"MLHINOAuthWindowController"];
}

- (NSURL *)authURL {
    @throw [NSException exceptionWithName:@"Subclass must override authURL" reason:nil userInfo:nil];
}

- (void)receivedTokens:(MLHINTokens *)tokens {
    @throw [NSException exceptionWithName:@"Subclass must override receivedTokens:" reason:nil userInfo:nil];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self displayStatus:@""];
    NSURLRequest *request = [NSURLRequest requestWithURL:[self authURL]];
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
            [_self displayStatus:NSLocalizedString(@"Loading: Received callback, fetching Access Token", @"")];
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
                    [_self displayStatus:NSLocalizedString(@"Received Access Token", @"")];
                    [_self receivedTokens:tokens];
                }];
                break;
            }
        }
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
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
