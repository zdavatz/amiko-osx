/*
 
 Copyright (c) 2015 Max Lungarella <cybrmx@gmail.com>
 
 Created on 25/02/2015.
 
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

#if defined (AMIKO)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (AMIKO_ZR)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (AMIKO_DESITIN)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (COMED)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (COMED_ZR)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#elif defined (COMED_DESITIN)
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#else
extern NSString* const APP_NAME;
extern NSString* const APP_ID;
#endif

@interface MLUtilities : NSObject
+ (NSString *) appOwner;
+ (NSString *) appLanguage;
+ (NSString *) notSpecified;
+ (BOOL) isGermanApp;
+ (BOOL) isFrenchApp;
+ (BOOL) isConnected;
+ (NSString *) documentsDirectory;
+ (BOOL) checkFileIsAllowed:(NSString *)name;
+ (NSNumber*) timeIntervalInSecondsSince1970:(NSDate *)date;
+ (double) timeIntervalSinceLastDBSync;
@end
