//
//  SCBulkDeviceInfo.h
//  USBDemo
//
//  Created by golfy on 2022/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCBulkDeviceInfo : NSObject

/// 扫描到的设备个数
@property (nonatomic, assign) int deviceNum;
/// 设备的索引
@property (nonatomic, assign) int deviceIndex;
/// 设备名称的长度
@property (nonatomic, assign) int deviceNameLen;
/// 设备的名称
@property (nonatomic, strong) NSString *devicename;
/// 设备的MAC地址值
@property (nonatomic, strong) NSString *macAddr;
/// 设备的序列号的长度
@property (nonatomic, assign) int seriLen;
/// 设备的序列号
@property (nonatomic, strong) NSString *deviceSeri;
/// 设备扫描的RSSI值
@property (nonatomic, assign) int deviceRssi;
/// 上次更新信息的时间戳
@property (nonatomic, assign) NSTimeInterval lastUpdateRssiTime;

/// 设备连接状态
@property (nonatomic, assign) bool connectState;

@end

NS_ASSUME_NONNULL_END
