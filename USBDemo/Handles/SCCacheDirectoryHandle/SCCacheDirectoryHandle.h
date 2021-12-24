//
//  SCCacheDirectoryHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCCacheDirectoryHandle : NSObject

+ (instancetype)shareInstance;

/**
 *  判断容量大小清空缓存目录
 */
- (void)clearAllCacheDirectory;

/**
 得到所有文件夹的大小
 */
- (unsigned long long)getAllFileSize;

/**
 *  创建文件夹
 *
 *  @param path 文件路径
 */
- (void)createFolderWithpath:(NSString *)path;

/**
 *  删除文件夹
 */
- (void)deleteFolderWithpath:(NSString *)path;

/**
 *  清空指定文件夹
 *
 *  @param path 指定文件夹路径
 */
- (void)clearDirectoryWithpath:(NSString *)path;

#pragma mark 获取文件夹
// 获取ecg导出缓存文件夹路径
- (NSString *)getEcgFrameExportCacheDirectory;

@end

NS_ASSUME_NONNULL_END
