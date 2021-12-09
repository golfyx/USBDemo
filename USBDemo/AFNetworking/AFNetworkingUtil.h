//
//  AFNetworkingUtil.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/12/19.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 工具函数
@interface AFNetworkingUtil : NSObject

/// 处理网络状态码回调
/// @param dataTask type of NSURLSessionDataTask
/// @param response type of NSHTTPURLResponse
/// @param responseObject 回复结果
/// @param error 错误信息
/// @param success 成功处理回调
/// @param failure 失败处理回调
+ (void)handleTaskCompletionHandleWithdataTask:(NSURLSessionDataTask *)dataTask
                                      response:(NSURLResponse *)response
                                responseObject:(id)responseObject
                                         error:(NSError *)error
                                       success:(void (^)(NSURLSessionDataTask *, id))success
                                       failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;

@end

NS_ASSUME_NONNULL_END
