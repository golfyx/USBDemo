//
//  SCDataBaseManagerHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/10.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCRegFormDataBaseOptHandle.h"

NS_ASSUME_NONNULL_BEGIN
/**
 数据库模块
 */
@interface SCDataBaseManagerHandle : NSObject

/// 登记保存表
@property (nonatomic, strong) SCRegFormDataBaseOptHandle *regFormDataBaseHandle;

+ (instancetype)shareInstance;

@end

NS_ASSUME_NONNULL_END
