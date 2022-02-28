//
//  SCRequestHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/7/22.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCRequestHandle.h"
#import "CommonUtil.h"
#import "ConstServerHeader.h"
#import "NetworkHelper.h"
#import "SCAppVaribleHandle.h"
#import "WDLog.h"

@implementation SCRequestHandle

#pragma mark - 登录注册相关


/// 登录接口
+ (void)userLoginWithPhone:(NSString *)phone captcha:(NSString *)captcha completion:(void(^)(BOOL success, id responseObject))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@%@?phone=%@&code=%@", ServerUrlString, PhoneCaptchaLogin, phone, captcha];
    WDLog(LOG_MODUL_HTTPREQUEST,  @"登录, url = %@", url);
    
    [NetworkHelper GET:url parameters:nil success:^(id  _Nonnull responseObject, NSInteger successCode) {
        //
        WDLog(LOG_MODUL_HTTPREQUEST,  @"responseObject = %@", responseObject);
        int code = [responseObject[@"code"] intValue];
        if (successCode == ResponseErrCode_Success)
        {
            if (200 == code) {
                SCAppVaribleHandleInstance.token = responseObject[@"data"];
                if (completion) { completion(YES, responseObject); }
            } else {
                NSString *msg = responseObject[@"msg"];
                WDLog(LOG_MODUL_HTTPREQUEST, @"登录遇到错误 --> %@", msg);
                if (completion) completion(NO, responseObject);
            }
        }
        else
        {
            WDLog(LOG_MODUL_HTTPREQUEST,  @"登录遇到错误>>>>>>");
            NSString *phoneCode = responseObject[@"number"][0][@"code"];
            if ([@"NotRegistered" isEqualToString:phoneCode])
            {
                [CommonUtil showMessageWithTitle:@"该手机号码未注册"];
            }
            else if ([phoneCode isEqualToString:@"throttled"])
            {
                [CommonUtil showMessageWithTitle:@"操作太过频繁，请稍后重试"];
            }
            else
            {
                [CommonUtil showMessageWithTitle:@"手机号或验证码错误"];
            }
            
            if (completion) {
                completion(NO, responseObject);
            }
        }
    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST,  @"%@", error.description);
        [CommonUtil showMessageWithTitle:@"网络异常"];
        if (completion) {
            completion(NO, nil);
        }
    }];
}

/// 获取验证码接口
+ (BOOL)acceptCaptchaWithPhone:(NSString *)phone {
    
    if (![CommonUtil validateMobile:phone]) {
        [CommonUtil showMessageWithTitle:@"请填写正确的手机号"];
        return false;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@%@/%@", ServerUrlString, GetVerifyCode, phone];
    WDLog(LOG_MODUL_HTTPREQUEST, @"获取验证码, url = %@", url);
    
    [NetworkHelper GET:url parameters:nil success:^(id  _Nonnull responseObject, NSInteger successCode) {
        
        WDLog(LOG_MODUL_HTTPREQUEST,  @"getMsgCode ===> %@", responseObject);
        if (successCode != ResponseErrCode_Success)
        {
            NSString *code = responseObject[@"code"];
            if ([@"ok" isEqualToString:code.lowercaseString] || [@"200" isEqualToString:code]) {
                [CommonUtil showMessageWithTitle:@"验证码已发送"];
            } else if ([@"limit" isEqualToString:code.lowercaseString]) {
                [CommonUtil showMessageWithTitle:@"获取验证码次数过多,请稍后"];
            } else if ([@"throttled" isEqualToString:code.lowercaseString]) {
                [CommonUtil showMessageWithTitle:@"操作太过频繁，请稍后重试"];
            }
        }
        
        int code = [responseObject[@"code"] intValue];
        if (200 == code) {
        } else {
            NSString *msg = responseObject[@"msg"];
            WDLog(LOG_MODUL_HTTPREQUEST, @"获取验证码遇到错误 --> %@", msg);
        }
        
    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST,  @"%@", error.description);
        [CommonUtil showMessageWithTitle:@"网络异常"];
    }];
    
    return true;
}

