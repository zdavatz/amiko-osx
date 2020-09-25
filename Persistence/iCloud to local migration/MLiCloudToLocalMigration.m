//
//  MLiCloudToLocalMigration.m
//  AmiKoDesitin
//
//  Created by b123400 on 2020/03/21.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLiCloudToLocalMigration.h"
#import "MLUtilities.h"
#import "MLPersistenceManager.h"
#import "MLOperator.h"

@interface MLiCloudToLocalMigration ()

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMetadataQuery *query;
@property (nonatomic, strong) NSMutableArray<NSURL *> *pendingURLs;
@property (nonatomic) BOOL isDone;

@end

@implementation MLiCloudToLocalMigration

- (instancetype)init {
    if (self = [super init]) {
        self.query = [[NSMetadataQuery alloc] init];
        self.query.predicate = [NSPredicate predicateWithValue:YES];
        self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        self.query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:NO]];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ubiquitousStoreDidUpdate:) name:NSMetadataQueryDidUpdateNotification object:self.query];
        
        self.pendingURLs = [NSMutableArray array];
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;
        self.isDone = NO;
    }
    return self;
}

- (void)start {
    [self.queue addOperationWithBlock:^{
        [self.query startQuery];
        self.pendingURLs = [NSMutableArray array];
        [self tryToMigrate];
    }];
}

- (void)dealloc {
    __strong NSMetadataQuery *q = self.query;
    [self.queue addOperationWithBlock:^{
        [q stopQuery];
    }];
}

- (void)tryToMigrate {
    MLPersistenceManager *manager = [MLPersistenceManager shared];
    [manager doctor]; // Migrate to file based doctor storage
    NSURL *localDocument = [NSURL fileURLWithPath:[MLUtilities documentsDirectory]];
    NSURL *remoteDocument = [manager iCloudDocumentDirectory];

    NSNumber *isDownloading = nil;
    NSNumber *isDownloadRequested = nil;
    NSString *downloadStatus = nil;
    NSError *error = nil;

    [remoteDocument getResourceValue:&isDownloading forKey:NSURLUbiquitousItemIsDownloadingKey error:&error];
    [remoteDocument getResourceValue:&isDownloadRequested forKey:NSURLUbiquitousItemDownloadRequestedKey error:&error];
    [remoteDocument getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error];

    if (self.deleteFilesOnICloud) {
        [self moveFile:[remoteDocument URLByAppendingPathComponent:@"doctor.plist"]
                 toURL:[localDocument URLByAppendingPathComponent:@"doctor.plist"]
   overwriteIfExisting:YES];
        [self moveFile:[remoteDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
                 toURL:[localDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
   overwriteIfExisting:YES];
        [self moveFile:[remoteDocument URLByAppendingPathComponent:@"favourites"]
                 toURL:[localDocument URLByAppendingPathComponent:@"favourites"]
   overwriteIfExisting:YES];
        [self mergeFolderRecursively:[remoteDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                                  to:[localDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                      deleteOriginal:YES];
        [[NSFileManager defaultManager] removeItemAtURL:[remoteDocument URLByAppendingPathComponent:@"patients"]
                                                  error:nil];
    } else {
        [self copyFile:[remoteDocument URLByAppendingPathComponent:@"doctor.plist"]
                 toURL:[localDocument URLByAppendingPathComponent:@"doctor.plist"]
   overwriteIfExisting:YES];
        [self copyFile:[remoteDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
                 toURL:[localDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
   overwriteIfExisting:YES];
        [self copyFile:[remoteDocument URLByAppendingPathComponent:@"favourites"]
                 toURL:[localDocument URLByAppendingPathComponent:@"favourites"]
   overwriteIfExisting:YES];
        [self mergeFolderRecursively:[remoteDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                                  to:[localDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                      deleteOriginal:NO];
    }
    if ([self.pendingURLs count] == 0) {
        if (!self.isDone) {
            if (self.deleteFilesOnICloud) {
                [[NSFileManager defaultManager] removeItemAtURL:[remoteDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                                                          error:nil];
            }
            self.isDone = YES;
            [self.delegate didFinishedICloudToLocalMigration:self];
        }
    } else {
        NSLog(@"Not finished because these items are not downloaded %@", self.pendingURLs);
    }
}

- (void)ubiquitousStoreDidUpdate:(NSNotification *)notification {
    [self.queue addOperationWithBlock:^{
        NSLog(@"Retrying...");
        self.pendingURLs = [NSMutableArray array];
        [self tryToMigrate];
    }];
}

- (void)moveFile:(NSURL *)url toURL:(NSURL *)targetUrl overwriteIfExisting:(BOOL)overwrite {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *downloadStatus = nil;
    NSError *error = nil;
    
    if ([url getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] &&
        ![downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
        [manager startDownloadingUbiquitousItemAtURL:url error:&error];
        NSLog(@"Started downloading %@", url);
        [self.pendingURLs addObject:url];
        return;
    }
    [MLUtilities moveFile:url toURL:targetUrl overwriteIfExisting:overwrite];
}

- (void)copyFile:(NSURL *)url toURL:(NSURL *)targetUrl overwriteIfExisting:(BOOL)overwrite {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *downloadStatus = nil;
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        return;
    }
    
    if ([url getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] &&
        ![downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
        [manager startDownloadingUbiquitousItemAtURL:url error:&error];
        NSLog(@"Started downloading %@", url);
        [self.pendingURLs addObject:url];
        return;
    }
    [MLUtilities copyFile:url toURL:targetUrl overwriteIfExisting:overwrite];
}

- (void)mergeFolderRecursively:(NSURL *)fromURL to:(NSURL *)toURL deleteOriginal:(BOOL)deleteOriginal {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL sourceExist = [manager fileExistsAtPath:[fromURL path] isDirectory:&isDirectory];
    if (!sourceExist || !isDirectory) {
        return;
    }
    isDirectory = NO;
    BOOL destExist = [manager fileExistsAtPath:[toURL path] isDirectory:&isDirectory];
    if (destExist && !isDirectory) {
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
                [self moveFile:sourceFile toURL:destFile overwriteIfExisting:YES];
            } else {
                [self copyFile:sourceFile toURL:destFile overwriteIfExisting:YES];
            }
        }
    }
}

@end
