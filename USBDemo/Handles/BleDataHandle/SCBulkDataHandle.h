//
//  BulkDataHandle.h
//  USBDemo
//
//  Created by golfy on 2021/11/19.
//

#import <Foundation/Foundation.h>
#import "DeviceObject.h"

NS_ASSUME_NONNULL_BEGIN

#define TG_CMD_BUFFER_LEN 64
#define TG_CMD_DATA_BUFFER_LEN 60
#define TG_CMD_READ 1
#define TG_CMD_DONGLE_MAC_LEN 8

typedef enum : NSUInteger {
    ReadWriteStateNull = 0,
    ReadWriteStateRead,
    ReadWriteStateWrite,
} ReadWriteState;

/// 操作的设备    注：当DeviceOfOperationState =DeviceOfOperationStateUSBBulk, ObjectOfOperationState的值没有意义。
typedef enum : NSUInteger {
    DeviceOfOperationStateBle = 0,   /// 针对蓝牙设备（包括蓝牙主模块和从模块）
    DeviceOfOperationStateUSBBulk,   /// 针对USB BULK device
} DeviceOfOperationState;

/// 操作的蓝牙对象
typedef enum : NSUInteger {
    ObjectOfOperationStatePassthrough = 0,   /// 针对蓝牙透传(直接对Dongle发送指令)
    ObjectOfOperationStateUSBBulk,           /// 针对(USB Bulk)设备本身
} ObjectOfOperationState;

/// 包的收发属性   (master相当于电脑，device相当于Dongle或者USB Bulk)
typedef enum : NSUInteger {
    PacketSendingReceivingStateDeviceToMaster = 0,
    PacketSendingReceivingStateMasterToDevice,
} PacketSendingReceivingState;

#define  SAVE_DATA_PROPERTY_LEN             128
#define  VALID_SAVE_DATA_PROPERTY_LENGTH    124
typedef union
{
   unsigned char Buffer[SAVE_DATA_PROPERTY_LEN];
   struct
   {
       unsigned char Data[VALID_SAVE_DATA_PROPERTY_LENGTH];
       unsigned int BagCrc;
       
   }DetailedContent;
    
}SAVE_BLK_DETAILED_INFOR;


typedef struct _BULK_BASE_PACKET_
{
     uint8_t type; /// Bit0~bit3 协议的总包数-取值范围： 0~15 . Bit4~bit5 该包的类型. Bit6 操作的对象 ObjectOfOperationState .  Bit7 包的收发属性  PacketSendingReceivingState
     uint8_t bagIndex;  /// 协议中当前包的索引  位部分：Bit0~bit3  取值范围： 0~15
     uint8_t len;     /// DataBuffer的长度。
     uint8_t checkSum;  /// DataBuffer的校验和。（暂定为DataBuffer的数据和）
     uint8_t dataBuffer[TG_CMD_BUFFER_LEN - 4];  /// 整个包的数据内容 , 前8个字节为蓝牙的Mac地址
} BULK_BASE_PACKET;

typedef union __BULK_BUFFER_PACKET__
{
    uint8_t dataBuffer[TG_CMD_BUFFER_LEN];
    BULK_BASE_PACKET bulkBasePacket;
} BULK_BUFFER_PACKET;


@protocol SCBulkDataHandleDelegate <NSObject>
@optional
- (void)usbDidPlunIn:(DeviceObject*)usbObject;
- (void)usbDidRemove:(DeviceObject*)usbObject;
- (void)usbOpenFail;
- (void)didReceiveBulkDataDevice:(DeviceObject*)pDev readBuffer:(unsigned char *)readBuffer;
- (void)didReceiveBulkDevice:(DeviceObject*)pDev connectState:(int)connectState;
@end

@interface SCBulkDataHandle : NSObject

@property(nonatomic,strong)id<SCBulkDataHandleDelegate> delegate;

+ (instancetype)sharedManager;

- (NSArray *)getDeviceArray;

/// 无线循环读取Bulk数据
- (void)readBuffer;
/// 向Bulk写入数据
- (IOReturn)writeBuffer:(uint8_t *)writeBufferData device:(DeviceObject*)pDev;

/// 向Bulk写入数据
//- (void)writeBuffer:(uint8_t *)writeBufferData;

/// 获取发送数据包
/// buffer Dongle蓝牙发送指令
/// bufLen Dongle蓝牙发送指令的长度
/// bagIndex 所有的传输包都是基于64个字节，分为3种包：首包，中间包，尾包。当前是第几个协议包
/// totalBagCount 总的有几个协议包
/// packetSendingReceivingState 包的收发属性  0:device -> Master 1:Master -> device  (master相当于电脑，device相当于Dongle或者USB Bulk)
/// objectOfOperationState 操作的蓝牙对象 0:针对蓝牙透传  1:针对(USB Bulk)设备本身
/// deviceOfOperationState 操作的设备    注：当DeviceOfOperationState =DeviceOfOperationStateUSBBulk, ObjectOfOperationState的值没有意义。 0:针对蓝牙设备（包括蓝牙主模块和从模块） 1:针对USB BULK device
- (BULK_BUFFER_PACKET)getSendDataByBuffer:(uint8_t *)buffer
                                   bufLen:(uint)bufLen
                                 bagIndex:(uint)bagIndex
                            totalBagCount:(uint)totalBagCount
              packetSendingReceivingState:(PacketSendingReceivingState)packetSendingReceivingState
                   objectOfOperationState:(ObjectOfOperationState)objectOfOperationState
                   deviceOfOperationState:(DeviceOfOperationState)deviceOfOperationState;

//MARK: USB BULK 模块指令

/// 断开蓝牙连接
- (IOReturn)disconnectBleDevice:(DeviceObject *)pDev;
/// 连接设备
- (IOReturn)connectBleDeviceIndex:(int)index deviceObject:(DeviceObject *)pDev;

- (void)sendGetEncipherSerialNumAddrCmd:(DeviceObject *)usbObject writeBufferData:(uint8_t *)writeBufferData;
- (void)sendCheckBulkSerialNumValidtyCmd:(DeviceObject *)usbObject writeBufferData:(uint8_t *)writeBufferData;
- (void)sendReadUSBBulkAndClearCacheCmd:(DeviceObject *)usbObject readUSBBulk:(int)enable;
- (void)sendReadUSBBleConnectStateCmd:(DeviceObject *)usbObject;

@end

NS_ASSUME_NONNULL_END
