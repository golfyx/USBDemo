//
//  ScreeningView.m
//  USBDemo
//
//  Created by golfy on 2021/11/18.
//

#import "ScreeningView.h"
#import "CommonUtil.h"
#import "SCRequestHandle.h"
#import "SCAppVaribleHandle.h"
#import "SCBleDataHandle.h"
#import "SCDetectionInfo.h"
#import "WDLog.h"
#import "EMRToast.h"
#import "OnlyIntegerValueFormatter.h"
#import "YYModel.h"
#import "SCDataBaseManagerHandle.h"

#import <AudioToolbox/AudioToolbox.h>

#import "DeviceListCell.h"
#import "SCBulkDeviceInfo.h"

@interface ScreeningView()<SCBleDataHandleDelegate, NSTableViewDelegate, NSTableViewDataSource, DeviceListCellDelegate>

@property (nonatomic, strong) NSTableView *deviceListTableView;

@property (nonatomic, strong) NSString *phoneNum;
@property (nonatomic, strong) NSString *captchaNum;
@property (nonatomic, strong) NSString *documentPath;
@property (nonatomic, strong) NSString *usersTableFilePath;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

/// 开始读取块的时间，方便统计读取块花费了多长时间
@property (nonatomic, strong) NSDate *startBlockDate;

@property (nonatomic, assign) int curBattery; // 当前电量

/// 当前选中的设备序列号
@property (nonatomic, strong) NSString *selectedDeviceSeri;

@end

@implementation ScreeningView {
}

- (NSTableView *)deviceListTableView {
    if (!_deviceListTableView) {
        _deviceListTableView = [[NSTableView alloc]initWithFrame:_deviceScrollView.bounds];
        NSTableColumn *column = [[NSTableColumn alloc]initWithIdentifier:@"DeviceTableColumn"];
        column.title = @"设备列表";
        column.width = 280;
        [_deviceListTableView addTableColumn:column];
        _deviceListTableView.delegate = self;
        _deviceListTableView.dataSource = self;
        _deviceScrollView.contentView.documentView = _deviceListTableView;
    }
    
    return _deviceListTableView;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (NSString *)documentPath {
    if (!_documentPath) {
        // 文件保存的路径
        _documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
        _documentPath = [NSString stringWithFormat:@"%@/UsersTables", _documentPath];
    }
    return _documentPath;
}

//- (NSString *)usersTableFilePath {
//    if (!_usersTableFilePath) {
//        self.dateFormatter.dateFormat = @"yyyy-MM-dd";
//        NSString *xlsxName = [NSString stringWithFormat:@"%@.xls", [self.dateFormatter stringFromDate:[NSDate date]]];
//        _usersTableFilePath = [self.documentPath stringByAppendingPathComponent:xlsxName];
//    }
//    return _usersTableFilePath;
//}

- (void)createFileAtPath:(NSString *)xlsxName {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.documentPath]) {
        WDLog(LOG_MODUL_FILE ,@"目录已经存在");
    } else {
        if ([fileManager createDirectoryAtPath:self.documentPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            WDLog(LOG_MODUL_FILE ,@"目录创建成功");
        } else{
            WDLog(LOG_MODUL_FILE ,@"目录创建失败");
        }
    }
    
    _usersTableFilePath = [self.documentPath stringByAppendingPathComponent:xlsxName];
    
    //文件是否存在
    if (![fileManager fileExistsAtPath:_usersTableFilePath]) {
        WDLog(LOG_MODUL_FILE ,@"设备信息文件不存在,进行创建");
        if ([fileManager createFileAtPath:_usersTableFilePath contents:nil attributes:nil]) {
            WDLog(LOG_MODUL_FILE ,@"登记文件创建成功");
            // 字符串插入"\t" (Tab键,制表键的简写）,达到换列的作用。 \n 换行符
            [self writeCheckInDataToFile:@"序号\t设备号\t开始时间\t结束时间\t总块数\t姓名\t性别\t年龄\t身高\t体重\t手机号\r\n"];
        } else{
            WDLog(LOG_MODUL_FILE ,@"登记文件创建失败");
        }
    }
    
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 70;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [SCBleDataHandle sharedManager].scanDeviceListDict.allValues.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row  {
    
    DeviceListCell *cell = (DeviceListCell *)[CommonUtil getViewFromNibName:@"DeviceListCell"];
    cell.delegate = self;
    
    if ([SCBleDataHandle sharedManager].scanDeviceListDict.allValues.count <= row) {
        return nil;
    }
    
    SCBulkDeviceInfo *bulkDeviceInfo = [SCBleDataHandle sharedManager].scanDeviceListDict.allValues[row];
    cell.deviceRssiTField.stringValue = [NSString stringWithFormat:@"信号：%d", bulkDeviceInfo.deviceRssi];
    cell.deviceNameTField.stringValue = bulkDeviceInfo.devicename;
    cell.deviceSeriTField.stringValue = bulkDeviceInfo.deviceSeri;
    cell.connectDeviceButton.title = bulkDeviceInfo.connectState ? @"断开" : @"连接";
    cell.index = bulkDeviceInfo.deviceIndex;
    
    return cell;
}

- (void)connectDevice:(DeviceListCell *)cell index:(int)index {
    if ([@"连接" isEqualToString:cell.connectDeviceButton.title]) {
        self.selectedDeviceSeri = cell.deviceSeriTField.stringValue;
        cell.connectDeviceButton.title = @"断开";
        SCBulkDeviceInfo *bulkDeviceInfo = [SCBleDataHandle sharedManager].scanDeviceListDict[self.selectedDeviceSeri];
        bulkDeviceInfo.connectState = YES;
        [SCBleDataHandle sharedManager].scanDeviceListDict[self.selectedDeviceSeri] = bulkDeviceInfo;
        for (DeviceObject *pDev in [[SCBleDataHandle sharedManager] getDeviceArray]) {
            [[SCBulkDataHandle sharedManager] connectBleDeviceIndex:index deviceObject:pDev];
        }
    } else {
        [self disconnectDeviceBle:nil];
    }
    
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.curBattery = 0;
    
    self.wantsLayer = YES;
    self.holterGriddingView.layer.shadowOffset = CGSizeMake(0, 5);
    self.holterGriddingView.layer.shadowRadius = 5;
    self.holterGriddingView.layer.shadowOpacity = 0.5f;
    self.holterGriddingView.layer.cornerRadius = 8;
    self.holterGriddingView.layer.masksToBounds = YES;
    
    [SCBleDataHandle sharedManager].delegate = self;
    
    OnlyIntegerValueFormatter *formatter1 = [OnlyIntegerValueFormatter new];
    formatter1.maxLen = 3;
    self.ageValue.formatter = formatter1;
    self.heightValue.formatter = formatter1;
    self.weightValue.formatter = formatter1;
    OnlyIntegerValueFormatter *formatter2 = [OnlyIntegerValueFormatter new];
    formatter2.maxLen = 11;
    self.userPhoneValue.formatter = formatter2;
    OnlyIntegerValueFormatter *formatter3 = [OnlyIntegerValueFormatter new];
    formatter3.maxLen = 6;
    self.captchaValue.formatter = formatter3;

    
    [self.serialNumPopUpBtn removeAllItems];
}

/// 激活蓝牙连接
- (void)activeBleHandle {
    [SCBleDataHandle sharedManager].scanDeviceListDict = @{}.mutableCopy;
    [SCBleDataHandle sharedManager].delegate = self;
}

- (IBAction)getCaptcha:(NSButton *)sender {
    
    [SCRequestHandle acceptCaptchaWithPhone:self.userPhoneValue.stringValue];
}
- (IBAction)phoneCaptchaLogin:(NSButton *)sender {
    
    if (![CommonUtil validateMobile:self.userPhoneValue.stringValue]) {
        [EMRToast Show:@"请填写正确的手机号"];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didStartAndSaveData)]) {
        [self.delegate didStartAndSaveData];
    }
    
    SCAppVaribleHandleInstance.isStartMeasure = YES;
    [SCBleDataHandle sharedManager].isReadingAllBlock = NO;
    
    NSArray *deviceArray = [[SCBleDataHandle sharedManager] getDeviceArray];
    if (deviceArray.count > 0) {
        for (DeviceObject *pDev in deviceArray) {
            [[SCBleDataHandle sharedManager] getDongleActiveType:pDev];
        }
    } else {
        [EMRToast Show:@"当前没有连接的USB设备！"];
        [self hiddenProgressIndicator];
    }
}

