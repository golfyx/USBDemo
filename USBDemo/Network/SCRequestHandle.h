//
//  SCRequestHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/7/22.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCUploadDataInfo.h"
#import "SCMultiDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

/**
 服务器交互接口
 */
@interface SCRequestHandle : NSObject

#pragma mark - 登录注册相关

/// 获取验证码接口
+ (BOOL)acceptCaptchaWithPhone:(NSString *)phone;

/// 登录接口
+ (void)userLoginWithPhone:(NSString *)phone captcha:(NSString *)captcha completion:(void(^)(BOOL success, id responseObject))completion;

/// 获取当前登录用户信息
+ (void)getCurUserInfoCompletion:(void(^)(BOOL success, id responseObject))completion;

/// 获取成员基本信息
+ (void)getMemberUserInfoCompletion:(void(^)(BOOL success, id responseObject))completion;

/// 更新基本信息
+ (void)updateMemberUserInfoCompletion:(void(^)(BOOL success, id responseObject))completion;


/// 保存24小时记录时间
+ (void)saveUserProcessingTimeCompletion:(void(^)(BOOL success, id responseObject))completion;

/// 24小时上传数据
+ (void)uploadDataFor24HoursWithUploadDataInfo:(SCUploadDataInfo *)uploadDataInfo Completion:(void(^)(BOOL success, id responseObject))completion;
/// 24小时完成
+ (void)finishFor24HoursWithUploadDataInfo:(SCUploadDataInfo *)uploadDataInfo Completion:(void(^)(BOOL success, id responseObject))completion;
/// 获取记录列表
+ (void)getECGRecordList:(int)memberId completion:(void(^)(BOOL success, id responseObject))completion;
/// 下载PDF报告
+ (void)downloadPDFReportUrl:(NSString *)reportUrl fileDir:(NSString *)fileDir completion:(void(^)(BOOL success, id responseObject))completion;

/// 清楚缓存
+ (void)clearCacheDataDeviceInfo:(SCMultiDeviceInfo *)deviceInfo completion:(void(^)(BOOL success, id responseObject))completion;

/// 获取当前用户检测 进行判断当前上传的页数
+ (void)getCurrentDetectionDeviceInfo:(SCMultiDeviceInfo *)deviceInfo completion:(void(^)(BOOL success, id responseObject))completion;

@end

NS_ASSUME_NONNULL_END
