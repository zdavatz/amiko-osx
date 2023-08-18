//
//  MLPreferencesWindowController.h
//  AmiKo
//
//  Created by b123400 on 2020/04/08.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLPreferencesWindowController : NSWindowController

+ (instancetype)shared;

- (void)handleOAuthCallbackWithCode:(NSString *)code state:(NSString *)state;

@end

NS_ASSUME_NONNULL_END
