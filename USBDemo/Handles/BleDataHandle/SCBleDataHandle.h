//
//  BleDataHandle.h
//  USBDemo
//
//  Created by golfy on 2021/11/19.
//

#import <Foundation/Foundation.h>
#import "SCMultiDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ReadingStatusUnread = 0, // 退出读取模式
    ReadingStatusRead,   // 进入读取模式
} ReadingStatus;


#define  SAVE_DATA_NAME_LEN             20
#define  SAVE_DATA_PHONE_LEN            16
#define  SAVE_DATA_GENDER_LEN           4
#define  SAVE_DATA_AGE_LEN              4
#define  SAVE_DATA_HEIGHT_LEN           4
#define  SAVE_DATA_WEIGHT_LEN           4
#define  SAVE_BULK_USER_INFO_LEN        52

typedef struct _BULK_BASE_USER_INFO_
{
    uint8_t DataName[SAVE_DATA_NAME_LEN];
    uint8_t DataPhone[SAVE_DATA_PHONE_LEN];
    uint8_t DataGender[SAVE_DATA_GENDER_LEN];
    uint8_t DataAge[SAVE_DATA_AGE_LEN];
    uint8_t DataHeight[SAVE_DATA_HEIGHT_LEN];
    uint8_t DataWeight[SAVE_DATA_WEIGHT_LEN];
} BULK_BASE_USER_INFO;

typedef union __SAVE_BULK_USER_INFO__
{
    uint8_t dataBuffer[SAVE_BULK_USER_INFO_LEN];
    BULK_BASE_USER_INFO bulkBaseUserInfo;
} SAVE_BULK_USER_INFO;

@protocol SCBleDataHandleDelegate <NSObject>
@optional
- (void)didReceiveBleDataReadBuffer:(unsigned char *)readBuffer;
- (void)didReceiveBleBattery:(int)battery storage:(int)storage;
- (void)didReceiveBleVersion:(NSString *)version;
- (void)didReceiveBleDisplayString:(NSString *)displayString;
- (void)didReceiveBleReadingStatus:(ReadingStatus)readingStatus;
- (void)didReceiveBleECGDataBlockCount:(int)count deviceInfo:(SCMultiDeviceInfo *)deviceInfo;
- (void)didReceiveBleEcgDataBlockDetail:(NSString *)blockDetail;
- (void)didReceiveBleEcgDataBlockUserInfo:(SCMultiDeviceInfo *)deviceInfo;
- (void)didReceiveBleBlockProgress:(double)blockProgress blockProgressValue:(NSString *)blockProgressValue;
- (void)didReceiveBleAutoSave:(SCMultiDeviceInfo *)deviceInfo;
- (void)didReceiveBleSerialNumber:(NSString *)deviceSerialNumber;
- (void)didReceiveBleDeleteData:(SCMultiDeviceInfo *)deviceInfo;
- (void)didReceiveBleDidConnectedDevice:(SCMultiDeviceInfo *)deviceInfo;
- (void)didReceiveBleActiveType:(int)type deviceInfo:(SCMultiDeviceInfo *)deviceInfo;
- (void)didReceiveBleLessPageData:(SCMultiDeviceInfo *)deviceInfo;

- (void)didStartUploadFirstBlockData:(SCMultiDeviceInfo *)deviceInfo;
- (void)didStartUploadBlockData:(SCMultiDeviceInfo *)deviceInfo;
- (void)didFinishUploadBlockData:(SCMultiDeviceInfo *)deviceInfo;

- (void)usbDidPlunIn:(DeviceObject*)usbObject;
- (void)usbDidRemove:(DeviceObject*)usbObject;
- (void)usbOpenFail;

@end

@interface SCBleDataHandle : NSObject

@property (nonatomic, assign) BOOL isHexadecimalDisplay;
@property (nonatomic, assign) BOOL isReadingAllBlock;
@property (nonatomic, assign) BOOL isReadingUserInfoBlock;
@property (nonatomic, assign) BOOL isDeleteECGData;
/// 是否需要上传数据
@property (nonatomic, assign) BOOL isNeedUploadData;
@property (nonatomic, assign) BOOL isExitReadMode; // 是否是退出读取模式

@property(nonatomic,strong)id<SCBleDataHandleDelegate> delegate;

+ (instancetype)sharedManager;

- (NSArray *)getDeviceArray;

/// 获取Dongle版本
- (void)getDongleVersion:(DeviceObject *)pDev;
/// 获取序列号
- (void)getDongleSerialNumber:(DeviceObject *)pDev;
/// 进入读取模式
- (void)enterReadMode:(DeviceObject *)pDev;
/// 退出读取模式
- (void)exitReadMode:(DeviceObject *)pDev;
/// 获取数据块的个数
- (void)getEcgDataBlockCount:(DeviceObject *)pDev;
/// 获取数据块的信息
/// pageindex: 第几块
/// internalIndex: 页内部索引序号(默认为 0，0代表第一个128字节， 1代表第二个128字节)
- (void)getEcgDataBlockDetailWithPageIndex:(int)pageIndex internalIndex:(int)internalIndex device:(DeviceObject *)pDev;
/// 获取数据块的内容
/// startPageIndex：开始页
/// endPageIndex：结束页
/// internalIndex: 页内部索引序号(默认为 0，0代表第一个128字节， 1代表第二个128字节)
- (void)getEcgDataBlockContentWithStartPageIndex:(int)startPageIndex endPageIndex:(int)endPageIndex internalIndex:(int)internalIndex device:(DeviceObject *)pDev;
/// 读取Dongle当前状态
- (void)getDongleActiveType:(DeviceObject *)pDev;

/// 设置Dongle时间
- (void)setDongleTime:(DeviceObject *)pDev;

/// 激活Dongle
- (void)setDongleActive:(UInt8)command device:(DeviceObject *)pDev;

/// 获取当前保存状态
- (void)getSaveEcgModelCmd:(DeviceObject *)pDev;

/// 设置当前状态(保存模式和擦除模式)
- (void)setDeviceSaveEcgModelTypeCmd:(UInt8)command device:(DeviceObject *)pDev;

/// 设置当前测量的用户信息(姓名手机号等)
- (IOReturn)setDeviceSaveUserInfo:(DeviceObject *)pDev;



//MARK: USB BULK 模块指令

/// 断开蓝牙连接
- (IOReturn)disconnectBleDevice:(DeviceObject *)pDev;
/// 连接设备
- (IOReturn)connectBleDeviceIndex:(int)index deviceObject:(DeviceObject *)pDev;

@end

NS_ASSUME_NONNULL_END
