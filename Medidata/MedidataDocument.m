//
//  MedidataDocument.m
//  AmiKo
//
//  Created by b123400 on 2021/08/17.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataDocument.h"

@implementation MedidataDocument

- (id)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.transmissionReference = dict[@"transmissionReference"];
        self.documentReference = dict[@"documentReference"];
        self.correlationReference = dict[@"correlationReference"];
        self.senderGln = dict[@"senderGln"];
        self.docType = dict[@"docType"];
        self.fileSize = dict[@"fileSize"];
        self.modus = dict[@"modus"];
        self.status = dict[@"status"];
        
        NSDateFormatter *isoDateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [isoDateFormatter setLocale:enUSPOSIXLocale];
        [isoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        [isoDateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
        self.created = [isoDateFormatter dateFromString:dict[@"created"]];
    }
    return self;
}

@end
