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
@property (nonatomic, assign) BOOL isStartMeasure; // 开始测量
@property (nonatomic, assign) BOOL isStopMeasure; // 结束测量

@property (nonatomic, assign) NSInteger startSerialNumber; // 登记表格序列号
@property (nonatomic, strong) NSString *startCheckInTime; // 登记时间
@property (nonatomic, assign) NSInteger endSerialNumber; // 登记表格序列号
@property (nonatomic, strong) NSString *endCheckInTime; // 登记时间




@property (nonatomic, strong) NSString *deviceSerialNumber; // 设备序列号

+ (instancetype)shareInstance;

/// 保存token
- (void)saveCurrentTokenInfo;
/// 清空token
- (void)clearCurrentTokenInfo;

/// 保存serialNumber
- (void)saveCurrentStartSerialNumber;

/// 清空serialNumber
- (void)clearCurrentStartSerialNumber;

/// 保存登记时间
- (void)saveCurrentStartCheckIn;
/// 清空登记时间
- (void)clearCurrentStartCheckIn;

/// 保存serialNumber
- (void)saveCurrentEndSerialNumber;

/// 清空serialNumber
- (void)clearCurrentEndSerialNumber;


/// 保存登记时间
- (void)saveCurrentEndCheckIn;
/// 清空登记时间
- (void)clearCurrentEndCheckIn;

/// 清空cookie
- (void)clearHttpCookieCache;


@end

