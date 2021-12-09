//
//  USBDeviceTool.h
//  USBDemo
//
//  Created by golfy on 2021/10/9.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDKeys.h>

NS_ASSUME_NONNULL_BEGIN

@protocol USBDeviceDelegate <NSObject>

- (void)robotPenUSBRecvData:(uint8_t *)recvData;

- (void)robotPenUSBConnectDevice:(IOHIDDeviceRef)deviceRef;

- (void)robotPenUSBRomveDevice;
@end

/// USB HID接口工具类
@interface USBDeviceTool : NSObject

+ (USBDeviceTool *)shareDeviceTool;

@property (weak, nonatomic) id<USBDeviceDelegate> delegate;
@property (assign, nonatomic) IOHIDManagerRef managerRef;
@property (assign, nonatomic) IOHIDDeviceRef deviceRef;

/// 连接设备
- (void)connectDevice;

/// 断开设备
- (void)disConnectDevice;

/// 发送数据USB
/// @param buffer buffer
- (void)sendData:(char *)buffer;

@end

NS_ASSUME_NONNULL_END
