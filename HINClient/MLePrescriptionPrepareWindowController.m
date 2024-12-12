//
//  MLePrescriptionPrepareWindowController.m
//  AmiKo
//
//  Created by b123400 on 2023/07/10.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLePrescriptionPrepareWindowController.h"
#import "MLPersistenceManager.h"
#import "MLPrescriptionItem.h"
#import "LFCGzipUtility.h"
#import "MLUtilities.h"
#import "MLHINADSwissAuthHandle.h"
#import "MLHINClient.h"

@interface MLePrescriptionPrepareWindowController ()

@property (nonatomic, strong) MLPatient *patient;
@property (nonatomic, strong) MLOperator *doctor;
@property (nonatomic, strong) NSArray<MLPrescriptionItem*> *items;

@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSButton *cancelButton;


@end

@implementation MLePrescriptionPrepareWindowController

+ (BOOL)applicable {
    MLHINTokens *adswissTokens = [[MLPersistenceManager shared] HINADSwissTokens];
    return adswissTokens != nil;
}

+ (BOOL)canPrintWithoutAuth {
    return [MLePrescriptionPrepareWindowController applicable] && [[MLPersistenceManager shared] HINADSwissAuthHandle] != nil;
}

- (instancetype)initWithPatient:(MLPatient *)patient
                         doctor:(MLOperator *)doctor
                          items:(NSArray<MLPrescriptionItem*> *)items
{
    if (self = [super initWithWindowNibName:@"MLePrescriptionPrepareWindowController"]) {
        self.patient = patient;
        self.doctor = doctor;
        self.items = items;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self startFlow];
}

- (IBAction)cancelClicked:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (void)handleOAuthCallbackWithAuthCode:(NSString *)code {
    typeof(self) __weak _self = self;
    [[MLHINClient shared] fetchADSwissAuthHandleWithToken:[[MLPersistenceManager shared] HINADSwissTokens]
                                                 authCode:code
                                               completion:^(NSError * _Nullable error, NSString * _Nullable authHandle) {
        NSLog(@"received Auth Handle1: (error:%@) %@", error, authHandle);
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
        [_self afterGettingAuthHandle:handle];
    }];
}

- (void)startFlow {
    typeof(self) __weak _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_self.loadingIndicator startAnimation:_self];
    });
    [self displayStatus:NSLocalizedString(@"Loading SAML", @"")];
    MLHINADSwissAuthHandle *authHandle = [self getAuthHandleOrAuth];
    if (!authHandle) return; // User should have browser opened by now
    [self afterGettingAuthHandle:authHandle];
}

- (void)afterGettingAuthHandle:(MLHINADSwissAuthHandle *)authHandle {
    typeof(self) __weak _self = self;
    [self displayStatus:NSLocalizedString(@"Preparing prescription file", @"")];
    NSString *prescriptionFile = [self preparePrescriptionFile];
    [self displayStatus:NSLocalizedString(@"Preparing QR Code", @"")];
    [authHandle updateLastUsedAt];
    [[MLPersistenceManager shared] setHINADSwissAuthHandle:authHandle];
    [self executeCertifactionWithGZippedBase64File:prescriptionFile
                                        authHandle:authHandle
                                        completion:^(NSError * _Nullable error, NSString * _Nullable qrCodeFile) {
        if (error.code == 401) {
            [[MLPersistenceManager shared] setHINADSwissAuthHandle:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self startFlow];
            });
            return;
        } else if (error) {
            [_self displayError:error];
            return;
        }
        [self displayStatus:NSLocalizedString(@"QR Code is ready", @"")];
        NSLog(@"QRCode file %@", qrCodeFile);
        NSImage *qrCodeImage = [[NSImage alloc] initWithContentsOfFile:qrCodeFile];
        NSLog(@"qrCodeImage %@", NSStringFromSize(qrCodeImage.size));
        self.outQRCode = qrCodeImage;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.window.sheetParent endSheet:_self.window
                                    returnCode:NSModalResponseOK];
        });
    }];
}

- (void)displayError:(NSError *)error {
    typeof(self) __weak _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSAlert alertWithError:error] runModal];
        [_self.window.sheetParent endSheet:_self.window
                                returnCode:NSModalResponseCancel];
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

- (MLHINADSwissAuthHandle *)getAuthHandleOrAuth {
    MLHINADSwissAuthHandle *authHandle = [[MLPersistenceManager shared] HINADSwissAuthHandle];
    if (authHandle) {
        return authHandle;
    }
    typeof(self) __weak _self = self;
    [[MLHINClient shared] fetchADSwissSAMLWithToken:[[MLPersistenceManager shared] HINADSwissTokens]
                                         completion:^(NSError * _Nullable error, MLHINADSwissSaml * _Nonnull result) {
        if (error) {
            [_self displayError:error];
            return;
        }
        NSLog(@"Opening URL received from ADSwiss's epdAuthURL: %@", result.epdAuthUrl);
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:result.epdAuthUrl]];
    }];
    return nil;
}

