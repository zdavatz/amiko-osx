/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 14/06/2017.
 
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

@implementation NSColor (MyColors)

+ (NSColor *) typicalGray { return [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0]; }
+ (NSColor *) typicalGreen { return [NSColor colorWithCalibratedRed:0.0 green:0.8 blue:0.2 alpha:1.0]; }
+ (NSColor *) typicalRed { return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0]; }
+ (NSColor *) mainTextFieldGray { return [NSColor colorWithCalibratedRed:(20/255.0) green:(20/255.0) blue:(20/255.0) alpha:1.0]; }
+ (NSColor *) mainTextFieldBlue { return [NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.8 alpha:1.0]; }
+ (NSColor *) selectBlue { return [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:1.0 alpha:1.0]; }
+ (NSColor *) lightYellow { return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:1.0]; }

@end
