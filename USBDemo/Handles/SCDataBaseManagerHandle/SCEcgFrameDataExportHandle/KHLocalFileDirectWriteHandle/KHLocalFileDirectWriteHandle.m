//
//  KHLocalFileDirectWriteHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "KHLocalFileDirectWriteHandle.h"
#import "utime.h"

@implementation KHLocalFileDirectWriteHandle

/**
 创建并打开文件
 
 @param filepath 文件路径
 @param alterTime 修改文件创建时间
 @return 文件对象
 */
- (void *)openFileFunction:(const char *)filepath alterTime:(time_t)alterTime
{
    const char* rwMode = "w+b";
    FILE *fp = fopen(filepath, rwMode);
    
    return fp;
}

/**
 关闭文件

 @param vsFile 文件对象
 @param path 文件路径
 @param alterTime 修改文件创建时间
 @return 返回值0:成功 其它:错误码
 */
- (int)closeFileFunction:(void *)vsFile path:(const char *)path alterTime:(time_t)alterTime
{
    if (vsFile != NULL)
    {
        int ret = fclose(vsFile);
        if (ret == 0)
        {
            // 修改本地文件时间
            if (alterTime == 0)
            {
                alterTime= [[NSDate date] timeIntervalSince1970];
            }
            struct utimbuf timebuf;
            timebuf.actime = (long long)alterTime;
            timebuf.modtime = (long long)alterTime;
            utime(path, &timebuf);
        }
        return ret;
    }
    return 1;
}

/**
 *  写文件
 *
 *  @param vsFile 文件对象
 *  @param buf    buffer
 *  @param size   size
 *
 *  @return 成功:0  失败:-1, 文件未打开 -2
 */
- (int)writeFunction:(void *)vsFile buf:(uint8_t *)buf size:(int)size
{
    if (NULL == vsFile)
    {
        return -2;
    }
    FILE *fp = (FILE *)vsFile;
    
    if (fwrite(buf, 1, (size_t)size, fp) != size)
    {
        return -1;
    }
    
    return 0;
}

/// seek文件
/// @param vsFile 文件对象
/// @param offset 偏移量
/// 成功返回0,失败返回非0
- (int)seekFunction:(void *)vsFile offset:(int)offset
{
    if (NULL == vsFile)
    {
        return -2;
    }
    FILE *fp = (FILE *)vsFile;
    
    int ret = fseek(fp, offset, SEEK_SET);
    return ret;
}

/**
 重命名文件
 
 @param oldPath 旧文件路径
 @param newPath 新文件路径
 @return YES/NO
 */
- (BOOL)renameFileWitholdPath:(NSString *)oldPath newPath:(NSString *)newPath
{
    return [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:nil];
}

/**
 删除指定文件
 
 @param path 文件路径
 @return YES/NO
 */
- (BOOL)removeItemAtPath:(NSString *)path
{
    return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
