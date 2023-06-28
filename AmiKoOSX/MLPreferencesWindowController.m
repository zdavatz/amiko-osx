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
#import "MLHINOAuthWindowController.h"

@interface MLPreferencesWindowController ()
@property (weak) IBOutlet NSButton *iCloudCheckbox;
@property (weak) IBOutlet NSPathControl *invoicePathControl;
@property (weak) IBOutlet NSPathControl *invoiceResponsePathControl;
@property (weak) IBOutlet NSTextField *hinUserIdTextField;
@property (weak) IBOutlet NSButton *loginWithHINButton;
@property (strong) MLHINOAuthWindowController *hinOauthController;

@end

@implementation MLPreferencesWindowController

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
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINTokens];
    if (tokens) {
        [self.hinUserIdTextField setStringValue:tokens.hinId];
        [self.hinUserIdTextField setEnabled:YES];
        [self.loginWithHINButton setTitle:NSLocalizedString(@"Logout from HIN", @"")];
    } else {
        [self.hinUserIdTextField setStringValue:@"[Not logged in]"];
        [self.hinUserIdTextField setEnabled:NO];
        [self.loginWithHINButton setTitle:NSLocalizedString(@"Login with HIN", @"")];
    }
}

- (IBAction)loginWithHINClicked:(id)sender {
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINTokens];
    if (tokens) {
        [[MLPersistenceManager shared] setHINTokens:nil];
        [self reloadHINState];
    } else {
        MLHINOAuthWindowController *controller = [[MLHINOAuthWindowController alloc] init];
        self.hinOauthController = controller;
        typeof(self) __weak _self = self;
        [self.window beginSheet:controller.window
              completionHandler:^(NSModalResponse returnCode) {
            [_self reloadHINState];
            _self.hinOauthController = nil;
        }];
    }
}


@end
