//
//  MLPreferencesWindowController.m
//  AmiKo
//
//  Created by b123400 on 2020/04/08.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLPreferencesWindowController.h"
#import "MLPersistenceManager.h"
#import "MLHINClient.h"

@interface MLPreferencesWindowController ()
@property (weak) IBOutlet NSButton *iCloudCheckbox;
@property (weak) IBOutlet NSPathControl *invoicePathControl;
@property (weak) IBOutlet NSPathControl *invoiceResponsePathControl;
@property (weak) IBOutlet NSTextField *hinSDSUserIdTextField;
@property (weak) IBOutlet NSButton *loginWithHINSDSButton;
@property (weak) IBOutlet NSTextField *hinADSwissUserIdTextField;
@property (weak) IBOutlet NSButton *loginWithHINADSwissButton;

@end

@implementation MLPreferencesWindowController

+ (instancetype)shared {
    static MLPreferencesWindowController *controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[MLPreferencesWindowController alloc] initWithWindowNibName:@"MLPreferencesWindowController"];
    });
    return controller;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self reloadiCloudCheckbox];
    [self reloadHINState];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquityIdentityDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [self reloadiCloudCheckbox];
    }];
    if ([[MLPersistenceManager shared] hadSetupMedidataInvoiceXMLDirectory]) {
        [self.invoicePathControl setURL:[[MLPersistenceManager shared] medidataInvoiceXMLDirectory]];
    } else {
        [self.invoicePathControl setURL: nil];
    }
    if ([[MLPersistenceManager shared] hadSetupMedidataInvoiceResponseXMLDirectory]) {
        [self.invoiceResponsePathControl setURL:[[MLPersistenceManager shared] medidataInvoiceResponseXMLDirectory]];
    } else {
        [self.invoiceResponsePathControl setURL: nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadiCloudCheckbox {
    self.iCloudCheckbox.enabled = [MLPersistenceManager supportICloud];
    self.iCloudCheckbox.state = [[MLPersistenceManager shared] currentSource] == MLPersistenceSourceICloud ? NSControlStateValueOn : NSControlStateValueOff;
}

- (IBAction)iCloudCheckboxDidChanged:(id)sender {
    if (self.iCloudCheckbox.state == NSControlStateValueOn) {
        [[MLPersistenceManager shared] setCurrentSourceToICloud];
    } else if (self.iCloudCheckbox.state == NSControlStateValueOff) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Do you want to delete files on iCloud?", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];

        [alert setAlertStyle:NSAlertStyleCritical];
        [alert beginSheetModalForWindow:[self window]
                      completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                [[MLPersistenceManager shared] setCurrentSourceToLocalWithDeleteICloud:NO];
            } else if (returnCode == NSAlertSecondButtonReturn) {
                [[MLPersistenceManager shared] setCurrentSourceToLocalWithDeleteICloud:YES];
            }
        }];
    }
}
- (IBAction)chooseInvoiceClicked:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];

    NSModalResponse returnCode = [openPanel runModal];
    if (returnCode != NSFileHandlingPanelOKButton) {
        return;
    }
    [[MLPersistenceManager shared] setMedidataInvoiceXMLDirectory:openPanel.URL];
    [self.invoicePathControl setURL:openPanel.URL];
}

- (IBAction)chooseInvoiceResponseClicked:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];

    NSModalResponse returnCode = [openPanel runModal];
    if (returnCode != NSFileHandlingPanelOKButton) {
        return;
    }
    [[MLPersistenceManager shared] setMedidataInvoiceResponseXMLDirectory:openPanel.URL];
    [self.invoiceResponsePathControl setURL:openPanel.URL];
}

