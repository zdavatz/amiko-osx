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

#import <Foundation/Foundation.h>

@interface MLMedication : NSObject

@property (nonatomic, assign) long medId;
@property (nonatomic, assign) int customerId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *auth;
@property (nonatomic, copy) NSString *atccode;
@property (nonatomic, copy) NSString *substances;
@property (nonatomic, copy) NSString *regnrs;
@property (nonatomic, copy) NSString *atcClass;
@property (nonatomic, copy) NSString *therapy;
@property (nonatomic, copy) NSString *application;
@property (nonatomic, copy) NSString *indications;
@property (nonatomic, copy) NSString *packInfo;
@property (nonatomic, copy) NSString *addInfo;
@property (nonatomic, copy) NSString *sectionIds;
@property (nonatomic, copy) NSString *sectionTitles;
@property (nonatomic, copy) NSString *styleStr;
@property (nonatomic, copy) NSString *contentStr;

@end
