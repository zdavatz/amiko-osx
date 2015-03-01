/*
 
 Copyright (c) 2014 Max Lungarella <cybrmx@gmail.com>
 
 Created on 25/01/2014.
 
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

#import "MLCustomURLConnection.h"
#import "MLProgressSheetController.h"
#import "MLUtilities.h"
#import "SSZipArchive.h"

@implementation MLCustomURLConnection
{
    NSURLConnection *myConnection;
    NSFileHandle *mFile;        // writes directly to disk
    // NSMutableData *mData;    // caches in memory
    NSUInteger bytesReceived;
    MLProgressSheetController *mProgressSheet;
    long mTotExceptedBytes;
    long mTotDownloadedBytes;
    long mStatusCode;
    bool mModal;
    NSString *mFileName;
}

static NSString *PILLBOX_ODDB_ORG = @"http://pillbox.oddb.org/";

- (void) releaseStuff
{
    [myConnection cancel];
    myConnection = nil;
    if (mFile)
        [mFile closeFile];
}

- (void) downloadFileWithName:(NSString *)fileName andModal:(bool)modal
{
    mModal = modal;
    mFileName = fileName;
    
    if (modal) {
        if (!mProgressSheet)
            mProgressSheet = [[MLProgressSheetController alloc] init];
        [mProgressSheet show:[NSApp mainWindow]];
    }
    
    dispatch_queue_t queue = dispatch_get_main_queue();//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async( queue, ^(void){
        NSURL *url = [NSURL URLWithString:[PILLBOX_ODDB_ORG stringByAppendingString:fileName]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:30.0];
        
        if (request!=nil) {
            myConnection = [[NSURLConnection alloc] initWithRequest:request
                                                           delegate:self
                                                   startImmediately:NO];
            if (myConnection!=nil) {
                // [myConnection setDelegateQueue:[NSOperationQueue mainQueue]];
                [myConnection start];
            }
        }
    });
    
    // Get handle to file where the downloaded file is saved
    NSString *documentsDirectory = [MLUtilities documentsDirectory];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    mFile = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
}

// delegate calls just so let us know when it's working or when it isn't
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Download failed with an error: %@, %@", error, [error description]);
    [self releaseStuff];
}


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Get status code
    mStatusCode = [((NSHTTPURLResponse *)response) statusCode];

    mTotExceptedBytes = [response expectedContentLength];
#ifdef DEBUG
    NSLog(@"Expected content length = %ld bytes", mTotExceptedBytes);
#endif
    mTotDownloadedBytes = 0;
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (mModal && ![mProgressSheet mDownloadInProgress]) {
        [self releaseStuff];
        if (mModal)
            [mProgressSheet remove];
        return;
    }
    
    if (mFile) {
        [mFile writeData:data];
    }
    mTotDownloadedBytes += [data length];
    if (mModal)
        [mProgressSheet update:mTotDownloadedBytes max:mTotExceptedBytes];
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self releaseStuff];
    if (mStatusCode==404) {
        // Notify status code 404 (file not found)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MLStatusCode404" object:self];
        return;
    }
    // Unzip database
    if ([[mFileName pathExtension] isEqualToString:@"zip"])  {
        NSString *documentsDirectory = [MLUtilities documentsDirectory];
        NSString *zipFilePath = [documentsDirectory stringByAppendingPathComponent:mFileName];

        // These are the files that will be unzipped...
        NSString *filePath;
        if ([mFileName isEqualToString:@"amiko_db_full_idx_de.zip"])
            filePath = [[NSBundle mainBundle] pathForResource:@"amiko_db_full_idx_de" ofType:@"db"];
        if ([mFileName isEqualToString:@"amiko_db_full_idx_fr.zip"])
            filePath = [[NSBundle mainBundle] pathForResource:@"amiko_db_full_idx_fr" ofType:@"db"];
        if ([mFileName isEqualToString:@"drug_interactions_csv_de.zip"])
            filePath = [[NSBundle mainBundle] pathForResource:@"drug_interactions_csv_de" ofType:@"csv"];
        if ([mFileName isEqualToString:@"drug_interactions_csv_fr.zip"])
            filePath = [[NSBundle mainBundle] pathForResource:@"drug_interactions_csv_fr" ofType:@"csv"];
        
        if (filePath!=nil) {
            NSString *output = [documentsDirectory stringByAppendingPathComponent:@"."];
            [SSZipArchive unzipFileAtPath:zipFilePath toDestination:output overwrite:YES password:nil error:nil];
        }
        if (mModal)
            [mProgressSheet remove];
        
        // Unzip data success, post notification when larger files is unzipped!
        if ([mFileName isEqualToString:@"amiko_db_full_idx_de.zip"] || [mFileName isEqualToString:@"amiko_db_full_idx_fr.zip"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MLDidFinishLoading" object:self];
        }
    } else {
        if (mModal)
            [mProgressSheet remove];
    }
}

@end
