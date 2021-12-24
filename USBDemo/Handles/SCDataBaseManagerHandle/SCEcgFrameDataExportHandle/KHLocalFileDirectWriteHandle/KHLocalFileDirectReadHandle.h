//
//  KHLocalFileDirectReadHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2020/1/7.
//  Copyright © 2020 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 读取文件处理
@interface KHLocalFileDirectReadHandle : NSObject

/**
 创建并打开文件
 
 @param filepath 文件路径
 @return 文件对象
 */
- (void *)openFileFunction:(const char *)filepath;

/**
 关闭文件

 @param vsFile 文件对象
 @param path 文件路径
 @return 返回值0:成功 其它:错误码
 */
- (int)closeFileFunction:(void *)vsFile path:(const char *)path;

/// 读文件
/// @param vsFile 文件对象
/// @param buf buffer
/// @param size size
/// 成功返回读取到的文件字节数量，失败返回<0
- (int)readFunction:(void *)vsFile buf:(uint8_t *)buf size:(int)size;

/// seek文件
/// @param vsFile 文件对象
/// @param offset 偏移量
/// 成功返回0,失败返回非0
- (int)seekFunction:(void *)vsFile offset:(int)offset;

@end

NS_ASSUME_NONNULL_END
