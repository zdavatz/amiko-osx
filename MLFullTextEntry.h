/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/04/2017.
 
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

@interface MLFullTextEntry : NSObject

@property (nonatomic, copy) NSString *hash;
@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, copy) NSString *regnrs;

- (void) setRegChaptersDict:(NSMutableDictionary *)dict;
- (NSDictionary *) getRegChaptersDict;

- (NSString *) getRegnrs;
- (NSSet *) getChaptersForKey:(NSString *)key;
- (NSArray *) getRegnrsAsArray;
- (unsigned long) numHits;

@end

