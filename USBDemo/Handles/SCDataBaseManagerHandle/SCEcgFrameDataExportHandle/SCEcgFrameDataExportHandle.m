//
//  SCEcgFrameDataExportHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCEcgFrameDataExportHandle.h"
#import "KHLocalFileDirectWriteHandle.h"
#import "SCCacheDirectoryHandle.h"

@interface SCEcgFrameDataExportHandle ()
{
    void *_vsFile;
    const char *_vsPath;
}

@property (nonatomic, strong) KHLocalFileDirectWriteHandle *fileWriteHandle;

@end

@implementation SCEcgFrameDataExportHandle

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
        _fileWriteHandle = [[KHLocalFileDirectWriteHandle alloc] init];
    }
    return self;
}

// 开始一个文件写入
- (void)openFileWithsample_dt:(NSString *)sample_dt
{
    NSString *fileName = [sample_dt stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    NSString *filepath = [NSString stringWithFormat:@"%@/%@.txt", [[SCCacheDirectoryHandle shareInstance] getEcgFrameExportCacheDirectory], fileName];
    
    _vsPath = [filepath UTF8String];
    _vsFile = [_fileWriteHandle openFileFunction:_vsPath alterTime:0];
    if (_vsFile != NULL)
    {
        _curSample_dt = sample_dt;
    }
}

// 写入数据
- (void)writeFrameDataToFileWith:(NSString *)framedata
{
    // 去掉首尾"[","]"
    NSString *resultStr = [framedata substringWithRange:NSMakeRange(1, framedata.length-2)];
    // TEST
    resultStr = [NSString stringWithFormat:@"%@,", resultStr];
    const char *buf = [resultStr UTF8String];
    [_fileWriteHandle writeFunction:_vsFile buf:(uint8_t *)buf size:(int)strlen(buf)];
}

// 关闭当前文件
- (void)closeFile
{
    [_fileWriteHandle closeFileFunction:_vsFile path:_vsPath alterTime:0];
    _vsFile = NULL;
    _vsPath = NULL;
}

@end
