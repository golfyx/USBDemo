//
//  SCDataBaseAbstractOptHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/10.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCDataBaseAbstractOptHandle : NSObject

@property (nonatomic, strong) FMDatabaseQueue * dateBaseQueue;

/**
 *  初始化操作表
 */
- (instancetype)initWithDataBaseQueue:(FMDatabaseQueue *)dateBaseQueue;

#pragma mark - 表操作公共方法(子类重写实现)
/**
 *  创建表
 */
- (void)createTable;

/**
 *  销毁表
 */
- (void)dropTable;

/**
 *  清空表
 */
- (void)clearTable;

@end

NS_ASSUME_NONNULL_END
