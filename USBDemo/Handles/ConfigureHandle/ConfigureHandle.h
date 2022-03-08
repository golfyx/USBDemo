//
//  FunctionConfigureHandle.h
//  GPUSBCamera
//
//  Created by hexueshi on 2017/11/9.
//  Copyright © 2017年 Semacare. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ConfigureHandleInstance [ConfigureHandle shareInstance]

/// 读取Config.plist文件配置
@interface ConfigureHandle : NSObject

/// 是否为筛查模式
@property (nonatomic, assign) BOOL isScreeningMode;

+ (instancetype)shareInstance;

@end
