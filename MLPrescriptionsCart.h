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

#import <Foundation/Foundation.h>

#import "MLMedication.h"
#import "MLPrescriptionItem.h"

@interface MLPrescriptionsCart : NSObject

@property (atomic) NSMutableArray *cart;
@property (atomic) NSInteger cartId;

- (NSInteger) size;
- (void) addItemToCart:(MLPrescriptionItem *)item;
- (void) removeItemFromCart:(MLPrescriptionItem *)item;
- (MLPrescriptionItem *) getItemAtIndex:(NSInteger)index;

@end
