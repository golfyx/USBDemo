//
//  BulkDataHandle.m
//  USBDemo
//
//  Created by golfy on 2021/11/19.
//

#import "SCBulkDataHandle.h"
#import "UsbMonitor.h"
#import "CommonUtil.h"
#import "WDLog.h"
#import "SCAppVaribleHandle.h"

@interface SCBulkDataHandle ()<UsbMonitorDelegate>

@property (nonatomic, strong) UsbMonitor *usbMonitor;
@property (nonatomic, strong) NSThread *pReadThread;
@property (nonatomic, strong) NSThread *pReadThread1;
@property (nonatomic, strong) NSThread *pReadThread2;

@property (nonatomic, strong) NSLock *readBulkLock;
@property (nonatomic, strong) NSLock *readBulkLock1;
@property (nonatomic, strong) NSLock *readBulkLock2;

@end

@implementation SCBulkDataHandle

+ (instancetype)sharedManager {
    
    static SCBulkDataHandle * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _readBulkLock = [[NSLock alloc] init];
        _readBulkLock1 = [[NSLock alloc] init];
        _readBulkLock2 = [[NSLock alloc] init];
        
        _usbMonitor = [[UsbMonitor alloc] initWithVID:0x1483 withPID:0x5751 withDelegate:self];
        _pReadThread = [[NSThread alloc] initWithTarget:self selector:@selector(readThreadBuffer) object:nil];
        [_pReadThread start];
        
        _pReadThread1 = [[NSThread alloc] initWithTarget:self selector:@selector(readThread1Buffer) object:nil];
        [_pReadThread1 start];
        
        _pReadThread2 = [[NSThread alloc] initWithTarget:self selector:@selector(readThread2Buffer) object:nil];
        [_pReadThread2 start];
    }
    return self;
}


/// 无线循环读取Bulk数据
- (void)readBuffer {
    while (1) {
        
        NSArray *tmpDeviceArray = [self.usbMonitor getDeviceArray];
        uint8_t buffer[TG_CMD_BUFFER_LEN] = {0};
        if (0 < tmpDeviceArray.count) {
            [self.usbMonitor ReadSync:tmpDeviceArray[0] buffer:buffer size:TG_CMD_BUFFER_LEN];
            if ([self.delegate respondsToSelector:@selector(didReceiveBulkDataDevice:readBuffer:)]) {
                if (0 < tmpDeviceArray.count) {
                    @synchronized (_readBulkLock) {
                        [self.delegate didReceiveBulkDataDevice:tmpDeviceArray[0] readBuffer:buffer];
                    }
                }
            }
        } else {
//            WDLog(LOG_MODUL_BLE, @"没有连接USB Bulk设备");
        }
        
    }
}

/// 无线循环读取Bulk数据
- (void)readThreadBuffer {
    while (1) {
        
        NSArray *tmpDeviceArray = [self.usbMonitor getDeviceArray];
        uint8_t buffer[TG_CMD_BUFFER_LEN] = {0};
        if (0 < tmpDeviceArray.count) {
            [self.usbMonitor ReadSync:tmpDeviceArray[0] buffer:buffer size:TG_CMD_BUFFER_LEN];
            if ([self.delegate respondsToSelector:@selector(didReceiveBulkDataDevice:readBuffer:)]) {
                if (0 < tmpDeviceArray.count) {
                    @synchronized (_readBulkLock) {
                        [self.delegate didReceiveBulkDataDevice:tmpDeviceArray[0] readBuffer:buffer];
                    }
                }
            }
        } else {
//            WDLog(LOG_MODUL_BLE, @"没有连接USB Bulk设备");
        }
        
    }
}

