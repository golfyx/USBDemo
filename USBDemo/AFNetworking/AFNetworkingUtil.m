//
//  AFNetworkingUtil.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/12/19.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "AFNetworkingUtil.h"

@implementation AFNetworkingUtil

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
                                       failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSInteger statusCode = 500;
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        statusCode = urlResponse.statusCode;
    }
    int statusValue = (int)statusCode/100;
    switch (statusValue)
    {
        case 2:
        case 4:{
            // 成功
            if (success) {
                success(dataTask, responseObject);
            }
            break;
        }
        default:{
            // 失败
            if (failure) {
                failure(dataTask, error);
            }
            break;
        }
    }
}

@end
