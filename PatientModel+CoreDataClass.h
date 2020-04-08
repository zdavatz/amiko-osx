//
//  PatientModel+CoreDataClass.h
//  AmiKo
//
//  Created by b123400 on 2020/04/05.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MLPatient.h"

NS_ASSUME_NONNULL_BEGIN

@interface PatientModel : NSManagedObject

- (void)importFromPatient:(MLPatient *)p timestamp:(NSDate *)timestamp;
- (MLPatient *)toPatient;

@end

NS_ASSUME_NONNULL_END

#import "PatientModel+CoreDataProperties.h"
