//
//  KHLocalFileDirectWriteHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KHLocalFileDirectWriteHandle : NSObject

/**
 创建并打开文件
 
 @param filepath 文件路径
 @param alterTime 修改文件创建时间
 @return 文件对象
 */
- (void *)openFileFunction:(const char *)filepath alterTime:(time_t)alterTime;

/**
 关闭文件
 
 @param vsFile 文件对象
 @param path 文件路径
 @param alterTime 修改文件创建时间
 @return 返回值0:成功 其它:错误码
 */
- (int)closeFileFunction:(void *)vsFile path:(const char *)path alterTime:(time_t)alterTime;

/**
 *  写文件
 *
 *  @param vsFile 文件对象
 *  @param buf    buffer
 *  @param size   size
 *
 *  @return 成功:0  失败:-1, 文件未打开 -2
 */
- (int)writeFunction:(void *)vsFile buf:(uint8_t *)buf size:(int)size;

/// seek文件
/// @param vsFile 文件对象
/// @param offset 偏移量
/// 成功返回0,失败返回非0
- (int)seekFunction:(void *)vsFile offset:(int)offset;

/**
 重命名文件
 
 @param oldPath 旧文件路径
 @param newPath 新文件路径
 @return YES/NO
 */
- (BOOL)renameFileWitholdPath:(NSString *)oldPath newPath:(NSString *)newPath;

/**
 删除指定文件
 
 @param path 文件路径
 @return YES/NO
 */
- (BOOL)removeItemAtPath:(NSString *)path;

@end
