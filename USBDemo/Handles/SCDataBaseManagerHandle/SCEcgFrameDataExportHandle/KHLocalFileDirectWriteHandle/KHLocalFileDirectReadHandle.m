//
//  KHLocalFileDirectReadHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2020/1/7.
//  Copyright © 2020 golfy.xiong. All rights reserved.
//

#import "KHLocalFileDirectReadHandle.h"

@implementation KHLocalFileDirectReadHandle

/**
 创建并打开文件
 
 @param filepath 文件路径
 @return 文件对象
 */
- (void *)openFileFunction:(const char *)filepath
{
    const char* rwMode = "r+";
    FILE *fp = fopen(filepath, rwMode);
    
    return fp;
}

/**
 关闭文件

 @param vsFile 文件对象
 @param path 文件路径
 @return 返回值0:成功 其它:错误码
 */
- (int)closeFileFunction:(void *)vsFile path:(const char *)path
{
    if (vsFile != NULL)
    {
        int ret = fclose(vsFile);
        return ret;
    }
    return 1;
}

/// 读文件
/// @param vsFile 文件对象
/// @param buf buffer
/// @param size size
/// 成功返回读取到的文件字节数量，失败返回<0
- (int)readFunction:(void *)vsFile buf:(uint8_t *)buf size:(int)size
{
    if (NULL == vsFile)
    {
        return -2;
    }
    FILE *fp = (FILE *)vsFile;
    
    int readSize = (int)fread(buf, 1, (size_t)size, fp);
    if (readSize < 0)
    {
        return -1;
    }
    
    return readSize;
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

@end
