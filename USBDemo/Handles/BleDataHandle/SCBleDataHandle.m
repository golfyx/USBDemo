//
//  BleDataHandle.m
//  USBDemo
//
//  Created by golfy on 2021/11/19.
//

#import "SCBleDataHandle.h"
#import "SCBulkDataHandle.h"
#import "SCAppVaribleHandle.h"
#import "SCSaveDataToFileHandle.h"
#import "SCRequestHandle.h"
#import "SCUploadDataInfo.h"
#import "CommonUtil.h"
#import "UserInfoCrcCheck.h"
#import "WDLog.h"


@interface SCBleDataHandle ()<SCBulkDataHandleDelegate>

///  传输类型
@property (nonatomic, assign) int transportType;
///  页数据发送到手机速度
@property (nonatomic, assign) int sendSpeed;

@property (nonatomic, strong) NSLock *fileLock;


@end

@implementation SCBleDataHandle


+ (instancetype)sharedManager {
    
    static SCBleDataHandle * manager = nil;
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
        _transportType = 1;
        _sendSpeed = 0;
        _isReadingAllBlock = NO;
        
        _isHexadecimalDisplay = NO;
        _isDeleteECGData = YES;
        _isReadingAllBlock = NO;
        _isReadingAllBlock = NO;
        
        _isExitReadMode = NO;
        
        _fileLock = [[NSLock alloc] init];
        
        [SCBulkDataHandle sharedManager].delegate = self;
    }
    return self;
}

/// 获取Dongle版本
- (void)getDongleVersion:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"获取硬件版本号");
    
    const int len = 5;
    uint8_t buffer[len] = {0xa5,0x5a,0x70,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

/// 获取序列号
- (void)getDongleSerialNumber:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"获取序列号");
    
    const int len = 6;
    uint8_t buffer[len] = {0xa5,0x5a,0x75,0x01,0x03,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

/// 进入读取模式
- (void)enterReadMode:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"进入读取模式");
    
    const int len = 7;
    uint8_t buffer[len] = {0xa5,0x5a,0x60,0x02,0x03,0x7f-0x03,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}
/// 退出读取模式
- (void)exitReadMode:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"退出读取模式");
    
    self.isExitReadMode = YES;
    // 设置激活或者停止设备命令，也就是相当于设置退出读取模式
    [self setDongleActive:0x02 device:pDev];
}