- (IBAction)stopAndUploadData:(NSButton *)sender {
    
    if (!self.curBattery || self.curBattery == 0) {
        [CommonUtil showMessageWithTitle:@"设备还没有返回电量！！！"];
        return;
    }
    if (self.curBattery <= 45) {
        [CommonUtil showMessageWithTitle:@"设备电量少于45%，请充电后再上传！！！"];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didStopAndUploadData)]) {
        [self.delegate didStopAndUploadData];
    }
    
    [SCBleDataHandle sharedManager].isReadingAllBlock = YES;
    SCAppVaribleHandleInstance.isStopMeasure = YES;
    [SCAppVaribleHandleInstance.multiDeviceInfo removeAllObjects];
    self.startBlockDate = [NSDate date];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.holterChartView clearCanvas];
    });
    
    NSArray *deviceArray = [[SCBleDataHandle sharedManager] getDeviceArray];
    if (deviceArray.count > 0) {
        for (DeviceObject *pDev in deviceArray) {
            // 停止Dongle
            [[SCBleDataHandle sharedManager] setDongleActive:0x02 device:pDev];
        }
    } else {
        [EMRToast Show:@"当前没有连接的USB设备！"];
        [self hiddenProgressIndicator];
    }
}

- (IBAction)directCompletionButton:(NSButton *)sender {
    [self didFinishUploadAllData];
}