- (void)readThread1Buffer {
    while (1) {
        NSArray *tmpDeviceArray = [self.usbMonitor getDeviceArray];
        uint8_t buffer[TG_CMD_BUFFER_LEN] = {0};
        if (1 < tmpDeviceArray.count) {
            [self.usbMonitor ReadSync:tmpDeviceArray[1] buffer:buffer size:TG_CMD_BUFFER_LEN];
            if ([self.delegate respondsToSelector:@selector(didReceiveBulkDataDevice:readBuffer:)]) {
                if (1 < tmpDeviceArray.count) {
                    @synchronized (_readBulkLock) {
                        [self.delegate didReceiveBulkDataDevice:tmpDeviceArray[1] readBuffer:buffer];
                    }
                }
            }
        } else {
            [self.pReadThread1 cancel];
            self.pReadThread1 = nil;
            break;
        }
    }
}

- (void)readThread2Buffer {
    while (1) {
        NSArray *tmpDeviceArray = [self.usbMonitor getDeviceArray];
        uint8_t buffer[TG_CMD_BUFFER_LEN] = {0};
        if (2 < tmpDeviceArray.count) {
            [self.usbMonitor ReadSync:tmpDeviceArray[2] buffer:buffer size:TG_CMD_BUFFER_LEN];
            if ([self.delegate respondsToSelector:@selector(didReceiveBulkDataDevice:readBuffer:)]) {
                if (2 < tmpDeviceArray.count) {
                    @synchronized (_readBulkLock) {
                        [self.delegate didReceiveBulkDataDevice:tmpDeviceArray[2] readBuffer:buffer];
                    }
                }
            }
        } else {
            [self.pReadThread2 cancel];
            self.pReadThread2 = nil;
            break;
        }
    }
}

/// 向Bulk写入数据
- (IOReturn)writeBuffer:(uint8_t *)writeBufferData device:(DeviceObject *)pDev {
    if (self.usbMonitor.arrayDevices.count <= 0) {
        return kIOReturnNoDevice;
    }
    kern_return_t kr = [self.usbMonitor WriteSync:pDev buffer:writeBufferData size:TG_CMD_BUFFER_LEN];
    return kr;
}

/// 向Bulk写入数据
- (void)writeBuffer:(uint8_t *)writeBufferData {
    
    NSArray *tmpDeviceArray = [self.usbMonitor getDeviceArray];
    
    for (int i = 0; i < tmpDeviceArray.count; i++) {
        sleep(1);
        if (i < tmpDeviceArray.count) {
            [self.usbMonitor WriteSync:tmpDeviceArray[i] buffer:writeBufferData size:TG_CMD_BUFFER_LEN];
        }
    }
        
    if ([self.usbMonitor getDeviceArray].count <= 0) {
//        WDLog(LOG_MODUL_BLE, @"没有连接USB Bulk设备");
    }
}

/// 获取发送数据包
/// buffer Dongle蓝牙发送指令
/// bufLen Dongle蓝牙发送指令的长度
/// bagIndex 所有的传输包都是基于64个字节，分为3种包：首包，中间包，尾包。当前是第几个协议包
/// totalBagCount 总的有几个协议包
/// packetSendingReceivingState 操作的对象 0:针对蓝牙透传  1:针对(USB Bulk)设备本身
/// objectOfOperationState 包的收发属性  0:device -> Master 1:Master -> device  (master相当于电脑，device相当于Dongle或者USB Bulk)
- (BULK_BUFFER_PACKET)getSendDataByBuffer:(uint8_t *)buffer
                                   bufLen:(uint)bufLen
                                 bagIndex:(uint)bagIndex
                            totalBagCount:(uint)totalBagCount
              packetSendingReceivingState:(PacketSendingReceivingState)packetSendingReceivingState
                   objectOfOperationState:(ObjectOfOperationState)objectOfOperationState {
    
    BULK_BUFFER_PACKET bulkBufferPacket;
    int macLen = (bagIndex == 0 ? TG_CMD_DONGLE_MAC_LEN : 0); // 判断是首包还是其他包
    
    bulkBufferPacket.bulkBasePacket.type = (packetSendingReceivingState << 7) | (objectOfOperationState << 6) | totalBagCount;
    bulkBufferPacket.bulkBasePacket.len = (bagIndex == 0 ? bufLen + 8 : bufLen);
    bulkBufferPacket.bulkBasePacket.bagIndex = bagIndex;
    
    uint8_t sendBuffer[TG_CMD_DATA_BUFFER_LEN] = {0};
    
    for(int i = 0; i < macLen; i++) {
        sendBuffer[i] = 0x00;
    }
    
    for (int i = macLen; i < macLen + bufLen; i++) {
        sendBuffer[i] = buffer[i-macLen];
    }
    
    int checkSum = 0;
    for(int i = 0; i < macLen + bufLen; i++) {
        checkSum += sendBuffer[i];
    }
    bulkBufferPacket.bulkBasePacket.checkSum = (checkSum & 0xff); // 取低位字节
    
    for (int i = 0; i < TG_CMD_DATA_BUFFER_LEN; i++) {
        bulkBufferPacket.bulkBasePacket.dataBuffer[i] = sendBuffer[i];
    }
    
    return bulkBufferPacket;
}


