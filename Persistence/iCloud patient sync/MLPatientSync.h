//
//  MLPatientSync.h
//  AmiKo
//
//  Created by b123400 on 2020/09/19.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLPersistenceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLPatientSync : NSObject

- (instancetype)initWithPersistenceManager:(MLPersistenceManager*)manager;

- (void)generatePatientFilesForICloud: (void (^ _Nullable)(bool success))callback;
- (void)generatePatientFile: (MLPatient*)patient forICloud: (void (^ _Nullable)(bool success))callback;
- (void)deletePatientFileForICloud: (MLPatient*)patient;

@end

NS_ASSUME_NONNULL_END