- (void)didFinishUploadAllData {
    NSString *phone = self.userPhoneValue.stringValue;
    if (![CommonUtil validateMobile:phone]) {
        [self hiddenProgressIndicator];
        [EMRToast Show:@"请输入手机号！"];
        WDLog(LOG_MODUL_BLE,@"请输入手机号！");
        return;
    }
    NSString *captcha = @"998080"; /// 为了筛查写的固定验证码
    if (self.captchaNum.length == 6) {
        captcha = self.captchaNum; // 如果用户自己输入了验证码，使用用户输入的验证码
    }

    [SCRequestHandle userLoginWithPhone:phone captcha:captcha completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            WDLog(LOG_MODUL_HTTPREQUEST,@"登录成功");
            
            [SCRequestHandle getCurUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    WDLog(LOG_MODUL_HTTPREQUEST,@"获取当前用户信息成功");
                    
                    // 记录id用于更新
                    SCUserInfoModel *userInfoModel = [[SCUserInfoModel alloc] init];
                    userInfoModel.userID = [[CommonUtil dataProcessing:responseObject title:@"userId" isInt:YES] intValue];
                    userInfoModel.memberID = [[CommonUtil dataProcessing:responseObject title:@"memberId" isInt:YES] intValue];
                    userInfoModel.name = [CommonUtil dataProcessing:responseObject title:@"name" isInt:NO];
                    userInfoModel.genderType = [[CommonUtil dataProcessing:responseObject title:@"gender" isInt:YES] intValue];
                    userInfoModel.iconUrl = [CommonUtil dataProcessing:responseObject title:@"avatarUrl" isInt:NO];
                    userInfoModel.birthday = [CommonUtil dataProcessing:responseObject title:@"birthdate" isInt:NO];
                    userInfoModel.height = [CommonUtil dataProcessing:responseObject title:@"height" isInt:NO];
                    userInfoModel.weight = [CommonUtil dataProcessing:responseObject title:@"weight" isInt:NO];
                    userInfoModel.phoneNum = phone;
                    SCAppVaribleHandleInstance.userInfoModel = userInfoModel;
                    
                    if ([@"" isEqualToString:userInfoModel.birthday] || !userInfoModel.birthday) {
                        WDLog(LOG_MODUL_HTTPREQUEST,@"当前账户没有注册,请重新输入手机号！");
                        [EMRToast Show:@"当前账户没有注册,请重新输入手机号！"];
                        [self hiddenProgressIndicator];
                        return;
                    }
                    
                    self.nameValue.stringValue = userInfoModel.name;
                    [self.genderValue selectItemAtIndex:(GenderType_male == userInfoModel.genderType ? 0 : GenderType_female == userInfoModel.genderType ? 1 : 2)];
                    self.ageValue.stringValue = [CommonUtil calAgeByBirthday:userInfoModel.birthday];
                    self.heightValue.stringValue = userInfoModel.height;
                    self.weightValue.stringValue = userInfoModel.weight;
                    self.userPhoneValue.stringValue = phone;
                    
                    [SCRequestHandle getCurrentDetectionDeviceInfo:nil completion:^(BOOL success, id  _Nonnull responseObject) {
                        if (success) {
                            WDLog(LOG_MODUL_HTTPREQUEST,@"获取当前检测信息成功");
                            SCDetectionInfo *detectionInfo = [SCDetectionInfo new];
                            detectionInfo.dataIndex = [[CommonUtil dataProcessing:responseObject title:@"dataIndex" isInt:YES] intValue];
                            detectionInfo.dataPageIndex = [[CommonUtil dataProcessing:responseObject title:@"dataPageIndex" isInt:YES] intValue];
                            detectionInfo.detectionId = [[CommonUtil dataProcessing:responseObject title:@"detectionId" isInt:YES] intValue];
                            detectionInfo.detectionId2Minutes = [[CommonUtil dataProcessing:responseObject title:@"detectionId2Minutes" isInt:YES] intValue];
                            detectionInfo.endPageIndex = [[CommonUtil dataProcessing:responseObject title:@"endPageIndex" isInt:YES] intValue];
                            
                            SCUploadDataInfo *uploadDataInfo = [SCUploadDataInfo new];
                            uploadDataInfo.dataBlockIndex = detectionInfo.dataIndex;
                            uploadDataInfo.dataLen = detectionInfo.dataPageIndex;
                            uploadDataInfo.dataPageIndex = detectionInfo.dataPageIndex;
                            uploadDataInfo.detectionType = 27;
                            uploadDataInfo.deviceType = 23;
                            uploadDataInfo.macAddress = @"";
                            uploadDataInfo.memberId = userInfoModel.memberID;
                            uploadDataInfo.samplingRate = 500;
                            
                            [SCRequestHandle finishFor24HoursWithUploadDataInfo:uploadDataInfo Completion:^(BOOL success, id  _Nonnull responseObject) {
                                if (success) {
                                    WDLog(LOG_MODUL_HTTPREQUEST, @"全部数据上传完成！");
                                    
                                } else {
                                    [EMRToast Show:[self handlingInvalidData:responseObject title:@"数据上传失败"]];
                                    [self hiddenProgressIndicator];
                                }
                            }];
                        } else {
                            [EMRToast Show:[self handlingInvalidData:responseObject title:@"获取当前检测信息失败"]];
                            [self hiddenProgressIndicator];
                        }
                    }];
                } else {
                    [EMRToast Show:[self handlingInvalidData:responseObject title:@"获取用户信息失败"]];
                    [self hiddenProgressIndicator];
                }
            }];
        } else {
            [EMRToast Show:[self handlingInvalidData:responseObject title:@"登录失败"]];
            [self hiddenProgressIndicator];
        }
    }];
}

- (IBAction)openUsersTable:(NSButton *)sender {
    
//    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//    NSArray<NSPasteboardType> *types = @[NSPasteboardTypeString];
//    [pasteboard declareTypes:types owner:nil];
//    [pasteboard setString:self.usersTableFilePath forType:NSPasteboardTypeString];
    
    
    [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:self.documentPath];
    
}
- (IBAction)disconnectDeviceBle:(NSButton *)sender {
    for (DeviceObject *pDev in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        [[SCBulkDataHandle sharedManager] disconnectBleDevice:pDev];
    }
    
    self.selectedDeviceSeri = @"";
    
    self.curBattery = 0;
    
    self.nameValue.stringValue = @"";
    self.ageValue.stringValue = @"";
    self.weightValue.stringValue = @"";
    self.heightValue.stringValue = @"";
    self.userPhoneValue.stringValue = @"";
    self.batteryStatus.stringValue = @"";
    [self.holterChartView clearCanvas];
    
    self.curEcgDataBlockDetail.stringValue = @"";
    self.readingBlockProgress.doubleValue = 0;
    self.readingBlockProgressValue.stringValue = @"0/10";
}
- (IBAction)connectDeviceBle:(NSButton *)sender {
    for (DeviceObject *pDev in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        self.selectedDeviceSeri = self.serialNumPopUpBtn.titleOfSelectedItem;
        if ([[SCBleDataHandle sharedManager].scanDeviceListDict.allKeys containsObject:self.selectedDeviceSeri]) {
            SCBulkDeviceInfo *bulkDeviceInfo = [SCBleDataHandle sharedManager].scanDeviceListDict[self.selectedDeviceSeri];
            [[SCBulkDataHandle sharedManager] connectBleDeviceIndex:bulkDeviceInfo.deviceIndex deviceObject:pDev];
        }
    }
}

- (void)writeCheckInDataToFile:(NSString *)dataStr {
    
    NSFileHandle *writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.usersTableFilePath];
    [writeFileHandle seekToEndOfFile];
    
    // excel使用UTF16才能显示汉字；如果显示为#######是因为格子宽度不够，拉开即可
    [writeFileHandle writeData:[dataStr dataUsingEncoding:NSUTF16StringEncoding]];
    [writeFileHandle synchronizeFile];
    
    [writeFileHandle closeFile];
}

- (void)hiddenProgressIndicator {
    if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
        [self.delegate didCompleteUploadData];
    }
}

// MARK: SCBleDataHandleDelegate
- (void)didReceiveBleBattery:(int)battery storage:(int)storage {

    self.curBattery = battery;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.batteryStatus.stringValue = [NSString stringWithFormat:@"电量:%d%% ， 内存:%d%%", battery, storage];
    });
}

