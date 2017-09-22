/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 21/07/2017.
 
 This file is part of AmiKo for OSX.
 
 AmiKo for OSX is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLPrescriptionsCart.h"

#import "MLInteractionsCart.h"
#import "MLUtilities.h"

@implementation MLPrescriptionsCart
{
    MLInteractionsAdapter *interactionsAdapter;
    MLInteractionsCart *interactionsCart;
}

@synthesize cart;
@synthesize cartId;
@synthesize interactions;
@synthesize uniqueHash;

- (id) init
{
    // Creates and returns a new UUID with RFC 4122 version 4 random bytes
    uniqueHash = [[NSUUID UUID] UUIDString];
    interactionsCart = [[MLInteractionsCart alloc] init];
    return [super init];
}

- (void) makeNewUniqueHash
{
    // Creates and returns a new UUID with RFC 4122 version 4 random bytes
    uniqueHash = [[NSUUID UUID] UUIDString];
}

- (void) setInteractionsAdapter:(MLInteractionsAdapter *)adapter
{
    interactionsAdapter = adapter;
}

- (NSInteger) size
{
    if (cart!=nil)
        return [cart count];
    return 0;
}

- (void) addItemToCart:(MLPrescriptionItem *)item
{
    if (cart!=nil) {
        [cart addObject:item];
        // Add item to interactions cart
        [interactionsCart.cart setObject:item.med forKey:item.title];
        NSLog(@"Num med in basket: %ld -> %ld", cartId, [cart count]);
    }
}

- (void) removeItemFromCart:(MLPrescriptionItem *)item
{
    if (cart!=nil) {
        [cart removeObject:item];
        [interactionsCart.cart removeObjectForKey:item.title];
        NSLog(@"Removed med %@ from basket %ld", item.title, cartId);
    }
}

- (void) clearCart
{
    if (cart!=nil) {
        [cart removeAllObjects];
        [interactionsCart.cart removeAllObjects];
        [self makeNewUniqueHash];
    }
}

- (MLPrescriptionItem *) getItemAtIndex:(NSInteger)index
{
    if (index<[cart count])
        return [cart objectAtIndex:index];
    return nil;
}

@end
