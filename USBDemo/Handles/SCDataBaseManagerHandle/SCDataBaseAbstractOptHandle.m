//
//  SCDataBaseAbstractOptHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/10.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCDataBaseAbstractOptHandle.h"

@implementation SCDataBaseAbstractOptHandle

/**
 *  初始化操作表
 */
- (instancetype)initWithDataBaseQueue:(FMDatabaseQueue *)dateBaseQueue
{
    if (self = [super init])
    {
        self.dateBaseQueue = dateBaseQueue;
    }
    return self;
}

#pragma mark - 表操作公共方法(子类重写实现)
/**
 *  创建表
 */
- (void)createTable
{
    
}

/**
 *  销毁表
 */
- (void)dropTable
{
    
}

/**
 *  清空表
 */
- (void)clearTable
{
    
}

@end