- (void)didReceiveBleDisplayString:(NSString *)displayString {
    
//    if ([displayString containsString:@".MetaCor:"]) {
//        NSArray *receiveArray = [displayString componentsSeparatedByString:@"."];
//        if (receiveArray.count >= 2) {
//            NSString *indexStr = receiveArray[0];
//            NSString *serialStr = [receiveArray[1] componentsSeparatedByString:@", "][1];
//            NSString *index = [indexStr substringFromIndex:indexStr.length - 2];
//
//            if (![SCAppVaribleHandleInstance.deviceSerialDic.allKeys containsObject:serialStr]) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:serialStr action:@selector(null) keyEquivalent:@""];
//                    [self.serialNumPopUpBtn.menu addItem:menuItem];
//                });
//            }
//            SCAppVaribleHandleInstance.deviceSerialDic[serialStr] = index;
//        }
//    }
//
//    if ([displayString containsString:@"Already Connect ble device."]) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            for (DeviceObject *item in [[SCBleDataHandle sharedManager] getDeviceArray]) {
//                [[SCBleDataHandle sharedManager] getDongleSerialNumber:item]; // 获取序列号
//            }
//        });
//    } else if ([displayString containsString:@"Device disconnect."]) {
//        SCAppVaribleHandleInstance.deviceSerialDic = @{}.mutableCopy;
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.serialNumPopUpBtn removeAllItems];
//        });
//    }
}

- (void)didReceiveBulkDevice:(DeviceObject *)pDev connectState:(int)connectState {
    
    if (connectState == 1) { // 蓝牙设备未连接
        dispatch_async(dispatch_get_main_queue(), ^{
            [SCBleDataHandle sharedManager].scanDeviceListDict = @{}.mutableCopy;
            [self.serialNumPopUpBtn removeAllItems];
            [self.deviceListTableView reloadData];
            self.selectedDeviceSeri = @"";
        });
    } else { // 蓝牙设备已连接
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.selectedDeviceSeri.length > 0) {
                
                NSArray *tmpKeys = [SCBleDataHandle sharedManager].scanDeviceListDict.allKeys;
                for (int i = 0; i < tmpKeys.count; i++) {
                    if (![self.selectedDeviceSeri isEqualToString:tmpKeys[i]]) {
                        [[SCBleDataHandle sharedManager].scanDeviceListDict removeObjectForKey:tmpKeys[i]];
                    }
                }
                [self.deviceListTableView reloadData];
                
                [self.serialNumPopUpBtn removeAllItems];
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:self.selectedDeviceSeri action:@selector(null) keyEquivalent:@""];
                [self.serialNumPopUpBtn.menu addItem:menuItem];
                
            } else {
                [[SCBleDataHandle sharedManager] getDongleSerialNumber:pDev];
            }
        });
    }
}

- (void)didReceiveBulkScanDeviceList:(SCBulkDeviceInfo *)bulkDeviceInfo {
    NSArray *deviceSeriArray = [SCBleDataHandle sharedManager].scanDeviceListDict.allKeys;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![deviceSeriArray containsObject:bulkDeviceInfo.deviceSeri]) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:bulkDeviceInfo.deviceSeri action:@selector(null) keyEquivalent:@""];
            [self.serialNumPopUpBtn.menu addItem:menuItem];
        }
        [self.deviceListTableView reloadData];
    });
}

- (void)didReceiveBleVersion:(NSString *)version {
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.dongleVersion.stringValue = version;
//    });
}

- (void)didReceiveBleActiveType:(int)type deviceInfo:(SCMultiDeviceInfo *)deviceInfo {
    
    if (type == 1) { // 激活状态
        dispatch_async(dispatch_get_main_queue(), ^{
            [EMRToast Show:@"当前正在测量，请先停止且上传完数据后在开始测量！"];
            [self hiddenProgressIndicator];
        });
    } else if (type == 2) { // 停止状态
        [[SCBleDataHandle sharedManager] getEcgDataBlockCount:deviceInfo.deviceObject];
    } else if (type == 3) { // 读取模式
        
    } else { // invalid
        [[SCBleDataHandle sharedManager] getEcgDataBlockCount:deviceInfo.deviceObject];
    }

}

- (void)didReceiveBleAutoSave:(SCMultiDeviceInfo *)deviceInfo {
    
    [SCRequestHandle clearCacheDataDeviceInfo:deviceInfo completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            WDLog(LOG_MODUL_HTTPREQUEST, @"清除服务器缓存失败");
            [SCRequestHandle saveUserProcessingTimeCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    WDLog(LOG_MODUL_HTTPREQUEST, @"服务器设置开始测量时间成功");
                } else {
                    [EMRToast Show:[self handlingInvalidData:responseObject title:@"服务器设置开始测量时间失败"]];
                    WDLog(LOG_MODUL_HTTPREQUEST, @"服务器设置开始测量时间失败");
                }
            }];
        } else {
            [EMRToast Show:[self handlingInvalidData:responseObject title:@"清除服务器缓存失败"]];
            WDLog(LOG_MODUL_HTTPREQUEST, @"清除服务器缓存失败");
        }
    }];
    
}

- (void)didReceiveBleSerialNumber:(NSString *)deviceSerialNumber {
    WDLog(LOG_MODUL_BLE, @"获取到的设备序列号-->%@", deviceSerialNumber);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hiddenProgressIndicator];
        self.deviceSerialNumber.stringValue = deviceSerialNumber;
        [SCAppVaribleHandleInstance.deviceSerialDic removeAllObjects];
        [self.serialNumPopUpBtn removeAllItems];
        SCAppVaribleHandleInstance.deviceSerialDic[deviceSerialNumber] = @"00";
        [[SCBleDataHandle sharedManager].scanDeviceListDict removeAllObjects];
            
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:deviceSerialNumber action:@selector(null) keyEquivalent:@""];
        [self.serialNumPopUpBtn.menu addItem:menuItem];
        
    });
}

