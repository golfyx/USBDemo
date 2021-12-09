//
//  ViewController.m
//  USBDemo
//
//  Created by golfy on 2021/10/9.
//

#import "ViewController.h"
#import "SCDeviceAllBlockInfo.h"
#import "SCGCDTimerUtil.h"
#import "CommonUtil.h"
#import "SCRequestHandle.h"
#import "SCAppVaribleHandle.h"
#import "SCUploadDataInfo.h"
#import "SCSaveDataToFileHandle.h"
#import "SCBleDataHandle.h"


@interface ViewController ()



/* 总共多少块 */
@property (nonatomic, assign) int blockCount;
/* 当前块序号 */
@property (nonatomic, assign) int curBlockIndex;
/* 当前起始页序号 */
@property (nonatomic, assign) int curStartPageIndex;
/* 读取页序号的长度 */
@property (nonatomic, assign) int intervalPageIndex;
/* 块的读取索引*/
@property (nonatomic, strong) SCDeviceAllBlockInfo *allBlockInfo;
@property (nonatomic, strong) SCDeviceBlockInfo *curBlockInfo;

/// 十进制的文件路径
@property (nonatomic, strong) NSMutableArray *filePathDataDecimalismArray;
/// 十六进制的文件路径
@property (nonatomic, strong) NSMutableArray *filePathDataHexadecimalArray;
/* 保存多设备返回页的内容 */
@property (nonatomic, strong) NSMutableDictionary *responsePageDataDict;
/* 保存返回页的内容 */
@property (nonatomic, strong) NSMutableArray<NSMutableArray *> *responsePageDataArray;
/** 读取块的起始时间 */
@property (nonatomic, strong) NSDate *startReadBlockDate;
/** 读取块的结束时间*/
@property (nonatomic, strong) NSDate *endReadBlockDate;

/// 当前上传的块数
@property (nonatomic, assign) int curUploadBlockIndex;

/// 是否需要上传数据
@property (nonatomic, assign) BOOL isNeedUploadData;


@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSString *docuDirectoryPath;
/** 读取块原始数据的16进制*/
@property (nonatomic, strong) NSString *filePathDataHexadecimal;
@property (nonatomic, strong) NSMutableString *rawDataHexadecimalStr;
/// 每个块的合并数据
//@property (nonatomic, strong) NSMutableData *rawDataHexadecimalData;

@end


static const int responsePageDataLen = 4194304; ///4M 的长度
static const int responsePageIntervalDataLen = 11; ///11 的长度

@implementation ViewController {
    dispatch_source_t _readBufferTimer;
    
    NSMutableString *receiveMStr;
    uint bleCmdType;
    uint type;
    uint bagIndex;
    uint bagContentLen;
    uint checkSum;
    
    uint bagCount;
    ObjectOfOperationState oooState;
    PacketSendingReceivingState psrState;
    /// 读取数据线程
    NSThread *_pReadThread;
    ////// 写入数据线程
    NSThread *_pWriteThread;
    /// 每个包的合并数据
    NSMutableData *perBagData;
    
    
    
    ///  页序号
    int _pageIndex;
    ///  块序号
    int _blockIndex;
    ///  页的开始时间戳
//    long long _startTimestamp;
    ///  页的保存长度
//    int _savedDataLen;
    ///  页的起始位置
//    int _startPageIndex;
    ///  页的结束位置
//    int _endPageIndex;
    ///  传输类型
    int _transportType;
    ///  页数据发送到手机速度
    int _sendSpeed;
    ///  写入时的页内部索引序号
    int _writeInternalIndex;
    ///  读取时的页内部索引序号
    int _readInternalIndex;
    ///  读取时页的长度
    int _readDataLen;

    ///  是否读取所有包
    bool _isReadingAllBlock;
}

- (void)readBuffer {
    NSArray *tmpArray = [[UsbMonitor sharedUsbMonitorManager] getDeviceArray];
    while (1) {
        for (int i = 0; i < tmpArray.count; i++) {
            uint8_t buffer[TG_CMD_BUFFER_LEN] = {0};
            [[UsbMonitor sharedUsbMonitorManager] ReadSync:tmpArray[i] buffer:buffer size:TG_CMD_BUFFER_LEN];
            [self didReceiveDataDevice:tmpArray[i] readBuffer:buffer];
        }
        
        if (tmpArray.count <= 0) {
            NSLog(@"没有连接USB Bulk设备");
        }
    }
}

- (void)writeBuffer:(uint8_t *)writeBufferData {
    NSArray *tmpArray = [[UsbMonitor sharedUsbMonitorManager] getDeviceArray];
    if (tmpArray.count > 0) {
//        uint8_t *writeBuffer = (uint8_t *)[writeBufferData bytes];
        [[UsbMonitor sharedUsbMonitorManager] WriteSync:tmpArray[0] buffer:writeBufferData size:TG_CMD_BUFFER_LEN];
    } else {
        NSLog(@"没有连接USB Bulk设备");
    }
}

- (void)writeBufferThread:(uint8_t *)writeBuffer {
    if (!_pWriteThread.isCancelled) {
        [_pWriteThread cancel];
        _pWriteThread = nil;
    }
    _pWriteThread = [[NSThread alloc] initWithTarget:self selector:@selector(writeBuffer:) object:[NSData dataWithBytes:writeBuffer length:TG_CMD_BUFFER_LEN]];
    [_pWriteThread start];
}

