//
//  DeviceObject.h
//  USBDemo
//
//  Created by golfy on 2021/10/18.
//

#import <Foundation/Foundation.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/IOCFPlugIn.h>

NS_ASSUME_NONNULL_BEGIN

 
@interface DeviceObject : NSObject
 
@property(nonatomic,assign)io_object_t              notification;
@property(nonatomic,assign)IOUSBInterfaceInterface  **interface;
@property(nonatomic,assign)UInt32                   locationID;
@property(nonatomic,assign)CFStringRef                deviceName;
 
@property(nonatomic,assign)IOUSBDeviceInterface     **dev;
@property(nonatomic,assign)UInt8                    pipeIn;
@property(nonatomic,assign)UInt8                    pipeOut;
@property(nonatomic,assign)UInt16                   maxPacketSizeIn;
@property(nonatomic,assign)UInt16                   maxPacketSizeOut;
 
@end

NS_ASSUME_NONNULL_END