- (void)writeStartCheckInDataToFile {
    self.dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:SCAppVaribleHandleInstance.startRecordTimestamp/1000];
    NSString *startTime = [self.dateFormatter stringFromDate:startDate];
    NSString *tmpCheckInTime = SCAppVaribleHandleInstance.startCheckInTime;
    if (![startTime isEqualToString:tmpCheckInTime]) {
        SCAppVaribleHandleInstance.startSerialNumber = 0;
        [SCAppVaribleHandleInstance saveCurrentStartSerialNumber];
        SCAppVaribleHandleInstance.startCheckInTime = startTime;
        [SCAppVaribleHandleInstance saveCurrentStartCheckIn];
    }
    
    NSString *xlsxName = [NSString stringWithFormat:@"%@开始表.xls", startTime];
    [self createFileAtPath:xlsxName];
    
    self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *gender = SCAppVaribleHandleInstance.userInfoModel.genderType == GenderType_female ? @"女" : @"男";
    NSString *dataStr = [NSString stringWithFormat:@"%ld\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@cm\t%@kg\t%@\r\n", (long)SCAppVaribleHandleInstance.startSerialNumber, self.serialNumPopUpBtn.titleOfSelectedItem, [self.dateFormatter stringFromDate:startDate], @"", @"", SCAppVaribleHandleInstance.userInfoModel.name, gender, [CommonUtil calAgeByBirthday:SCAppVaribleHandleInstance.userInfoModel.birthday], SCAppVaribleHandleInstance.userInfoModel.height, SCAppVaribleHandleInstance.userInfoModel.weight, SCAppVaribleHandleInstance.userInfoModel.phoneNum];
    [self writeCheckInDataToFile:dataStr];
    
    SCAppVaribleHandleInstance.startSerialNumber++;
    [SCAppVaribleHandleInstance saveCurrentStartSerialNumber];
    
    
    SCRegFormSaveInfo *saveInfo = [SCRegFormSaveInfo new];
    saveInfo.name = SCAppVaribleHandleInstance.userInfoModel.name;
    saveInfo.gender = (int)SCAppVaribleHandleInstance.userInfoModel.genderType;
    saveInfo.age = [[CommonUtil calAgeByBirthday:SCAppVaribleHandleInstance.userInfoModel.birthday] intValue];
    saveInfo.height = [SCAppVaribleHandleInstance.userInfoModel.height intValue];
    saveInfo.weight = [SCAppVaribleHandleInstance.userInfoModel.weight intValue];
    saveInfo.phone = SCAppVaribleHandleInstance.userInfoModel.phoneNum;
    saveInfo.serial_number = self.serialNumPopUpBtn.titleOfSelectedItem;
    saveInfo.start_date = [self.dateFormatter stringFromDate:startDate];
    saveInfo.end_date = @"";
    saveInfo.block_count = 0;
    saveInfo.operating_time = startTime;
    saveInfo.operating_type = 1;
    [[SCDataBaseManagerHandle shareInstance].regFormDataBaseHandle saveRegFormDataWithInfo:saveInfo];
    
    [self hiddenProgressIndicator];
}

- (void)didReceiveBleECGDataBlockCount:(int)count deviceInfo:(SCMultiDeviceInfo *)deviceInfo {
    WDLog(LOG_MODUL_BLE, @"获取到当前设备的数据块有 --> %d", count);
    dispatch_async(dispatch_get_main_queue(), ^{
    
        if ([SCBleDataHandle sharedManager].isReadingUserInfoBlock) {
            [SCBleDataHandle sharedManager].isReadingUserInfoBlock = NO;
            if (count > 0) {
                WDLog(LOG_MODUL_BLE, @"开始从设备里面读取个人信息");
                SCAppVaribleHandleInstance.isReadBlockUserInfo = YES;
                [[SCBleDataHandle sharedManager] getEcgDataBlockDetailWithPageIndex:0 internalIndex:1 device:deviceInfo.deviceObject];
            } else {
                [self hiddenProgressIndicator];
                [EMRToast Show:@"当前设备没有数据"];
            }
        } else {
            if (![SCBleDataHandle sharedManager].isReadingAllBlock) {
                if (count > 0) {
                    [CommonUtil showMessageWithTitle:@"当前设备里面有测量数据，是否需要删除？"
                                    firstButtonTitle:@"删除"
                                          firstBlock:^{
                        WDLog(LOG_MODUL_BLE, @"进入读取模式然后删除设备里面的数据");
                        [[SCBleDataHandle sharedManager] enterReadMode:deviceInfo.deviceObject];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[SCBleDataHandle sharedManager] setDeviceSaveEcgModelTypeCmd:0x04 device:deviceInfo.deviceObject];
                        });
                    }
                                   secondButtonTitle:@"取消"
                                         secondBlock:^{[self hiddenProgressIndicator];}];
                } else {
                    
                    
                    if ([SCAppVaribleHandleInstance.deviceSerialDic.allKeys containsObject:self.serialNumPopUpBtn.titleOfSelectedItem]) {
                        NSString *index = SCAppVaribleHandleInstance.deviceSerialDic[self.serialNumPopUpBtn.titleOfSelectedItem];
                        [[SCBulkDataHandle sharedManager] connectBleDeviceIndex:index.intValue deviceObject:deviceInfo.deviceObject];
                    }
                    
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [[SCBleDataHandle sharedManager] getDongleSerialNumber:deviceInfo.deviceObject]; // 获取序列号
//                    });
                    
                    self.curEcgDataBlockDetail.stringValue = @"";
                    self.readingBlockProgress.doubleValue = 0;
                    self.readingBlockProgressValue.stringValue = @"0/10";
                    
                    NSString *captcha = @"998080"; /// 为了筛查写的固定验证码
                    if (self.captchaValue.stringValue.length == 6) {
                        captcha = self.captchaValue.stringValue;
                    }
                    
                    [SCRequestHandle userLoginWithPhone:self.userPhoneValue.stringValue captcha:captcha completion:^(BOOL success, id  _Nonnull responseObject) {
                        if (success) {
                            WDLog(LOG_MODUL_HTTPREQUEST, @"登录成功");
                            [SCRequestHandle getCurUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                                if (success) {
                                    
                                    WDLog(LOG_MODUL_HTTPREQUEST, @"获取用户信息成功");
                                    SCUserInfoModel *userInfoModel = SCAppVaribleHandleInstance.userInfoModel;
                                    
                                    userInfoModel.userID = [[CommonUtil dataProcessing:responseObject title:@"userId" isInt:YES] intValue];
                                    userInfoModel.memberID = [[CommonUtil dataProcessing:responseObject title:@"memberId" isInt:YES] intValue];
                                    userInfoModel.phoneNum = self.userPhoneValue.stringValue;
                                    userInfoModel.name = [self.nameValue.stringValue isEqualToString:@""] ? [CommonUtil dataProcessing:responseObject title:@"name" isInt:NO] : self.nameValue.stringValue;
                                    userInfoModel.genderType = [@"男" isEqualToString:self.genderValue.selectedItem.title] ? GenderType_male : [@"女" isEqualToString:self.genderValue.selectedItem.title] ? GenderType_female : GenderType_unknow;
                                    userInfoModel.birthday = [self.ageValue.stringValue isEqualToString:@""] ? [CommonUtil dataProcessing:responseObject title:@"birthdate" isInt:NO] : [CommonUtil calBirthdayByAge:self.ageValue.stringValue];
                                    userInfoModel.height = [self.heightValue.stringValue isEqualToString:@""] ? [CommonUtil dataProcessing:responseObject title:@"height" isInt:NO] : self.heightValue.stringValue;
                                    userInfoModel.weight = [self.weightValue.stringValue isEqualToString:@""] ? [CommonUtil dataProcessing:responseObject title:@"weight" isInt:NO] : self.weightValue.stringValue;
                                    SCAppVaribleHandleInstance.userInfoModel = userInfoModel;
                                    
                                    [SCRequestHandle updateMemberUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                                        if (success) {
                                            WDLog(LOG_MODUL_HTTPREQUEST, @"更新用户信息成功");
                                            WDLog(LOG_MODUL_BLE, @"设置设备时间");
                                            [[SCBleDataHandle sharedManager] setDongleTime:deviceInfo.deviceObject]; // 设置设备时间
                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                [self writeStartCheckInDataToFile];
                                            });
                                        } else {
                                            [EMRToast Show:[self handlingInvalidData:responseObject title:@"更新用户信息失败"]];
                                            [self hiddenProgressIndicator];
                                        }
                                    }];
                                } else {
                                    [EMRToast Show:[self handlingInvalidData:responseObject title:@"获取用户信息失败"]];
                                    [self hiddenProgressIndicator];
                                }
                            }];
                        } else {
                            [EMRToast Show:[self handlingInvalidData:responseObject title:@"登录失败"]];
                            [self hiddenProgressIndicator];
                        }
                    }];
                }
            }
        }
    });
}

