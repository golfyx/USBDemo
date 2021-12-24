//
//  SCCacheDirectoryHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCCacheDirectoryHandle.h"
#import "NSString+AddMethod.h"

@interface SCCacheDirectoryHandle ()

@property (nonatomic,copy) NSString *cachesDirectory;
@property (nonatomic,copy) NSString *documentDirectory;
@property (nonatomic,copy) NSString *basicCachePath;

@end

static NSString *const basicCacheFolder = @"SAICache";

@implementation SCCacheDirectoryHandle

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
        self.cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
//        self.basicCachePath = [NSString stringWithFormat:@"%@/%@", self.cachesDirectory, basicCacheFolder];
        self.basicCachePath = [NSString stringWithFormat:@"%@/.Documents/%@", self.documentDirectory, basicCacheFolder];
        
        [self createAllCacheDirectory];
    }
    return self;
}

/**
 *  判断容量大小清空缓存目录
 */
- (void)clearAllCacheDirectory
{
    [self deleteAllCacheDirectory];
    [self createAllCacheDirectory];
}

/**
 得到所有文件夹的大小
 */
- (unsigned long long)getAllFileSize
{
    unsigned long long fileSize = 0;
    
    NSString *temp = NSTemporaryDirectory();
    fileSize += [temp fileSize];
    fileSize += [self.basicCachePath fileSize];
    
    return fileSize;
}

/**
 *  创建文件夹
 *
 *  @param path 文件路径
 */
- (void)createFolderWithpath:(NSString *)path
{
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
}

/**
 *  删除文件夹
 */
- (void)deleteFolderWithpath:(NSString *)path
{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

/**
 *  清空指定文件夹
 *
 *  @param path 指定文件夹路径
 */
- (void)clearDirectoryWithpath:(NSString *)path
{
    [self deleteFolderWithpath:path];
    [self createFolderWithpath:path];
}

#pragma mark 获取文件夹
// 获取ecg导出缓存文件夹路径
- (NSString *)getEcgFrameExportCacheDirectory
{
    return [NSString stringWithFormat:@"%@/%@", self.basicCachePath, @"EcgExport"];
}

#pragma mark - private method
// 删除tmp文件夹里的内容
- (void)clearTmpDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 删除tmp临时文件夹里面的内容
    NSString *temp = NSTemporaryDirectory();
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:temp error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject]))
    {
        [fileManager removeItemAtPath:[temp stringByAppendingPathComponent:filename] error:NULL];
    }
}

/**
 *  创建所有缓存目录
 */
- (void)createAllCacheDirectory
{
    [self createFolderWithpath:self.basicCachePath];
    
    [self createFolderWithpath:[self getEcgFrameExportCacheDirectory]];
}

/**
 *  删除所有缓存文件夹
 */
- (void)deleteAllCacheDirectory
{
    [self deleteFolderWithpath:self.basicCachePath];
    [self clearTmpDirectory];
}

@end