/// 获取当前登录用户信息
+ (void)getCurUserInfoCompletion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@", ServerUrlString, GetUserInfo];
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@", url);

    [NetworkHelper GET:url parameters:nil success:^(id  _Nonnull responseObject, NSInteger successCode) {

        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject);
        
        int code = [responseObject[@"code"] intValue];
        if (200 == code) {
            if (completion) completion(YES, responseObject);
        } else {
            NSString *msg = responseObject[@"msg"];
            WDLog(LOG_MODUL_HTTPREQUEST, @"获取用户信息遇到错误 --> %@", msg);
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {

        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

/// 获取成员基本信息
+ (void)getMemberUserInfoCompletion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@%d/", ServerUrlString, GetMemberInfo, SCAppVaribleHandleInstance.userInfoModel.userID];
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@", url);

    [NetworkHelper GET:url parameters:nil success:^(id  _Nonnull responseObject, NSInteger successCode) {

        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject);
        
        int code = [responseObject[@"code"] intValue];
        if (200 == code) {
            // 记录id用于更新
            SCUserInfoModel *userInfoModel = SCAppVaribleHandleInstance.userInfoModel;
            userInfoModel.userID = [responseObject[@"data"][@"userId"] intValue];
            userInfoModel.memberID = [responseObject[@"data"][@"memberId"] intValue];
            userInfoModel.name = responseObject[@"data"][@"name"];
            userInfoModel.genderType = [responseObject[@"data"][@"gender"] intValue];
            userInfoModel.iconUrl = responseObject[@"data"][@"avatarUrl"];
            userInfoModel.birthday = responseObject[@"data"][@"birthdate"];
            userInfoModel.height = (responseObject[@"data"][@"height"] ? [NSString stringWithFormat:@"%@", responseObject[@"data"][@"height"]] : @"");
            userInfoModel.weight = (responseObject[@"data"][@"weight"] ? [NSString stringWithFormat:@"%@", responseObject[@"data"][@"weight"]] : @"");

            SCAppVaribleHandleInstance.userInfoModel = userInfoModel;
            if (completion) completion(YES, responseObject);
        } else {
            NSString *msg = responseObject[@"msg"];
            WDLog(LOG_MODUL_HTTPREQUEST, @"获取成员信息遇到错误 --> %@", msg);
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {

        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

/// 更新基本信息
+ (void)updateMemberUserInfoCompletion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@", ServerUrlString, UpdateOrSaveMemberInfo];
    NSDictionary *dict = @{@"gender": @(SCAppVaribleHandleInstance.userInfoModel.genderType),
                                           @"memberId":@(SCAppVaribleHandleInstance.userInfoModel.memberID),
                                           @"name":SCAppVaribleHandleInstance.userInfoModel.name,
                                           @"phone":SCAppVaribleHandleInstance.userInfoModel.phoneNum,
                                           @"height":SCAppVaribleHandleInstance.userInfoModel.height,
                                           @"weight":SCAppVaribleHandleInstance.userInfoModel.weight,
                                           @"birthdate":SCAppVaribleHandleInstance.userInfoModel.birthday};
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@, dict = %@", url, dict);

    [NetworkHelper POST:url parameters:dict success:^(id  _Nonnull responseObject, NSInteger successCode) {
        //
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject);
        if (ResponseErrCode_Success == successCode) {
            int code = [responseObject[@"code"] intValue];
            if (200 == code) {
                if (completion) completion(YES, responseObject);
            } else {
                NSString *msg = responseObject[@"msg"];
                WDLog(LOG_MODUL_HTTPREQUEST, @"更新用户信息遇到错误 --> %@", msg);
                if (completion) completion(NO, responseObject);
            }
        } else {
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

/// 保存24小时记录时间
+ (void)saveUserProcessingTimeCompletion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@/%lld", ServerUrlString, SaveUserProcessingTime, SCAppVaribleHandleInstance.startRecordTimestamp];
    NSDictionary *dict = @{};
//    NSDictionary *dict = @{@"processingTime": @(SCAppVaribleHandleInstance.startRecordTimestamp)};
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@, dict = %@", url, dict);

    [NetworkHelper POST:url parameters:dict success:^(id  _Nonnull responseObject, NSInteger successCode) {
        //
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject);
        if (ResponseErrCode_Success == successCode) {
            int code = [responseObject[@"code"] intValue];
            if (200 == code) {
                if (completion) completion(YES, responseObject);
            } else {
                NSString *msg = responseObject[@"msg"];
                WDLog(LOG_MODUL_HTTPREQUEST, @"保存24小时记录遇到错误 --> %@", msg);
                if (completion) completion(NO, responseObject);
            }
        } else {
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

+ (void)uploadDataFor24HoursWithUploadDataInfo:(SCUploadDataInfo *)uploadDataInfo Completion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@", ServerUrlString, UploadDataFor24Hours];
    NSDictionary *dict = @{
        @"data" : uploadDataInfo.rawData,
        @"dataIndex" : @(uploadDataInfo.dataBlockIndex),
        @"dataLength" : @(uploadDataInfo.dataLen),
        @"dataPageIndex" : @(uploadDataInfo.dataPageIndex),
//        @"detectionTime" : @(uploadDataInfo.detectionTime),
        @"detectionType" : @(uploadDataInfo.detectionType),
        @"deviceType" : @(uploadDataInfo.deviceType),
        @"mac" : uploadDataInfo.macAddress,
        @"memberId" : @(uploadDataInfo.memberId),
        @"samplingRate" : @(uploadDataInfo.samplingRate),
//        @"toBin" : @(uploadDataInfo.isToBin)
    };
    
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@, dict = %@", url, @{
        @"data" : uploadDataInfo.rawData.length > 10 ? [uploadDataInfo.rawData substringToIndex:10] : uploadDataInfo.rawData,
        @"dataIndex" : @(uploadDataInfo.dataBlockIndex),
        @"dataLength" : @(uploadDataInfo.dataLen),
        @"dataPageIndex" : @(uploadDataInfo.dataPageIndex),
//        @"detectionTime" : @(uploadDataInfo.detectionTime),
        @"detectionType" : @(uploadDataInfo.detectionType),
        @"deviceType" : @(uploadDataInfo.deviceType),
        @"mac" : uploadDataInfo.macAddress,
        @"memberId" : @(uploadDataInfo.memberId),
        @"samplingRate" : @(uploadDataInfo.samplingRate),
//        @"toBin" : @(uploadDataInfo.isToBin)
    });

    [NetworkHelper POST:url parameters:dict success:^(id  _Nonnull responseObject, NSInteger successCode) {
        //
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject[@"data"]);
        if (ResponseErrCode_Success == successCode) {
            int code = [responseObject[@"code"] intValue];
            if (200 == code) {
                if (completion) completion(YES, responseObject);
            } else {
                NSString *msg = responseObject[@"msg"];
                WDLog(LOG_MODUL_HTTPREQUEST, @"上传心电数据遇到错误 --> %@", msg);
                if (completion) completion(NO, responseObject);
            }
        } else {
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

/// 24小时完成
+ (void)finishFor24HoursWithUploadDataInfo:(SCUploadDataInfo *)uploadDataInfo Completion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@", ServerUrlString, FinishFor24Hours];
    NSDictionary *dict = @{
        @"dataIndex" : @(uploadDataInfo.dataBlockIndex),
        @"dataLength" : @(uploadDataInfo.dataLen),
        @"dataPageIndex" : @(uploadDataInfo.dataPageIndex),
//        @"detectionTime" : @(uploadDataInfo.detectionTime),
        @"detectionType" : @(uploadDataInfo.detectionType),
        @"deviceType" : @(uploadDataInfo.deviceType),
        @"mac" : uploadDataInfo.macAddress,
        @"memberId" : @(uploadDataInfo.memberId),
        @"samplingRate" : @(uploadDataInfo.samplingRate),
//        @"toBin" : @(uploadDataInfo.isToBin)
    };
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@, dict = %@", url, dict);

    [NetworkHelper POST:url parameters:dict success:^(id  _Nonnull responseObject, NSInteger successCode) {
        //
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject[@"data"]);
        if (ResponseErrCode_Success == successCode) {
            int code = [responseObject[@"code"] intValue];
            if (200 == code) {
                if (completion) completion(YES, responseObject);
            } else {
                NSString *msg = responseObject[@"msg"];
                WDLog(LOG_MODUL_HTTPREQUEST, @"完成上传心电数据遇到错误 --> %@", msg);
                if (completion) completion(NO, responseObject);
            }
        } else {
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

/// 获取记录列表
+ (void)getECGRecordList:(int)memberId startTime:(NSString *)startTime endTime:(NSString *)endTime completion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@", ServerUrlString, ECGRecordList];
    NSDictionary *dict = @{
        @"memberId" : @(memberId),
        @"startTime" : startTime,
        @"endTime" : endTime
    };
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@, dict = %@", url, dict);

    [NetworkHelper POST:url parameters:dict success:^(id  _Nonnull responseObject, NSInteger successCode) {
        //
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject[@"data"]);
        if (ResponseErrCode_Success == successCode) {
            if (completion) completion(YES, responseObject);
        } else {
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

/// 下载PDF报告
+ (void)downloadPDFReportUrl:(NSString *)reportUrl fileDir:(NSString *)fileDir completion:(void(^)(BOOL success, id responseObject))completion {
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@, fileDir = %@", reportUrl, fileDir);

    [NetworkHelper downloadWithURL:reportUrl fileDir:fileDir progress:^(NSProgress * _Nonnull progress) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"progress --> %@", progress);
    } success:^(NSString * _Nonnull filePath) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", filePath);
        if (completion) completion(YES, filePath);
    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

/// 清楚缓存
+ (void)clearCacheDataDeviceInfo:(SCMultiDeviceInfo *)deviceInfo completion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@?memberId=%d&mac=%@", ServerUrlString, ClearCacheData, SCAppVaribleHandleInstance.userInfoModel.memberID, deviceInfo.curBlockInfo.deviceMacAddress];
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@", url);

    [NetworkHelper GET:url parameters:nil success:^(id  _Nonnull responseObject, NSInteger successCode) {
        //
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject[@"data"]);
        if (ResponseErrCode_Success == successCode) {
            int code = [responseObject[@"code"] intValue];
            if (200 == code) {
                if (completion) completion(YES, responseObject);
            } else {
                NSString *msg = responseObject[@"msg"];
                WDLog(LOG_MODUL_HTTPREQUEST, @"清楚缓存数据遇到错误 --> %@", msg);
                if (completion) completion(NO, responseObject);
            }
        } else {
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}


/// 获取当前用户检测 进行判断当前上传的页数
+ (void)getCurrentDetectionDeviceInfo:(SCMultiDeviceInfo *)deviceInfo completion:(void(^)(BOOL success, id responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"%@%@?mac=%@", ServerUrlString, GetCurrentDetection, deviceInfo.curBlockInfo.deviceMacAddress];
    WDLog(LOG_MODUL_HTTPREQUEST, @"url = %@", url);

    [NetworkHelper GET:url parameters:nil success:^(id  _Nonnull responseObject, NSInteger successCode) {
        //
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", responseObject[@"data"]);
        if (ResponseErrCode_Success == successCode) {
            int code = [responseObject[@"code"] intValue];
            if (200 == code) {
                if (completion) completion(YES, responseObject);
            } else {
                NSString *msg = responseObject[@"msg"];
                WDLog(LOG_MODUL_HTTPREQUEST, @"获取当前用户检测数据遇到错误 --> %@", msg);
                if (completion) completion(NO, responseObject);
            }
        } else {
            if (completion) completion(NO, responseObject);
        }

    } failure:^(NSError * _Nonnull error) {
        WDLog(LOG_MODUL_HTTPREQUEST, @"%@", error.description);
        if (completion) completion(NO, nil);
    }];
}

@end
