//
//  MedidataXMLGenerator.h
//  AmiKo
//
//  Created by b123400 on 2021/07/02.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLOperator.h"
#import "MLPatient.h"
#import "MLPrescriptionItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface MedidataXMLGenerator : NSObject

+ (NSXMLDocument *)xmlInvoiceRequestDocumentWithOperator:(MLOperator *)operator
                                                 patient:(MLPatient *)patient
                                       prescriptionItems:(NSArray<MLPrescriptionItem*> *)items;

@end

NS_ASSUME_NONNULL_END
