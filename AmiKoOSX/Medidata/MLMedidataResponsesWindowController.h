//
//  MLMedidataResponsesWindowController.h
//  AmiKo
//
//  Created by b123400 on 2021/08/16.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLPatient.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLMedidataResponsesWindowController : NSWindowController

- (instancetype)initWithPatient:(MLPatient *)patient;

@end

NS_ASSUME_NONNULL_END
