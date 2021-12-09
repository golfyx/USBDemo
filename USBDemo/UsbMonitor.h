//
//  UsbMonitor.h
//  USBDemo
//
//  Created by golfy on 2021/10/18.
//

#import <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#import "DeviceObject.h"
#import "SCBulkDataHandle.h"

NS_ASSUME_NONNULL_BEGIN

@protocol UsbMonitorDelegate <NSObject>
@optional
- (void)usbDidPlunIn:(DeviceObject*)usbObject;
- (void)usbDidRemove:(DeviceObject*)usbObject;
- (void)usbOpenFail;
- (void)didReceiveDataDevice:(DeviceObject*)pDev readBuffer:(unsigned char *)readBuffer;
@end
 
/// USB Bulk接口工具类
@interface UsbMonitor : NSObject 
 
@property(nonatomic,strong)NSMutableArray* arrayDevices;
@property(nonatomic,strong)id<UsbMonitorDelegate> delegate;
@property(nonatomic,assign)ReadWriteState rw;
@property(nonatomic,assign)long lostReadBufferPointCount;
@property(nonatomic,assign)long readBufferPointCount;
 
+ (UsbMonitor *)sharedUsbMonitorManager;
- (id)initWithVID:(long)vid withPID:(long)pid;
- (id)initWithVID:(long)vid withPID:(long)pid withDelegate:(id<UsbMonitorDelegate>)gate;
- (DeviceObject*)getObjectByID:(long)localid;
- (IOReturn)WriteSync:(DeviceObject*)pDev buffer:(unsigned char*) writeBuffer size:(unsigned int)size;
- (IOReturn)WriteAsync:(DeviceObject*)pDev buffer:(unsigned char*)writeBuffer size:(unsigned int)size;
- (IOReturn)ReadSync:(DeviceObject*)pDev buffer:(unsigned char*)buff size:(unsigned int)size;
- (IOReturn)ReadAsync:(DeviceObject*)pDev buffer:(unsigned char*)buff size:(unsigned int)size;
- (void)readPipeAsync;
- (NSMutableArray*)getDeviceArray;
 
@end

NS_ASSUME_NONNULL_END
