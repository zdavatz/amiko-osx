//
//  MLHealthCard.m
//  AmiKo
//
//  Created by Alex Bettarini on 22 May 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLHealthCard.h"
#import "MLPatient.h"

@implementation MLHealthCard

- (uint8_t) parseTLV:(NSData *)data
{
    //NSLog(@"%s %lu %@", __FUNCTION__, (unsigned long)data.length, data);
    NSString *s;
    uint8_t *bytes = (uint8_t *)[data bytes];
    uint8_t tag = bytes[0];
    uint8_t length = bytes[1];
    NSData* value = [data subdataWithRange:NSMakeRange(2, length)];
    //NSLog(@"T:0x%02x, L:%d, V: %@", tag, length, value);
    switch (tag) {
        case 0x80:  // UTF8InternationalString
        {
            s = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            NSArray *a = [s componentsSeparatedByString:@", "];
            familyName = [a objectAtIndex:0];
            givenName = @"";
            if (a.count > 1)
                givenName = [a objectAtIndex:1];
            //NSLog(@"Name <%@>", a);
        }
            break;
            
        case 0x82:  // NUMERIC STRING
        {
            s = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            NSLog(@"DOB yyyymmdd <%@>", s);
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];

            [dateFormat setDateFormat:@"yyyymmdd"]; // convert from this
            NSDate *dob = [dateFormat dateFromString:s];
            
            [dateFormat setDateFormat:@"dd.mm.yyyy"];   // to this
            birthDate = [dateFormat stringFromDate:dob];
            //NSLog(@"DOB dd.mm.yyyy <%@>", birthDate);
        }
            break;
            
        case 0x83:  // UTF8InternationalString
            s = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            NSLog(@"Card holder ID <%@>", s);
            break;
            
        case 0x84:  // ENUMERATED
        {
            uint8_t sexEnum = *(uint8_t *)[value bytes];
            NSLog(@"Sex %d (1=male, 2=female, 0=not known, 9=not appl.)", sexEnum);
            if (sexEnum == 1)
                gender = @"man";
            else if (sexEnum == 2)
                gender = @"woman";
            else
                gender = @"";
        }
            break;
            
        case 0x90: // UTF8InternationalString
            s = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            NSLog(@"Issuing State ID Number <%@>", s);
            break;
            
        case 0x91: // UTF8InternationalString
            s = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            NSLog(@"name Of The Institution <%@>", s);
            break;
            
        case 0x92:  // NUMERIC STRING
            s = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            NSLog(@"identificationNumber Of The Institution <%@>", s);
            break;
            
        case 0x93: // UTF8InternationalString
            s = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            NSLog(@"Insured Person Number <%@>", s);
            break;
            
        case 0x94:  // NUMERIC STRING
            s = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            NSLog(@"ExpiryDate yyyymmdd <%@>", s);
            break;
            
        default:
            NSLog(@"T:0x%02x, L:%d, V: <%@>", tag, length, value);
            break;
    }
    return length+2;
}

- (void) parseCardData:(NSData *)data
{
    NSRange dataRange;
    uint8_t offset = 0;
    
    //NSLog(@"%s %lu %@", __FUNCTION__, (unsigned long)data.length, data);
    uint8_t *bytes = (uint8_t *)[data bytes];
    uint8_t packetType = bytes[0];
    uint8_t packetSize = bytes[1];
    NSData* payload = [data subdataWithRange:NSMakeRange(2, packetSize)];
    //NSLog(@"=== payload:%@", payload);
    switch (packetType) {
        case 0x65:
            while (offset < packetSize) {
                dataRange = NSMakeRange(offset, packetSize-offset);
                offset += [self parseTLV:[payload subdataWithRange:dataRange]];
                //NSLog(@"line %d, offset:0x%02x=%d", __LINE__, offset, offset);
            }
            break;
            
        default:
            break;
    }
}

- (void) processValidCard: (TKSmartCard *) sc
{
    //NSLog(@"%s", __FUNCTION__);

    uint8_t ef_id[] = {0x2f, 0x06};
    NSData *filePath = [NSData dataWithBytes:ef_id length:sizeof ef_id];
    [self scSelectFile:sc byPath:filePath];
    
    [sc sendIns:INS_READ_BIN // READ BINARY
             p1:0
             p2:0
           data:nil
             le:[NSNumber numberWithInt:84] // what we expect *back*
          reply:^(NSData *replyData, UInt16 sw, NSError *error2) {
              if (error2)
                  NSLog(@"Line %d READ_BIN, %@", __LINE__, error2);
              
              assert(!error2);
//            NSLog(@"SW:      %02x/%02x", sw >> 8, sw & 0xFF);
//            NSLog(@"Serial:  %@", replyData);
              [self parseCardData:replyData];
          }
     ];

    [NSThread sleepForTimeInterval:0.5f];

    uint8_t ef_ad[] = {0x2f, 0x07};
    filePath = [NSData dataWithBytes:ef_ad length:sizeof ef_ad];
    [self scSelectFile:sc byPath:filePath];
    
    [sc sendIns:INS_READ_BIN // READ BINARY
             p1:0
             p2:0
           data:nil
             le:[NSNumber numberWithInt:95] // what we expect *back*
          reply:^(NSData *replyData, UInt16 sw, NSError *error2) {
              if (error2)
                  NSLog(@"Line %d READ_BIN, %@", __LINE__, error2);

              assert(!error2);
//            NSLog(@"SW:      %02x/%02x", sw >> 8, sw & 0xFF);
//            NSLog(@"Serial:  %@", replyData);
              [self parseCardData:replyData];
              
              NSDictionary *patientDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        familyName, KEY_AMK_PAT_SURNAME,
                                        givenName,  KEY_AMK_PAT_NAME,
                                        birthDate,  KEY_AMK_PAT_BIRTHDATE,
                                        gender,     KEY_AMK_PAT_GENDER,
                                        nil];
              
              [[NSNotificationCenter defaultCenter] postNotificationName:@"smartCardDataAcquired"
                                                                  object:patientDict];
          }
     ];
}

@end
