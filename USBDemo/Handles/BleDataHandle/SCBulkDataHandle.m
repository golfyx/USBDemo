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
#import "EncipherHandler.h"

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
        
        for (DeviceObject *deviceObject in [self.usbMonitor getDeviceArray]) {
            if (self.usbMonitor) {
                GetEncipherSerialNumAddr();
                uint8_t *writeBufferData = [EncipherHandler new].interactiveBuffer;
                [self sendGetEncipherSerialNumAddrCmd:deviceObject writeBufferData:writeBufferData];
            }
        }
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

- (void)processTheDataReturnedByUSBBulk:(NSArray *)tmpDeviceArray buffer:(uint8_t *)buffer bulkIndex:(int)bulkIndex {
    NSData *tmpData;
    uint8_t bagIndex = buffer[1];
    uint8_t bulkCmdIndex = buffer[17];  // 返回的是ASCII为6， 十六进制为0x36
    //n @"A55A6F66"
    uint8_t *writeBufferData;
    if (bulkCmdIndex == 0x36 && buffer[12] == 0xA5 && buffer[13] == 0x5A && buffer[14] == 0x6f && buffer[15] == 0x66) {
        if (bagIndex == 0) {
            WDLog(LOG_MODUL_BLE, @"获取USB Bulk序列号成功！");
            tmpData = [NSData dataWithBytes:buffer length:TG_CMD_BUFFER_LEN];
            tmpData = [tmpData subdataWithRange:NSMakeRange(18, 32)]; // 从第18位开始截取返回的32位ASCII字符
            
            [self.usbMonitor ReadSync:tmpDeviceArray[bulkIndex] buffer:buffer size:TG_CMD_BUFFER_LEN];
            
            GetFixSerialNumBuffer((uint8_t *)[tmpData bytes]);
            
            CheckBulkSerialNumValidtyCmd();
            writeBufferData = [EncipherHandler new].interactiveBuffer;
            [self sendCheckBulkSerialNumValidtyCmd:tmpDeviceArray[bulkIndex] writeBufferData:writeBufferData];
        }
    }
    else if (bulkCmdIndex == 0x37 && buffer[12] == 0xA5 && buffer[13] == 0x5A && buffer[14] == 0x6f && buffer[15] == 0x66) {
        if (bagIndex == 0) {
            unsigned char rs = buffer[18];
            [self.usbMonitor ReadSync:tmpDeviceArray[bulkIndex] buffer:buffer size:TG_CMD_BUFFER_LEN];
            if (1 == rs) {
                WDLog(LOG_MODUL_BLE, @"校验USB Bulk序列号成功！");
                [self sendReadUSBBulkAndClearCacheCmd:tmpDeviceArray[bulkIndex] readUSBBulk:1];
            } else {
                WDLog(LOG_MODUL_BLE, @"校验USB Bulk序列号失败！");
            }
        }
    }
    else if (bulkCmdIndex == 0x34 && buffer[12] == 0xA5 && buffer[13] == 0x5A && buffer[14] == 0x6f && buffer[15] == 0x66) {
        if (bagIndex == 0) {
            unsigned char rs = buffer[19];
            [self.usbMonitor ReadSync:tmpDeviceArray[bulkIndex] buffer:buffer size:TG_CMD_BUFFER_LEN];
            if (0x31 == rs) {
                WDLog(LOG_MODUL_BLE, @"USB Bulk激活并清空缓存成功！");
                [self sendReadUSBBleConnectStateCmd:tmpDeviceArray[bulkIndex]];
            } else if (0x32 == rs) {
                WDLog(LOG_MODUL_BLE, @"USB Bulk禁用并清空缓存成功！");
            } else {
                WDLog(LOG_MODUL_BLE, @"USB Bulk禁用并清空命令无效！");
            }
        }
    }
    else if (bulkCmdIndex == 0x35 && buffer[12] == 0xA5 && buffer[13] == 0x5A && buffer[14] == 0x6f && buffer[15] == 0x66) {
        if (bagIndex == 0) {
            unsigned char rs = buffer[21];
            [self.usbMonitor ReadSync:tmpDeviceArray[bulkIndex] buffer:buffer size:TG_CMD_BUFFER_LEN];
            if (0x32 == rs) {
                WDLog(LOG_MODUL_BLE, @"USB Ble已连接！");
                if ([self.delegate respondsToSelector:@selector(didReceiveBulkDevice:connectState:)]) {
                    [self.delegate didReceiveBulkDevice:tmpDeviceArray[bulkIndex] connectState:2];
                }
            } else if (0x31 == rs) {
                WDLog(LOG_MODUL_BLE, @"USB Ble未连接！");
                if ([self.delegate respondsToSelector:@selector(didReceiveBulkDevice:connectState:)]) {
                    [self.delegate didReceiveBulkDevice:tmpDeviceArray[bulkIndex] connectState:1];
                }
            } else {
                WDLog(LOG_MODUL_BLE, @"USB Ble连接命令无效！");
            }
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didReceiveBulkDataDevice:readBuffer:)]) {
            if (bulkIndex < tmpDeviceArray.count) {
                @synchronized (_readBulkLock) {
                    [self.delegate didReceiveBulkDataDevice:tmpDeviceArray[bulkIndex] readBuffer:buffer];
                }
            }
        }
    }
}

