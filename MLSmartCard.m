//
//  MLSmartCard.m
//  AmiKo
//
//  Created by Alex Bettarini on 22 May 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLSmartCard.h"

@implementation MLSmartCard

@synthesize slots, cards;

- (instancetype)init
{
    if (self = [super init]) {
        self.mngr = [TKSmartCardSlotManager defaultManager];
        assert(self.mngr);
        
        // Observe readers joining and leaving.
        [self.mngr addObserver:self
                    forKeyPath:@"slotNames"
                       options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial
                       context:nil];
        
        return self;
    }

    return nil;
}

- (void)dealloc
{
    [self.mngr removeObserver:self forKeyPath:@"slotNames"];
    
    for(id slot in self.slots)
        [slot removeObserver:self];
    
    for(id card in self.cards)
        [card removeObserver:self];
}

- (void) parseCardData:(NSData *)data
{
    NSLog(@"%s", __FUNCTION__);
}

- (void) processValidCard: (TKSmartCard *) sc
{
    NSLog(@"%s", __FUNCTION__);
}

- (BOOL) validAtr: (TKSmartCardATR *) atr
{
    NSLog(@"%s", __FUNCTION__);
    return true;
}

#pragma mark - ISO 7816 commands

- (void) scSelectMF:(TKSmartCard *)card
{
    UInt16 sw;
    NSError *error;
    
    uint8_t aid[] = {0x3f, 0x00};
    NSData *data = [NSData dataWithBytes:aid length:sizeof aid];
    NSData *response = [card sendIns:INS_SELECT_FILE
                                  p1:0x00 // Select MF, DF or EF
                                  p2:0x00
                                data:data
                                  le:nil
                                  sw:&sw
                               error:&error];
    if (!response)
        NSLog(@"sendIns error: %@", error);
    
#ifdef DEBUG
    NSLog(@"line %d SELECT_FILE 0x%02x%02x, response: %@, SW:0x%04X", __LINE__,
          aid[0], aid[1],
          response, sw);
#endif
}

- (void) scSelectFile:(TKSmartCard *)card byPath:(NSData *)filePath
{
    UInt16 sw;
    NSError *error;
    
    NSData *response = [card sendIns:INS_SELECT_FILE
                                  p1:0x08   // Selection by path from MF
                                  p2:0x00
                                data:filePath
                                  le:nil
                                  sw:&sw
                               error:&error];
    if (!response)
        NSLog(@"sendIns error: %@", error);
    
#ifdef DEBUG
    NSLog(@"line %d SELECT_FILE %@, response: %@, SW:0x%04X", __LINE__, filePath, response, sw);
#endif
}

- (NSData *) scReadBinary:(TKSmartCard *)card :(int) size
{
    __block NSData *response = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [card sendIns:INS_READ_BIN
               p1:0
               p2:0
             data:nil
               le:[NSNumber numberWithInt:size] // what we expect *back*
            reply:^(NSData *replyData, UInt16 sw, NSError *error2) {
                if (error2)
                    NSLog(@"Line %d READ_BIN, %@", __LINE__, error2);
                
                assert(!error2);
//              NSLog(@"SW:      %02x/%02x", sw >> 8, sw & 0xFF);
//              NSLog(@"Serial:  %@", replyData);
                [self parseCardData:replyData];
                
                dispatch_semaphore_signal(sem); // signals end of block
            }
     ];
    
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
    dispatch_semaphore_wait(sem, timeout);
    
    return response;
}

