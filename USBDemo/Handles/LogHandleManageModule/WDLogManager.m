//
//  WDLogManager.h
//  Wi-Fi_Disk
//
//  Created by hexs on 14-6-9.
//  Copyright (c) 2014年 hexs. All rights reserved.
//

#import "WDLogManager.h"

@implementation WDLogManager

+ (instancetype)shareInstance
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
    if (self = [super init])
    {
        _queue = [[NSMutableArray alloc] init];
        _signal = [[NSCondition alloc] init];
        /**
         特别说明: 设置为YES后，将重定向系统的输出流，错误流，并且使用系统自带的NSLog输出日志到文件，且无大小上限，会一直写入,一般情况下不开启此宏
         */
        _isReopenSystemOutputStream = NO;
//        _isReopenSystemOutputStream = YES;
        
        [self configureInfo];
    }
    return self;
}

- (void)configureInfo
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    
    NSString *logDirStr = [NSString stringWithFormat:@"%@/Log", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
    [[NSFileManager defaultManager] createDirectoryAtPath:logDirStr withIntermediateDirectories:YES attributes:nil error:nil];
    
    [formatter setDateFormat:@"HH_mm_ss"];
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    
    // 检测是否有当天的日志文件夹，没有日期（年月日）创建文件夹
    NSString *logFolder = [NSString stringWithFormat:@"%@/%@",logDirStr, dateStr];
    [[NSFileManager defaultManager] createDirectoryAtPath:logFolder withIntermediateDirectories:YES attributes:nil error:nil];
    
    _currentLogFileName = [NSString stringWithFormat:@"%@.txt", timeStr];
    _currentLogFilePath = [[NSString stringWithFormat:@"%@/%@",logFolder, _currentLogFileName] copy];
    // 创建文件
    [[NSFileManager defaultManager] createFileAtPath:_currentLogFilePath contents:nil attributes:nil];
    
    /**
     *  1.打印日志到屏幕和文件.
     *  2.打印日志到屏幕并且重定向输出流.
     */
    //重定向到本地文件
    if (_isReopenSystemOutputStream)
    {
        _logType = WDLogTypeConsole;
        
#if 0
        FILE *outfp = fopen([_currentLogFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a");
        // close original fd for stdout and stderr
        close(1);
        close(2);
        // set new fd for stdout and stderr
        dup2(fileno(outfp), 1);
        dup2(fileno(outfp), 2);
#endif
        
#if 1
        freopen([_currentLogFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
        freopen([_currentLogFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
#endif
    }
    else
    {
        _logType = WDLogTypeConsoleAndFile;
    }
}

#pragma mark - public method
/**
 输出日志
 
 @param entry log内容
 */
- (void)appendLogEntry:(NSString *)entry
{
    [_signal lock];
    [self logExportText:entry];
    [_signal unlock];
}

#pragma mark - private method
/*
 * 打印日志到文件或控制台
 */
- (void)logExportText:(NSString *)logString
{
    switch (_logType)
    {
        case WDLogTypeNull:
        {
            // 不打印日志
            break;
        }
        case WDLogTypeConsole:
        {
            // 打印日志到控制台
            [self logToConsole:logString];
            break;
        }
        case WDLogTypeFile:
        {
            // 打印日志到文件
            [self logToFile:logString];
            break;
        }
        case WDLogTypeConsoleAndFile:
        {
            // 打印日志到控制台和文件
            [self logToConsole:logString];
            [self logToFile:logString];
            break;
        }
        default:
        {
            break;
        }
    }
}

/**
 打印日志到屏幕
 */
- (void)logToConsole:(NSString *)logString
{
    NSLog(@"%@",logString);
}

/**
 打印日志到文件
 */
- (void)logToFile:(NSString *)logString
{
    const char *type = "a";
    
    FILE *file = fopen([_currentLogFilePath UTF8String],type);
    
    if (NULL == file)  return;
    
    const char *ch = [logString UTF8String];
    int writeResult = fputs(ch, file);
    if (writeResult == EOF)
    {
        NSLog(@"log write file failed.");
    }
    fclose(file);
    file = NULL;
}

@end