- (void)didReceiveBleEcgDataBlockUserInfo:(SCMultiDeviceInfo *)deviceInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        __block NSString *phone = deviceInfo.userInfoModel.phoneNum;
        if (![CommonUtil validateMobile:phone]) {
            WDLog(LOG_MODUL_BLE,@"未获取到设备里手机号");
            phone = self.userPhoneValue.stringValue;  // 如果设备里面没有手机号，在判断用户有没有输入手机号，都没有就返回，一个有就登录
            if (![CommonUtil validateMobile:phone]) {
                [self hiddenProgressIndicator];
                [EMRToast Show:@"请输入手机号！"];
                WDLog(LOG_MODUL_BLE,@"请输入手机号！");
                return;
            }
        }
        
        [SCBleDataHandle sharedManager].isReadingAllBlock = YES;
        [SCBleDataHandle sharedManager].isNeedUploadData = YES;
        BOOL tmpIsDeleteECGData = (self.isDeleteECGData.state == NSControlStateValueOn);
        [SCBleDataHandle sharedManager].isDeleteECGData = tmpIsDeleteECGData;
        self.phoneNum = self.userPhoneValue.stringValue;
        self.captchaNum = self.captchaValue.stringValue;
        
        NSString *captcha = @"998080"; /// 为了筛查写的固定验证码
        if (self.captchaNum.length == 6) {
            captcha = self.captchaNum; // 如果用户自己输入了验证码，使用用户输入的验证码
        }
    
    
        [SCRequestHandle userLoginWithPhone:phone captcha:captcha completion:^(BOOL success, id  _Nonnull responseObject) {
            if (success) {
                deviceInfo.token = responseObject[@"data"];
                WDLog(LOG_MODUL_HTTPREQUEST,@"登录成功");
                
                [SCRequestHandle getCurUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                    if (success) {
                        WDLog(LOG_MODUL_HTTPREQUEST,@"获取当前用户信息成功");
                        
                        // 记录id用于更新
                        SCUserInfoModel *userInfoModel = [[SCUserInfoModel alloc] init];
                        userInfoModel.userID = [[CommonUtil dataProcessing:responseObject title:@"userId" isInt:YES] intValue];
                        userInfoModel.memberID = [[CommonUtil dataProcessing:responseObject title:@"memberId" isInt:YES] intValue];
                        userInfoModel.name = [CommonUtil dataProcessing:responseObject title:@"name" isInt:NO];
                        userInfoModel.genderType = [[CommonUtil dataProcessing:responseObject title:@"gender" isInt:YES] intValue];
                        userInfoModel.iconUrl = [CommonUtil dataProcessing:responseObject title:@"avatarUrl" isInt:NO];
                        userInfoModel.birthday = [CommonUtil dataProcessing:responseObject title:@"birthdate" isInt:NO];
                        userInfoModel.height = [CommonUtil dataProcessing:responseObject title:@"height" isInt:NO];
                        userInfoModel.weight = [CommonUtil dataProcessing:responseObject title:@"weight" isInt:NO];
                        userInfoModel.phoneNum = phone;
                        SCAppVaribleHandleInstance.userInfoModel = userInfoModel;
                        deviceInfo.userInfoModel = userInfoModel;
                        
                        if ([@"" isEqualToString:userInfoModel.birthday] || !userInfoModel.birthday) {
                            WDLog(LOG_MODUL_HTTPREQUEST,@"当前账户没有注册,请重新输入手机号！");
                            [EMRToast Show:@"当前账户没有注册,请重新输入手机号！"];
                            [self hiddenProgressIndicator];
                            return;
                        }
                        
                        self.nameValue.stringValue = userInfoModel.name;
                        [self.genderValue selectItemAtIndex:(GenderType_male == userInfoModel.genderType ? 0 : GenderType_female == userInfoModel.genderType ? 1 : 2)];
                        self.ageValue.stringValue = [CommonUtil calAgeByBirthday:userInfoModel.birthday];
                        self.heightValue.stringValue = userInfoModel.height;
                        self.weightValue.stringValue = userInfoModel.weight;
                        self.userPhoneValue.stringValue = phone;
                        
                        [SCRequestHandle getCurrentDetectionDeviceInfo:deviceInfo completion:^(BOOL success, id  _Nonnull responseObject) {
                            if (success) {
                                WDLog(LOG_MODUL_HTTPREQUEST,@"获取当前检测信息成功");
                                SCDetectionInfo *detectionInfo = [SCDetectionInfo new];
                                detectionInfo.dataIndex = [[CommonUtil dataProcessing:responseObject title:@"dataIndex" isInt:YES] intValue];
                                detectionInfo.dataPageIndex = [[CommonUtil dataProcessing:responseObject title:@"dataPageIndex" isInt:YES] intValue];
                                detectionInfo.detectionId = [[CommonUtil dataProcessing:responseObject title:@"detectionId" isInt:YES] intValue];
                                detectionInfo.detectionId2Minutes = [[CommonUtil dataProcessing:responseObject title:@"detectionId2Minutes" isInt:YES] intValue];
                                detectionInfo.endPageIndex = [[CommonUtil dataProcessing:responseObject title:@"endPageIndex" isInt:YES] intValue];
                                SCAppVaribleHandleInstance.detectionInfo = detectionInfo;
                                
                                WDLog(LOG_MODUL_BLE, @"进入读取模式");
                                [[SCBleDataHandle sharedManager] enterReadMode:deviceInfo.deviceObject];
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    WDLog(LOG_MODUL_BLE,@"开始数据全部上传，获取设备数据块！");
                                    [[SCBleDataHandle sharedManager] getEcgDataBlockCount:deviceInfo.deviceObject];
                                });
                            } else {
                                [EMRToast Show:[self handlingInvalidData:responseObject title:@"获取当前检测信息失败"]];
                                [self hiddenProgressIndicator];
                            }
                        }];
                    } else {
                        [EMRToast Show:[self handlingInvalidData:responseObject title:@"获取用户信息失败"]];
                        [self hiddenProgressIndicator];
                    }
                }];
            } else {
                [EMRToast Show:[self handlingInvalidData:responseObject title:@"登录失败"]];
                [self hiddenProgressIndicator];
            }
        }];
    });
}