#pragma mark - Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    //NSLog(@"%s keyPath <%@>, change dictionary %@", __FUNCTION__, keyPath, change);
    NSLog(@"%s keyPath <%@>", __FUNCTION__, keyPath);

    if ([keyPath isEqualToString:@"slotNames"])
    {
#ifdef DEBUG
        NSLog(@"(Re)Scanning Slots: %@", [self.mngr slotNames]);
#endif
        
        // Purge any old observing and rebuild the array.
        for (id slot in self.slots)
            [slot removeObserver:self forKeyPath:@"state"];
        
        for (id card in self.cards)
            [card removeObserver:self forKeyPath:@"valid"];
        
        self.slots = [[NSMutableArray alloc] init];
        self.cards = [[NSMutableArray alloc] init];
        
        for (NSString *slotName in [self.mngr slotNames])
        {
            [self.mngr getSlotWithName:slotName reply:^(TKSmartCardSlot *slot) {
                [self.slots addObject:slot];
                
                [slot addObserver:self
                       forKeyPath:@"state"
                          options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial
                          context:nil];

#ifdef DEBUG
                NSLog(@"Slot:    %@",slot);
                NSLog(@"  name:  %@",slot.name);
                NSLog(@"  state: %@",[self stateString:slot.state]);
#endif
            }];
        };
    }  // end of Slot change
    else if ([keyPath isEqualToString:@"state"]) {
        TKSmartCardSlot *slot = object;
        NSLog(@"  state: %@ for %@", [self stateString:slot.state], slot);
        
        if (slot.state == TKSmartCardSlotStateValidCard)
        {
            TKSmartCardATRInterfaceGroup * iface = [slot.ATR interfaceGroupForProtocol:TKSmartCardProtocolT1];
#ifdef DEBUG
            NSLog(@"  atr:   %@", slot.ATR);
            NSLog(@"  atr bytes:   %@", slot.ATR.bytes);
            NSLog(@"Iface for T1: %@", iface);
#endif
            if (![self validAtr:slot.ATR]) {  // handled by subclass
                // TODO: find a clean way of aborting processing for this card
                return;
            }
            
            TKSmartCard * sc = [slot makeSmartCard];
            [self.cards addObject:sc];
            
            [sc addObserver:self
                 forKeyPath:@"valid"
                    options:NSKeyValueObservingOptionNew |
                            NSKeyValueObservingOptionOld |
                            NSKeyValueObservingOptionInitial
                    context:nil];
            
#ifdef DEBUG
            NSLog(@"Card: %@", sc);
            NSLog(@"Allowed protocol bitmask: %lx", sc.allowedProtocols);
            
            if (sc.allowedProtocols & TKSmartCardProtocolT0)
                NSLog(@"        T0");
            if (sc.allowedProtocols & TKSmartCardProtocolT1)
                NSLog(@"        T1");
            if (sc.allowedProtocols & TKSmartCardProtocolT15)
                NSLog(@"        T15");
#endif
        }
    }
    else if ([keyPath isEqualToString:@"valid"]) {
        TKSmartCard * sc = object;
        
        if (sc.valid) {
            [sc beginSessionWithReply:^(BOOL success, NSError *error) {
#ifdef DEBUG
                NSLog(@"Card in slot <%@>",sc.slot.name);
                NSLog(@"   now in session, selected protocol: %lx", sc.currentProtocol);
#endif
                assert(sc.currentProtocol != TKSmartCardProtocolNone);
                [self processValidCard:sc];  // handled by subclass
                [sc endSession];
            }];
        }
    } // end of TKSmartCard sc valid change
    else {
        NSLog(@"Ignored...");
    }
}

-(NSString *)stateString:(TKSmartCardSlotState)state
{
    switch (state) {
        case TKSmartCardSlotStateEmpty:
            return @"TKSmartCardSlotStateEmpty";
            break;
        case TKSmartCardSlotStateMissing:
            return @"TKSmartCardSlotStateMissing";
            break;
        case TKSmartCardSlotStateMuteCard:
            return @"TKSmartCardSlotStateMuteCard";
            break;
        case TKSmartCardSlotStateProbing:
            return @"TKSmartCardSlotStateProbing";
            break;
        case TKSmartCardSlotStateValidCard:
            return @"TKSmartCardSlotStateValidCard";
            break;
        default:
            return @"error";
            break;
    }
    return @"bug";
}

@end
