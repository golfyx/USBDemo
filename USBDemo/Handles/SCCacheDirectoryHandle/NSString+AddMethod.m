//
//  NSString+AddMethod.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "NSString+AddMethod.h"

@implementation NSString (AddMethod)

/**
 转化文件大小显示
 */
+ (NSString *)covertBytesWithfileSize:(unsigned long long)fileSize
{
    NSString *sizeText = nil;
    
    if (fileSize >= pow(1024, 3))
    {
        // size >= 1GB
        sizeText = [NSString stringWithFormat:@"%.1fGB", (float)fileSize/pow(1024, 3)];
    }
    else if (fileSize >= pow(1024, 2))
    {
        // 1GB > size >= 1MB
        sizeText = [NSString stringWithFormat:@"%.1fMB", (float)fileSize/pow(1024, 2)];
    }
    else if (fileSize >= pow(1024, 1))
    {
        // 1MB > size >= 1KB
        sizeText = [NSString stringWithFormat:@"%.1fKB", (float)fileSize/pow(1024, 1)];
    }
    else
    {
        // 1KB > size
        sizeText = [NSString stringWithFormat:@"%zdB",fileSize];
    }
    
    return sizeText;
}

// 得到当前文件夹的大小
- (unsigned long long)fileSize
{
    unsigned long long size = 0;
    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self isDirectory:&isDirectory];
    if (!exists)
    {
        return size;
    }
    
    if (isDirectory)
    {
        NSArray<NSString *> *subNameArray = [[NSFileManager defaultManager] subpathsAtPath:self];
        NSString *fullSubpath = nil;
        for (NSString *fileName in subNameArray)
        {
            fullSubpath = [self stringByAppendingPathComponent:fileName];
            exists = [[NSFileManager defaultManager] fileExistsAtPath:fullSubpath isDirectory:&isDirectory];
            if (!exists)
            {
                continue;
            }
            if (isDirectory)
            {
                // 文件夹递归获取
                size += [fullSubpath fileSize];
            }
            else
            {
                size += [[NSFileManager defaultManager] attributesOfItemAtPath:fullSubpath error:nil].fileSize;
            }
        }
    }
    else
    {
        size = [[NSFileManager defaultManager] attributesOfItemAtPath:self error:nil].fileSize;
    }
    
    return size;
}

/// 判断字符是否是只有字母组成
- (BOOL)isOnlyLatter
{
    if (self.length == 0)
    {
        return NO;
    }
    
    for (NSInteger i = 0; i < self.length; i++)
    {
        unichar ch = [self characterAtIndex:i];
        if (!(((ch >= 'a') && (ch <= 'z')) || ((ch >= 'A') && (ch <= 'Z'))) || (ch == ' ')){ //0=48
            return NO;
        }
    }
    return YES;
}

@end
