/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
 This file is part of AMiKoOSX.
 
 AmiKoOSX is free software: you can redistribute it and/or modify
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

@interface MLDBAdapter : NSObject

- (int) openDatabase: (NSString *)name;
- (void) closeDatabase;
- (NSInteger) getNumRecords;
- (MLMedication *) searchId: (long)rowId;
- (NSArray *) getRecord: (long)rowId;
- (NSArray *) searchWithQuery: (NSString *)query;
- (NSArray *) searchTitle: (NSString *)title;
- (NSArray *) searchAuthor: (NSString *)author;
- (NSArray *) searchATCCode: (NSString *)atccode;
- (NSArray *) searchIngredients: (NSString *)ingredients;
- (NSArray *) searchRegNr: (NSString *)regnr;
- (NSArray *) searchTherapy: (NSString *)therapy;
- (NSArray *) searchApplication: (NSString *)application;
- (MLMedication *) cursorToShortMedInfo: (NSArray *)cursor;
- (MLMedication *) cursorToFullMedInfo: (NSArray *)cursor;
- (NSArray *) extractShortMedInfoFrom: (NSArray *)cursor;
- (NSArray *) extractFullMedInfoFrom: (NSArray *)results;

@end
