//
//  SCUploadDataInfo.h
//  USBDemo
//
//  Created by golfy on 2021/11/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCUploadDataInfo : NSObject

/// 检测的原始十六进制数据(finish接口不用传)
@property (nonatomic, strong) NSString *rawData;
/// 数据块索引
@property (nonatomic, assign) int dataBlockIndex;
/// 数据长度
@property (nonatomic, assign) int dataLen;
/// 数据页索引
@property (nonatomic, assign) int dataPageIndex;
/// 检测时间
@property (nonatomic, assign) long long detectionTime;
/// 检测类型(1,3,5,27)
@property (nonatomic, assign) int detectionType;
/// 设备类型(默认23)
@property (nonatomic, assign) int deviceType;
@property (nonatomic, strong) NSString *logs;
/// MAC地址
@property (nonatomic, strong) NSString *macAddress;
/// 成员ID
@property (nonatomic, assign) int memberId;
/// 采样率
@property (nonatomic, assign) int samplingRate;
/// 是否转BIN文件
@property (nonatomic, assign) BOOL isToBin;
/// X不用传
@property (nonatomic, assign) int userId;

@end

NS_ASSUME_NONNULL_END
