//
//  SCDataBaseManagerHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/10.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCDataBaseManagerHandle.h"

@interface SCDataBaseManagerHandle ()

@property (nonatomic, copy) NSString *dataBasefilePath;
@property (nonatomic, strong) FMDatabaseQueue *dataBaseQueue;

@end

@implementation SCDataBaseManagerHandle
static NSString *const dataBasefileName = @".screening.sqlite";

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
        _dataBasefilePath = [NSString stringWithFormat:@"%@/%@", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], dataBasefileName];
        _dataBaseQueue = [FMDatabaseQueue databaseQueueWithPath:_dataBasefilePath];
        
        _regFormDataBaseHandle = [[SCRegFormDataBaseOptHandle alloc] initWithDataBaseQueue:_dataBaseQueue];
        
        [self createAllTables];
    }
    return self;
}

/**
 *  创建表
 */
- (void)createAllTables
{
    [_regFormDataBaseHandle createTable];
}

@end
