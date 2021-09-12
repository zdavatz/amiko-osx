//
//  MLMedidataDownloadAndCheckOperation.m
//  AmiKo
//
//  Created by b123400 on 2021/09/10.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MLMedidataDownloadAndCheckOperation.h"
#import "MedidataClient.h"
#import "MedidataResponseDocument.h"

@interface MLMedidataDownloadAndCheckOperation ()

@property (nonatomic, strong) MedidataClient *client;

@property (nonatomic, assign) BOOL _isExecuting;
@property (nonatomic, assign) BOOL _isFinished;

@property (nonatomic, strong) NSString *ref;
@property (nonatomic, strong) NSString *gln;
@property (nonatomic, strong) NSURL *destination;

@end

@implementation MLMedidataDownloadAndCheckOperation

- (instancetype)initWithTransmissionReference:(NSString *)ref preferredGLN:(NSString *)gln andDestination:(NSURL *)url {
    if (self = [super init]) {
        self.ref = ref;
        self.gln = gln;
        self.destination = url;
        self.client = [[MedidataClient alloc] init];
    }
    return self;
}

- (void)start {
    self._isExecuting = YES;
    self._isFinished = NO;
    __weak typeof(self) _self = self;
    
    NSString *filename = [[NSUUID UUID] UUIDString];
    NSURL *tempFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:filename]];
    [self.client downloadInvoiceResponseWithTransmissionReference:self.ref
                                                           toFile:tempFile
                                                       completion:^(NSError * _Nullable error) {
        if (error) {
            [_self finishWithError:error andURL:nil];
            return;
        }
        NSError *xmlError = nil;
        NSXMLDocument *xmldoc = [[NSXMLDocument alloc] initWithContentsOfURL:tempFile
                                                                     options:0
                                                                       error:&xmlError];
        if (xmlError) {
            [_self finishWithError:xmlError andURL:nil];
            return;
        }
        NSError *moveError = nil;
        MedidataResponseDocument *doc = [[MedidataResponseDocument alloc] initWithXMLDocument:xmldoc];
        if ([[doc transportToGLN] isEqualToString:_self.gln]) {
            [[NSFileManager defaultManager] moveItemAtURL:tempFile
                                                    toURL:_self.destination
                                                    error:&moveError];
            if (moveError) {
                [_self finishWithError:moveError andURL:nil];
                return;
            }
            [_self finishWithError:nil andURL:self.destination];
            return;
        }
        [_self finishWithError:nil andURL:nil];
    }];
}

- (void)finishWithError:(NSError *)error andURL:(NSURL *)url {
    if (self.callback) {
        self.callback(error, url);
    }
    [self finished];
}

- (void)finished {
    self._isFinished = YES;
    self._isExecuting = NO;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    return self._isExecuting;
}

- (BOOL)isFinished {
    return self._isFinished;
}

+ (NSSet *)keyPathsForValuesAffectingIsFinished {
    return [NSSet setWithObject:@"_isFinished"];
}

+ (NSSet *)keyPathsForValuesAffectingIsExecuting {
    return [NSSet setWithObject:@"_isExecuting"];
}

- (void)set_isFinished:(BOOL)_isFinished {
    __isFinished = _isFinished;
}

- (void)set_isExecuting:(BOOL)_isExecuting {
    __isExecuting = _isExecuting;
}

@end
