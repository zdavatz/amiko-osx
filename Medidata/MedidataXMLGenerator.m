//
//  MedidataXMLGenerator.m
//  AmiKo
//
//  Created by b123400 on 2021/07/02.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataXMLGenerator.h"

@implementation MedidataXMLGenerator

+ (NSDateFormatter *)isoDateFormatter {
    NSDateFormatter *isoDateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [isoDateFormatter setLocale:enUSPOSIXLocale];
    [isoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    [isoDateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
    return isoDateFormatter;
}

+ (NSXMLElement *)xmlInvoicePersonWithOperator:(MLOperator *)operator {
//      <invoice:person title="Dr. med.">
//        <invoice:familyname>Hello</invoice:familyname>
//        <invoice:givenname>World</invoice:givenname>
//        <invoice:postal>
//          <invoice:street>XXXXX</invoice:street>
//          <invoice:zip>12345</invoice:zip>
//          <invoice:city>XXXXX</invoice:city>
//        </invoice:postal>
//      </invoice:person>
    NSXMLElement *person = [NSXMLElement elementWithName:@"invoice:person"];
    if (operator.title) {
        [person setAttributesWithDictionary:@{
            @"title": operator.title,
        }];
    }
    
    NSXMLElement *familyName = [NSXMLElement elementWithName:@"invoice:familyname"];
    [person addChild:familyName];
    [familyName setStringValue:operator.familyName];
    
    NSXMLElement *givenName = [NSXMLElement elementWithName:@"invoice:givenname"];
    [person addChild:givenName];
    [givenName setStringValue:operator.givenName];
    
    NSXMLElement *postal = [NSXMLElement elementWithName:@"invoice:postal"];
    [person addChild:postal];
    
    NSXMLElement *street = [NSXMLElement elementWithName:@"invoice:street"];
    [postal addChild:street];
    [street setStringValue:operator.postalAddress];
    
    NSXMLElement *zip = [NSXMLElement elementWithName:@"invoice:zip"];
    [postal addChild:zip];
    [zip setStringValue:operator.zipCode];
    
    NSXMLElement *city = [NSXMLElement elementWithName:@"invoice:city"];
    [postal addChild:city];
    [city setStringValue:operator.city];
    
    return person;
}

+ (NSXMLElement *)xmlInvoiceBillerWithOperator:(MLOperator *)operator {
//    <invoice:biller ean_party="2099988876514" zsr="U666666">
//    ...
//    </invoice:biller>
    NSXMLElement *root = [NSXMLElement elementWithName:@"invoice:biller"];
    [root setAttributesWithDictionary:@{
        @"ean_party": operator.gln ?: @"",
        @"zsr": @"U666666",
    }];
    [root addChild:[MedidataXMLGenerator xmlInvoicePersonWithOperator:operator]];
    return root;
}

+ (NSXMLElement *)xmlInvoiceProviderWithOperator:(MLOperator *)operator {
//    <invoice:biller ean_party="2099988876514" zsr="U666666">
//    ...
//    </invoice:biller>
    NSXMLElement *root = [NSXMLElement elementWithName:@"invoice:provider"];
    [root setAttributesWithDictionary:@{
        @"ean_party": operator.gln ?: @"",
        @"zsr": @"U666666",
    }];
    [root addChild:[MedidataXMLGenerator xmlInvoicePersonWithOperator:operator]];
    return root;
}

+ (NSXMLElement *)xmlInvoicePersonWithPatient:(MLPatient *)patient {
//  <invoice:person salutation="Herr">
//    <invoice:familyname>XXXX</invoice:familyname>
//    <invoice:givenname>XXXXX</invoice:givenname>
//    <invoice:postal>
//      <invoice:street>XXXXX</invoice:street>
//      <invoice:zip>1234</invoice:zip>
//      <invoice:city>AAAA</invoice:city>
//    </invoice:postal>
//    <invoice:telecom>
//      <invoice:phone>1234567</invoice:phone>
//    </invoice:telecom>
//    <invoice:online>
//      <invoice:email>a@b.com</invoice:email>
//    </invoice:online>
//  </invoice:person>
    NSXMLElement *person = [NSXMLElement elementWithName:@"invoice:person"];
    [person setAttributesWithDictionary:@{
        @"salutation": [patient.gender isEqualToString:@"man"] ? @"Herr" : @"Dame"
    }];
    
    NSXMLElement *familyName = [NSXMLElement elementWithName:@"invoice:familyname"];
    [person addChild:familyName];
    [familyName setStringValue:patient.familyName];
    
    NSXMLElement *givenName = [NSXMLElement elementWithName:@"invoice:givenname"];
    [person addChild:givenName];
    [givenName setStringValue:patient.givenName];
    
    NSXMLElement *postal = [NSXMLElement elementWithName:@"invoice:postal"];
    [person addChild:postal];
    
    NSXMLElement *street = [NSXMLElement elementWithName:@"invoice:street"];
    [postal addChild:street];
    [street setStringValue:patient.postalAddress];
    
    NSXMLElement *zip = [NSXMLElement elementWithName:@"invoice:zip"];
    [postal addChild:zip];
    [zip setStringValue:patient.zipCode];
    
    NSXMLElement *city = [NSXMLElement elementWithName:@"invoice:city"];
    [postal addChild:city];
    [city setStringValue:patient.city];
    
    NSXMLElement *telecom = [NSXMLElement elementWithName:@"invoice:telecom"];
    [person addChild:telecom];
    NSXMLElement *phone = [NSXMLElement elementWithName:@"invoice:phone"];
    [telecom addChild:phone];
    [phone setStringValue:patient.phoneNumber];
    
    NSXMLElement *online = [NSXMLElement elementWithName:@"invoice:online"];
    [person addChild:online];
    NSXMLElement *email = [NSXMLElement elementWithName:@"invoice:email"];
    [online addChild:email];
    [email setStringValue:patient.emailAddress];
    
    return person;
}

+ (NSXMLElement *)xmlInvoicePatientWithPatient:(MLPatient *)patient {
//  <invoice:patient gender="male" birthdate="1986-04-22T00:00:00" ssn="7566813511452">
//      ...
//      <invoice:card card_id="80756000080064720646" expiry_date="2022-05-31T00:00:00"/>
//  </invoice:patient>
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd.MM.yyyy"];
    NSDate *birthdate = [dateFormat dateFromString:patient.birthDate];
    
    NSDateFormatter *isoDateFormatter = [MedidataXMLGenerator isoDateFormatter];

    NSXMLElement *patientElement = [NSXMLElement elementWithName:@"invoice:patient"];
    [patientElement setAttributesWithDictionary:@{
        @"gender": [patient.gender isEqualToString:@"man"] ? @"male" : @"female",
        @"birthdate": [isoDateFormatter stringFromDate:birthdate] ?: @"",
//        @"ssn": @"TODO",
    }];
    
    [patientElement addChild:[MedidataXMLGenerator xmlInvoicePersonWithPatient:patient]];
    
    NSXMLElement *card = [NSXMLElement elementWithName:@"invoice:card"];
    [patientElement addChild:card];
    [card setAttributesWithDictionary:@{
        @"card_id": patient.healthCardNumber ?: @"",
        @"expiry_date": patient.healthCardExpiry ? [isoDateFormatter stringFromDate:[dateFormat dateFromString:patient.healthCardExpiry]] : @"",
    }];
    
    return patientElement;
}

+ (NSXMLElement *)xmlInvoiceInsuranceWithPatient:(MLPatient *)patient {
    NSDictionary *participantsKvg = [patient findParticipantsKvg];
    NSXMLElement *insurance = [NSXMLElement elementWithName:@"invoice:insurance"];
    [insurance setAttributesWithDictionary:@{
        @"ean_party": participantsKvg[@"glnParticipant"],
    }];
    NSXMLElement *company = [NSXMLElement elementWithName:@"company"];
    [insurance addChild:company];
    
    NSXMLElement *companyName = [NSXMLElement elementWithName:@"invoice:companyname"];
    [company addChild:companyName];
    [companyName setStringValue:participantsKvg[@"name"]];
    
    NSXMLElement *postal = [NSXMLElement elementWithName:@"invoice:postal"];
    [company addChild:postal];
    
    if (participantsKvg[@"street"]) {
        NSXMLElement *street = [NSXMLElement elementWithName:@"invoice:street"];
        [postal addChild:street];
        [street setStringValue:participantsKvg[@"street"]];
    }
    
    NSXMLElement *zip = [NSXMLElement elementWithName:@"invoice:zip"];
    [postal addChild:zip];
    [zip setStringValue:participantsKvg[@"zipCode"]];
    
    NSXMLElement *city = [NSXMLElement elementWithName:@"invoice:city"];
    [postal addChild:city];
    [city setStringValue:participantsKvg[@"town"]];

    return insurance;
//    <invoice:insurance ean_party="7601003001082">
//      <invoice:company>
//        <invoice:companyname>CSS (KVG)</invoice:companyname>
//        <invoice:postal>
//          <invoice:street>Tribschenstrasse 21</invoice:street>
//          <invoice:zip>6002</invoice:zip>
//          <invoice:city>Luzern</invoice:city>
//        </invoice:postal>
//      </invoice:company>
//    </invoice:insurance>
}

+ (NSXMLElement *)xmlInvoiceGuarantorWithPatient:(MLPatient *)patient {
    // TODO
    NSXMLElement *guarantor = [NSXMLElement elementWithName:@"invoice:guarantor"];
    [guarantor addChild:[MedidataXMLGenerator xmlInvoicePersonWithPatient:patient]];
    return guarantor;
}

+ (NSXMLElement *)xmlInvoiceRecordDrugWithOperator:(MLOperator *)operator index:(NSNumber *)number prescriptionItem:(MLPrescriptionItem *)item {
    NSXMLElement *drug = [NSXMLElement elementWithName:@"invoice:record_drug"];
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *price = [f numberFromString:[[item price] stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]]];
//    <invoice:record_drug record_id="1" tariff_type="402" code="7680300580117" session="1" quantity="1" date_begin="2021-06-22T00:00:00" provider_id="2099988876514" responsible_id="2099988876514" unit="8.2" unit_factor="1" amount="8.20" validate="1" service_attributes="0" obligation="1" name="MAXIDEX Gtt Opht 5 ml"/>
    [drug setAttributesWithDictionary:@{
        @"record_id": [@([number intValue] + 1) stringValue],
        @"tariff_type": @"402",
        @"code": item.eanCode ?: @"",
        @"quantity": @"1",
        @"date_begin": [[MedidataXMLGenerator isoDateFormatter] stringFromDate:[NSDate date]],
        @"provider_id": operator.gln,
        @"responsible_id": operator.gln,
        @"unit": [f stringFromNumber:price] ?: @"0",
        @"amount": [f stringFromNumber:price] ?: @"0",
        @"name": item.title ?: @"",
    }];
    return drug;
}

+ (NSXMLElement *)xmlInvoiceRequestWithOperator:(MLOperator *)operator
                                        patient:(MLPatient *)patient
                              prescriptionItems:(NSArray<MLPrescriptionItem*> *)items
{
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
    
    NSXMLElement *root = [NSXMLElement elementWithName:@"invoice:request"];
    [root setAttributesWithDictionary:@{
        @"xmlns:xsi": @"http://www.w3.org/2001/XMLSchema-instance",
        @"xmlns:xenc": @"http://www.w3.org/2001/04/xmlenc#",
        @"xmlns:ds": @"http://www.w3.org/2000/09/xmldsig#",
        @"xmlns:invoice": @"http://www.forum-datenaustausch.ch/invoice",
        @"xmlns": @"http://www.forum-datenaustausch.ch/invoice",
        @"xsi:schemaLocation": @"http://www.forum-datenaustausch.ch/invoice generalInvoiceRequest_440.xsd",
        @"language": @"de",
        @"modus": @"production",
        @"validation_status": @"0",
    }];
    
    NSXMLElement *processing = [NSXMLElement elementWithName:@"invoice:processing"];
    [root addChild:processing];
    NSXMLElement *transport = [NSXMLElement elementWithName:@"invoice:transport"];
    [processing addChild:transport];
    [transport setAttributesWithDictionary:@{
        @"from": operator.gln,
        @"to": [patient findParticipantsKvg][@"glnParticipant"] ?: @"",
    }];
    NSXMLElement *via = [NSXMLElement elementWithName:@"invoice:via"];
    [transport addChild:via];
    [via setAttributesWithDictionary:@{
        @"via": @"7601001304307",
        @"sequence_id": @"1",
    }];

    NSXMLElement *payload = [NSXMLElement elementWithName:@"invoice:payload"];
    [root addChild:payload];
    [payload setAttributesWithDictionary:@{
        @"type": @"invoice",
        @"copy": @"0",
        @"storno": @"0",
    }];
    
    NSXMLElement *invoice = [NSXMLElement elementWithName:@"invoice:invoice"];
    [payload addChild:invoice];
    [invoice setAttributesWithDictionary:@{
        @"request_timestamp": [@([@([now timeIntervalSince1970]) integerValue]) stringValue],
        @"request_date": [dateFormatter stringFromDate:now],
        @"request_id": [[[NSUUID UUID] UUIDString] substringToIndex:30],
    }];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"invoice:body"];

    NSXMLElement *prolog = [NSXMLElement elementWithName:@"invoice:prolog"];
    [body addChild:prolog];
    
    NSXMLElement *package = [NSXMLElement elementWithName:@"invoice:package"];
    [prolog addChild:package];
    [package setAttributesWithDictionary:@{
        @"name": @"Ywesee",
        @"copyright": @"(c) 2021 Ywesee GmbH",
        @"version": @"2021",
    }];
    
    NSXMLElement *generator = [NSXMLElement elementWithName:@"invoice:generator"];
    [prolog addChild:generator];
    [generator setAttributesWithDictionary:@{
        @"name": @"AmiKo",
        @"copyright": @"(c) 2021 Ywesee GmbH",
        @"version": [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] stringByReplacingOccurrencesOfString:@"." withString:@""],
    }];
    
    [payload addChild:body];
    [body setAttributesWithDictionary:@{
        @"role": @"physician",
        @"place": @"practice",
    }];
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *total = @0; // [f numberFromString:[[item price] stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]]];
    for (MLPrescriptionItem *item in items) {
        total = [[NSDecimalNumber decimalNumberWithDecimal:[[f numberFromString:[[item price] stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]]] decimalValue]] decimalNumberByAdding:[NSDecimalNumber decimalNumberWithDecimal:total.decimalValue]];
    }
    
    NSXMLElement *balance = [NSXMLElement elementWithName:@"invoice:balance"];
    [body addChild:balance];
    [balance setAttributesWithDictionary:@{
        @"currency": @"CHF",
        @"amount": [f stringFromNumber:total] ?: @"0",
        @"amount_due": [f stringFromNumber:total] ?: @"0",
    }];
    
    NSXMLElement *vat = [NSXMLElement elementWithName:@"invoice:vat"];
    [balance addChild:vat];
    [vat setAttributesWithDictionary:@{
        @"vat": @"0"
    }];
    NSXMLElement *vatRate = [NSXMLElement elementWithName:@"invoice:vat_rate"];
    [vat addChild:vatRate];
    [vatRate setAttributesWithDictionary:@{
        @"vat": @"0.0",
        @"vat_rate": @"0",
        @"amount": @"0.0",
    }];
    
    // TODO: I have no idea what is this
    NSXMLElement *esr9 = [NSXMLElement elementWithName:@"invoice:esr9"];
    [body addChild:esr9];
    [esr9 setAttributesWithDictionary:@{
        @"participant_number": @"01-123-6",
        @"reference_number": @"12 34560 00000 00000 00015 85733",
        @"coding_line": @"0100000056306>123456000000000000001585733+ 010001456>"
    }];
    
    NSXMLElement *tiersPayment = [NSXMLElement elementWithName:@"invoice:tiers_payant"];
    [body addChild:tiersPayment];
    [tiersPayment addChild:[MedidataXMLGenerator xmlInvoiceBillerWithOperator:operator]];
    [tiersPayment addChild:[MedidataXMLGenerator xmlInvoiceProviderWithOperator:operator]];
    [tiersPayment addChild:[MedidataXMLGenerator xmlInvoiceInsuranceWithPatient:patient]];
    [tiersPayment addChild:[MedidataXMLGenerator xmlInvoicePatientWithPatient:patient]];
    [tiersPayment addChild:[MedidataXMLGenerator xmlInvoiceGuarantorWithPatient:patient]];
    
    // TODO:
    NSXMLElement *kvg = [NSXMLElement elementWithName:@"invoice:kvg"];
    [kvg setAttributesWithDictionary:@{
        @"insured_id": @"209-17-965",
    }];
    [body addChild:kvg];
    
    NSXMLElement *treatment = [NSXMLElement elementWithName:@"invoice:treatment"];
    [body addChild:treatment];
    [treatment setAttributesWithDictionary:@{
        @"date_begin": [dateFormatter stringFromDate:now], // TODO
        @"date_end": [dateFormatter stringFromDate:now],
        @"canton": @"AR",
        @"reason": @"disease",
    }];
    
    NSXMLElement *services = [NSXMLElement elementWithName:@"invoice:services"];
    [body addChild:services];
    
    for (NSInteger i = 0; i < items.count; i++) {
        [services addChild:[MedidataXMLGenerator xmlInvoiceRecordDrugWithOperator:operator index:@(i) prescriptionItem:items[i]]];
    }

    return root;
}

+ (NSXMLDocument *)xmlInvoiceRequestDocumentWithOperator:(MLOperator *)operator
                                                 patient:(MLPatient *)patient
                                       prescriptionItems:(NSArray<MLPrescriptionItem*> *)items {
    NSXMLElement *root = [MedidataXMLGenerator xmlInvoiceRequestWithOperator:operator
                                                                     patient:patient
                                                           prescriptionItems:items];
    NSXMLDocument *document = [NSXMLDocument documentWithRootElement:root];
    [document setVersion:@"1.0"];
    [document setStandalone:NO];
    return document;
}


@end
