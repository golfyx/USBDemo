//
//  FunctionConfigureHandle.m
//  GPUSBCamera
//
//  Created by hexueshi on 2017/11/9.
//  Copyright © 2017年 Semacare. All rights reserved.
//

#import "ConfigureHandle.h"
#import "WDLog.h"

//配置文件的名称（配置文件要放在程序沙盒的document目录下）
#define CONFIGURE_INFO_FILE_NAME     @"Config.plist"
//应用程序程序包路径
#define PACKAGE_FILE_PATH(FILE_NAME) [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:FILE_NAME]

@implementation ConfigureHandle

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
    self = [super init];
    if (self)
    {
        [self readConfigureFunctionFromFile];
    }
    return self;
}

- (void)readConfigureFunctionFromFile
{
    NSString *configFilePath = PACKAGE_FILE_PATH(CONFIGURE_INFO_FILE_NAME);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:configFilePath])
    {
        WDLog(LOG_EXCEPTION,@"configure file does not exist!");
        return;
    }
    
    NSDictionary *confDictionary = [NSDictionary dictionaryWithContentsOfFile:configFilePath];
    if (confDictionary == nil)
    {
        WDLog(LOG_EXCEPTION,@"read configure info failed.");
        return;
    }
    
    _isScreeningMode = [[confDictionary objectForKey:@"screening"] boolValue];
}

@end