- (void)reloadHINState {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINSDSTokens];
    if (tokens) {
        [self.hinSDSUserIdTextField setStringValue:tokens.hinId];
        [self.hinSDSUserIdTextField setEnabled:YES];
        [self.loginWithHINSDSButton setTitle:NSLocalizedString(@"Logout from HIN (SDS)", @"")];
    } else {
        [self.hinSDSUserIdTextField setStringValue:@"[Not logged in]"];
        [self.hinSDSUserIdTextField setEnabled:NO];
        [self.loginWithHINSDSButton setTitle:NSLocalizedString(@"Login with HIN (SDS)", @"")];
    }
    [self.loginWithHINSDSButton setEnabled:YES];
    tokens = [[MLPersistenceManager shared] HINADSwissTokens];
    if (tokens) {
        [self.hinADSwissUserIdTextField setStringValue:tokens.hinId];
        [self.hinADSwissUserIdTextField setEnabled:YES];
        [self.loginWithHINADSwissButton setTitle:NSLocalizedString(@"Logout from HIN (ADSwiss)", @"")];
    } else {
        [self.hinADSwissUserIdTextField setStringValue:@"[Not logged in]"];
        [self.hinADSwissUserIdTextField setEnabled:NO];
        [self.loginWithHINADSwissButton setTitle:NSLocalizedString(@"Login with HIN (ADSwiss)", @"")];
    }
    [self.loginWithHINADSwissButton setEnabled:YES];
}

- (IBAction)loginWithHINSDSClicked:(id)sender {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINSDSTokens];
    if (tokens) {
        [[MLPersistenceManager shared] setHINSDSTokens:nil];
        [self reloadHINState];
    } else {
        NSURL *authURL = [[MLHINClient shared] authURLForSDS];
        NSLog(@"Opening SDS auth URL: %@", authURL);
        [[NSWorkspace sharedWorkspace] openURL:authURL];
    }
}

- (IBAction)loginWithHINADSwissClicked:(id)sender {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINADSwissTokens];
    if (tokens) {
        [[MLPersistenceManager shared] setHINADSwissTokens:nil];
        [self reloadHINState];
    } else {
        NSURL *authURL = [[MLHINClient shared] authURLForADSwiss];
        NSLog(@"Opening SDS auth URL: %@", authURL);
        [[NSWorkspace sharedWorkspace] openURL:authURL];
    }
}

- (void)handleOAuthCallbackWithCode:(NSString *)code state:(NSString *)state {
    __weak typeof(self) _self = self;
    if ([state isEqual:[[MLHINClient shared] sdsApplicationName]]) {
        [self.loginWithHINSDSButton setEnabled:NO];
        _self.hinSDSUserIdTextField.stringValue = NSLocalizedString(@"Loading", @"");
    } else if ([state isEqual:[[MLHINClient shared] ADSwissApplicationName]]) {
        [self.loginWithHINADSwissButton setEnabled:NO];
        _self.hinADSwissUserIdTextField.stringValue = NSLocalizedString(@"Loading", @"");
    }
    [[MLHINClient shared] fetchAccessTokenWithAuthCode:code
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
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            _self.hinSDSUserIdTextField.stringValue = NSLocalizedString(@"Received Access Token", @"");
        });
        if ([state isEqual:[[MLHINClient shared] sdsApplicationName]]) {
            [[MLPersistenceManager shared] setHINSDSTokens:tokens];
            dispatch_async(dispatch_get_main_queue(), ^{
                _self.hinSDSUserIdTextField.stringValue = NSLocalizedString(@"Loading: Received Access Token, fetching profile", @"");
            });
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    _self.hinSDSUserIdTextField.stringValue = NSLocalizedString(@"Received profile", @"");
                });
                MLOperator *doctor = [[MLPersistenceManager shared] doctor];
                [profile mergeWithDoctor:doctor];
                [[MLPersistenceManager shared] setDoctor:doctor];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_self reloadHINState];
                });
            }];
        } else if ([state isEqual:[[MLHINClient shared] ADSwissApplicationName]]) {
            [[MLPersistenceManager shared] setHINADSwissTokens:tokens];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self reloadHINState];
            });
        }
    }];
}

- (void)displayError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSAlert alertWithError:error] runModal];
        [self reloadHINState];
    });
}

@end
