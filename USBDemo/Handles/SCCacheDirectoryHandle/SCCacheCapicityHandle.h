//
//  SCCacheCapicityHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCCacheCapicityHandle : NSObject

/**
 *  请求当前系统的缓存文件大小(数据已经做了格式显示化处理)
 */
+ (void)requestAllCachSize:(void(^)(NSString *cachString))completion;

/**
 *  清除缓存
 */
+ (void)clearAllCache:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
