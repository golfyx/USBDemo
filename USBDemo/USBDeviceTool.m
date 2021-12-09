//
//  USBDeviceTool.m
//  USBDemo
//
//  Created by golfy on 2021/10/9.
//

#import "USBDeviceTool.h"
#import "USBDeviceTool+robot.h"

static const NSInteger iDR210_VID = 0x1a81;
static const NSInteger iDR210_PID = 0x101b; // 鼠标
//static const NSInteger iDR210_VID = 0x1483;
//static const NSInteger iDR210_PID = 0x5751; // echo

// 9、实现接收数据callback方法，即可接收数据。
void Handle_DeviceOutgoingData(void* context, IOReturn result, void* sender, IOHIDReportType type, uint32_t reportID, uint8_t *report,CFIndex reportLength) {
    [[USBDeviceTool shareDeviceTool].delegate robotPenUSBRecvData:report];
}
// 6、实现插入callback
void Handle_DeviceMatchingCallback(void *inContext,IOReturn inResult,void *inSender,IOHIDDeviceRef inIOHIDDeviceRef) {
    NSLog(@"Handle_DeviceMatchingCallback: %@", inIOHIDDeviceRef);
    BOOL isRot = [[USBDeviceTool shareDeviceTool] isRobotProdut:inIOHIDDeviceRef];
    if (isRot && ![USBDeviceTool shareDeviceTool].deviceRef) {
        if (![USBDeviceTool shareDeviceTool].deviceRef) {
            // 7、插入设备获取到IOHIDDeviceRef inIOHIDDeviceRef后，打开IOHIDDeviceRef。
            IOReturn ret = IOHIDDeviceOpen(inIOHIDDeviceRef, 0L);
            [USBDeviceTool shareDeviceTool].deviceRef = inIOHIDDeviceRef;
            [[USBDeviceTool shareDeviceTool].delegate robotPenUSBConnectDevice:inIOHIDDeviceRef];
            if (ret == kIOReturnSuccess) {
               
                char *inputbuffer = malloc(64);
                // 8、注册的接收数据callback。
                IOHIDDeviceRegisterInputReportCallback(inIOHIDDeviceRef, (uint8_t*)inputbuffer, 64, Handle_DeviceOutgoingData, NULL);
                
                [[USBDeviceTool shareDeviceTool] enterUSBState];
            }
        }
    }
}
// 6、实现拔出callback
void Handle_DeviceRemovalCallback(void *inContext,IOReturn inResult,void *inSender,IOHIDDeviceRef inIOHIDDeviceRef) {
    NSLog(@"Handle_DeviceRemovalCallback: %@", inIOHIDDeviceRef);
    BOOL isRot = [[USBDeviceTool shareDeviceTool] isRobotProdut:inIOHIDDeviceRef];
    if (isRot) {
        [[USBDeviceTool shareDeviceTool].delegate robotPenUSBRomveDevice];
        [USBDeviceTool shareDeviceTool].deviceRef = nil;
    }
}


@implementation USBDeviceTool

+ (USBDeviceTool *)shareDeviceTool
{
    static USBDeviceTool *deviceTool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!deviceTool) {
            deviceTool = [[USBDeviceTool alloc] init];
        }
    });
    return deviceTool;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // 1、初始化IOHIDManager
        self.managerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        // 4、加入RunLoop
        IOHIDManagerScheduleWithRunLoop(self.managerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        // 5、打开IOHIDManager
        IOReturn ret = IOHIDManagerOpen(self.managerRef, kIOHIDOptionsTypeNone);
        if (ret != kIOReturnSuccess) {
            NSLog(@"打开失败");
        }
        // 3、注册插拔设备的callback
        // 注册插入callback
        IOHIDManagerRegisterDeviceMatchingCallback(self.managerRef, &Handle_DeviceMatchingCallback, NULL);
        // 注册拔出callback
        IOHIDManagerRegisterDeviceRemovalCallback(self.managerRef, &Handle_DeviceRemovalCallback, NULL);
        // 2、进行配对设置，可以过滤其他USB设备。
//        [self setDeviceMatching];
    }
    return self;
}

- (void)setDeviceMatching {
    // 1）无配对设备
//    IOHIDManagerSetDeviceMatching(self.managerRef, NULL);
    // 2）单类设备配对
    NSMutableDictionary* dict= [NSMutableDictionary dictionary];
    [dict setValue:@(iDR210_PID) forKey:[NSString stringWithCString:kIOHIDProductIDKey encoding:NSUTF8StringEncoding]];
    [dict setValue:@(iDR210_VID) forKey:[NSString stringWithCString:kIOHIDVendorIDKey encoding:NSUTF8StringEncoding]];
    IOHIDManagerSetDeviceMatching(self.managerRef, (__bridge CFMutableDictionaryRef)dict);
    // 3）多种设备配对设置
//    NSMutableArray *arr = [NSMutableArray array];
//    [arr addObject:dict];
//    IOHIDManagerSetDeviceMatchingMultiple(self.managerRef, (__bridge CFMutableArrayRef)arr);
}

- (void)connectDevice
{
    if (!_deviceRef) {
        // 2、进行配对设置，可以过滤其他USB设备。
        [self setDeviceMatching];
    }
}

- (void)disConnectDevice
{
    if (!_deviceRef) {
        return;
    }
    
    if ([self isRobotProdut:_deviceRef]) {

        [self exitOutUSBState];
        
        // 11、断开设备
        IOReturn ret = IOHIDDeviceClose(_deviceRef, 0L);
        if (ret == kIOReturnSuccess) {
            _deviceRef = nil;
            [[USBDeviceTool shareDeviceTool].delegate robotPenUSBRomveDevice];
        }
    }
   
}

- (void)sendData:(char *)buffer {
    if (!_deviceRef) {
        return ;
    }
    
    BOOL isRot = [self isRobotProdut:_deviceRef];
    if (isRot) {
        // 10、向USB设备发送指令。
        IOReturn ret = IOHIDDeviceSetReport(_deviceRef, kIOHIDReportTypeOutput, 0, (uint8_t*)buffer, 64);
        if (ret == kIOReturnSuccess) {
            NSLog(@"发送数据成功");
        } else {
            NSLog(@"发送数据失败：%X", ret);
        }
    }
}

@end