int DebugMsgCounter = 0;
/// 统计接受包的频率
- (void)countTheFrequencyOfReceivingPackets {
    
    if (self.isStopDisplay.state == NSControlStateValueOn) {
        return;
    }
    
    DebugMsgCounter++;
    if (DebugMsgCounter > 10) {
        [[_textViewContent textStorage] replaceCharactersInRange:NSMakeRange(0, [[_textViewContent textStorage] length]) withString:@""];
        DebugMsgCounter = 0;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
    int length = 0;
    NSAttributedString *theString;
    NSRange theRange;
    
    NSString * str = [NSString stringWithFormat:@"当前计时时间:%@,丢包数:%ld/s,读取到的包个数:%ld/s,读取到的字节个数:%ld/s\r",[dateFormatter stringFromDate:[NSDate date]],[UsbMonitor sharedUsbMonitorManager].lostReadBufferPointCount,[UsbMonitor sharedUsbMonitorManager].readBufferPointCount,[UsbMonitor sharedUsbMonitorManager].readBufferPointCount*64];
    theString = [[NSAttributedString alloc] initWithString:str];
    [[_textViewContent textStorage] appendAttributedString: theString];
    length = (int)[[_textViewContent textStorage] length];
    theRange = NSMakeRange(length, 0);
    [_textViewContent scrollRangeToVisible:theRange];
    [_textViewContent setNeedsDisplay:YES];
    [UsbMonitor sharedUsbMonitorManager].readBufferPointCount = 0;
    [UsbMonitor sharedUsbMonitorManager].lostReadBufferPointCount = 0;
}

/// 显示Dongle列表
- (void)displayDongleList {
    
    if (self.isStopDisplay.state == NSControlStateValueOn) {
        return;
    }
    
    DebugMsgCounter++;
    if (DebugMsgCounter > 40) {
        [[self.textViewContent textStorage] replaceCharactersInRange:NSMakeRange(0, [[self.textViewContent textStorage] length]) withString:@""];
        DebugMsgCounter = 0;
    }
    
    NSAttributedString *theString = [[NSAttributedString alloc] initWithString:receiveMStr];
    [[self.textViewContent textStorage] appendAttributedString: theString];
    int length = (int)[[self.textViewContent textStorage] length];
    NSRange theRange = NSMakeRange(length, 0);
    [self.textViewContent scrollRangeToVisible:theRange];
    [self.textViewContent setNeedsDisplay:YES];
    
}

/// 查找USB Bulk设备
- (IBAction)searchUSBDevice:(NSButton *)sender {
    NSLog(@"暂时不做处理");
}
/// 关闭USB Bulk设备
- (IBAction)closeUSBDevice:(NSButton *)sender {
    NSLog(@"暂时不做处理");
}
/// 连接Dongle设备
- (IBAction)connectBleDevice:(NSButton *)sender {
    NSLog(@"暂时不做处理");
}
/// 断开Dongle设备
- (IBAction)disconnectBleDevice:(NSButton *)sender {
    NSLog(@"暂时不做处理");
}
/// 清空屏幕
- (IBAction)clearDisplay:(NSButton *)sender {
    [[_textViewContent textStorage] replaceCharactersInRange:NSMakeRange(0, [[_textViewContent textStorage] length]) withString:@""];
    DebugMsgCounter = 0;
}
/// 停止显示
- (IBAction)stopDisplay:(NSButton *)sender {
    sender.title = (self.isStopDisplay.state == NSControlStateValueOn) ? @"开始显示" : @"停止显示";
}
/// 获取Dongle版本
- (IBAction)getDongleVersion:(NSButton *)sender {
    const int len = 5;
    uint8_t buffer[len] = {0xa5,0x5a,0x70,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}
/// 获取数据块的个数
- (IBAction)getEcgDataBlockCount:(NSButton *)sender {
    _isReadingAllBlock = NO;
    
    [self getEcgDataBlockCount];
}
/// 进入读取模式
- (IBAction)enterReadMode:(NSButton *)sender {
    const int len = 7;
    uint8_t buffer[len] = {0xa5,0x5a,0x60,0x02,0x03,0x7f-0x03,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}
/// 退出读取模式
- (IBAction)exitReadMode:(NSButton *)sender {
    // 设置激活或者停止设备命令，也就是相当于设置退出读取模式
    const int len = 7;
    uint8_t buffer[len] = {0xa5,0x5a,0x60,0x02,0x02,0x7f-0x02,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}
/// 获取单个块的信息
- (IBAction)getEcgDataBlockDetail:(NSButton *)sender {
    _isReadingAllBlock = NO;
    
    NSString *curBlock = self.curEcgDataBlock.stringValue;
    [self getEcgDataBlockDetailWithPageIndex:curBlock.intValue];
}
/// 获取单个块的内容
- (IBAction)getEcgDataBlockContent:(NSButton *)sender {
    _isReadingAllBlock = NO;
    _isNeedUploadData = NO;
    
    [self getEcgDataBlockContentWithStartPageIndex:self.curBlockInfo.startpageIndex endPageIndex:self.curBlockInfo.endpageIndex];
}
/// 获取所有块
- (IBAction)getAllEcgDataBlockContent:(NSButton *)sender {
    _isReadingAllBlock = YES;
    _isNeedUploadData = NO;
    
    [self getEcgDataBlockCount];
}

- (void)getEcgDataBlockCount {
    
    const int len = 5;
    UInt8 buffer[len] = {0xa5,0x5a,0x43,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}

- (void)getEcgDataBlockDetailWithPageIndex:(int)pageIndex {
    const int len = 8;
    UInt8 pageindexlow = pageIndex & 0xff;
    UInt8 pageindexhigh = (pageIndex >> 8) & 0xff;
    UInt8 buffer[len] = {0xa5,0x5a,0x44,0x03,pageindexlow,pageindexhigh,_writeInternalIndex,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}

- (void)getEcgDataBlockContentWithStartPageIndex:(int)startPageIndex endPageIndex:(int)endPageIndex {
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
        _sendSpeed,_writeInternalIndex,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}

/// 读取Dongle当前状态
- (void)getDongleActiveType
{
    const int len = 5;
    uint8_t buffer[len] = {0xa5,0x5a,0x61,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}

/// 设置Dongle时间
- (void)setDongleTime
{
    const int len = 9;
    NSDate *datenow = [NSDate date];
    long long _timesp = [datenow timeIntervalSince1970] * 1000;
    SCAppVaribleHandleInstance.startRecordTimestamp = _timesp; // 服务器的开始时间以毫秒为单位
    _timesp /= 1000; // 设备的开始时间以秒为单位
    uint8_t buffer[len] = {0xa5,0x5a,0x51,0x04,_timesp&0xff,(_timesp >> 8)&0xff,(_timesp >> 16)&0xff,(_timesp >> 24)&0xff,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}

/// 激活Dongle
- (void)setDongleActive:(UInt8)command
{
    const int len = 7;
    uint8_t buffer[len] = {0xa5,0x5a,0x60,0x02,command,0x7f-command,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}

/// 获取当前保存状态
- (void)getSaveEcgModelCmd
{
    const int len = 5;
    UInt8 buffer[len] = {0xa5,0x5a,0x62,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}

/// 设置当前状态(保存模式和擦除模式)
- (void)setDeviceSaveEcgModelTypeCmd:(UInt8)command
{
    const int len = 7;
    UInt8 buffer[len] = {0xa5,0x5a,0x63,0x02,command,0x00,0};
    [CommonUtil calXortmpForSendBuffer:buffer len:len];
    
    [self writeBuffer:[self getSendDataByBuffer:buffer
                                         bufLen:len
                                       bagIndex:0
                                  totalBagCount:1
                    packetSendingReceivingState:PacketSendingReceivingStateMasterToDevice
                         objectOfOperationState:ObjectOfOperationStatePassthrough].dataBuffer];
}
//
//// cal xortmp for sendbuffer
//void CalXortmpForSendBuffer(uint8_t *target,uint8_t len)
//{
//    uint8_t xortmp;
//    uint16_t i;
//    
//    xortmp = 0;
//    for(i=0;i<len-1;i++)
//    {
//        xortmp = xortmp ^ target[i];
//    }
//    target[i] = xortmp;
//}

- (IBAction)getCaptcha:(NSButton *)sender {
    
    [SCRequestHandle acceptCaptchaWithPhone:self.userPhoneValue.stringValue];
}
- (IBAction)phoneCaptchaLogin:(NSButton *)sender {
    
    NSString *captcha = @"998080"; /// 为了筛查写的固定验证码
    [SCRequestHandle userLoginWithPhone:self.userPhoneValue.stringValue captcha:captcha completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            
            [SCRequestHandle getCurUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    SCUserInfoModel *userInfoModel = SCAppVaribleHandleInstance.userInfoModel;
                    userInfoModel.phoneNum = self.userPhoneValue.stringValue;
                    userInfoModel.name = self.nameValue.stringValue;
                    userInfoModel.genderType = [@"男" isEqualToString:self.genderValue.selectedItem.title] ? GenderType_male : [@"女" isEqualToString:self.genderValue.selectedItem.title] ? GenderType_female : GenderType_unknow;
                    NSDate *changeDate = [CommonUtil getNewDateDistanceNowWithYear:-[self.ageValue.stringValue intValue] withMonth:0 withDays:0];
                    userInfoModel.birthday = [CommonUtil getStrDateWithDateFormatter:@"yyyy-MM-dd" date:changeDate];
                    userInfoModel.height = self.heightValue.stringValue;
                    userInfoModel.weight = self.weightValue.stringValue;
                    SCAppVaribleHandleInstance.userInfoModel = userInfoModel;
                    
                    [SCRequestHandle updateMemberUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                        if (success) {
                            [self setDongleTime]; // 设置设备时间
                        }
                    }];
                }
            }];
        }
    }];
}
- (IBAction)stopAndUploadData:(NSButton *)sender {
    _isReadingAllBlock = YES;
    _isNeedUploadData = YES;
    
    [self.holterChartView clearCanvas];
    
    // 停止Dogle
    [self setDongleActive:0x02];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self enterReadMode:nil];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        /// 开始数据全部上传
        [self getEcgDataBlockCount];
    });
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
//    self. = @"快速普筛系统";
    
//    self.holterChartView.layer.shadowColor = KHRGBA(0x00, 0x00, 0x00, 0.06).CGColor;
    self.holterGriddingView.layer.shadowOffset = CGSizeMake(0, 5);
    self.holterGriddingView.layer.shadowRadius = 5;
    self.holterGriddingView.layer.shadowOpacity = 0.5f;
    self.holterGriddingView.layer.cornerRadius = 8;
    self.holterGriddingView.layer.masksToBounds = YES;
    
    self.appVersion.stringValue = [NSString stringWithFormat:@"当前软件版本号:%@", kCurrentVersion];
    self.curEcgDataBlock.stringValue = @"0";
    _transportType = 1;
    _sendSpeed = 0;
    _writeInternalIndex = 0;
    _isReadingAllBlock = NO;
    
    _allBlockInfo = [[SCDeviceAllBlockInfo alloc] init];
    _curBlockIndex = 0;
    _intervalPageIndex = 40;
    _responsePageDataDict = @{}.mutableCopy;
    _responsePageDataArray = [[NSMutableArray alloc] init];
    // 开辟一个4M 大小的内存空间
    for (int i = 0; i < responsePageDataLen; i++) {
        NSMutableArray *responsePageIntervalDataArray = [[NSMutableArray alloc] init];
        for (int j = 0; j < responsePageIntervalDataLen; j++) {
            [responsePageIntervalDataArray addObject:@0];
        }
        [_responsePageDataArray addObject:responsePageIntervalDataArray];
    }
    _rawDataHexadecimalStr = [NSMutableString string];
//    _rawDataHexadecimalData = [NSMutableData data];
    _curUploadBlockIndex = 1;
    
    
//    USBDeviceTool *usbDeviceTool = [USBDeviceTool shareDeviceTool];
//    usbDeviceTool.delegate = self;
//    [usbDeviceTool connectDevice];
    
    UsbMonitor *usbMonitor = [[UsbMonitor alloc] initWithVID:0x1483 withPID:0x5751 withDelegate:self];
    _pReadThread = [[NSThread alloc] initWithTarget:self selector:@selector(readBuffer) object:nil];
    [_pReadThread start];
    
//    [self startReadBufferTimer];
//    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(readBuffer) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}



- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

// MARK: USBDeviceDelegate
- (void)robotPenUSBConnectDevice:(nonnull IOHIDDeviceRef)deviceRef {
    NSLog(@"robotPenUSBConnectDevice: %@", deviceRef);
}

- (void)robotPenUSBRecvData:(nonnull uint8_t *)recvData {
    NSLog(@"robotPenUSBRecvData: \n");
//    NSLog(@"%02X %02X %02X %02X - %02X %02X %02X %02X", recvData[0], recvData[1], recvData[2], recvData[3], recvData[4], recvData[5], recvData[6], recvData[7]);
    int len = sizeof(recvData);
    for (int i = 0; i < len; i++) {
        NSLog(@"%02X", recvData[i]);
    }
    
}

- (void)robotPenUSBRomveDevice {
    NSLog(@"robotPenUSBRomveDevice");
}

// MARK: HIDDeviceDelegate
- (void)idrReaderClosed {
    NSLog(@"idrReaderClosed");
}

- (void)idrReaderOpened {
    NSLog(@"idrReaderOpened");
}

// MARK: UsbMonitorDelegate
- (void)usbDidPlunIn:(DeviceObject *)usbObject {
    NSLog(@"usbDidPlunIn --> %@", usbObject);
}

- (void)usbDidRemove:(DeviceObject *)usbObject {
    NSLog(@"usbDidRemove --> %@", usbObject);
}

- (void)didReceiveDataDevice:(DeviceObject *)pDev readBuffer:(unsigned char *)readBuffer {
    
    
    BULK_BUFFER_PACKET bulkBufferPacket;
    memcpy(bulkBufferPacket.dataBuffer, readBuffer, TG_CMD_BUFFER_LEN);
    
    type = readBuffer[0];
    bagIndex = readBuffer[1];
    bagContentLen = readBuffer[2];
    checkSum = readBuffer[3];
    
    bagCount = type & 0x7;
    oooState = (type >> 6) & 0x1;
    psrState = (type >> 7) & 0x1;
     
    Byte *pageBytes;
     
    if (bagIndex == 0) {
        receiveMStr = [[NSMutableString alloc] init];
        bleCmdType = readBuffer[14];
    }
    
    if ((self.isHexadecimalDisplay.state == NSControlStateValueOn) && (ObjectOfOperationStatePassthrough == oooState)) {
        for (int i = 4; i < TG_CMD_BUFFER_LEN; i+=2) {
            [receiveMStr appendFormat:@"%02X%02X", readBuffer[i], readBuffer[i+1]];
        }
    } else {
        for (int i = 4; i < TG_CMD_BUFFER_LEN; i++) {
            [receiveMStr appendFormat:@"%c", readBuffer[i]];
        }
    }
    
    if (bagCount - 1 == bagIndex) { // 判断是否是最后一个包
        receiveMStr = [NSMutableString stringWithFormat:@"%@\n", receiveMStr];
//        NSLog(@"%@", receiveMStr);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self displayDongleList];
//        });
    }
    
    if (ObjectOfOperationStateUSBBulk == oooState) {
        return;
    }
    
    
//    if (readBuffer[12] == 0xA5 && readBuffer[13] == 0x5A) {
//    bleCmdType = readBuffer[14];


    if (bleCmdType == 0x40) {  //  获取Dongle电量和内存
        dispatch_async(dispatch_get_main_queue(), ^{
            self.batteryStatus.stringValue = [NSString stringWithFormat:@"电量:%d%% ， 内存:%d%%", bulkBufferPacket.bulkBasePacket.dataBuffer[12], 100 - bulkBufferPacket.bulkBasePacket.dataBuffer[13]];
        });
    } else if (bleCmdType == 0x70) {  //  获取Dongle版本
        //ASCII to NSStrings
        NSString *versionStr = @"";
        int bufLen = bulkBufferPacket.bulkBasePacket.dataBuffer[12];
        for (int i = 13; i < bufLen + 13; i++) {
            if (bulkBufferPacket.bulkBasePacket.dataBuffer[i] != 0x00) {
                versionStr = [NSString stringWithFormat:@"%@%c", versionStr, bulkBufferPacket.bulkBasePacket.dataBuffer[i]]; //A
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dongleVersion.stringValue = versionStr;
        });
        
    } else if (bleCmdType == 0x43) {  //  获取块的个数
        self.blockCount = ((int)bulkBufferPacket.bulkBasePacket.dataBuffer[13] << 8) | (int)bulkBufferPacket.bulkBasePacket.dataBuffer[12];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.ecgDataBlockCount.stringValue = [NSString stringWithFormat:@"%d", self.blockCount];
        });
        
        if (!_isReadingAllBlock) {
            return;
        }
        
        if (self.blockCount > 0) {
            [self.allBlockInfo.allBlockInfoArray removeAllObjects];
            self.curBlockIndex = 0;
            self.curStartPageIndex = 0;
            
            [self getEcgDataBlockDetailWithPageIndex:0];
        } else {
            NSLog(@"当前没有可读取的包");
        }
        
    } else if (bleCmdType == 0x44) {  //  获取块的信息
        if (bagIndex == 0) {
            _curBlockIndex = ((int)bulkBufferPacket.bulkBasePacket.dataBuffer[13] << 8) | (int)bulkBufferPacket.bulkBasePacket.dataBuffer[12];
            perBagData = [NSData dataWithBytes:bulkBufferPacket.bulkBasePacket.dataBuffer length:TG_CMD_DATA_BUFFER_LEN].mutableCopy;
        } else {
            [perBagData appendData:[NSData dataWithBytes:bulkBufferPacket.bulkBasePacket.dataBuffer length:TG_CMD_DATA_BUFFER_LEN]];
        }
        
        if (bagCount - 1 == bagIndex) { // 判断是否是最后一个包
            
            uint8_t tmpReadbuffer[HEAD_BUFFER_LEN] = {0};
            uint8_t *perBagDataBytes = (uint8_t *)[perBagData bytes];
            for (int i = 0; i < HEAD_BUFFER_LEN; i++) {
                tmpReadbuffer[i] = perBagDataBytes[i + 15];
            }
            SAVE_DATA_HEAD saveDataHead;
            memcpy(saveDataHead.HeadBuffer, tmpReadbuffer, HEAD_BUFFER_LEN);
            
            
            self.curBlockInfo = [SCDeviceBlockInfo infoWithBlockIndex:_curBlockIndex start_timestamp:saveDataHead.DataHead.StartTimeStamp end_timestamp:saveDataHead.DataHead.EndTimeStamp saved_datalen:saveDataHead.DataHead.SaveDataLen startpageIndex:saveDataHead.DataHead.BeginPageIndex endpageIndex:saveDataHead.DataHead.EndPageIndex];
            self.curBlockInfo.deviceSerialNumber = [NSString stringWithCString:saveDataHead.DataHead.IdNumberBuf encoding:(NSUTF8StringEncoding)];
            NSString *deviceMacAddress;
            for (int i = 0; i < MAC_LEN; i++) {
                if (i == 0) {
                    deviceMacAddress = [NSString stringWithFormat:@"%02X", saveDataHead.DataHead.MacAddr[i]];
                } else {
                    deviceMacAddress = [NSString stringWithFormat:@"%@:%02X", deviceMacAddress, saveDataHead.DataHead.MacAddr[i]];
                }
            }
            self.curBlockInfo.deviceMacAddress = deviceMacAddress;
            self.curBlockInfo.samplingRate = saveDataHead.DataHead.SampleRate;
            self.curBlockInfo.leadCount = saveDataHead.DataHead.LeadCnt;
            self.curBlockInfo.leadTpye = saveDataHead.DataHead.LeadType;
            self.curBlockInfo.userId = [NSString stringWithCString:saveDataHead.DataHead.UserIDStrBuf encoding:(NSUTF8StringEncoding)];
            self.curBlockInfo.onlyFlag = [NSString stringWithCString:saveDataHead.DataHead.SaveDataOnlyFlagBuf encoding:(NSUTF8StringEncoding)];
            
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:self.curBlockInfo.start_timestamp];
            NSLog(@"当前块信息, bagIndex = %d, start_timestamp = %u, saved_datalen = %d, startpageIndex = %d, endpageIndex = %d", _curBlockIndex, saveDataHead.DataHead.StartTimeStamp, saveDataHead.DataHead.SaveDataLen, saveDataHead.DataHead.BeginPageIndex, saveDataHead.DataHead.EndPageIndex);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.curEcgDataBlockDetail.stringValue = [NSString stringWithFormat:@"当前块信息:\n当前是第几块 = %d, 开始测量时间 = %@  \n设备序列号 = %@, 设备Mac地址 = %@ \n当前块的数据长度 = %d, \n开始页的序号 = %d, 结束页的序号 = %d", self->_curBlockIndex + 1, [dateFormatter stringFromDate:tmpStartDate], self.curBlockInfo.deviceSerialNumber, self.curBlockInfo.deviceMacAddress, self.curBlockInfo.saved_datalen, self.curBlockInfo.startpageIndex, self.curBlockInfo.endpageIndex];
            });
            
            
            self.curBlockInfo.buffer = perBagData;
            [self.allBlockInfo.allBlockInfoArray addObject:self.curBlockInfo];
            
            if (!_isReadingAllBlock) {
                return;
            }
            
            // 判断继续获取下一块数据
            UInt16 nextBlockIndex = _curBlockIndex + 1;
            if (nextBlockIndex < self.blockCount)
            {
                [self getEcgDataBlockDetailWithPageIndex:nextBlockIndex];
                
            } else {
                
                self.startReadBlockDate = [NSDate date];
                self.curBlockIndex = 0;
//                self.rawDataHexadecimalData = [NSMutableData data];
                self.rawDataHexadecimalStr = [NSMutableString string];
                self.filePathDataDecimalismArray = [NSMutableArray array];
                self.filePathDataHexadecimalArray = [NSMutableArray array];
                
                [self getCurBlockInfo];
                
                // 将第0的数值保存块的信息
//                self.responsePageDataArray[0][0] = [self.curBlockInfo.buffer subdataWithRange:NSMakeRange(7, 0x80)];
                
                [self startAcceptNextIntervalPageData];
            }
        }
        
    } else if (bleCmdType == 0x45) {  //  获取块的内容
        
        if (bagIndex == 0) {
            int preCharLen = 16; // 前面有多少个字节，然后后面从0开始计算
            _pageIndex = ((int)readBuffer[2 + preCharLen] << 14)|((int)readBuffer[1 + preCharLen] << 7)|(int)readBuffer[0 + preCharLen];
            _readInternalIndex = readBuffer[3 + preCharLen];
            _readDataLen = readBuffer[4 + preCharLen];
            
//            NSLog(@"当前页序号: %d 页的内部索引：%d data_len %d", _pageIndex, _readInternalIndex, _readDataLen);
            
            perBagData = [[NSData dataWithBytes:readBuffer length:TG_CMD_BUFFER_LEN] subdataWithRange:NSMakeRange(12, TG_CMD_BUFFER_LEN - 12)].mutableCopy;
        } else {
            [perBagData appendData:[[NSData dataWithBytes:readBuffer length:TG_CMD_BUFFER_LEN] subdataWithRange:NSMakeRange(4, TG_CMD_BUFFER_LEN - 4)]];
        }
        
        if (bagCount - 1 == bagIndex) { // 判断是否是最后一个包
            
            int tmpPageIndex = _pageIndex - self.curBlockInfo.startpageIndex;
            if (tmpPageIndex < 0) {
                tmpPageIndex = 0;
            }
            
            NSData *tmpData;
            if (_readInternalIndex == 10) {
                tmpData = [perBagData subdataWithRange:NSMakeRange(9, 0x60)];
            } else {
                tmpData = [perBagData subdataWithRange:NSMakeRange(9, _readDataLen)];
            }
            
//            [self.rawDataHexadecimalData appendData:[perBagData subdataWithRange:NSMakeRange(9, _readDataLen)]];
            pageBytes = (Byte *)[tmpData bytes];
            for (int i = 0; i < tmpData.length; i++) {
                [_rawDataHexadecimalStr appendFormat:@"%02X", pageBytes[i]];
            }
            
            // 1536 压缩后一页总长度  2048 压缩前一页的总长度
            // 将页的内容保存进数组
            self.responsePageDataArray[tmpPageIndex][_readInternalIndex] = tmpData;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                double curPageProgress = self->_pageIndex - self.curBlockInfo.startpageIndex;
                double curBlockAllPage = self.curBlockInfo.endpageIndex - self.curBlockInfo.startpageIndex;
                self.readingBlockProgress.doubleValue = (curPageProgress / curBlockAllPage) * 100;
                self.readingBlockProgressValue.stringValue = [NSString stringWithFormat:@"%d/%d", self.curBlockIndex + 1, self.blockCount];
            });
            
            /// 如果接收到的区间页块大于区间结束值才进行读取下一页 并且 是一页的最后一段
            if (self.curStartPageIndex > _pageIndex || (self.curBlockInfo.endpageIndex == _pageIndex && _readInternalIndex < 10))
            {
                return;
            }
            
            /// 判断读取下一页
            if ( self.curStartPageIndex < self.curBlockInfo.endpageIndex)
            {
                // 继续读取下一页
                [self startAcceptNextIntervalPageData];
            }
            else
            {
                if (self.allBlockInfo.allBlockInfoArray.count <= 0) {
                    return;
                }
                
                self.endReadBlockDate = [NSDate date];
                NSTimeInterval distanceTime = [self.endReadBlockDate timeIntervalSinceDate:self.startReadBlockDate];
                
                SCDeviceBlockInfo *tmpBlockInfo = self.allBlockInfo.allBlockInfoArray[self.curBlockIndex];
                tmpBlockInfo.uploadProgress = distanceTime;
                self.allBlockInfo.allBlockInfoArray[self.curBlockIndex] = tmpBlockInfo;
    
                // 将数据保存到本地文件
                [self writeDataToFile];
                
                if (_isNeedUploadData) {
                    // 将数据上传到服务器
                    [self uploadDataToAliCloudService];
                }
                
                if (!_isReadingAllBlock) {
                    return;
                }
                
                
                if (self.curBlockIndex < self.allBlockInfo.allBlockInfoArray.count - 1) {
                    self.curBlockIndex++;
                    self.startReadBlockDate = [NSDate date];
//                    self.rawDataHexadecimalData = [NSMutableData data];
                    self.rawDataHexadecimalStr = [NSMutableString string];

                    [self getCurBlockInfo];

                    [self startAcceptNextIntervalPageData];
                } else {
                    
                    if (self.isDeleteECGData.state == NSControlStateValueOn) {  // 是否需要删除数据
                        [self setDeviceSaveEcgModelTypeCmd:0x04];
                    }
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self exitReadMode:nil];
                    });
                    
                    [self saveMergedBleDataFilePath];
                }
            }
            
        }
        
    } else if (bleCmdType == 0x60) {  //  设备停止指令
        int tmpbleCmdType = readBuffer[16];
        if (tmpbleCmdType == 0x02) {
            
            // 退出保存模式
            [self setDeviceSaveEcgModelTypeCmd:0x02];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.readingStatus.stringValue = @"退出读取模式";
            });
            
        } else if (tmpbleCmdType == 0x03) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.readingStatus.stringValue = @"进入读取模式";  //  进入读取模式
            });
            
        } else if (tmpbleCmdType == 0x01) {
            [self getSaveEcgModelCmd]; // 获取当前保存模式
        }
    } else if (bleCmdType == 0x51) {
        // 时间误差在1s之内，认为设置成功
        [self setDongleActive:0x01]; // 激活设备
    } else if (bleCmdType == 0x62) {
        int tmpbleCmdType = readBuffer[16];
        if (tmpbleCmdType == 0x02) { // 自动保存模式
            
            [SCRequestHandle saveUserProcessingTimeCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    NSLog(@"saveUserProcessingTimeCompletion");
                }
            }];
            
        } else {
            [self setDeviceSaveEcgModelTypeCmd:0x03]; // 设置当前保存模式
        }
    } else if (bleCmdType == 0x63) {
        int tmpbleCmdType = readBuffer[16];
        if (tmpbleCmdType == 0x01) { // 正常保存模式
            
        } else if (tmpbleCmdType == 0x02) { // 退出保存模式
            
        } else if (tmpbleCmdType == 0x03) { // 自动保存模式
            [SCRequestHandle saveUserProcessingTimeCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    NSLog(@"saveUserProcessingTimeCompletion");
                }
            }];
        } else if (tmpbleCmdType == 0x04) { // 擦除模式
            NSLog(@"数据擦除成功");
        } else {

        }
    } else if (bleCmdType == 0x01) {
        
        if (bagIndex == 0) {
            _readDataLen = (int)bulkBufferPacket.bulkBasePacket.dataBuffer[11];
            perBagData = [[NSData dataWithBytes:bulkBufferPacket.bulkBasePacket.dataBuffer length:TG_CMD_DATA_BUFFER_LEN] subdataWithRange:NSMakeRange(8, TG_CMD_DATA_BUFFER_LEN - 8)].mutableCopy;
        } else {
            [perBagData appendData:[NSData dataWithBytes:bulkBufferPacket.bulkBasePacket.dataBuffer length:TG_CMD_DATA_BUFFER_LEN]];
        }
        
        if (bagCount - 1 == bagIndex) { // 判断是否是最后一个包
            
            if (SCAppVaribleHandleInstance.bleDrawDataBlock) {
                SCAppVaribleHandleInstance.bleDrawDataBlock(perBagData);
            }
            
        }
    }
    
}

