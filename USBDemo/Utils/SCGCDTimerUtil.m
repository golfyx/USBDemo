//
//  SCGCDTimerUtil.m
//  SCBLESDK
//
//  Created by He Kerous on 2020/1/16.
//  Copyright © 2020 Semacare. All rights reserved.
//

#import "SCGCDTimerUtil.h"

@implementation SCGCDTimerUtil

/// 单次定时
/// @param mainThread 是否是主线程回调
/// @param timeinterval 间隔时间
/// @param handler 回调接口
+ (void)scheduledTimerOncequeuemainThread:(BOOL)mainThread timeInterval:(NSTimeInterval)timeinterval handler:(dispatch_block_t)handler
{
    dispatch_queue_t queue;
    if (mainThread)
    {
        queue = dispatch_get_main_queue();
    }
    else
    {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    }
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeinterval * NSEC_PER_SEC));
    dispatch_after(when, queue, ^{
        if (handler) {
            handler();
        }
    });
}

/// 执行定时
/// @param mainThread 是否是主线程回调
/// @param timeinterval 间隔时间
/// @param repeats 重复
/// @param handler 回调接口
+ (dispatch_source_t)scheduledTimermainThread:(BOOL)mainThread timeInterval:(NSTimeInterval)timeinterval repeats:(BOOL)repeats handler:(dispatch_block_t)handler
{
    dispatch_queue_t queue;
    if (mainThread)
    {
        queue = dispatch_get_main_queue();
    }
    else
    {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    }
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    // GCD的时间参数，一般是纳秒(1秒 == 10的9次方纳秒)
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeinterval * NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(timeinterval * NSEC_PER_SEC);
    dispatch_source_set_timer(timer, start, interval, 0);
    // 设置回调
    dispatch_source_set_event_handler(timer, ^{
        
        if (!repeats) {
            [[self class] cancelTimer:timer];
        }
        if (handler) {
            handler();
        }
    });
    dispatch_resume(timer);
    return timer;
}

// 取消定时器
+ (void)cancelTimer:(dispatch_source_t)timer
{
    if (timer) {
        dispatch_source_cancel(timer);
    }
}

@end
