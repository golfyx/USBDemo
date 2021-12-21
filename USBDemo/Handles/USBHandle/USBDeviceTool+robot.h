//
//  USBDeviceTool+robot.h
//  USBDemo
//
//  Created by golfy on 2021/10/9.
//

#import "USBDeviceTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface USBDeviceTool (robot)

/// 判断设备的vid , 是否自己的设备
- (BOOL)isRobotProdut:(IOHIDDeviceRef)inIOHIDDeviceRef;
/// 使设备进入USB状态
- (void)enterUSBState;
/// 使设备退出USB状态
- (void)exitOutUSBState;

@end

NS_ASSUME_NONNULL_END
