//
//  WDLog.h
//  Wi-Fi_Disk
//
//  Created by hexs on 14-6-9.
//  Copyright (c) 2014年 hexs. All rights reserved.
//

#import "WDLog.h"
#import "WDLogManager.h"

@implementation WDLog

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = [NSString stringWithFormat:@"yyyy-MM-dd HH_mm_ss_SSS"];
        
        NSSetUncaughtExceptionHandler(handleRootException);
        
        _logLevelValue = LOG_OFF;
    }
    return self;
}

void handleRootException(NSException *exception)
{
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSArray *symbols = [exception callStackSymbols]; // 异常发生时的调用栈
    NSMutableString *strSymbols = [[NSMutableString alloc] init]; // 将调用栈拼成输出日志的字符串
    for (NSString *item in symbols)
    {
        [strSymbols appendString:item];
        [strSymbols appendString:@"\r\n"];
    }
    
    NSString *errorInfo = [NSString stringWithFormat:@"[ Uncaught Exception ]\r\nName: %@, Reason: %@\r\n[ Fe Symbols Start ]\r\n%@[ Fe Symbols End ]", name, reason, strSymbols];
    
    // 写日志，模块为异常
    //异常无行号，和文件名称
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    dateFormatter.dateFormat = [NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    NSString *entry = [[NSString alloc] initWithFormat:@"[%@]*[%@+%d]*[%@]",dateString, @"EXCEPTION", 0, errorInfo];
    [[WDLogManager shareInstance] appendLogEntry:entry];
}

- (void)log:(int32_t)modul file:(const char *)file function:(const char *)function line:(int)line format:(NSString *)format, ...
{
    @autoreleasepool
    {
        //当前模块是否打印
        if (!(modul & self.logLevelValue)) return;
        
        NSString *str = @"";
        if (format != nil)
        {
            va_list args;
            va_start(args, format);
            str = [[NSString alloc] initWithFormat:format arguments:args];
            va_end(args);
        }
        if (str == nil) str = @"";
        
        NSString* fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
        if (fileName == nil) fileName = @"";
        
        //屏蔽，注释掉不用类名和函数名
        NSString* functionName = [NSString stringWithUTF8String:function];
        if (functionName == nil) functionName = @"";
        
        NSDate *date = [NSDate date];
        NSString *dateString = [_dateFormatter stringFromDate:date];
        
        // 如果已经重定向的系统的输出流，则会自动加上时间日期
        NSString *entry = nil;
        if ([WDLogManager shareInstance].isReopenSystemOutputStream)
        {
            entry = [[NSString alloc] initWithFormat:@"[%@]*[%@: %d]*%@(): [%@]",[NSThread currentThread],fileName,line,functionName,str];
        }
        else
        {
            entry = [[NSString alloc] initWithFormat:@"[%@]*[%@]*[%@: %d]*%@(): [%@]\n",dateString,[NSThread currentThread],fileName,line,functionName,str];
        }
        [[WDLogManager shareInstance] appendLogEntry:entry];
    }
}

@end
