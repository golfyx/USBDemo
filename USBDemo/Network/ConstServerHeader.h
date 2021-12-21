//
//  ConstServerHeader.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/11/15.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#ifndef ConstServerHeader_h
#define ConstServerHeader_h

// 测试服务器需要定义该宏, 正式环境则去掉此宏(Target macr中已配置此宏)
//#define DEBUG_ENVIRONMNET
#ifdef DEBUG_ENVIRONMNET // 开发环境
#define ServerUrlString @"https://miniprogram-dev.semacare.cn:8009/"
#else // 生产环境
#define ServerUrlString @"https://miniprogram.semacare.cn/"
#endif



/// 微信登录
#define WxUserLogin @"api/wx/user/login"
/// 手机号验证码登录
#define PhoneCaptchaLogin  @"api/wx/user/login-phone"
/// 退出登录
#define UserLogout @"api/wx/user/logout"
/// 发送短信
#define GetVerifyCode @"api/common/send-sms-code"
/// 获取当前登录用户信息
#define GetUserInfo @"api/member/get-current-user-member-info"
/// 获取成员信息
#define GetMemberInfo @"api/member/get-member-info"
/// 修改或保存成员信息
#define UpdateOrSaveMemberInfo @"api/member/update-or-save-member-info"

/// 保存24小时记录时间
#define SaveUserProcessingTime @"api/detection/save-user-processing-time"
/// 24小时上传数据
#define UploadDataFor24Hours @"api/detection/upload-data-for-24hours"
/// 修改备注信息(症状行为等)
#define FinallyUpdate @"api/detection/finally-update"
/// 24小时完成
#define FinishFor24Hours @"api/detection/finish-for-24Hours"
/// 获取记录列表
#define ECGRecordList @"/api/detection/list"
/// 获取记录详情
#define GetECGRecordDetail @"/api/detection/get-detail"

/// 清楚缓存
#define ClearCacheData @"/api/detection/clear-cache-data"

/// 获取当前用户检测 进行判断当前上传的页数
#define GetCurrentDetection @"/api/detection/get-current-detection"

#endif /* ConstServerHeader_h */