- (void)getEcgDataBlockCount:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"获取设备数据块");
    
    const int len = 5;
    UInt8 buffer[len] = {0xa5,0x5a,0x43,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

- (void)getEcgDataBlockDetailWithPageIndex:(int)pageIndex internalIndex:(int)internalIndex device:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"获取设备数据详情");
    
    const int len = 8;
    UInt8 pageindexlow = pageIndex & 0xff;
    UInt8 pageindexhigh = (pageIndex >> 8) & 0xff;
    UInt8 buffer[len] = {0xa5,0x5a,0x44,0x03,pageindexlow,pageindexhigh,internalIndex,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

- (void)getEcgDataBlockContentWithStartPageIndex:(int)startPageIndex endPageIndex:(int)endPageIndex internalIndex:(int)internalIndex device:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"获取设备数据页内容");
    
    const int len = 14;
    
    UInt8 startPageindexlow = startPageIndex & 0x7f;
    UInt8 startPageindexmid = (startPageIndex >> 7) & 0x7f;
    UInt8 startPageindexhigh = (startPageIndex >> 14) & 0x7f;
    
    UInt8 endPageIndexlow = endPageIndex & 0x7f;
    UInt8 endPageIndexmid = (endPageIndex >> 7) & 0x7f;
    UInt8 endPageIndexhigh = (endPageIndex >> 14) & 0x7f;
    UInt8 buffer[len] = {0xa5,0x5a,0x45,0x09,_transportType,
        startPageindexlow,startPageindexmid,startPageindexhigh,
        endPageIndexlow,endPageIndexmid,endPageIndexhigh,
        _sendSpeed,internalIndex,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

/// 读取Dongle当前状态
- (void)getDongleActiveType:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"读取设备当前状态");
    
    const int len = 5;
    uint8_t buffer[len] = {0xa5,0x5a,0x61,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

/// 设置Dongle时间
- (void)setDongleTime:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"设置设备时间");
    
    const int len = 9;
    NSDate *datenow = [NSDate date];
    long long _timesp = [datenow timeIntervalSince1970] * 1000;
    SCAppVaribleHandleInstance.startRecordTimestamp = _timesp; // 服务器的开始时间以毫秒为单位
    _timesp /= 1000; // 设备的开始时间以秒为单位
    uint8_t buffer[len] = {0xa5,0x5a,0x51,0x04,_timesp&0xff,(_timesp >> 8)&0xff,(_timesp >> 16)&0xff,(_timesp >> 24)&0xff,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

/// 激活Dongle
- (void)setDongleActive:(UInt8)command device:(DeviceObject *)pDev {
    const int len = 7;
    uint8_t buffer[len] = {0xa5,0x5a,0x60,0x02,command,0x7f-command,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

/// 获取当前保存状态
- (void)getSaveEcgModelCmd:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"获取当前保存状态");
    
    const int len = 5;
    UInt8 buffer[len] = {0xa5,0x5a,0x62,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

/// 设置当前状态(保存模式和擦除模式)
- (void)setDeviceSaveEcgModelTypeCmd:(UInt8)command device:(DeviceObject *)pDev {
    const int len = 7;
    UInt8 buffer[len] = {0xa5,0x5a,0x63,0x02,command,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
}

/// 设置当前测量的用户信息(姓名手机号等)
- (IOReturn)setDeviceSaveUserInfo:(DeviceObject *)pDev {
    WDLog(LOG_MODUL_BLE, @"设置当前测量的用户信息");
    
    NSMutableData *userInfoData = [NSMutableData data];
    [userInfoData appendData:[CommonUtil hexToBytes:@"A55A44830000"]];
    [userInfoData appendData:[CommonUtil hexToBytes:@"11"]];  // bit4 = 0 表示读取信息   bit4 = 1 表示写入信息
    
    SAVE_BLK_DETAILED_INFOR saveBulkDetailedInfor;
    NSMutableData *phoneData = [NSMutableData data];
    [phoneData appendBytes:[SCAppVaribleHandleInstance.userInfoModel.name cStringUsingEncoding:NSUTF8StringEncoding] length:SAVE_DATA_NAME_LEN];
    [phoneData appendBytes:[SCAppVaribleHandleInstance.userInfoModel.phoneNum cStringUsingEncoding:NSUTF8StringEncoding] length:SAVE_DATA_PHONE_LEN];
    [phoneData appendBytes:[[NSString stringWithFormat:@"%lu",(unsigned long)SCAppVaribleHandleInstance.userInfoModel.genderType] cStringUsingEncoding:NSUTF8StringEncoding] length:SAVE_DATA_GENDER_LEN];
    NSString *ageStr = [CommonUtil calAgeByBirthday:SCAppVaribleHandleInstance.userInfoModel.birthday];
    ageStr = [ageStr substringToIndex:ageStr.length - 1];
    [phoneData appendBytes:[ageStr cStringUsingEncoding:NSUTF8StringEncoding] length:SAVE_DATA_AGE_LEN];
    [phoneData appendBytes:[SCAppVaribleHandleInstance.userInfoModel.height cStringUsingEncoding:NSUTF8StringEncoding] length:SAVE_DATA_HEIGHT_LEN];
    [phoneData appendBytes:[SCAppVaribleHandleInstance.userInfoModel.weight cStringUsingEncoding:NSUTF8StringEncoding] length:SAVE_DATA_WEIGHT_LEN];
    
    NSUInteger phoneLen = phoneData.length; // 这样设置是为了防止动态变化长度
    
    if (phoneLen <= VALID_SAVE_DATA_PROPERTY_LENGTH) {
        for (int i = 0; i < VALID_SAVE_DATA_PROPERTY_LENGTH - phoneLen; i++) {
            [phoneData appendData:[CommonUtil hexToBytes:@"00"]];
        }
    } else {
        phoneData = [phoneData subdataWithRange:NSMakeRange(0, VALID_SAVE_DATA_PROPERTY_LENGTH)].mutableCopy;
    }
    
    memcpy(saveBulkDetailedInfor.Buffer, [phoneData bytes], VALID_SAVE_DATA_PROPERTY_LENGTH);
    
    // 将用户信息进行(网络版CRC)校验
    MakeCrc32Table();
    saveBulkDetailedInfor.DetailedContent.BagCrc = CalcCrc32((Byte *)phoneData.bytes, VALID_SAVE_DATA_PROPERTY_LENGTH);
    
    phoneData = [NSData dataWithBytes:saveBulkDetailedInfor.Buffer length:SAVE_DATA_PROPERTY_LEN].mutableCopy;
    [userInfoData appendData:phoneData];
    [userInfoData appendData:[CommonUtil hexToBytes:@"00"]];
    
    Byte *userInfoBytes = (Byte *)[userInfoData bytes];
    [CommonUtil calXortmpForSendBuffer:userInfoBytes len:userInfoData.length];
    
    userInfoData = [NSData dataWithBytes:userInfoBytes length:userInfoData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;
    
    userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:userInfoBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:3
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
    
    if (kr == kIOReturnSuccess) {
        loc += len;
        len = 60;
        userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
        kr = [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:userInfoBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:3
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
        if (kr == kIOReturnSuccess) {
            loc += len;
            len = (uint)userInfoData.length - loc;
            userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
            [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:userInfoBytes
                                                 bufLen:len
                                               bagIndex:2
                                          totalBagCount:3
                            packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                                 objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer device:pDev];
        } else {
            WDLog(LOG_MODUL_BLE, @"setDeviceSaveUserInfo 发送失败！");
        }
    } else {
        WDLog(LOG_MODUL_BLE, @"setDeviceSaveUserInfo 发送失败！");
    }
    
    return kr;
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
    
    
    for (int i = 0; i < 96; i++) {
        [userInfoData appendData:[CommonUtil hexToBytes:@"00"]];
    }
    
    [userInfoData appendData:[CommonUtil hexToBytes:@"00"]]; // 校验码位
    
    Byte *userInfoBytes = (Byte *)[userInfoData bytes];
    [CommonUtil calXortmpForSendBuffer:userInfoBytes len:userInfoData.length];
    
    userInfoData = [NSData dataWithBytes:userInfoBytes length:userInfoData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;
    
    userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:userInfoBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:2
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStateUSBBulk].dataBuffer device:pDev];
    
    if (kr == kIOReturnSuccess) {
        loc += len;
        len = (uint)userInfoData.length - loc;
        userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
        [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:userInfoBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:2
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStateUSBBulk].dataBuffer device:pDev];
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
    
    for (int i = 0; i < 98; i++) {
        [userInfoData appendData:[CommonUtil hexToBytes:@"00"]];
    }
    
    [userInfoData appendData:[CommonUtil hexToBytes:@"00"]]; // 校验码位
    
    Byte *userInfoBytes = (Byte *)[userInfoData bytes];
    [CommonUtil calXortmpForSendBuffer:userInfoBytes len:userInfoData.length];
    
    userInfoData = [NSData dataWithBytes:userInfoBytes length:userInfoData.length].mutableCopy;
    
    uint loc = 0;
    uint len = 52;
    
    userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
    kern_return_t kr = [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:userInfoBytes
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:2
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStateUSBBulk].dataBuffer device:pDev];
    
    if (kr == kIOReturnSuccess) {
        loc += len;
        len = (uint)userInfoData.length - loc;
        userInfoBytes = (Byte *)[[userInfoData subdataWithRange:NSMakeRange(loc, len)] bytes];
        [[SCBulkDataHandle sharedManager] writeBuffer:[[SCBulkDataHandle sharedManager] getSendDataByBuffer:userInfoBytes
                                             bufLen:len
                                           bagIndex:1
                                      totalBagCount:2
                        packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                             objectOfOperationState:ObjectOfOperationStateUSBBulk].dataBuffer device:pDev];
    } else {
        WDLog(LOG_MODUL_BLE, @"disconnectBleDevice 发送失败！");
    }
    
    return kr;
}


// MARK: SCBulkDataHandleDelegate
- (void)didReceiveBulkDataDevice:(DeviceObject *)pDev readBuffer:(unsigned char *)readBuffer {
    
    BULK_BUFFER_PACKET bulkBufferPacket;
    memcpy(bulkBufferPacket.dataBuffer, readBuffer, TG_CMD_BUFFER_LEN);
    
    SCMultiDeviceInfo *deviceInfo;
    for (SCMultiDeviceInfo *item in SCAppVaribleHandleInstance.multiDeviceInfo) {
        if (pDev.locationID == item.deviceObject.locationID) {
            deviceInfo = item;
            break;
        }
    }
    if (!deviceInfo) {
        deviceInfo = [[SCMultiDeviceInfo alloc] init];
        deviceInfo.deviceObject = pDev;
        [SCAppVaribleHandleInstance.multiDeviceInfo addObject:deviceInfo];
    }
    
    deviceInfo.type = readBuffer[0];
    deviceInfo.bagIndex = readBuffer[1];
    deviceInfo.bagContentLen = readBuffer[2];
    deviceInfo.checkSum = readBuffer[3];
    
    deviceInfo.bagCount = deviceInfo.type & 0x7;
    deviceInfo.oooState = (deviceInfo.type >> 6) & 0x1;
    deviceInfo.psrState = (deviceInfo.type >> 7) & 0x1;
    
    Byte *pageBytes;
    if (deviceInfo.bagIndex == 0) {
        deviceInfo.receiveMStr = [[NSMutableString alloc] init];
        deviceInfo.bleCmdType = readBuffer[14];
    }
    
    if ((self.isHexadecimalDisplay) && (ObjectOfOperationStatePassthrough == deviceInfo.oooState)) {
        for (int i = 4; i < TG_CMD_BUFFER_LEN; i+=2) {
            [deviceInfo.receiveMStr appendFormat:@"%02X%02X", readBuffer[i], readBuffer[i+1]];
        }
    } else {
        for (int i = 4; i < TG_CMD_BUFFER_LEN; i++) {
            [deviceInfo.receiveMStr appendFormat:@"%c", readBuffer[i]];
        }
    }
    
    if (deviceInfo.bagCount - 1 == deviceInfo.bagIndex) { // 判断是否是最后一个包
        
        if (0x14100000 == deviceInfo.deviceObject.locationID) {
            deviceInfo.receiveMStr = [NSMutableString stringWithFormat:@"左接0：%@\n", deviceInfo.receiveMStr];
        } else if (0x14110000 == deviceInfo.deviceObject.locationID) {
            deviceInfo.receiveMStr = [NSMutableString stringWithFormat:@"左接1：%@\n", deviceInfo.receiveMStr];
        } else if (0x14120000 == deviceInfo.deviceObject.locationID) {
            deviceInfo.receiveMStr = [NSMutableString stringWithFormat:@"左接2：%@\n", deviceInfo.receiveMStr];
        } else if (0x14130000 == deviceInfo.deviceObject.locationID) {
            deviceInfo.receiveMStr = [NSMutableString stringWithFormat:@"左接3：%@\n", deviceInfo.receiveMStr];
        } else if (0x14200000 == deviceInfo.deviceObject.locationID) {
            deviceInfo.receiveMStr = [NSMutableString stringWithFormat:@"右接0：%@\n", deviceInfo.receiveMStr];
        } else if (0x14210000 == deviceInfo.deviceObject.locationID) {
            deviceInfo.receiveMStr = [NSMutableString stringWithFormat:@"右接1：%@\n", deviceInfo.receiveMStr];
        } else if (0x14220000 == deviceInfo.deviceObject.locationID) {
            deviceInfo.receiveMStr = [NSMutableString stringWithFormat:@"右接2：%@\n", deviceInfo.receiveMStr];
        } else if (0x14230000 == deviceInfo.deviceObject.locationID) {
            deviceInfo.receiveMStr = [NSMutableString stringWithFormat:@"右接3：%@\n", deviceInfo.receiveMStr];
        }
        
        if ([self.delegate respondsToSelector:@selector(didReceiveBleDisplayString:)]) {
            [self.delegate didReceiveBleDisplayString:deviceInfo.receiveMStr];
        }
    }
    
    
    if (ObjectOfOperationStateUSBBulk == deviceInfo.oooState) {
        return;
    }


    if (deviceInfo.bleCmdType == 0x40) {  //  获取Dongle电量和内存
        if ([self.delegate respondsToSelector:@selector(didReceiveBleBattery:storage:)]) {
            [self.delegate didReceiveBleBattery:bulkBufferPacket.bulkBasePacket.dataBuffer[12] storage:100 - bulkBufferPacket.bulkBasePacket.dataBuffer[13]];
        }
    } else if (deviceInfo.bleCmdType == 0x70) {  //  获取Dongle版本
        WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);
        //ASCII to NSStrings
        NSString *versionStr = @"";
        int bufLen = bulkBufferPacket.bulkBasePacket.dataBuffer[12];
        for (int i = 13; i < bufLen + 13; i++) {
            if (bulkBufferPacket.bulkBasePacket.dataBuffer[i] != 0x00) {
                versionStr = [NSString stringWithFormat:@"%@%c", versionStr, bulkBufferPacket.bulkBasePacket.dataBuffer[i]]; //A
            }
        }

        if ([self.delegate respondsToSelector:@selector(didReceiveBleVersion:)]) {
            [self.delegate didReceiveBleVersion:versionStr];
        }

    } else if (deviceInfo.bleCmdType == 0x43) {  //  获取块的个数
        WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);
        
        deviceInfo.blockCount = ((int)bulkBufferPacket.bulkBasePacket.dataBuffer[13] << 8) | (int)bulkBufferPacket.bulkBasePacket.dataBuffer[12];

        if ([self.delegate respondsToSelector:@selector(didReceiveBleECGDataBlockCount:deviceInfo:)]) {
            [self.delegate didReceiveBleECGDataBlockCount:deviceInfo.blockCount deviceInfo:deviceInfo];
        }

        if (!_isReadingAllBlock) {
            return;
        }

        if (deviceInfo.blockCount > 0) {
            [deviceInfo.allBlockInfo.allBlockInfoArray removeAllObjects];
            deviceInfo.curBlockIndex = 0;

            [self getEcgDataBlockDetailWithPageIndex:0 internalIndex:0 device:pDev];
        } else {
            WDLog(LOG_MODUL_BLE, @"当前没有可读取的包");
        }

    } else if (deviceInfo.bleCmdType == 0x44) {  //  获取块的信息
        
        if (deviceInfo.bagIndex == 0) {
            deviceInfo.curBlockIndex = ((int)bulkBufferPacket.bulkBasePacket.dataBuffer[13] << 8) | (int)bulkBufferPacket.bulkBasePacket.dataBuffer[12];
            deviceInfo.readBlockInternalIndex = (int)bulkBufferPacket.bulkBasePacket.dataBuffer[14];
            deviceInfo.perBagData = [NSData dataWithBytes:bulkBufferPacket.bulkBasePacket.dataBuffer length:TG_CMD_DATA_BUFFER_LEN].mutableCopy;
        } else {
            [deviceInfo.perBagData appendData:[NSData dataWithBytes:bulkBufferPacket.bulkBasePacket.dataBuffer length:TG_CMD_DATA_BUFFER_LEN]];
        }

        if (deviceInfo.bagCount - 1 == deviceInfo.bagIndex) { // 判断是否是最后一个包
            WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);

            int tmpInternalIndex = (deviceInfo.readBlockInternalIndex & 0xF); // 判断是第几块
            int isReadUserInfo = (deviceInfo.readBlockInternalIndex & 0x10);  // 判断是读取还是写入
            if (tmpInternalIndex == 1) { // 第1块是保存的读取用户信息

                if (isReadUserInfo == 0) {
                    if (SCAppVaribleHandleInstance.isReadBlockUserInfo) {
                        
                        SAVE_BULK_USER_INFO saveBulkUserInfo;
                        memcpy(saveBulkUserInfo.dataBuffer, (Byte *)[[deviceInfo.perBagData subdataWithRange:NSMakeRange(15, SAVE_BULK_USER_INFO_LEN)] bytes], SAVE_BULK_USER_INFO_LEN);
                        
                        NSString *name = [NSString stringWithCString:(char *)saveBulkUserInfo.bulkBaseUserInfo.DataName encoding:NSUTF8StringEncoding];
                        NSString *phone = [NSString stringWithCString:(char *)saveBulkUserInfo.bulkBaseUserInfo.DataPhone encoding:NSUTF8StringEncoding];
                        NSString *gender = [NSString stringWithCString:(char *)saveBulkUserInfo.bulkBaseUserInfo.DataGender encoding:NSUTF8StringEncoding];
                        NSString *age = [NSString stringWithCString:(char *)saveBulkUserInfo.bulkBaseUserInfo.DataAge encoding:NSUTF8StringEncoding];
                        NSString *height = [NSString stringWithCString:(char *)saveBulkUserInfo.bulkBaseUserInfo.DataHeight encoding:NSUTF8StringEncoding];
                        NSString *weight = [NSString stringWithCString:(char *)saveBulkUserInfo.bulkBaseUserInfo.DataWeight encoding:NSUTF8StringEncoding];
                        
                        SCUserInfoModel *userInfoModel = SCAppVaribleHandleInstance.userInfoModel;
                        userInfoModel.phoneNum = phone;
                        userInfoModel.name = name;
                        userInfoModel.genderType = [gender intValue];
                        userInfoModel.birthday = [CommonUtil calBirthdayByAge:age];
                        userInfoModel.height = height;
                        userInfoModel.weight = weight;
                        SCAppVaribleHandleInstance.userInfoModel = userInfoModel;
                        deviceInfo.userInfoModel = userInfoModel;
                        WDLog(LOG_MODUL_BLE, @"读取到的用户信息: 手机号 %@，姓名 %@",phone, name);
                        
                        if ([self.delegate respondsToSelector:@selector(didReceiveBleEcgDataBlockUserInfo:)]) {
                            [self.delegate didReceiveBleEcgDataBlockUserInfo:deviceInfo];
                        }
                        
                    } else {
                        WDLog(LOG_MODUL_BLE, @"保存用户信息成功!");
                    }
                    
                } else {
                    WDLog(LOG_MODUL_BLE, @"保存用户信息成功!");
                }

            } else if (tmpInternalIndex == 0) {// 第0块是块的基本信息
                        
                SAVE_DATA_HEAD saveDataHead;
                memcpy(saveDataHead.HeadBuffer,
                       [deviceInfo.perBagData subdataWithRange:NSMakeRange(15, HEAD_BUFFER_LEN)].bytes,
                       HEAD_BUFFER_LEN);

                deviceInfo.curBlockInfo = [SCDeviceBlockInfo infoWithBlockIndex:deviceInfo.curBlockIndex start_timestamp:saveDataHead.DataHead.StartTimeStamp end_timestamp:saveDataHead.DataHead.EndTimeStamp saved_datalen:saveDataHead.DataHead.SaveDataLen startpageIndex:saveDataHead.DataHead.BeginPageIndex endpageIndex:saveDataHead.DataHead.EndPageIndex];
                deviceInfo.curBlockInfo.deviceSerialNumber = [NSString stringWithCString:(char *)saveDataHead.DataHead.IdNumberBuf encoding:(NSUTF8StringEncoding)];
                NSString *deviceMacAddress;
                for (int i = 0; i < MAC_LEN; i++) {
                    if (i == 0) {
                        deviceMacAddress = [NSString stringWithFormat:@"%02X", saveDataHead.DataHead.MacAddr[i]];
                    } else {
                        deviceMacAddress = [NSString stringWithFormat:@"%@:%02X", deviceMacAddress, saveDataHead.DataHead.MacAddr[i]];
                    }
                }
                deviceInfo.curBlockInfo.deviceMacAddress = deviceMacAddress;
                deviceInfo.curBlockInfo.samplingRate = saveDataHead.DataHead.SampleRate;
                deviceInfo.curBlockInfo.leadCount = saveDataHead.DataHead.LeadCnt;
                deviceInfo.curBlockInfo.leadTpye = saveDataHead.DataHead.LeadType;
                deviceInfo.curBlockInfo.userId = [NSString stringWithCString:(char *)saveDataHead.DataHead.UserIDStrBuf encoding:(NSUTF8StringEncoding)];
                deviceInfo.curBlockInfo.onlyFlag = [NSString stringWithCString:(char *)saveDataHead.DataHead.SaveDataOnlyFlagBuf encoding:(NSUTF8StringEncoding)];


                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:deviceInfo.curBlockInfo.start_timestamp];
                WDLog(LOG_MODUL_BLE, @"当前块信息, bagIndex = %d, start_timestamp = %u, saved_datalen = %d, startpageIndex = %d, endpageIndex = %d", deviceInfo.curBlockIndex, saveDataHead.DataHead.StartTimeStamp, saveDataHead.DataHead.SaveDataLen, saveDataHead.DataHead.BeginPageIndex, saveDataHead.DataHead.EndPageIndex);
                if ([self.delegate respondsToSelector:@selector(didReceiveBleEcgDataBlockDetail:)]) {
                    [self.delegate didReceiveBleEcgDataBlockDetail:[NSString stringWithFormat:@"当前块信息:\n当前是第几块 = %d, 开始测量时间 = %@  \n设备序列号 = %@, 设备Mac地址 = %@ \n当前块的数据长度 = %d, \n开始页的序号 = %d, 结束页的序号 = %d", deviceInfo.curBlockIndex + 1, [dateFormatter stringFromDate:tmpStartDate], deviceInfo.curBlockInfo.deviceSerialNumber, deviceInfo.curBlockInfo.deviceMacAddress, deviceInfo.curBlockInfo.saved_datalen, deviceInfo.curBlockInfo.startpageIndex, deviceInfo.curBlockInfo.endpageIndex]];
                }

                deviceInfo.curBlockInfo.buffer = deviceInfo.perBagData;
                [deviceInfo.allBlockInfo.allBlockInfoArray addObject:deviceInfo.curBlockInfo];

                if (!_isReadingAllBlock) {
                    return;
                }

                if (deviceInfo.curBlockIndex == 0) {
                    deviceInfo.start_timestamp = deviceInfo.curBlockInfo.start_timestamp; // 保存第一块的开始时间作为测量开始时间
                }
                
                // 判断继续获取下一块数据
                UInt16 nextBlockIndex = deviceInfo.curBlockIndex + 1;
                if (nextBlockIndex < deviceInfo.blockCount)
                {
                    [self getEcgDataBlockDetailWithPageIndex:nextBlockIndex internalIndex:0 device:pDev];
                } else {

                    deviceInfo.end_timestamp = deviceInfo.curBlockInfo.end_timestamp; // 保存最后一块的结束时间作为测量结束时间
                    if ([self.delegate respondsToSelector:@selector(didStartUploadFirstBlockData:)]) {
                        [self.delegate didStartUploadFirstBlockData:deviceInfo];
                    }
                    
                    if (!self.isNeedUploadData || (SCAppVaribleHandleInstance.detectionInfo.dataIndex == 0 && SCAppVaribleHandleInstance.detectionInfo.dataPageIndex == 0)) {
                        deviceInfo.curBlockIndex = 0;
                        deviceInfo.rawDataHexadecimalStr = [NSMutableString string];
                        [deviceInfo clearFileCache];
                        
                        deviceInfo.curBlockInfo = deviceInfo.allBlockInfo.allBlockInfoArray[deviceInfo.curBlockIndex];
                    } else if (SCAppVaribleHandleInstance.detectionInfo.dataIndex == deviceInfo.blockCount - 1) {
                        if (SCAppVaribleHandleInstance.detectionInfo.dataPageIndex == deviceInfo.curBlockInfo.endpageIndex) {
                            // 完成数据上传到服务器
                            if ([self.delegate respondsToSelector:@selector(didFinishUploadBlockData:)]) {
                                [self.delegate didFinishUploadBlockData:deviceInfo];
                            }
                            
                            if (self.isDeleteECGData) {  // 是否需要删除数据
                                WDLog(LOG_MODUL_BLE, @"设置删除数据");
                                [self setDeviceSaveEcgModelTypeCmd:0x04 device:pDev];
                            }

                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self exitReadMode:pDev];
                            });

                            @synchronized (_fileLock) {
                                [SCSaveDataToFileHandle sharedManager].deviceInfo = deviceInfo;
                                [[SCSaveDataToFileHandle sharedManager] saveMergedBleDataFilePath];
                            }
                            
                            return;
                        } else {
                            deviceInfo.curBlockIndex = SCAppVaribleHandleInstance.detectionInfo.dataIndex + 1;
                            deviceInfo.curBlockInfo = deviceInfo.allBlockInfo.allBlockInfoArray[deviceInfo.curBlockIndex];
                            deviceInfo.curBlockInfo.startpageIndex = SCAppVaribleHandleInstance.detectionInfo.dataPageIndex + 1;
                            deviceInfo.curUploadBlockIndex = deviceInfo.curBlockIndex + 1;
                        }
                    } else {
                        deviceInfo.curBlockIndex = SCAppVaribleHandleInstance.detectionInfo.dataIndex + 1;
                        deviceInfo.curBlockInfo = deviceInfo.allBlockInfo.allBlockInfoArray[deviceInfo.curBlockIndex];
                        deviceInfo.curBlockInfo.startpageIndex = SCAppVaribleHandleInstance.detectionInfo.dataPageIndex + 1;
                        deviceInfo.curUploadBlockIndex = deviceInfo.curBlockIndex + 1;
                    }
                    
                    // 开始读取块的内容
                    [self startAcceptNextIntervalPageData:deviceInfo device:pDev];
                    
                }
            }
            
        }

    } else if (deviceInfo.bleCmdType == 0x45) {  //  获取块的内容

        if (deviceInfo.bagIndex == 0) {
            int preCharLen = 16; // 前面有多少个字节，然后后面从0开始计算
            deviceInfo.pageIndex = ((int)readBuffer[2 + preCharLen] << 14)|((int)readBuffer[1 + preCharLen] << 7)|(int)readBuffer[0 + preCharLen];
            deviceInfo.readPageInternalIndex = readBuffer[3 + preCharLen];
            deviceInfo.readDataLen = readBuffer[4 + preCharLen];

            deviceInfo.perBagData = [[NSData dataWithBytes:readBuffer length:TG_CMD_BUFFER_LEN] subdataWithRange:NSMakeRange(12, TG_CMD_BUFFER_LEN - 12)].mutableCopy;
        } else {
            [deviceInfo.perBagData appendData:[[NSData dataWithBytes:readBuffer length:TG_CMD_BUFFER_LEN] subdataWithRange:NSMakeRange(4, TG_CMD_BUFFER_LEN - 4)]];
        }

        if (deviceInfo.bagCount - 1 == deviceInfo.bagIndex) { // 判断是否是最后一个包
            WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);

            int tmpPageIndex = deviceInfo.pageIndex - deviceInfo.curBlockInfo.startpageIndex;
            if (tmpPageIndex < 0) {
                tmpPageIndex = 0;
            }

            NSData *tmpData;
            if (deviceInfo.readPageInternalIndex == 10) {
                tmpData = [deviceInfo.perBagData subdataWithRange:NSMakeRange(9, 0x60)];
            } else {
                if (deviceInfo.perBagData.length <= deviceInfo.readDataLen) {
                    return;
                }
                tmpData = [deviceInfo.perBagData subdataWithRange:NSMakeRange(9, deviceInfo.readDataLen)];
            }

            pageBytes = (Byte *)[tmpData bytes];
            for (int i = 0; i < tmpData.length; i++) {
                [deviceInfo.rawDataHexadecimalStr appendFormat:@"%02X", pageBytes[i]];
            }

            // 1536 压缩后一页总长度  2048 压缩前一页的总长度
            // 将页的内容保存进数组
            deviceInfo.responsePageDataArray[tmpPageIndex][deviceInfo.readPageInternalIndex] = tmpData;

            double curPageProgress = deviceInfo.pageIndex - deviceInfo.curBlockInfo.startpageIndex;
            double curBlockAllPage = deviceInfo.curBlockInfo.endpageIndex - deviceInfo.curBlockInfo.startpageIndex;

            if ([self.delegate respondsToSelector:@selector(didReceiveBleBlockProgress:blockProgressValue:)]) {
                [self.delegate didReceiveBleBlockProgress:(curPageProgress / curBlockAllPage) * 100 blockProgressValue:[NSString stringWithFormat:@"%d/%d", deviceInfo.curBlockIndex + 1, deviceInfo.blockCount]];
            }

            /// 如果接收到的区间页块大于区间结束值才进行读取下一页 并且 是一页的最后一段
            if (!(deviceInfo.curBlockInfo.endpageIndex == deviceInfo.pageIndex && deviceInfo.readPageInternalIndex == 10))
            {
                return;
            }


            if (deviceInfo.allBlockInfo.allBlockInfoArray.count <= 0) {
                return;
            }

            @synchronized (_fileLock) {
                [SCSaveDataToFileHandle sharedManager].deviceInfo = deviceInfo;
                // 将数据保存到本地文件
                [[SCSaveDataToFileHandle sharedManager] writeDataToFile];
            }

            if (_isNeedUploadData) {
                // 将数据上传到服务器
                if ([self.delegate respondsToSelector:@selector(didStartUploadBlockData:)]) {
                    [self.delegate didStartUploadBlockData:deviceInfo];
                }
            }

            if (!_isReadingAllBlock) {
                return;
            }

            // 判断是否是最后一块
            if (deviceInfo.curBlockIndex < deviceInfo.allBlockInfo.allBlockInfoArray.count - 1) {
                deviceInfo.curBlockIndex++;
                deviceInfo.rawDataHexadecimalStr = [NSMutableString string];

                deviceInfo.curBlockInfo = deviceInfo.allBlockInfo.allBlockInfoArray[deviceInfo.curBlockIndex];
                [self startAcceptNextIntervalPageData:deviceInfo device:pDev];
                
            } else {

                if (self.isDeleteECGData) {  // 是否需要删除数据
                    WDLog(LOG_MODUL_BLE, @"设置删除数据");
                    [self setDeviceSaveEcgModelTypeCmd:0x04 device:pDev];
                }

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self exitReadMode:pDev];
                });

                @synchronized (_fileLock) {
                    [SCSaveDataToFileHandle sharedManager].deviceInfo = deviceInfo;
                    [[SCSaveDataToFileHandle sharedManager] saveMergedBleDataFilePath];
                }
            }
        }

    } else if (deviceInfo.bleCmdType == 0x60) {  //  设备停止指令
        WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);
        
        int tmpbleCmdType = readBuffer[16];
        if (tmpbleCmdType == 0x02) {

            if (self.isExitReadMode) {
                self.isExitReadMode = NO;
                if ([self.delegate respondsToSelector:@selector(didReceiveBleReadingStatus:)]) {
                    [self.delegate didReceiveBleReadingStatus:ReadingStatusUnread];
                }
            } else {
                [self getSaveEcgModelCmd:pDev]; // 获取当前保存模式
            }

        } else if (tmpbleCmdType == 0x03) {

            if ([self.delegate respondsToSelector:@selector(didReceiveBleReadingStatus:)]) {
                [self.delegate didReceiveBleReadingStatus:ReadingStatusRead];
            }

        } else if (tmpbleCmdType == 0x01) {
            [self getSaveEcgModelCmd:pDev]; // 获取当前保存模式
        }
    } else if (deviceInfo.bleCmdType == 0x51) { // 时间误差在1s之内，认为设置成功
        WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);
        
        SCAppVaribleHandleInstance.isReadBlockUserInfo = NO;
        kern_return_t kr = [self setDeviceSaveUserInfo:pDev]; // 保存用户信息
        if (kIOReturnSuccess == kr) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                WDLog(LOG_MODUL_BLE, @"设置激活设备");
                [self setDongleActive:0x01 device:pDev]; // 激活设备
            });
        } else { // 如果失败了再试一次
            kr = [self setDeviceSaveUserInfo:pDev]; // 保存用户信息
            if (kIOReturnSuccess == kr) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    WDLog(LOG_MODUL_BLE, @"设置激活设备");
                    [self setDongleActive:0x01 device:pDev]; // 激活设备
                });
            }
        }
    } else if (deviceInfo.bleCmdType == 0x61) {
        WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);
        
        if ([self.delegate respondsToSelector:@selector(didReceiveBleActiveType:deviceInfo:)]) {
            [self.delegate didReceiveBleActiveType:readBuffer[16] & 0x7 deviceInfo:deviceInfo];
        }
    } else if (deviceInfo.bleCmdType == 0x62) {
        WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);
        
        int tmpbleCmdType = readBuffer[16];
        if (tmpbleCmdType == 0x02) { // 自动保存模式
            if (SCAppVaribleHandleInstance.isStopMeasure) {
                SCAppVaribleHandleInstance.isStopMeasure = NO;
                WDLog(LOG_MODUL_BLE, @"设置退出保存模式");
                [self setDeviceSaveEcgModelTypeCmd:0x02 device:pDev];
            } else {
                if ([self.delegate respondsToSelector:@selector(didReceiveBleAutoSave:)]) {
                    [self.delegate didReceiveBleAutoSave:deviceInfo];
                }
            }

        } else {
            if (SCAppVaribleHandleInstance.isStopMeasure) {
                SCAppVaribleHandleInstance.isStopMeasure = NO;
                
                self.isReadingUserInfoBlock = YES;
                [self getEcgDataBlockCount:pDev];
            } else {
                WDLog(LOG_MODUL_BLE, @"设置自动保存模式");
                [self setDeviceSaveEcgModelTypeCmd:0x03 device:pDev]; // 设置当前保存模式
            }
        }
    } else if (deviceInfo.bleCmdType == 0x63) {
        WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);
        
        int tmpbleCmdType = readBuffer[16];
        if (tmpbleCmdType == 0x01) { // 正常保存模式

        } else if (tmpbleCmdType == 0x02) { // 退出保存模式
            self.isReadingUserInfoBlock = YES;
            [self getEcgDataBlockCount:pDev];
        } else if (tmpbleCmdType == 0x03) { // 自动保存模式
            if ([self.delegate respondsToSelector:@selector(didReceiveBleAutoSave:)]) {
                [self.delegate didReceiveBleAutoSave:deviceInfo];
            }
        } else if (tmpbleCmdType == 0x04) { // 擦除模式
            WDLog(LOG_MODUL_BLE, @"数据擦除成功");
            if ([self.delegate respondsToSelector:@selector(didReceiveBleDeleteData:)]) {
                [self.delegate didReceiveBleDeleteData:deviceInfo];
            }
        } else {

        }
    }  else if (deviceInfo.bleCmdType == 0x75) {
        WDLog(LOG_MODUL_BLE, @"BulkDataBuffer-->%@", deviceInfo.receiveMStr);
        
        int tmpbleCmdType = readBuffer[16];
        if (tmpbleCmdType == 0x01) { // 正常保存模式

        } else if (tmpbleCmdType == 0x02) { // 退出保存模式

        } else if (tmpbleCmdType == 0x03) { // 序列号
            
            //ASCII to NSStrings
            NSString *versionStr = @"";
            int bufLen = bulkBufferPacket.bulkBasePacket.dataBuffer[13];
            for (int i = 14; i < bufLen + 14; i++) {
                if (bulkBufferPacket.bulkBasePacket.dataBuffer[i] != 0x00) {
                    versionStr = [NSString stringWithFormat:@"%@%c", versionStr, bulkBufferPacket.bulkBasePacket.dataBuffer[i]]; //A
                }
            }
            SCAppVaribleHandleInstance.deviceSerialNumber = versionStr;
            
            if ([self.delegate respondsToSelector:@selector(didReceiveBleSerialNumber:)]) {
                [self.delegate didReceiveBleSerialNumber:versionStr];
            }
            
        } else if (tmpbleCmdType == 0x04) { // 擦除模式
            
        } else {

        }
    } else if (deviceInfo.bleCmdType == 0x01) {

        if (deviceInfo.bagIndex == 0) {
            deviceInfo.readDataLen = (int)bulkBufferPacket.bulkBasePacket.dataBuffer[11];
            deviceInfo.perBagData = [[NSData dataWithBytes:bulkBufferPacket.bulkBasePacket.dataBuffer length:TG_CMD_DATA_BUFFER_LEN] subdataWithRange:NSMakeRange(8, TG_CMD_DATA_BUFFER_LEN - 8)].mutableCopy;
        } else {
            [deviceInfo.perBagData appendData:[NSData dataWithBytes:bulkBufferPacket.bulkBasePacket.dataBuffer length:TG_CMD_DATA_BUFFER_LEN]];
        }

        if (deviceInfo.bagCount - 1 == deviceInfo.bagIndex) { // 判断是否是最后一个包

            if (SCAppVaribleHandleInstance.bleDrawDataBlock) {
                SCAppVaribleHandleInstance.bleDrawDataBlock(deviceInfo.perBagData);
            }

        }
    }
    
}