- (void)didReceiveBleEcgDataBlockDetail:(NSString *)blockDetail {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.curEcgDataBlockDetail.stringValue = blockDetail;
    });
}

- (void)didReceiveBleDeleteData:(SCMultiDeviceInfo *)deviceInfo {
    
    WDLog(LOG_MODUL_BLE, @"退出读取模式");
    [[SCBleDataHandle sharedManager] exitReadMode:deviceInfo.deviceObject];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        WDLog(LOG_MODUL_BLE,@"数据删除成功！");
        [EMRToast Show:@"数据删除成功！"];
        [self hiddenProgressIndicator];
    });
    
}

- (void)didReceiveBleBlockProgress:(double)blockProgress blockProgressValue:(NSString *)blockProgressValue {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.readingBlockProgress.doubleValue = blockProgress;
        self.readingBlockProgressValue.stringValue = blockProgressValue;
    });
}

- (void)didReceiveBleLessPageData:(SCMultiDeviceInfo *)deviceInfo {
    WDLog(LOG_MODUL_BLE, @"最后块的页数少于3页，不需要读取！");
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonUtil showMessageWithTitle:@"最后块的页数少于3页，不需要读取！"];
    });
    
    [self didFinishUploadBlockData:deviceInfo];
}

- (void)didStartUploadFirstBlockData:(SCMultiDeviceInfo *)deviceInfo {
    
    if (!deviceInfo.userInfoModel) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            WDLog(LOG_MODUL_HTTPREQUEST,@"获取用户信息失败,请拔下设备重新尝试！");
            [EMRToast Show:@"获取用户信息失败,请拔下设备重新尝试！"];
            [self hiddenProgressIndicator];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            WDLog(LOG_MODUL_BLE, @"退出读取模式");
            [[SCBleDataHandle sharedManager] exitReadMode:deviceInfo.deviceObject];
        });
        
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.deviceSerialNumber.stringValue = deviceInfo.curBlockInfo.deviceSerialNumber;
    });
    
    self.dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSString *endTime = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString *tmpCheckInTime = SCAppVaribleHandleInstance.endCheckInTime;
    if (![endTime isEqualToString:tmpCheckInTime]) {
        SCAppVaribleHandleInstance.endSerialNumber = 0;
        [SCAppVaribleHandleInstance saveCurrentEndSerialNumber];
        SCAppVaribleHandleInstance.endCheckInTime = endTime;
        [SCAppVaribleHandleInstance saveCurrentEndCheckIn];
    }
    
    NSString *xlsxName = [NSString stringWithFormat:@"%@结束表.xls", endTime];
    [self createFileAtPath:xlsxName];
    
    self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:deviceInfo.start_timestamp];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:deviceInfo.end_timestamp];
    NSString *gender = deviceInfo.userInfoModel.genderType == GenderType_female ? @"女" : @"男";
    NSString *dataStr = [NSString stringWithFormat:@"%ld\t%@\t%@\t%@\t%d\t%@\t%@\t%@\t%@cm\t%@kg\t%@\r\n", (long)SCAppVaribleHandleInstance.endSerialNumber, deviceInfo.curBlockInfo.deviceSerialNumber, [self.dateFormatter stringFromDate:startDate], [self.dateFormatter stringFromDate:endDate], deviceInfo.blockCount, deviceInfo.userInfoModel.name, gender, [CommonUtil calAgeByBirthday:deviceInfo.userInfoModel.birthday], deviceInfo.userInfoModel.height, deviceInfo.userInfoModel.weight, deviceInfo.userInfoModel.phoneNum];
    [self writeCheckInDataToFile:dataStr];
    
    if (!SCAppVaribleHandleInstance.userInfoArray) {
        SCAppVaribleHandleInstance.userInfoArray = @[].mutableCopy;
    }
    [SCAppVaribleHandleInstance.userInfoArray addObject:[deviceInfo.userInfoModel yy_modelToJSONString]];
    [SCAppVaribleHandleInstance saveUserInfoArray];
    
    SCAppVaribleHandleInstance.endSerialNumber++;
    [SCAppVaribleHandleInstance saveCurrentEndSerialNumber];
    
    
    SCRegFormSaveInfo *saveInfo = [SCRegFormSaveInfo new];
    saveInfo.name = deviceInfo.userInfoModel.name;
    saveInfo.gender = (int)deviceInfo.userInfoModel.genderType;
    saveInfo.age = [[CommonUtil calAgeByBirthday:deviceInfo.userInfoModel.birthday] intValue];
    saveInfo.height = [deviceInfo.userInfoModel.height intValue];
    saveInfo.weight = [deviceInfo.userInfoModel.weight intValue];
    saveInfo.phone = deviceInfo.userInfoModel.phoneNum;
    saveInfo.serial_number = deviceInfo.curBlockInfo.deviceSerialNumber;
    saveInfo.start_date = [self.dateFormatter stringFromDate:startDate];
    saveInfo.end_date = [self.dateFormatter stringFromDate:endDate];
    saveInfo.block_count = deviceInfo.blockCount;
    saveInfo.operating_time = endTime;
    saveInfo.operating_type = 2;
    [[SCDataBaseManagerHandle shareInstance].regFormDataBaseHandle saveRegFormDataWithInfo:saveInfo];
    
}

