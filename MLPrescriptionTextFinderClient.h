//
//  MLPrescriptionTextFinderClient.h
//  AmiKo
//
//  Created by b123400 on 2020/10/15.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLPrescriptionsAdapter.h"
#import "MLMainWindowController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLPrescriptionTextFinderClient : NSObject<NSTextFinderClient>

- (instancetype)initWithAdapter:(MLPrescriptionsAdapter *)adapter mainWindowController:(MLMainWindowController *)mainWindowController;
- (void)reloadSearchString;

@end

NS_ASSUME_NONNULL_END
