//
//  WDLog.h
//  Wi-Fi_Disk
//
//  Created by hexs on 14-6-9.
//  Copyright (c) 2014年 hexs. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * 定义各个模块
 */
#define LOG_OFF                       ((int32_t)1 << 0)                // 关闭日志
#define LOG_UI_DEBUG                  ((int32_t)1 << 1)                // UI调试
#define LOG_EXCEPTION                 ((int32_t)1 << 2)                // 各个模块出现异常
#define LOG_MODUL_LOGIN               ((int32_t)1 << 3)                // 注册登录模块
#define LOG_MODUL_DATABASE            ((int32_t)1 << 4)                // 数据库模块
#define LOG_MODUL_FILE                ((int32_t)1 << 5)                // 文件模块
#define LOG_MODUL_ANALYSIS            ((int32_t)1 << 6)                // 分析模块
#define LOG_MODUL_DEALLOC             ((int32_t)1 << 7)                // dealloc内存
#define LOG_MODUL_BLE                 ((int32_t)1 << 8)                // 蓝牙模块
#define LOG_MODUL_HTTPREQUEST         ((int32_t)1 << 9)                // Http请求模块
#define LOG_MODUL_PAIN                ((int32_t)1 << 10)               // 疼痛管理模块
#define LOG_MODUL_PUSHMESSAGE         ((int32_t)1 << 11)               // 消息推送
#define LOG_MODUL_UPLOAD              ((int32_t)1 << 12)               // ecg文件导出上传

#define LOG_MODUL_HIGHLEVEL           ((int32_t)1 << 31)               // 高级别日志(打印比较多)
#define LOG_ALL                       ((int32_t)0xffffffff)    //开启所有日志

/**
 *  定义该宏，打开日志系统
 *  不定义该宏，将使用正常的NSLog打印日志
 */
#define OPEN_WD_LOG

#ifdef  OPEN_WD_LOG
/**
 *  打印日志
 */
#define WDLog(MODUL, frmt,...)       do {                                            \
[[WDLog sharedInstance] log:MODUL \
file:__FILE__ \
function:__FUNCTION__ \
line:__LINE__ \
format:(frmt), ##__VA_ARGS__]; \
} while(0)
#else
#define WDLog(MODUL,format,...)      NSLog(format, ##__VA_ARGS__)
#endif

// Release模式下关闭系统日志打印
//#ifdef DEBUG
//#define NSLog(...) NSLog(__VA_ARGS__)
//#else
//#define NSLog(...) {}
//#endif

@interface WDLog : NSObject

@property (nonatomic,assign) int32_t logLevelValue;
@property (nonatomic,strong) NSDateFormatter *dateFormatter;

+ (instancetype)sharedInstance;

/**
 *  将日志信息写到文件中
 *  @param modul    当前模块号
 *  @param file     记录日志所在的文件
 *  @param function 记录日志所在的函数名称
 *  @param line     记录日志所在的行号
 *  @param format   日志内容，格式化字符串
 *  @param ...      格式化字符串的参数
 */
- (void)log:(int32_t)modul file:(const char *)file function:(const char *)function line:(int)line format:(NSString *)format, ... __attribute__ ((format (__NSString__, 5, 6)));

@end