- (void)didStartUploadBlockData:(SCMultiDeviceInfo *)deviceInfo {
    [self uploadDataToAliCloudService:deviceInfo];
}

/// 将数据上传到服务器
- (void)uploadDataToAliCloudService:(SCMultiDeviceInfo *)deviceInfo {
    SCUploadDataInfo *uploadDataInfo = [self getUploadDataInfo:deviceInfo isFinish:NO];
    SCAppVaribleHandleInstance.token = deviceInfo.token;
    [SCRequestHandle uploadDataFor24HoursWithUploadDataInfo:uploadDataInfo Completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            WDLog(LOG_MODUL_HTTPREQUEST, @"数据上传成功");
            if (deviceInfo.curUploadBlockIndex == deviceInfo.blockCount) {
                [self didFinishUploadBlockData:deviceInfo];
            } else {
                deviceInfo.curUploadBlockIndex++;
            }
        } else {
            [EMRToast Show:[self handlingInvalidData:responseObject title:@"数据上传失败"]];
            [[SCBleDataHandle sharedManager] exitReadMode:deviceInfo.deviceObject];
            [self hiddenProgressIndicator];
        }
    }];
}

- (void)didFinishUploadBlockData:(SCMultiDeviceInfo *)deviceInfo {
    SCUploadDataInfo *finishDataInfo = [self getUploadDataInfo:deviceInfo isFinish:YES];
    SCAppVaribleHandleInstance.token = deviceInfo.token;
    [SCRequestHandle finishFor24HoursWithUploadDataInfo:finishDataInfo Completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            WDLog(LOG_MODUL_HTTPREQUEST, @"全部数据上传完成！");
            [EMRToast Show:@"数据上传完成！"];
            
            [SCRequestHandle clearCacheDataDeviceInfo:deviceInfo completion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    WDLog(LOG_MODUL_HTTPREQUEST, @"clearCacheDataCompletion");

                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *timeIntervalStr = [NSString stringWithFormat:@"读取并上传数据共花费的时长为:%0.2fs", -[self.startBlockDate timeIntervalSinceNow]];
                        WDLog(LOG_MODUL_BLE, @"%@", timeIntervalStr);
                        self.curEcgDataBlockDetail.stringValue = timeIntervalStr;
                        self.readingBlockProgress.doubleValue = 0;
                        self.readingBlockProgressValue.stringValue = @"0/10";
                    });
                } else {
                    [EMRToast Show:[self handlingInvalidData:responseObject title:@"清除缓存失败"]];
                }
                [self playVoiceHandler];
                [self hiddenProgressIndicator];
            }];
            
        } else {
            [EMRToast Show:[self handlingInvalidData:responseObject title:@"数据上传失败"]];
            [self hiddenProgressIndicator];
        }
    }];
}

- (NSString *)handlingInvalidData:(id)responseObject title:(NSString *)title {
    NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : title;
    WDLog(LOG_MODUL_HTTPREQUEST, @"%@", msg);
    return msg;
}

- (SCUploadDataInfo *)getUploadDataInfo:(SCMultiDeviceInfo *)deviceInfo isFinish:(BOOL)isFinish {
    SCUploadDataInfo *uploadDataInfo = [SCUploadDataInfo new];
    if (!isFinish) {
        uploadDataInfo.rawData = deviceInfo.rawDataHexadecimalStr;
    }
    uploadDataInfo.dataBlockIndex = deviceInfo.curBlockIndex;
    uploadDataInfo.dataLen = deviceInfo.curBlockInfo.saved_datalen;
    uploadDataInfo.dataPageIndex = deviceInfo.curBlockInfo.endpageIndex;
//    uploadDataInfo.detectionTime = SCAppVaribleHandleInstance.startRecordTimestamp;
    uploadDataInfo.detectionType = 27;
    uploadDataInfo.deviceType = 23;
    uploadDataInfo.macAddress = deviceInfo.curBlockInfo.deviceMacAddress;
    uploadDataInfo.memberId = deviceInfo.userInfoModel.memberID;
    uploadDataInfo.samplingRate = deviceInfo.curBlockInfo.samplingRate;
//    uploadDataInfo.isToBin = YES;
    
    return uploadDataInfo;
}

/// 上传完后播放声音进行提示
- (void)playVoiceHandler {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"dingdong" ofType:@"wav"];
    NSURL *url = [NSURL URLWithString:bundlePath];
    SystemSoundID soundId = 0;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundId);
    AudioServicesPlayAlertSound(soundId);
    AudioServicesAddSystemSoundCompletion(soundId, nil, nil, AudioPlaybackComplete, nil);
    
}

static void AudioPlaybackComplete(SystemSoundID ssID, void *clientData) {
    WDLog(LOG_MODUL_HTTPREQUEST, @"AudioServicesRemoveSystemSoundCompletion");
    AudioServicesRemoveSystemSoundCompletion(ssID);
    AudioServicesDisposeSystemSoundID(ssID);
}

- (void)usbDidPlunIn:(DeviceObject *)usbObject {
//    [[SCBleDataHandle sharedManager] getDongleSerialNumber:usbObject]; // 获取序列号
}

- (void)usbDidRemove:(DeviceObject *)usbObject {
    [self hiddenProgressIndicator];
    self.curBattery = 0;
}

- (void)usbOpenFail {
    [self hiddenProgressIndicator];
    self.curBattery = 0;
}

@end
