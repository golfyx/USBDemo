//
//  SCGCDTimerUtil.h
//  SCBLESDK
//
//  Created by He Kerous on 2020/1/16.
//  Copyright © 2020 Semacare. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// GCD定时器
@interface SCGCDTimerUtil : NSObject

/// 单次定时
/// @param mainThread 是否是主线程回调
/// @param timeinterval 间隔时间
/// @param handler 回调接口
+ (void)scheduledTimerOncequeuemainThread:(BOOL)mainThread timeInterval:(NSTimeInterval)timeinterval handler:(dispatch_block_t)handler;

/// 执行定时
/// @param mainThread 是否是主线程回调
/// @param timeinterval 间隔时间
/// @param repeats 重复
/// @param handler 回调接口
+ (dispatch_source_t)scheduledTimermainThread:(BOOL)mainThread timeInterval:(NSTimeInterval)timeinterval repeats:(BOOL)repeats handler:(dispatch_block_t)handler;
// 取消定时器
+ (void)cancelTimer:(dispatch_source_t)timer;

@end

NS_ASSUME_NONNULL_END