- (void)startAcceptNextIntervalPageData:(SCMultiDeviceInfo *)deviceInfo device:(DeviceObject *)pDev {

//    deviceInfo.curBlockInfo = deviceInfo.allBlockInfo.allBlockInfoArray[deviceInfo.curBlockIndex];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:deviceInfo.curBlockInfo.start_timestamp];
    if ([self.delegate respondsToSelector:@selector(didReceiveBleEcgDataBlockDetail:)]) {
        [self.delegate didReceiveBleEcgDataBlockDetail:[NSString stringWithFormat:@"当前块信息:\n当前是第几块 = %d, 开始测量时间 = %@  \n设备序列号 = %@, 设备Mac地址 = %@ \n当前块的数据长度 = %d, \n开始页的序号 = %d, 结束页的序号 = %d", deviceInfo.curBlockIndex + 1, [dateFormatter stringFromDate:tmpStartDate], deviceInfo.curBlockInfo.deviceSerialNumber, deviceInfo.curBlockInfo.deviceMacAddress, deviceInfo.curBlockInfo.saved_datalen, deviceInfo.curBlockInfo.startpageIndex, deviceInfo.curBlockInfo.endpageIndex]];
    }

    [self getEcgDataBlockContentWithStartPageIndex:deviceInfo.curBlockInfo.startpageIndex endPageIndex:deviceInfo.curBlockInfo.endpageIndex internalIndex:0 device:pDev];

}

- (NSArray *)getDeviceArray {
    return [[SCBulkDataHandle sharedManager] getDeviceArray];
}


- (void)usbDidPlunIn:(DeviceObject *)usbObject {
    
    if ([self.delegate respondsToSelector:@selector(usbDidPlunIn:)]) {
        [self.delegate usbDidPlunIn:usbObject];
    }
    
}

- (void)usbDidRemove:(DeviceObject *)usbObject {
    
    if ([self.delegate respondsToSelector:@selector(usbDidRemove:)]) {
        [self.delegate usbDidRemove:usbObject];
    }
    
}

- (void)usbOpenFail {
    
    if ([self.delegate respondsToSelector:@selector(usbOpenFail)]) {
        [self.delegate usbOpenFail];
    }
}

@end
