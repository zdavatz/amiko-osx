//
//  MLiCloudToLocalMigration.h
//  AmiKoDesitin
//
//  Created by b123400 on 2020/03/21.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MLiCloudToLocalMigrationDelegate <NSObject>

@required
- (void)didFinishedICloudToLocalMigration:(_Nonnull id)sender;

@end

NS_ASSUME_NONNULL_BEGIN

@interface MLiCloudToLocalMigration : NSObject

@property (nonatomic) BOOL deleteFilesOnICloud;
@property (nonatomic, weak) id<MLiCloudToLocalMigrationDelegate> delegate;

- (instancetype)init;
- (void)start;

@end

NS_ASSUME_NONNULL_END
