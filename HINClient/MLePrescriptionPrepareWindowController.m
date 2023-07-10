//
//  MLePrescriptionPrepareWindowController.m
//  AmiKo
//
//  Created by b123400 on 2023/07/10.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLePrescriptionPrepareWindowController.h"
#import "MLPersistenceManager.h"
#import "MLADSwissSAMLWindowController.h"
#import "MLPrescriptionItem.h"
#import "LFCGzipUtility.h"

@interface MLePrescriptionPrepareWindowController ()

@property (nonatomic, strong) MLPatient *patient;
@property (nonatomic, strong) MLOperator *doctor;
@property (nonatomic, strong) NSArray<MLPrescriptionItem*> *items;

@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;
@property (weak) IBOutlet NSTextField *statusLabel;

@property (nonatomic, strong, nullable) MLADSwissSAMLWindowController *samlWindowController;

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

- (void)startFlow {
    typeof(self) __weak _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadingIndicator startAnimation:self];
    });
    [self displayStatus:NSLocalizedString(@"Loading SAML", @"")];
    [self prepareSAMLIfNeeded:^(NSError * _Nullable error, NSString *authHandle) {
        if (error) {
            [_self displayError:error];
            self.outError = error;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self.window.sheetParent endSheet:_self.window
                                        returnCode:NSModalResponseCancel];
            });
            return;
        }
        if (!authHandle) {
            // No error but no auth handle = user cancelled;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self.window.sheetParent endSheet:_self.window
                                        returnCode:NSModalResponseCancel];
            });
            return;
        }
        [self displayStatus:NSLocalizedString(@"Preparing prescription file", @"")];
        NSString *prescriptionFile = [self preparePrescriptionFile];
        [self displayStatus:NSLocalizedString(@"Preparing QR Code", @"")];
        [self executeCertifactionWithGZippedBase64File:prescriptionFile
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
    }];
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

- (void)prepareSAMLIfNeeded:(void (^_Nonnull)(NSError * _Nullable error, NSString *authHandle))callback {
    NSString *authHandle = [[MLPersistenceManager shared] HINADSwissAuthHandle];
    if (authHandle) {
        callback(nil, authHandle);
        return;
    }
    typeof(self) __weak _self = self;
    MLADSwissSAMLWindowController *samlWindowController = [[MLADSwissSAMLWindowController alloc] init];
    self.samlWindowController = samlWindowController;
    [self.window beginSheet:samlWindowController.window
           completionHandler:^(NSModalResponse returnCode) {
        _self.samlWindowController = nil;
        if (returnCode == NSModalResponseOK) {
            callback(nil, [[MLPersistenceManager shared] HINADSwissAuthHandle]);
        } else {
            callback(nil, nil);
        }
    }];
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
                                        completion:(void (^_Nonnull)(NSError * _Nullable error, NSString * _Nullable result))callback
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^{
        NSString *authHandle = [[MLPersistenceManager shared] HINADSwissAuthHandle];
        NSString *tempOutFilePath = [NSString stringWithFormat:
                                         @"%@.png",
                                     [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]
        ];
        NSURL *exePath = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"certifaction-arm64"];
        NSTask *task = [NSTask new];
        [task setEnvironment:@{
            @"ENABLE_EPRESCRIPTION": @"true",
        }];
        [task setLaunchPath:[exePath path]];
        [task setArguments:@[
            @"eprescription",
            @"create",
            @"--api", @"https://api.testnet.certifaction.io",
            @"--hin-api", @"https://oauth2.sign-test.hin.ch/api",
            @"--token", authHandle,
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
