//
//  DeviceInteractionView.m
//  USBDemo
//
//  Created by golfy on 2021/11/18.
//

#import "DeviceInteractionView.h"
#import "SCBleDataHandle.h"
#import "ShortcutHeader.h"
#import "SCAppVaribleHandle.h"

@interface DeviceInteractionView ()<SCBleDataHandleDelegate>

@end

@implementation DeviceInteractionView {
    NSString *receiveMStr;
    int debugMsgCounter;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    debugMsgCounter = 0;
    
    self.curEcgDataBlock.stringValue = @"0";
    self.appVersion.stringValue = [NSString stringWithFormat:@"当前软件版本号:%@", kCurrentVersion];
    
    [SCBleDataHandle sharedManager].delegate = self;
    
}

/// 激活蓝牙连接
- (void)activeBleHandle {
    [SCBleDataHandle sharedManager].delegate = self;
}

/// 显示Dongle列表
- (void)displayDongleList {
    
    if (self.isStopDisplay.state == NSControlStateValueOn) {
        return;
    }
    
    debugMsgCounter++;
    if (debugMsgCounter > 40) {
        [[self.displayContent textStorage] replaceCharactersInRange:NSMakeRange(0, [[self.displayContent textStorage] length]) withString:@""];
        debugMsgCounter = 0;
    }
    
    NSAttributedString *theString = [[NSAttributedString alloc] initWithString:receiveMStr];
    [[self.displayContent textStorage] appendAttributedString: theString];
    int length = (int)[[self.displayContent textStorage] length];
    NSRange theRange = NSMakeRange(length, 0);
    [self.displayContent scrollRangeToVisible:theRange];
    [self.displayContent setNeedsDisplay:YES];
    
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
    [[self.displayContent textStorage] replaceCharactersInRange:NSMakeRange(0, [[self.displayContent textStorage] length]) withString:@""];
    debugMsgCounter = 0;
}
/// 停止显示
- (IBAction)stopDisplay:(NSButton *)sender {
    sender.title = (self.isStopDisplay.state == NSControlStateValueOn) ? @"开始显示" : @"停止显示";
}
/// 获取Dongle版本
- (IBAction)getDongleVersion:(NSButton *)sender {
    for (DeviceObject *pDev in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        [[SCBleDataHandle sharedManager] getDongleVersion:pDev];
    }
}
/// 获取数据块的个数
- (IBAction)getEcgDataBlockCount:(NSButton *)sender {
    [SCBleDataHandle sharedManager].isReadingAllBlock = NO;
    
    for (DeviceObject *item in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        [[SCBleDataHandle sharedManager] getEcgDataBlockCount:item];
    }
}
/// 进入读取模式
- (IBAction)enterReadMode:(NSButton *)sender {
    for (DeviceObject *pDev in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        [[SCBleDataHandle sharedManager] enterReadMode:pDev];
    }
}
/// 退出读取模式
- (IBAction)exitReadMode:(NSButton *)sender {
    for (DeviceObject *pDev in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        [[SCBleDataHandle sharedManager] exitReadMode:pDev];
    }
}
/// 获取单个块的信息
- (IBAction)getEcgDataBlockDetail:(NSButton *)sender {
    [SCBleDataHandle sharedManager].isReadingAllBlock = NO;
    
    NSString *curBlock = self.curEcgDataBlock.stringValue;
    
    for (DeviceObject *item in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        [[SCBleDataHandle sharedManager] getEcgDataBlockDetailWithPageIndex:curBlock.intValue internalIndex:0 device:item];
    }
}
/// 获取单个块的内容
- (IBAction)getEcgDataBlockContent:(NSButton *)sender {
    [SCBleDataHandle sharedManager].isReadingAllBlock = NO;
    [SCBleDataHandle sharedManager].isNeedUploadData = NO;
    [SCBleDataHandle sharedManager].isDeleteECGData = (self.isDeleteECGData.state == NSControlStateValueOn);
    
    for (DeviceObject *item in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        [[SCBleDataHandle sharedManager] getEcgDataBlockContentWithStartPageIndex:SCAppVaribleHandleInstance.multiDeviceInfo[0].curBlockInfo.startpageIndex endPageIndex:SCAppVaribleHandleInstance.multiDeviceInfo[0].curBlockInfo.endpageIndex internalIndex:0 device:item];
    }
}
/// 获取所有块
- (IBAction)getAllEcgDataBlockContent:(NSButton *)sender {
    [SCBleDataHandle sharedManager].isReadingAllBlock = YES;
    [SCBleDataHandle sharedManager].isNeedUploadData = NO;
    [SCBleDataHandle sharedManager].isDeleteECGData = (self.isDeleteECGData.state == NSControlStateValueOn);
    [SCAppVaribleHandleInstance.multiDeviceInfo removeAllObjects];
    
    for (DeviceObject *item in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        [[SCBleDataHandle sharedManager] enterReadMode:item];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[SCBleDataHandle sharedManager] getEcgDataBlockCount:item];
        });
    }
}
- (IBAction)hexadecimalDisplay:(NSButton *)sender {
    [SCBleDataHandle sharedManager].isHexadecimalDisplay = (sender.state == NSControlStateValueOn);
}


// MARK: SCBleDataHandleDelegate
- (void)didReceiveBleBattery:(int)battery storage:(int)storage {

    dispatch_async(dispatch_get_main_queue(), ^{
        self.batteryStatus.stringValue = [NSString stringWithFormat:@"电量:%d%% ， 内存:%d%%", battery, storage];
    });
}

- (void)didReceiveBleVersion:(NSString *)version {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dongleVersion.stringValue = version;
    });
}

- (void)didReceiveBleECGDataBlockCount:(int)count {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ecgDataBlockCount.stringValue = [NSString stringWithFormat:@"%d", count];
    });
}

- (void)didReceiveBleEcgDataBlockDetail:(NSString *)blockDetail {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.curEcgDataBlockDetail.stringValue = blockDetail;
    });
}

- (void)didReceiveBleBlockProgress:(double)blockProgress blockProgressValue:(NSString *)blockProgressValue {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.readingBlockProgress.doubleValue = blockProgress;
        self.readingBlockProgressValue.stringValue = blockProgressValue;
    });
}

- (void)didReceiveBleDisplayString:(NSString *)displayString {
    receiveMStr = displayString;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayDongleList];
    });
}

- (void)didReceiveBleReadingStatus:(ReadingStatus)readingStatus {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.readingStatus.stringValue = (readingStatus == ReadingStatusRead) ? @"进入读取模式" : @"退出读取模式";
    });
}

@end