// MARK: UsbMonitorDelegate
- (void)usbDidPlunIn:(DeviceObject *)usbObject {
    WDLog(LOG_MODUL_BLE, @"usbDidPlunIn --> %@", usbObject);
    [CommonUtil showMessageWithTitle:@"设备已插入"];
    SCAppVaribleHandleInstance.deviceSerialDic = @{}.mutableCopy;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(usbDidPlunIn:)]) {
            [self.delegate usbDidPlunIn:usbObject];
        }
    });
    
    if ([self.usbMonitor getDeviceArray].count == 3) {
        if (!self.pReadThread1) {
            _pReadThread1 = [[NSThread alloc] initWithTarget:self selector:@selector(readThread1Buffer) object:nil];
            [_pReadThread1 start];
        }
        if (!self.pReadThread2) {
            _pReadThread2 = [[NSThread alloc] initWithTarget:self selector:@selector(readThread2Buffer) object:nil];
            [_pReadThread2 start];
        }
    } else if ([self.usbMonitor getDeviceArray].count == 2) {
        if (!self.pReadThread1) {
            _pReadThread1 = [[NSThread alloc] initWithTarget:self selector:@selector(readThread1Buffer) object:nil];
            [_pReadThread1 start];
        }
    }
}

- (void)usbDidRemove:(DeviceObject *)usbObject {
    WDLog(LOG_MODUL_BLE, @"usbDidRemove --> %@", usbObject);
    [CommonUtil showMessageWithTitle:@"设备已拔出"];
    SCAppVaribleHandleInstance.deviceSerialDic = @{}.mutableCopy;
    if ([self.delegate respondsToSelector:@selector(usbDidRemove:)]) {
        [self.delegate usbDidRemove:usbObject];
    }
    
    if ([self.usbMonitor getDeviceArray].count < 2) {
        if (self.pReadThread1) {
            [self.pReadThread1 cancel];
            self.pReadThread1 = nil;
        }
        if (self.pReadThread2) {
            [self.pReadThread2 cancel];
            self.pReadThread2 = nil;
        }
    } else if ([self.usbMonitor getDeviceArray].count < 3) {
        if (self.pReadThread2) {
            [self.pReadThread2 cancel];
            self.pReadThread2 = nil;
        }
    }
}

- (void)usbOpenFail {
    WDLog(LOG_MODUL_BLE, @"usbOpenFail --> ");
    [CommonUtil showMessageWithTitle:@"USB蓝牙设备连接失败,请重新拔插~~"];
    SCAppVaribleHandleInstance.deviceSerialDic = @{}.mutableCopy;
    if ([self.delegate respondsToSelector:@selector(usbOpenFail)]) {
        [self.delegate usbOpenFail];
    }
}

- (void)didReceiveDataDevice:(DeviceObject *)pDev readBuffer:(unsigned char *)readBuffer {
    
}

- (NSArray *)getDeviceArray {
    return [self.usbMonitor getDeviceArray];
}

@end
