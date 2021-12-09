//
//  USBDeviceTool+robot.m
//  USBDemo
//
//  Created by golfy on 2021/10/9.
//

#import "USBDeviceTool+robot.h"

@implementation USBDeviceTool (robot)

/// 判断设备的vid , 是否自己的设备
- (BOOL)isRobotProdut:(IOHIDDeviceRef)inIOHIDDeviceRef {
    NSLog(@"判断设备的vid , 是否自己的设备");
    return YES;
//    NSString *vid = [NSString stringWithFormat:@"%@",IOHIDDeviceGetProperty(devf, CFSTR(kIOHIDVendorIDKey))];
//    return [vid isEqualToString:ROBOTVID] ? YES : NO;
}
/// 使设备进入USB状态
- (void)enterUSBState {
    NSLog(@"使设备进入USB状态");
}
/// 使设备退出USB状态
- (void)exitOutUSBState {
    NSLog(@"使设备退出USB状态");
}

@end