- (void)getCurBlockInfo {
    self.curBlockInfo = self.allBlockInfo.allBlockInfoArray[self.curBlockIndex];
    self.curStartPageIndex = self.curBlockInfo.startpageIndex;
}

- (void)startAcceptNextIntervalPageData {
    
    int tmpCurPageIndex = self.curStartPageIndex;
    int tmpEndPageIndex = tmpCurPageIndex + self.intervalPageIndex;
    if (tmpEndPageIndex > self.curBlockInfo.endpageIndex) {
        tmpEndPageIndex = self.curBlockInfo.endpageIndex;
        self.curStartPageIndex = tmpEndPageIndex - self.intervalPageIndex;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:self.curBlockInfo.start_timestamp];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.curEcgDataBlockDetail.stringValue = [NSString stringWithFormat:@"当前块信息:\n当前是第几块 = %d, 开始测量时间 = %@  \n设备序列号 = %@, 设备Mac地址 = %@ \n当前块的数据长度 = %d, \n开始页的序号 = %d, 结束页的序号 = %d", self->_curBlockIndex + 1, [dateFormatter stringFromDate:tmpStartDate], self.curBlockInfo.deviceSerialNumber, self.curBlockInfo.deviceMacAddress, self.curBlockInfo.saved_datalen, self.curBlockInfo.startpageIndex, self.curBlockInfo.endpageIndex];
    });
    
    tmpEndPageIndex = self.curBlockInfo.endpageIndex; // 直接读取到最后
    [self getEcgDataBlockContentWithStartPageIndex:tmpCurPageIndex endPageIndex:tmpEndPageIndex];
    
    self.curStartPageIndex += self.intervalPageIndex;
    self.curStartPageIndex = tmpEndPageIndex;
}
/// 将数据上传到服务器
- (void)uploadDataToAliCloudService {
    SCUploadDataInfo *uploadDataInfo = [SCUploadDataInfo new];
    uploadDataInfo.rawData = self.rawDataHexadecimalStr;
//    uploadDataInfo.rawData = [NSString stringWithContentsOfFile:_filePathDataHexadecimal encoding:NSUTF8StringEncoding error:nil];
    uploadDataInfo.dataBlockIndex = self.curBlockIndex;
    uploadDataInfo.dataLen = self.curBlockInfo.saved_datalen;
    uploadDataInfo.dataPageIndex = self.curBlockInfo.endpageIndex;
    uploadDataInfo.detectionTime = SCAppVaribleHandleInstance.startRecordTimestamp;
    uploadDataInfo.detectionType = 27;
    uploadDataInfo.deviceType = 23;
    uploadDataInfo.macAddress = self.curBlockInfo.deviceMacAddress;
    uploadDataInfo.memberId = SCAppVaribleHandleInstance.userInfoModel.memberID;
    uploadDataInfo.samplingRate = self.curBlockInfo.samplingRate;
    uploadDataInfo.isToBin = YES;
    [SCRequestHandle uploadDataFor24HoursWithUploadDataInfo:uploadDataInfo Completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            if (self.curUploadBlockIndex == self.blockCount) {
                SCUploadDataInfo *finishDataInfo = [SCUploadDataInfo new];
                finishDataInfo.dataBlockIndex = self.curBlockIndex;
                finishDataInfo.dataLen = self.curBlockInfo.saved_datalen;
                finishDataInfo.dataPageIndex = self.curBlockInfo.endpageIndex;
                finishDataInfo.detectionTime = SCAppVaribleHandleInstance.startRecordTimestamp;
                finishDataInfo.detectionType = 27;
                finishDataInfo.deviceType = 23;
                finishDataInfo.macAddress = self.curBlockInfo.deviceMacAddress;
                finishDataInfo.memberId = SCAppVaribleHandleInstance.userInfoModel.memberID;
                finishDataInfo.samplingRate = self.curBlockInfo.samplingRate;
                finishDataInfo.isToBin = YES;
                [SCRequestHandle finishFor24HoursWithUploadDataInfo:finishDataInfo Completion:^(BOOL success, id  _Nonnull responseObject) {
                    if (success) {
                        NSLog(@"全部数据上传完成！");
                    }
                }];
            } else {
                self.curUploadBlockIndex++;
            }
        }
    }];
    
}
/// 将数据保存到本地文件
- (void)writeDataToFile {
    _docuDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    NSString *timeInterval = [NSString stringWithFormat:@"%.3f.bin", [[NSDate date] timeIntervalSince1970]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:self.curBlockInfo.start_timestamp];
    _docuDirectoryPath = [NSString stringWithFormat:@"%@/Block/%@/%@", _docuDirectoryPath, [dateFormatter stringFromDate:tmpStartDate], self.curBlockInfo.deviceSerialNumber];
    
    _fileManager = [NSFileManager defaultManager];
    if ([_fileManager fileExistsAtPath:_docuDirectoryPath]) {
        NSLog(@"目录已经存在");
    } else {
        BOOL ret = [_fileManager createDirectoryAtPath:_docuDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        if (ret) {
            NSLog(@"目录创建成功");
        } else{
            NSLog(@"目录创建失败");
        }
    }
    
    // 保存设备数据块的信息
    NSString *filePathInfo = [self createFileAtPathWithTitle:@"info" pathExtension:@"txt"];
    [self saveDeviceInfo:filePathInfo];
    
    // 将数据进行3转4后保存为十六进制文件
    NSString *filePathData = [self createFileAtPathWithTitle:@"hexadecimal" pathExtension:@"bin"];
    // 将数据保存为十进制文件
    NSString *filePathDataDecimalism = [self createFileAtPathWithTitle:@"decimalism" pathExtension:@"txt"];
    [self.filePathDataDecimalismArray addObject:filePathDataDecimalism];
    [self.filePathDataHexadecimalArray addObject:filePathData];
    
    [self changeAndSaveBleUploadData:filePathData filePathDataDecimalism:filePathDataDecimalism];
    
    // 将数据保存为十六进制原始文件
//    [self saveBleUploadDataFilePathDataHexadecimal];
}

- (NSString *)createFileAtPathWithTitle:(NSString *)title pathExtension:(NSString *)pathExtension {
    
    NSString *tmpTimestamp = [NSString stringWithFormat:@"%08llX_%@_%d.%@", self.curBlockInfo.start_timestamp, title,  self->_curBlockIndex + 1, pathExtension];
    NSString *filePath = [_docuDirectoryPath stringByAppendingPathComponent:tmpTimestamp];
    
    //文件夹是否存在
    if (![_fileManager fileExistsAtPath:filePath]) {
        NSLog(@"设备信息文件不存在,进行创建");
        [_fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    return filePath;
}

/// 保存设备数据块的信息
- (void)saveDeviceInfo:(NSString *)filePath {
    
    NSFileHandle *writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [writeFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:self.curBlockInfo.start_timestamp];
    NSDate *tmpEndDate = [NSDate dateWithTimeIntervalSince1970:self.curBlockInfo.end_timestamp];
    NSString *deviceInfo = [NSString stringWithFormat:@"当前块信息:\n当前是第几块 = %d, 开始时间 = %@, 结束时间 = %@  \n设备序列号 = %@, 设备Mac地址 = %@ \n当前块的数据长度 = %d, \n开始页的序号 = %d, 结束页的序号 = %d", self->_curBlockIndex + 1, [dateFormatter stringFromDate:tmpStartDate], [dateFormatter stringFromDate:tmpEndDate], self.curBlockInfo.deviceSerialNumber, self.curBlockInfo.deviceMacAddress, self.curBlockInfo.saved_datalen, self.curBlockInfo.startpageIndex, self.curBlockInfo.endpageIndex];

    [writeFileHandle writeData:[deviceInfo dataUsingEncoding:NSUTF8StringEncoding]];
    [writeFileHandle synchronizeFile];
    [writeFileHandle closeFile];
}

// 将数据进行3转4后保存为十六进制文件 和十进制文件
- (void)changeAndSaveBleUploadData:(NSString *)filePathData
            filePathDataDecimalism:(NSString *)filePathDataDecimalism {
    
    NSFileHandle *writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePathData];
    NSFileHandle *readFileHandle = [NSFileHandle fileHandleForReadingAtPath:filePathData];
    [writeFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
    NSFileHandle *writeDataDecimalismFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePathDataDecimalism];
    NSFileHandle *readDataDecimalismFileHandle = [NSFileHandle fileHandleForReadingAtPath:filePathDataDecimalism];
    [writeDataDecimalismFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
    
    Byte val1,val2,val3;
    WORD_TYPE value1,value2;
    Byte *resultBytes;
    NSData *tmpData;
    NSMutableData *tmpMutData;
    NSString *tmpDecimalismStr;
    
    NSArray *tmpArray = self.responsePageDataArray;
    for (int i = 0; i < tmpArray.count; i++) {
        NSArray *tmpSubArray = tmpArray[i];
        for (int j = 0; j < tmpSubArray.count; j++) {
            tmpData = tmpSubArray[j];
            if ([tmpData isKindOfClass: NSNumber.class]) {
                break;
            }
            
            resultBytes = (Byte *)[tmpData bytes];
            tmpMutData = [NSMutableData data];
            tmpDecimalismStr = @"";
            for (int k = 0; k < tmpData.length; k+=3) {
                val1 = resultBytes[k];
                val2 = resultBytes[k+1];
                val3 = resultBytes[k+2];
                
                value1.DataUint = (val2 & 0xf0) * 16 + val1;
                value2.DataUint = (val2 & 0x0f) * 256 + val3;
                
                value1.DataInt = value1.DataInt - 0x800;
                value2.DataInt = value2.DataInt - 0x800;
                tmpDecimalismStr = [NSString stringWithFormat:@"%@\n%d\n%d", tmpDecimalismStr, value1.DataInt, value2.DataInt];
                
                value1.DataUint = (value1.DataUint + 0x8000) & 0xFFFF;
                value2.DataUint = (value2.DataUint + 0x8000) & 0xFFFF;
                
                unsigned int intValue = value1.DataUint & 0xff;
                [tmpMutData appendBytes:&intValue length:1];
                intValue = (value1.DataUint>>8) & 0xff;
                [tmpMutData appendBytes:&intValue length:1];
                intValue = value2.DataUint & 0xff;
                [tmpMutData appendBytes:&intValue length:1];
                intValue = (value2.DataUint>>8) & 0xff;
                [tmpMutData appendBytes:&intValue length:1];
            }
            [writeFileHandle writeData:tmpMutData];
            [writeFileHandle seekToEndOfFile];
            
            [writeDataDecimalismFileHandle writeData:[tmpDecimalismStr dataUsingEncoding:NSUTF8StringEncoding]];
            [writeDataDecimalismFileHandle seekToEndOfFile];
        }
    }
    [writeFileHandle synchronizeFile];
    
    /// 这样写是为了截取掉多余的字节
    NSData *tmpReadFileData = [readFileHandle readDataOfLength:self.curBlockInfo.saved_datalen];
    [writeFileHandle truncateFileAtOffset:0];
    [writeFileHandle writeData:tmpReadFileData];
    [writeFileHandle synchronizeFile];
    
    [writeFileHandle closeFile];
    [readFileHandle closeFile];
    
    
    [writeDataDecimalismFileHandle synchronizeFile];
    
    /// 这样写是为了截取掉多余的字节
    NSData *tmpReadDecimalismFileData = [readDataDecimalismFileHandle readDataOfLength:self.curBlockInfo.saved_datalen];
    [writeDataDecimalismFileHandle truncateFileAtOffset:0];
    [writeDataDecimalismFileHandle writeData:tmpReadDecimalismFileData];
    [writeDataDecimalismFileHandle synchronizeFile];
    
    [writeDataDecimalismFileHandle closeFile];
    [readDataDecimalismFileHandle closeFile];
    
}


// 合并所有文件
- (void)saveMergedBleDataFilePath {
    _docuDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:self.curBlockInfo.start_timestamp];
    _docuDirectoryPath = [NSString stringWithFormat:@"%@/MergedFiles/%@/%@", _docuDirectoryPath, [dateFormatter stringFromDate:tmpStartDate], self.curBlockInfo.deviceSerialNumber];
    
    if ([_fileManager fileExistsAtPath:_docuDirectoryPath]) {
        NSLog(@"目录已经存在");
    } else {
        BOOL ret = [_fileManager createDirectoryAtPath:_docuDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        if (ret) {
            NSLog(@"目录创建成功");
        } else{
            NSLog(@"目录创建失败");
        }
    }

    NSString *mergedFilePathDataHexadecimal = [self createFileAtPathWithTitle:@"hexadecimal" pathExtension:@"bin"];
    NSString *mergedFilePathDataDecimalism = [self createFileAtPathWithTitle:@"decimalism" pathExtension:@"txt"];

    
    NSFileHandle *writeDataHexadecimalFileHandle = [NSFileHandle fileHandleForWritingAtPath:mergedFilePathDataHexadecimal];
    [writeDataHexadecimalFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
    NSFileHandle *writeDataDecimalismFileHandle = [NSFileHandle fileHandleForWritingAtPath:mergedFilePathDataDecimalism];
    [writeDataDecimalismFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写

    NSString *tmpDecimalismOfRawDataStr;
    NSData *tmpHexadecimalData;

    for (int i = 0; i < self.filePathDataDecimalismArray.count; i++) {
        tmpDecimalismOfRawDataStr = [NSString stringWithContentsOfFile:self.filePathDataDecimalismArray[i] encoding:NSUTF8StringEncoding error:nil];
        [writeDataDecimalismFileHandle writeData:[tmpDecimalismOfRawDataStr dataUsingEncoding:NSUTF8StringEncoding]];
        [writeDataDecimalismFileHandle seekToEndOfFile];
        [writeDataDecimalismFileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [writeDataDecimalismFileHandle seekToEndOfFile];
        
        tmpHexadecimalData = [NSData dataWithContentsOfFile:self.filePathDataHexadecimalArray[i]];
        [writeDataHexadecimalFileHandle writeData:tmpHexadecimalData];
        [writeDataHexadecimalFileHandle seekToEndOfFile];
    }

    [writeDataDecimalismFileHandle synchronizeFile];
    [writeDataDecimalismFileHandle closeFile];
    
    [writeDataHexadecimalFileHandle synchronizeFile];
    [writeDataHexadecimalFileHandle closeFile];

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
    
    bulkBufferPacket.bulkBasePacket.type = (packetSendingReceivingState << 7) | (objectOfOperationState << 6) | totalBagCount;
    bulkBufferPacket.bulkBasePacket.len = TG_CMD_DATA_BUFFER_LEN;
    bulkBufferPacket.bulkBasePacket.bagIndex = bagIndex;
    
    uint8_t sendBuffer[TG_CMD_DATA_BUFFER_LEN] = {0};
    for(int i = 0; i < TG_CMD_DONGLE_MAC_LEN; i++) {
        sendBuffer[i] = 0x00;
    }
    
    for (int i = TG_CMD_DONGLE_MAC_LEN; i < TG_CMD_DONGLE_MAC_LEN + bufLen; i++) {
        sendBuffer[i] = buffer[i-TG_CMD_DONGLE_MAC_LEN];
    }
    
    int checkSum = 0;
    for(int i = 0; i < TG_CMD_DONGLE_MAC_LEN + bufLen; i++)
    {
        checkSum += sendBuffer[i];
    }
    bulkBufferPacket.bulkBasePacket.checkSum = (checkSum & 0xff); // 取低位字节
    
    for (int i = 0; i < TG_CMD_DATA_BUFFER_LEN; i++) {
        bulkBufferPacket.bulkBasePacket.dataBuffer[i] = sendBuffer[i];
    }
    
    return bulkBufferPacket;
}

@end
