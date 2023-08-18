//
//  MLePrescriptionPrepareWindowController.h
//  AmiKo
//
//  Created by b123400 on 2023/07/10.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLPatient.h"
#import "MLOperator.h"
#import "MLPrescriptionItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLePrescriptionPrepareWindowController : NSWindowController

+ (BOOL)applicable;

+ (BOOL)canPrintWithoutAuth;

- (instancetype)initWithPatient:(MLPatient *)patient
                          doctor:(MLOperator *)doctor
                           items:(NSArray<MLPrescriptionItem*> *)items;

- (void)handleOAuthCallbackWithAuthCode:(NSString *)code;

@property (nonatomic, strong, nullable) NSImage *outQRCode;

@end

NS_ASSUME_NONNULL_END
