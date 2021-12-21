//
//  WDLogManager.h
//  Wi-Fi_Disk
//
//  Created by hexs on 14-6-9.
//  Copyright (c) 2014年 hexs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    WDLogTypeNull = 0,          //不打印日志
    WDLogTypeConsole,           //打印日志到控制台
    WDLogTypeFile,              //打印日志到文件
    WDLogTypeConsoleAndFile     //同时打印日志到文件和控制台
}WDLogType;

@interface WDLogManager : NSObject
{
    NSMutableArray*     _queue;
    NSCondition*        _signal;
    WDLogType           _logType;                   //日志打印类型
    NSString*           _currentLogFileName;        //日志的保存文件
    NSString*           _currentLogFilePath;        //日志的保存路径
}

@property(nonatomic,readonly) WDLogType mLogType;
@property(nonatomic,readonly) NSString* mCurrentLogFileName;
@property(nonatomic,readonly) NSString* mCurrentLogFilePath;
@property (nonatomic,assign,readonly) BOOL isReopenSystemOutputStream;

+ (instancetype)shareInstance;

#pragma mark - public method
/**
 输出日志

 @param entry log内容
 */
- (void)appendLogEntry:(NSString *)entry;

@end
