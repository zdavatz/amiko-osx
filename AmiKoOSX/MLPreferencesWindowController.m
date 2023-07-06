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
#import "MLSDSOAuthWindowController.h"

@interface MLPreferencesWindowController ()
@property (weak) IBOutlet NSButton *iCloudCheckbox;
@property (weak) IBOutlet NSPathControl *invoicePathControl;
@property (weak) IBOutlet NSPathControl *invoiceResponsePathControl;
@property (weak) IBOutlet NSTextField *hinSDSUserIdTextField;
@property (weak) IBOutlet NSButton *loginWithHINSDSButton;
@property (strong) MLSDSOAuthWindowController *hinSDSOauthController;
@property (weak) IBOutlet NSTextField *hinADSwissUserIdTextField;
@property (weak) IBOutlet NSButton *loginWithHINADSwissButton;

@end

@implementation MLPreferencesWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self reloadiCloudCheckbox];
    [self reloadHINSDSState];
    
    [[MLHINClient shared] renewTokenIfNeededWithToken:[[MLPersistenceManager shared] HINSDSTokens]
                                           completion:^(NSError * _Nullable error, MLHINTokens * _Nullable tokens) {
        NSLog(@"Token %@", tokens);
    }];
    
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

- (void)reloadHINSDSState {
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
}

- (void)reloadHINADSwissState {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINSDSTokens];
    if (tokens) {
        [self.hinADSwissUserIdTextField setStringValue:tokens.hinId];
        [self.hinADSwissUserIdTextField setEnabled:YES];
        [self.loginWithHINADSwissButton setTitle:NSLocalizedString(@"Logout from HIN (ADSwiss)", @"")];
    } else {
        [self.hinADSwissUserIdTextField setStringValue:@"[Not logged in]"];
        [self.hinADSwissUserIdTextField setEnabled:NO];
        [self.loginWithHINADSwissButton setTitle:NSLocalizedString(@"Login with HIN (ADSwiss)", @"")];
    }
}

- (IBAction)loginWithHINSDSClicked:(id)sender {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINSDSTokens];
    if (tokens) {
        [[MLPersistenceManager shared] setHINSDSTokens:nil];
        [self reloadHINSDSState];
    } else {
        MLSDSOAuthWindowController *controller = [[MLSDSOAuthWindowController alloc] init];
        self.hinSDSOauthController = controller;
        typeof(self) __weak _self = self;
        [self.window beginSheet:controller.window
              completionHandler:^(NSModalResponse returnCode) {
            [_self reloadHINSDSState];
            _self.hinSDSOauthController = nil;
        }];
    }
}

- (IBAction)loginWithHINADSwissClicked:(id)sender {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINADSwissTokens];
    if (tokens) {
        [[MLPersistenceManager shared] setHINADSwissTokens:nil];
        [self reloadHINSDSState];
    } else {
//        MLSDSOAuthWindowController *controller = [[MLSDSOAuthWindowController alloc] init];
//        self.hinSDSOauthController = controller;
//        typeof(self) __weak _self = self;
//        [self.window beginSheet:controller.window
//              completionHandler:^(NSModalResponse returnCode) {
//            [_self reloadHINSDSState];
//            _self.hinSDSOauthController = nil;
//        }];
    }
}

@end
