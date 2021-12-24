//
//  SCEcgFrameDataExportHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// ecg数据导出模块
@interface SCEcgFrameDataExportHandle : NSObject

@property (nonatomic, copy) NSString *curSample_dt;

+ (instancetype)shareInstance;

// 开始一个文件写入
- (void)openFileWithsample_dt:(NSString *)sample_dt;

// 写入数据
- (void)writeFrameDataToFileWith:(NSString *)framedata;

// 关闭当前文件
- (void)closeFile;

@end

NS_ASSUME_NONNULL_END