- (NSString *)preparePrescriptionFile {
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSMutableArray *items = [NSMutableArray array];
    for (MLPrescriptionItem *item in self.items) {
        [items addObject:@{
            @"Id": item.eanCode,
            @"IdType": @2, // GTIN
        }];
    }
    NSDictionary *jsonBody = @{
        @"Patient": @{
            @"FName": self.patient.givenName ?: @"",
            @"LName": self.patient.familyName ?: @"",
            @"BDt": [self formatBirthday:self.patient.birthDate] ?: @"",
            @"Gender": [self.patient.gender isEqual:@"man"] ? @1 : [self.patient.gender isEqual:@"woman"] ? @2 : [NSNull null],
            @"Street": self.patient.postalAddress ?: @"",
            @"Zip": self.patient.zipCode ?: @"",
            @"City": self.patient.city ?: @"",
            @"Lng": [NSLocale systemLocale].localeIdentifier ?: @"",
            @"Phone": self.patient.phoneNumber ?: @"",
            @"Email": self.patient.emailAddress ?: @"",
            @"Rcv": self.patient.insuranceGLN ?: @"",
        },
        @"Medicaments": items,
        @"MedType": @3, // Prescription
        @"Id": [[NSUUID UUID] UUIDString],
        @"Auth": self.doctor.gln ?: @"", // GLN of doctor
        @"Dt": [formatter stringFromDate:[NSDate date]],
    };
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:jsonBody
                                                   options:0
                                                     error:&error];
    NSLog(@"prescription json data %@", [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
    if (error != nil) {
        NSLog(@"json error %@", error);
        return nil;
    }
    NSData *gzipped = [LFCGzipUtility gzipData:json];
    NSData *base64 = [gzipped base64EncodedDataWithOptions:0];
    NSMutableData *prefixed = [NSMutableData dataWithCapacity:base64.length + 9];
    [prefixed appendData:[@"CHMED16A1" dataUsingEncoding:NSUTF8StringEncoding]];
    [prefixed appendData:base64];
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    if (![prefixed writeToFile:tempFilePath options:0 error:&error]) {
        NSLog(@"Cannot write file %@", error);
        return nil;
    }
    return tempFilePath;
}

- (NSString *)formatBirthday:(NSString *)birthday {
    // dd.mm.yyyy -> yyyy-mm-dd
    NSArray *parts = [birthday componentsSeparatedByString:@"."];
    if (parts.count != 3) return nil;
    return [NSString stringWithFormat:@"%@-%@-%@", parts[2], parts[1], parts[0]];
}

- (void )executeCertifactionWithGZippedBase64File:(NSString *)filePath
                                       authHandle:(MLHINADSwissAuthHandle *)authHandle
                                        completion:(void (^_Nonnull)(NSError * _Nullable error, NSString * _Nullable result))callback
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^{
        NSString *tempOutFilePath = [NSString stringWithFormat:
                                         @"%@.png",
                                     [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]
        ];
        NSURL *exePath = [[NSBundle mainBundle] URLForAuxiliaryExecutable:[MLUtilities isAppleSilicon] ? @"certifaction-arm64" : @"certifaction-x86"];
        NSTask *task = [NSTask new];
        [task setEnvironment:@{
            @"ENABLE_EPRESCRIPTION": @"true",
        }];
        [task setLaunchPath:[exePath path]];
        [task setArguments:@[
            @"eprescription",
            @"create",
#if DEBUG
            @"--api", @"https://api.testnet.certifaction.io",
            @"--hin-api", @"https://oauth2.sign-test.hin.ch/api",
#else
            @"--api", @"https://api.certifaction.io",
            @"--hin-api", @"https://oauth2.sign.hin.ch/api",
#endif
            @"--token", authHandle.token,
            @"-o", tempOutFilePath,
            @"-f", @"qrcode",
            filePath,
        ]];
        
        NSPipe *outputPipe = [NSPipe pipe];
        NSPipe *errorPipe = [NSPipe pipe];
        [task setStandardInput:[NSPipe pipe]];
        [task setStandardError:errorPipe];
        [task setStandardOutput:outputPipe];
        
        [task launch];
        [task waitUntilExit]; // Alternatively, make it asynchronous.
        
        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        
        NSLog(@"output str %@", outputString);
        
        NSData *errorData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
        
        NSLog(@"error str %@", errorString);
        
        int exitCode = [task terminationStatus];
        NSLog(@"exit code %d", exitCode);
        
        if (exitCode == 1) {
            NSError *jsonError = nil;
            id errorResponse = [NSJSONSerialization JSONObjectWithData:outputData
                                                               options:0
                                                                 error:&jsonError];
            if (!jsonError && [errorResponse isKindOfClass:[NSDictionary class]]) {
                if ([errorResponse[@"error_code"] isEqualTo:@"unauthorized"]) {
                    callback([NSError errorWithDomain:@"ch.ywesee"
                                                 code:401
                                             userInfo:nil], nil);
                    return;
                }
            }
        }
        callback(nil, tempOutFilePath);
    });
}

@end