/// 无线循环读取Bulk数据
- (void)readThreadBuffer {
    while (1) {
        
        NSArray *tmpDeviceArray = [self.usbMonitor getDeviceArray];
        if (0 < tmpDeviceArray.count) {
            uint8_t buffer[TG_CMD_BUFFER_LEN] = {0};
            [self.usbMonitor ReadSync:tmpDeviceArray[0] buffer:buffer size:TG_CMD_BUFFER_LEN];
            
            [self processTheDataReturnedByUSBBulk:tmpDeviceArray buffer:buffer bulkIndex:0];
            
        } else {
            [self.pReadThread cancel];
            self.pReadThread = nil;
            break;
        }
        
    }
}

- (void)readThread1Buffer {
    while (1) {
        NSArray *tmpDeviceArray = [self.usbMonitor getDeviceArray];
        if (1 < tmpDeviceArray.count) {
            uint8_t buffer[TG_CMD_BUFFER_LEN] = {0};
            [self.usbMonitor ReadSync:tmpDeviceArray[1] buffer:buffer size:TG_CMD_BUFFER_LEN];
            
            [self processTheDataReturnedByUSBBulk:tmpDeviceArray buffer:buffer bulkIndex:1];
            
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
        if (2 < tmpDeviceArray.count) {
            uint8_t buffer[TG_CMD_BUFFER_LEN] = {0};
            [self.usbMonitor ReadSync:tmpDeviceArray[2] buffer:buffer size:TG_CMD_BUFFER_LEN];
            
            [self processTheDataReturnedByUSBBulk:tmpDeviceArray buffer:buffer bulkIndex:2];
            
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
/// packetSendingReceivingState 包的收发属性  0:device -> Master 1:Master -> device  (master相当于电脑，device相当于Dongle或者USB Bulk)
/// objectOfOperationState 操作的蓝牙对象 0:针对蓝牙透传  1:针对(USB Bulk)设备本身
/// deviceOfOperationState 操作的设备    注：当DeviceOfOperationState =DeviceOfOperationStateUSBBulk, ObjectOfOperationState的值没有意义。 0:针对蓝牙设备（包括蓝牙主模块和从模块） 1:针对USB BULK device
- (BULK_BUFFER_PACKET)getSendDataByBuffer:(uint8_t *)buffer
                                   bufLen:(uint)bufLen
                                 bagIndex:(uint)bagIndex
                            totalBagCount:(uint)totalBagCount
              packetSendingReceivingState:(PacketSendingReceivingState)packetSendingReceivingState
                   objectOfOperationState:(ObjectOfOperationState)objectOfOperationState
                   deviceOfOperationState:(DeviceOfOperationState)deviceOfOperationState {
    
    BULK_BUFFER_PACKET bulkBufferPacket;
    int macLen = (bagIndex == 0 ? TG_CMD_DONGLE_MAC_LEN : 0); // 判断是首包还是其他包
    
    switch (deviceOfOperationState) {
        case DeviceOfOperationStateUSBBulk:
            bulkBufferPacket.bulkBasePacket.type = (deviceOfOperationState << 5) | totalBagCount;
            break;
            
        default:
            bulkBufferPacket.bulkBasePacket.type = (packetSendingReceivingState << 7) | (objectOfOperationState << 6) | totalBagCount;
            break;
    }
    
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
        if (!self.pReadThread) {
            _pReadThread = [[NSThread alloc] initWithTarget:self selector:@selector(readThreadBuffer) object:nil];
            [_pReadThread start];
        }
        if (!self.pReadThread1) {
            _pReadThread1 = [[NSThread alloc] initWithTarget:self selector:@selector(readThread1Buffer) object:nil];
            [_pReadThread1 start];
        }
        if (!self.pReadThread2) {
            _pReadThread2 = [[NSThread alloc] initWithTarget:self selector:@selector(readThread2Buffer) object:nil];
            [_pReadThread2 start];
        }
    } else if ([self.usbMonitor getDeviceArray].count == 2) {
        if (!self.pReadThread) {
            _pReadThread = [[NSThread alloc] initWithTarget:self selector:@selector(readThreadBuffer) object:nil];
            [_pReadThread start];
        }
        if (!self.pReadThread1) {
            _pReadThread1 = [[NSThread alloc] initWithTarget:self selector:@selector(readThread1Buffer) object:nil];
            [_pReadThread1 start];
        }
    } else if ([self.usbMonitor getDeviceArray].count == 1) {
        if (!self.pReadThread) {
            _pReadThread = [[NSThread alloc] initWithTarget:self selector:@selector(readThreadBuffer) object:nil];
            [_pReadThread start];
        }
    }
    
    if (self.usbMonitor) {
        GetEncipherSerialNumAddr();
        uint8_t *writeBufferData = [EncipherHandler new].interactiveBuffer;
        [self sendGetEncipherSerialNumAddrCmd:usbObject writeBufferData:writeBufferData];
    }
}

- (void)usbDidRemove:(DeviceObject *)usbObject {
    WDLog(LOG_MODUL_BLE, @"usbDidRemove --> %@", usbObject);
    [CommonUtil showMessageWithTitle:@"设备已拔出"];
    SCAppVaribleHandleInstance.deviceSerialDic = @{}.mutableCopy;
    if ([self.delegate respondsToSelector:@selector(usbDidRemove:)]) {
        [self.delegate usbDidRemove:usbObject];
    }
    
    if ([self.usbMonitor getDeviceArray].count < 1) {
        if (self.pReadThread) {
            [self.pReadThread cancel];
            self.pReadThread = nil;
        }
        if (self.pReadThread1) {
            [self.pReadThread1 cancel];
            self.pReadThread1 = nil;
        }
        if (self.pReadThread2) {
            [self.pReadThread2 cancel];
            self.pReadThread2 = nil;
        }
    } else if ([self.usbMonitor getDeviceArray].count < 2) {
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

//MARK: USB BULK 模块指令
- (NSData *)getASCIIValueByString:(NSString *)str {
    //1.转换成const char*类型.这里得出的是char*指针
    const char* charNum = [str cStringUsingEncoding:NSASCIIStringEncoding];
    //2.计算ASCII的值('0'和'A').
    char result = charNum[0] + 0x11;
    //3.转成NSString
    NSString *numStr = [NSString stringWithFormat:@"%c",result];
    //4.转成NSData
    return [numStr dataUsingEncoding:NSUTF8StringEncoding];
}

/// 连接设备
- (IOReturn)connectBleDeviceIndex:(int)index deviceObject:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"连接设备");
    
    NSMutableData *userInfoData = [NSMutableData data];
    [userInfoData appendData:[CommonUtil hexToBytes:@"A55A6F66"]];
    // 一个十六进制(0x02)拆分为两个ACSII 字节(0和2)(0x30对应十六进制的高位 0，0x32对应十六位低位 2)
    [userInfoData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // CmdIndex
    [userInfoData appendBytes:[@"2" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [userInfoData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // 连接或断开BLE设备 type
    [userInfoData appendBytes:[@"1" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [userInfoData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // BLE设备索引:0~15(连接命令是有效)
    [userInfoData appendBytes:[[NSString stringWithFormat:@"%1x",index] cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    
    unsigned int intValue = 0;
    for (int i = 0; i < 96; i++) {
        [userInfoData appendBytes:&intValue length:1];
    }
    
    [userInfoData appendBytes:&intValue length:1]; // 校验码位
    
    Byte *userInfoBytes = (Byte *)[userInfoData bytes];
    [CommonUtil calXortmpForSendBuffer:userInfoBytes len:userInfoData.length];
    
    userInfoData = [NSData dataWithBytes:userInfoBytes length:userInfoData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;
    
    userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [self writeBuffer:[self getSendDataByBuffer:userInfoBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:2
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStateUSBBulk
                         deviceOfOperationState:DeviceOfOperationStateBle].dataBuffer device:pDev];
    
    if (kr == kIOReturnSuccess) {
        loc += len;
        len = (uint)userInfoData.length - loc;
        userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
        [self writeBuffer:[self getSendDataByBuffer:userInfoBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:2
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStateUSBBulk
                             deviceOfOperationState:DeviceOfOperationStateBle].dataBuffer device:pDev];
    } else {
        WDLog(LOG_MODUL_BLE, @"disconnectBleDevice 发送失败！");
    }
    
    return kr;
}

/// 断开蓝牙连接
- (IOReturn)disconnectBleDevice:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"设置断开蓝牙连接");
    
    NSMutableData *userInfoData = [NSMutableData data];
    [userInfoData appendData:[CommonUtil hexToBytes:@"A55A6F66"]];
    // 一个十六进制(0x02)拆分为两个ACSII 字节(0和2)(0x30对应十六进制的高位 0，0x32对应十六位低位 2)
    [userInfoData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // CmdIndex
    [userInfoData appendBytes:[@"2" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [userInfoData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // 连接或断开BLE设备 type
    [userInfoData appendBytes:[@"2" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    
    unsigned int intValue = 0;
    for (int i = 0; i < 98; i++) {
        [userInfoData appendBytes:&intValue length:1];
    }
    
    [userInfoData appendBytes:&intValue length:1]; // 校验码位
    
    Byte *userInfoBytes = (Byte *)[userInfoData bytes];
    [CommonUtil calXortmpForSendBuffer:userInfoBytes len:userInfoData.length];
    
    userInfoData = [NSData dataWithBytes:userInfoBytes length:userInfoData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;
    
    userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [self writeBuffer:[self getSendDataByBuffer:userInfoBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:2
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStateUSBBulk
                         deviceOfOperationState:DeviceOfOperationStateBle].dataBuffer device:pDev];
    
    if (kr == kIOReturnSuccess) {
        loc += len;
        len = (uint)userInfoData.length - loc;
        userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
        [self writeBuffer:[self getSendDataByBuffer:userInfoBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:2
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStateUSBBulk
                             deviceOfOperationState:DeviceOfOperationStateBle].dataBuffer device:pDev];
    } else {
        WDLog(LOG_MODUL_BLE, @"disconnectBleDevice 发送失败！");
    }
    
    return kr;
}

- (void)sendGetEncipherSerialNumAddrCmd:(DeviceObject *)usbObject writeBufferData:(uint8_t *)writeBufferData {
    WDLog(LOG_MODUL_BLE, @"开始获取USB Bulk的序列号");
    
    NSMutableData *sendData = [NSMutableData data];
    [sendData appendData:[CommonUtil hexToBytes:@"A55A6F66"]];
    // 一个十六进制(0x02)拆分为两个ACSII 字节(0和2)(0x30对应十六进制的高位 0，0x32对应十六位低位 2)
    [sendData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // CmdIndex：这个是USB Bulk的协议指令，相当于蓝牙里面的 6F
    [sendData appendBytes:[@"6" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [sendData appendBytes:writeBufferData length:64];

    unsigned int intValue = 0;
    for (int i = 0; i < 36; i++) {
        [sendData appendBytes:&intValue length:1];
    }

    [sendData appendBytes:&intValue length:1]; // 校验码位

    Byte *sendBytes = (Byte *)[sendData bytes];
    [CommonUtil calXortmpForSendBuffer:sendBytes len:sendData.length];

    sendData = [NSData dataWithBytes:sendBytes length:sendData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;

    sendBytes = (Byte *)[[sendData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [self writeBuffer:[self getSendDataByBuffer:sendBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:2
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStateUSBBulk
                         deviceOfOperationState:DeviceOfOperationStateUSBBulk].dataBuffer device:usbObject];

    if (kr == kIOReturnSuccess) {
        loc += len;
        len = (uint)sendData.length - loc;
        sendBytes = (Byte *)[[sendData subdataWithRange:NSMakeRange(loc, len)] bytes];
        [self writeBuffer:[self getSendDataByBuffer:sendBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:2
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStateUSBBulk
                             deviceOfOperationState:DeviceOfOperationStateUSBBulk].dataBuffer device:usbObject];
    } else {
        WDLog(LOG_MODUL_BLE, @"sendGetEncipherSerialNumAddr 发送失败！");
    }
}

- (void)sendCheckBulkSerialNumValidtyCmd:(DeviceObject *)usbObject writeBufferData:(uint8_t *)writeBufferData {
    WDLog(LOG_MODUL_BLE, @"开始校验USB Bulk的序列号有效性");
    
    NSMutableData *sendData = [NSMutableData data];
    [sendData appendData:[CommonUtil hexToBytes:@"A55A6F66"]];
    // 一个十六进制(0x02)拆分为两个ACSII 字节(0和2)(0x30对应十六进制的高位 0，0x32对应十六位低位 2)
    [sendData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // CmdIndex：这个是USB Bulk的协议指令，相当于蓝牙里面的 6F
    [sendData appendBytes:[@"7" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [sendData appendBytes:writeBufferData length:64];

    unsigned int intValue = 0;
    for (int i = 0; i < 36; i++) {
        [sendData appendBytes:&intValue length:1];
    }

    [sendData appendBytes:&intValue length:1]; // 校验码位

    Byte *sendBytes = (Byte *)[sendData bytes];
    [CommonUtil calXortmpForSendBuffer:sendBytes len:sendData.length];

    sendData = [NSData dataWithBytes:sendBytes length:sendData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;

    sendBytes = (Byte *)[[sendData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [self writeBuffer:[self getSendDataByBuffer:sendBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:2
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStateUSBBulk
                         deviceOfOperationState:DeviceOfOperationStateUSBBulk].dataBuffer device:usbObject];

    if (kr == kIOReturnSuccess) {
        loc += len;
        len = (uint)sendData.length - loc;
        sendBytes = (Byte *)[[sendData subdataWithRange:NSMakeRange(loc, len)] bytes];
        [self writeBuffer:[self getSendDataByBuffer:sendBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:2
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStateUSBBulk
                             deviceOfOperationState:DeviceOfOperationStateUSBBulk].dataBuffer device:usbObject];
    } else {
        WDLog(LOG_MODUL_BLE, @"sendCheckBulkSerialNumValidtyCmd 发送失败！");
    }
}

- (void)sendReadUSBBulkAndClearCacheCmd:(DeviceObject *)usbObject readUSBBulk:(int)enable {
    WDLog(LOG_MODUL_BLE, @"开始%@USB Bulk并清空缓存", enable == 1 ? @"激活" : enable == 2 ? @"禁用" : @"保留");
    
    NSMutableData *sendData = [NSMutableData data];
    [sendData appendData:[CommonUtil hexToBytes:@"A55A6F66"]];
    // 一个十六进制(0x02)拆分为两个ACSII 字节(0和2)(0x30对应十六进制的高位 0，0x32对应十六位低位 2)
    [sendData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // CmdIndex：这个是USB Bulk的协议指令，相当于蓝牙里面的 6F
    [sendData appendBytes:[@"4" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [sendData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [sendData appendBytes:[enable == 1 ? @"1" : enable == 2 ? @"2" : @"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [sendData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [sendData appendBytes:[@"1" cStringUsingEncoding:NSUTF8StringEncoding] length:1];

    unsigned int intValue = 0;
    for (int i = 0; i < 96; i++) {
        [sendData appendBytes:&intValue length:1];
    }

    [sendData appendBytes:&intValue length:1]; // 校验码位

    Byte *sendBytes = (Byte *)[sendData bytes];
    [CommonUtil calXortmpForSendBuffer:sendBytes len:sendData.length];

    sendData = [NSData dataWithBytes:sendBytes length:sendData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;

    sendBytes = (Byte *)[[sendData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [self writeBuffer:[self getSendDataByBuffer:sendBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:2
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStateUSBBulk
                         deviceOfOperationState:DeviceOfOperationStateUSBBulk].dataBuffer device:usbObject];

    if (kr == kIOReturnSuccess) {
        loc += len;
        len = (uint)sendData.length - loc;
        sendBytes = (Byte *)[[sendData subdataWithRange:NSMakeRange(loc, len)] bytes];
        [self writeBuffer:[self getSendDataByBuffer:sendBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:2
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStateUSBBulk
                             deviceOfOperationState:DeviceOfOperationStateUSBBulk].dataBuffer device:usbObject];
    } else {
        WDLog(LOG_MODUL_BLE, @"sendReadUSBBulkAndClearCacheCmd 发送失败！");
    }
}

- (void)sendReadUSBBleConnectStateCmd:(DeviceObject *)usbObject {
    WDLog(LOG_MODUL_BLE, @"开始读取USB Ble连接状态");
    
    NSMutableData *sendData = [NSMutableData data];
    [sendData appendData:[CommonUtil hexToBytes:@"A55A6F66"]];
    // 一个十六进制(0x02)拆分为两个ACSII 字节(0和2)(0x30对应十六进制的高位 0，0x32对应十六位低位 2)
    [sendData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1]; // CmdIndex：这个是USB Bulk的协议指令，相当于蓝牙里面的 6F
    [sendData appendBytes:[@"5" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [sendData appendBytes:[@"0" cStringUsingEncoding:NSUTF8StringEncoding] length:1];
    [sendData appendBytes:[@"1" cStringUsingEncoding:NSUTF8StringEncoding] length:1];

    unsigned int intValue = 0;
    for (int i = 0; i < 98; i++) {
        [sendData appendBytes:&intValue length:1];
    }

    [sendData appendBytes:&intValue length:1]; // 校验码位

    Byte *sendBytes = (Byte *)[sendData bytes];
    [CommonUtil calXortmpForSendBuffer:sendBytes len:sendData.length];

    sendData = [NSData dataWithBytes:sendBytes length:sendData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;

    sendBytes = (Byte *)[[sendData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [self writeBuffer:[self getSendDataByBuffer:sendBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:2
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStateUSBBulk
                         deviceOfOperationState:DeviceOfOperationStateUSBBulk].dataBuffer device:usbObject];

    if (kr == kIOReturnSuccess) {
        loc += len;
        len = (uint)sendData.length - loc;
        sendBytes = (Byte *)[[sendData subdataWithRange:NSMakeRange(loc, len)] bytes];
        [self writeBuffer:[self getSendDataByBuffer:sendBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:2
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStateUSBBulk
                             deviceOfOperationState:DeviceOfOperationStateUSBBulk].dataBuffer device:usbObject];
    } else {
        WDLog(LOG_MODUL_BLE, @"sendReadUSBBulkAndClearCacheCmd 发送失败！");
    }
}

@end
