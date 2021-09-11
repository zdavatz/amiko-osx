//
//  MedidataGetStatusOperation.m
//  AmiKo
//
//  Created by b123400 on 2021/08/18.
//  Copyright © 2021 Ywesee GmbH. All rights reserved.
//

#import "MedidataGetUploadStatusOperation.h"

@interface MedidataGetUploadStatusOperation ()

@property (nonatomic, strong) MedidataClient *client;

@property (nonatomic, assign) BOOL _isExecuting;
@property (nonatomic, assign) BOOL _isFinished;

@end

@implementation MedidataGetUploadStatusOperation

- (instancetype)initWithTransmissionReference:(NSString *)ref {
    if (self = [super init]) {
        self.transmissionReference = ref;
        self.client = [[MedidataClient alloc] init];
    }
    return self;
}

- (void)start {
    self._isExecuting = YES;
    self._isFinished = NO;
    __weak typeof(self) _self = self;
    [self.client getDocumentStatusWithTransmissionReference:self.transmissionReference
                                                 completion:^(NSError * _Nullable error, MedidataClientUploadStatus * _Nullable status) {
        if (_self.callback) {
            _self.callback(error, status);
        }
        [_self finished];
    }];
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
