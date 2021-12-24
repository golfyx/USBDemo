//
//  NSString+AddMethod.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/10/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (AddMethod)

/**
 转化文件大小显示
 */
+ (NSString *)covertBytesWithfileSize:(unsigned long long)fileSize;

// 得到当前文件夹的大小
- (unsigned long long)fileSize;

/// 判断字符是否是只有字母组成
- (BOOL)isOnlyLatter;

@end

NS_ASSUME_NONNULL_END
