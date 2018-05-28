//
//  MLSmartCard.h
//  AmiKo
//
//  Created by Alex Bettarini on 22 May 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CryptoTokenKit/CryptoTokenKit.h>

#define INS_ERASE_BIN      0x0E
#define INS_VRFY           0x20
#define INS_MANAGE_CHANNEL 0x70
#define INS_EXT_AUTH       0x82
#define INS_GET_CHALLENGE  0x84
#define INS_SELECT_FILE    0xA4
#define INS_READ_BIN       0xB0
#define INS_READ_REC       0xB2
#define INS_GET_RESP       0xC0
#define INS_ENVELOPE       0xC2
#define INS_GET_DATA       0xCA
#define INS_WRITE_BIN      0xD0
#define INS_WRITE_REC      0xD2
#define INS_UPDATE_BIN     0xD6
#define INS_PUT_DATA       0xDA
#define INS_UPDATE_REC     0xDC
#define INS_APPEND_REC     0xE2
/* for our transaction tracking, not defined in the specification */
#define INS_INVALID        0x00

@interface MLSmartCard : NSObject

@property (nonatomic, retain) TKSmartCardSlotManager * mngr;
@property (nonatomic, retain) NSMutableArray *slots;
@property (nonatomic, retain) NSMutableArray *cards;

- (void) parseCardData:(NSData *)data;
- (void) processValidCard: (TKSmartCard *) sc;
- (BOOL) validAtr: (TKSmartCardATR *) atr;

- (void) scSelectMF:(TKSmartCard *)card;
- (void) scSelectFile:(TKSmartCard *)card byPath:(NSData *)filePath;
- (NSData *) scReadBinary:(TKSmartCard *)card :(int)size;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context;
-(NSString *)stateString:(TKSmartCardSlotState)state;

@end
