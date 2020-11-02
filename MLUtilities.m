/*
 
 Copyright (c) 2015 Max Lungarella <cybrmx@gmail.com>
 
 Created on 01/03/2015.
 
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

#import "MLUtilities.h"
#import <CommonCrypto/CommonHMAC.h>

#if defined (AMIKO)
NSString* const APP_NAME = @"AmiKo";
NSString* const APP_ID = @"708142753";
#elif defined (COMED)
NSString* const APP_NAME = @"CoMed";
NSString* const APP_ID = @"710472327";
#else
#error "TARGET not selected"
#endif

@implementation MLUtilities

+ (void) reportMemory {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in bytes): %lu", info.resident_size);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}

+ (NSString *) appOwner
{
    if ([APP_NAME isEqualToString:@"AmiKo"] || [APP_NAME isEqualToString:@"CoMed"])
        return @"ywesee";
//    else if ([APP_NAME isEqualToString:@"AmiKo-zR"] || [APP_NAME isEqualToString:@"CoMed-zR"])
//        return @"zurrose";
//    else if ([APP_NAME isEqualToString:@"AmiKo-Desitin"] || [APP_NAME isEqualToString:@"CoMed-Desitin"])
//        return @"desitin";

    return nil;
}

+ (NSString *) appLanguage
{
    if ([APP_NAME isEqualToString:@"AmiKo"]
//        || [APP_NAME isEqualToString:@"AmiKo-zR"]
//        || [APP_NAME isEqualToString:@"AmiKo-Desitin"]
        )
    {
        return @"de";
    }

    else if ([APP_NAME isEqualToString:@"CoMed"]
//             || [APP_NAME isEqualToString:@"CoMed-zR"]
//             || [APP_NAME isEqualToString:@"CoMed-Desitin"]
             )
    {
        return @"fr";
    }
    
    return nil;
}

+ (BOOL) isGermanApp
{
    return [[self appLanguage] isEqualToString:@"de"];
}

+ (BOOL) isFrenchApp
{
    return [[self appLanguage] isEqualToString:@"fr"];
}

+ (BOOL) isConnected
{
    NSURL *dummyURL = [NSURL URLWithString:@"http://pillbox.oddb.org"];
    NSData *data = [NSData dataWithContentsOfURL:dummyURL];
    NSLog(@"Ping to pillbox.oddb.org = %lu bytes", (unsigned long)[data length]);
    
    return data!=nil;
}

+ (NSString *)iCloudContainerIdentifier {
    if ([APP_NAME isEqualToString:@"AmiKo"])
        return @"iCloud.com.ywesee.AmikoDesitin";
    
    if ([APP_NAME isEqualToString:@"CoMed"])
        return @"iCloud.com.ywesee.ComedDesitin";
    
    return nil;
}

+ (NSString *) documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return [paths lastObject];
}

+ (BOOL) checkFileIsAllowed:(NSString *)name
{
    if ([[self appLanguage] isEqualToString:@"de"]) {
        if ([name isEqualToString:@"amiko_db_full_idx_de.db"]
            || [name isEqualToString:@"amiko_report_de.html"]
            || [name isEqualToString:@"drug_interactions_csv_de.csv"]
            || [name isEqualToString:@"amiko_frequency_de.db"])  {
            return true;
        }
    }
    else if ([[self appLanguage] isEqualToString:@"fr"]) {
        if ([name isEqualToString:@"amiko_db_full_idx_fr.db"]
            || [name isEqualToString:@"amiko_report_fr.html"]
            || [name isEqualToString:@"drug_interactions_csv_fr.csv"]
            || [name isEqualToString:@"amiko_frequency_fr.db"])  {            
            return true;
        }
    }
    
    return false;
}

+ (NSNumber*) timeIntervalInSecondsSince1970:(NSDate *)date
{
    // Result in seconds
    NSNumber* timeInterval = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
    return timeInterval;
}

+ (double) timeIntervalSinceLastDBSync
{
    double timeInterval = 0.0;
    
    if ([[MLUtilities appLanguage] isEqualToString:@"de"]) {
        NSDate* lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"germanDBLastUpdate"];
        if (lastUpdated!=nil)
            timeInterval = [[NSDate date] timeIntervalSinceDate:lastUpdated];
    }
    else if ([[MLUtilities appLanguage] isEqualToString:@"fr"]) {
        NSDate* lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"frenchDBLastUpdate"];
        if (lastUpdated!=nil)
            timeInterval = [[NSDate date] timeIntervalSinceDate:lastUpdated];
    }
    
    return timeInterval;
}

+ (NSString *) currentTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm.ss";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSString *) prettyTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd.MM.yyyy (HH:mm:ss)";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSString*) encodeStringToBase64:(NSString*)string
{
    NSData *plainData = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [plainData base64Encoding];
}

+ (NSString*) decodeBase64ToString:(NSString*)base64String
{
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    return [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
}

+ (NSString *) getColorCss
{
    NSString *colorSchemeFilename = @"color-scheme-light";
    if (@available(macOS 10.14, *)) {
        NSAppearanceName name = [[[NSApp mainWindow] effectiveAppearance] bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
        if ([name isEqualToString:NSAppearanceNameDarkAqua]) {
            colorSchemeFilename = @"color-scheme-dark";
        }
    }
    
    NSString *colorCssPath = [[NSBundle mainBundle] pathForResource:colorSchemeFilename ofType:@"css"];
    NSString *colorCss = [NSString stringWithContentsOfFile:colorCssPath encoding:NSUTF8StringEncoding error:nil];
    return colorCss;
}

+ (void)moveFile:(NSURL *)url toURL:(NSURL *)targetUrl overwriteIfExisting:(BOOL)overwrite {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:[url path]]) {
        return;
    }
    BOOL exist = [manager fileExistsAtPath:[targetUrl path]];
    if (exist && overwrite) {
        [manager replaceItemAtURL:targetUrl
                    withItemAtURL:url
                   backupItemName:[NSString stringWithFormat:@"%@.bak", [url lastPathComponent]]
                          options:NSFileManagerItemReplacementUsingNewMetadataOnly
                 resultingItemURL:nil
                            error:nil];
        [manager removeItemAtURL:url error:nil];
    } else if (!exist) {
        [manager moveItemAtURL:url
                         toURL:targetUrl
                         error:nil];
    }
}

+ (void)copyFile:(NSURL *)url toURL:(NSURL *)targetUrl overwriteIfExisting:(BOOL)overwrite {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:[url path]]) {
        return;
    }
    BOOL exist = [manager fileExistsAtPath:[targetUrl path]];
    if (exist && overwrite) {
        [manager replaceItemAtURL:targetUrl
                    withItemAtURL:url
                   backupItemName:[NSString stringWithFormat:@"%@.bak", [url lastPathComponent]]
                          options:NSFileManagerItemReplacementUsingNewMetadataOnly
                 resultingItemURL:nil
                            error:nil];
    } else if (!exist) {
        [manager copyItemAtURL:url
                         toURL:targetUrl
                         error:nil];
    }

}

+ (void)mergeFolderRecursively:(NSURL *)fromURL to:(NSURL *)toURL deleteOriginal:(BOOL)deleteOriginal {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL sourceExist = [manager fileExistsAtPath:[fromURL path] isDirectory:&isDirectory];
    if (!sourceExist || !isDirectory) {
        return;
    }
    isDirectory = NO;
    BOOL destExist = [manager fileExistsAtPath:[toURL path] isDirectory:&isDirectory];
    if (destExist && !isDirectory) {
        // Remote is a file but we need a directory, abort
        return;
    }
    if (!destExist) {
        [manager createDirectoryAtURL:toURL
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
    }
    NSArray<NSURL *> *sourceFiles = [manager contentsOfDirectoryAtURL:fromURL
                                           includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                              options:0
                                                                error:nil];
    for (NSURL *sourceFile in sourceFiles) {
        NSURL *destFile = [toURL URLByAppendingPathComponent:[sourceFile lastPathComponent]];
        NSNumber *sourceIsDir = @0;
        [sourceFile getResourceValue:&sourceIsDir
                              forKey:NSURLIsDirectoryKey
                               error:nil];
        if ([sourceIsDir boolValue]) {
            [self mergeFolderRecursively:sourceFile
                                      to:destFile
                          deleteOriginal:deleteOriginal];
        } else {
            if (deleteOriginal) {
                [MLUtilities moveFile:sourceFile toURL:destFile overwriteIfExisting:YES];
            } else {
                [MLUtilities copyFile:sourceFile toURL:destFile overwriteIfExisting:YES];
            }
        }
    }
}

+ (NSString *)sha256:(NSString *)input {
    const char* str = [input UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, strlen(str), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

@end
