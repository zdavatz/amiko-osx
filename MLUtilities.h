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

extern NSString* const APP_NAME;
extern NSString* const APP_ID;

@interface MLUtilities : NSObject

+ (void) reportMemory;
+ (NSString *) appOwner;
+ (NSString *) appLanguage;
+ (BOOL) isGermanApp;
+ (BOOL) isFrenchApp;
+ (BOOL) isAppleSilicon;
+ (BOOL) isConnected;
+ (NSString *)iCloudContainerIdentifier;
+ (NSString *) documentsDirectory;
+ (BOOL) checkFileIsAllowed:(NSString *)name;
+ (NSNumber*) timeIntervalInSecondsSince1970:(NSDate *)date;
+ (double) timeIntervalSinceLastDBSync;
+ (NSString *) currentTime;
+ (NSString *) prettyTime;
+ (NSString *) encodeStringToBase64:(NSString *)string;
+ (NSString *) decodeBase64ToString:(NSString *)base64String;

+ (NSString *) getColorCss;

+ (void)moveFile:(NSURL *)url toURL:(NSURL *)targetUrl overwriteIfExisting:(BOOL)overwrite;
+ (void)copyFile:(NSURL *)url toURL:(NSURL *)targetUrl overwriteIfExisting:(BOOL)overwrite;
+ (void)mergeFolderRecursively:(NSURL *)fromURL to:(NSURL *)toURL deleteOriginal:(BOOL)deleteOriginal;
+ (NSString *)sha256:(NSString *)clear;

@end
