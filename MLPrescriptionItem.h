/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/07/2017.
 
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

@interface MLPrescriptionItem : NSObject

@property (nonatomic, copy) NSString *eanCode;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, copy) NSString *fullPackageInfo;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *owner;
@property (nonatomic, copy) NSString *price;

@end
