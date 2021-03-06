/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
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

#import "MLMedication.h"

@interface MLDBAdapter : NSObject

+ (void)copyDBFilesFromBundleIfNeeded;

- (instancetype) initWithQueue:(dispatch_queue_t)dispatchQueue;
- (BOOL) openDatabase:(NSString *)name;
- (void) closeDatabase;
- (NSInteger) getNumRecords;
- (NSInteger) getNumProducts;
- (MLMedication *) getMediWithId:(long)rowId;
- (MLMedication *) getShortMediWithId:(long)rowId;
- (MLMedication *) getMediWithRegnr:(NSString *)regnr;
- (NSArray *) getFullRecord:(long)rowId;
- (NSArray *) searchWithQuery:(NSString *)query;
- (NSArray *) searchTitle:(NSString *)title;
- (NSArray *) searchAuthor:(NSString *)author;
- (NSArray *) searchATCCode:(NSString *)atccode;
- (NSArray *) searchIngredients:(NSString *)ingredients;
- (NSArray *) searchRegNr:(NSString *)regnr;
- (NSArray *) searchTherapy:(NSString *)therapy;
- (NSArray *) searchApplication:(NSString *)application;
- (NSArray<MLMedication*> *) searchRegnrsFromList:(NSArray *)listOfRegnrs;
- (MLMedication *) cursorToVeryShortMedInfo:(NSArray *)cursor;
- (MLMedication *) cursorToShortMedInfo:(NSArray *)cursor;
- (MLMedication *) cursorToFullMedInfo:(NSArray *)cursor;
- (NSArray *) extractVeryShortMedInfoFrom:(NSArray *)results;
- (NSArray *) extractShortMedInfoFrom:(NSArray *)results;
- (NSArray *) extractFullMedInfoFrom:(NSArray *)results;

@end
