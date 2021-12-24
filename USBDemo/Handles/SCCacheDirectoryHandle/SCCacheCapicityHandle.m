//
//  SCCacheCapicityHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCCacheCapicityHandle.h"
#import "SCCacheDirectoryHandle.h"
#import "NSString+AddMethod.h"

@implementation SCCacheCapicityHandle

/**
 *  请求当前系统的缓存文件大小(数据已经做了格式显示化处理)
 */
+ (void)requestAllCachSize:(void(^)(NSString *cachString))completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        unsigned long long cachecacheSize = [[SCCacheDirectoryHandle shareInstance] getAllFileSize];
        NSString *cachString = [NSString covertBytesWithfileSize:cachecacheSize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completion)
            {
                completion(cachString);
            }
        });
    });
}

/**
 *  清空缓存
 */
+ (void)clearAllCache:(void(^)(void))completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [[SCCacheDirectoryHandle shareInstance] clearAllCacheDirectory];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion)
            {
                completion();
            }
        });
    });
}

@end
