/*
 
 Copyright (c) 2015 Max Lungarella <cybrmx@gmail.com>
 
 Created on 25/02/2015.
 
 This file is part of AMiKoOSX
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
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

#if defined (AMIKO)
NSString* const APP_NAME = @"AmiKo";
NSString* const APP_ID = @"708142753";
#elif defined (AMIKO_ZR)
NSString* const APP_NAME = @"AmiKo-zR";
NSString* const APP_ID = @"708142753";
#elif defined (COMED)
NSString* const APP_NAME = @"CoMed";
NSString* const APP_ID = @"710472327";
#elif defined (COMED_ZR)
NSString* const APP_NAME = @"CoMed-zR";
NSString* const APP_ID = @"710472327";
#else
NSString* const APP_NAME = @"AmiKo";
NSString* const APP_ID = @"708142753";
#endif

@interface MLUtilities : NSObject
+ (NSString *) appOwner;
+ (NSString *) appLanguage;
+ (NSString *) notSpecified;
@end

@implementation MLUtilities
+ (NSString *) appOwner
{
    if ([APP_NAME isEqualToString:@"AmiKo"]
        || [APP_NAME isEqualToString:@"CoMed"])
        return @"ywesee";
    else if ([APP_NAME isEqualToString:@"AmiKo-zR"]
             || [APP_NAME isEqualToString:@"CoMed-zR"])
        return @"zurrose";
    
    return nil;
}

+ (NSString *) appLanguage
{
    if ([APP_NAME isEqualToString:@"AmiKo"]
        || [APP_NAME isEqualToString:@"AmiKo-zR"])
        return @"de";
    else if ([APP_NAME isEqualToString:@"CoMed"]
             || [APP_NAME isEqualToString:@"CoMed-zR"])
        return @"fr";
    
    return nil;
}

+ (NSString *) notSpecified
{
    if ([APP_NAME isEqualToString:@"AmiKo"]
        || [APP_NAME isEqualToString:@"AmiKo-zR"])
        return @"k.A.";
    else if ([APP_NAME isEqualToString:@"CoMed"]
             || [APP_NAME isEqualToString:@"CoMed-zR"])
        return @"n.s.";
    
    return nil;
}
@end
