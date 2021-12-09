//
//  SCAppVaribleHandle.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/6/26.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCUserInfoModel.h"
#import "SCMultiDeviceInfo.h"
#import "SCDetectionInfo.h"

#define SCAppVaribleHandleInstance [SCAppVaribleHandle shareInstance]

typedef void (^BleDrawDataBlock)(NSData *data);

@interface SCAppVaribleHandle : NSObject

@property (nonatomic, copy) NSString *token;
@property (nonatomic, strong) SCUserInfoModel *userInfoModel;
/// 开始24小时的记录时间戳
@property (nonatomic, assign) long long startRecordTimestamp;

@property (nonatomic, strong) SCDetectionInfo *detectionInfo;

/// 获取到的数据回调
@property (nonatomic, copy) BleDrawDataBlock bleDrawDataBlock;

@property (nonatomic, strong) NSMutableArray <SCMultiDeviceInfo *>*multiDeviceInfo;
@property (nonatomic, assign) BOOL isReadBlockUserInfo; // 判断是读取块里面的信息还是写入

@property (nonatomic, assign) NSInteger serialNumber; // 登记表格序列号
@property (nonatomic, strong) NSString *checkInTime; // 登记时间

+ (instancetype)shareInstance;

// 保存token
- (void)saveCurrentTokenInfo;
// 清空token
- (void)clearCurrentTokenInfo;

// 保存serialNumber
- (void)saveCurrentSerialNumber;
// 清空serialNumber
- (void)clearCurrentSerialNumber;

// 保存登记时间
- (void)saveCurrentCheckIn;
// 清空登记时间
- (void)clearCurrentCheckIn;

// 清空cookie
- (void)clearHttpCookieCache;


@end

