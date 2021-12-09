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

@interface ScreeningView()<SCBleDataHandleDelegate>

@property (nonatomic, strong) NSString *phoneNum;
@property (nonatomic, strong) NSString *captchaNum;
@property (nonatomic, strong) NSString *documentPath;
@property (nonatomic, strong) NSString *usersTableFilePath;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;


@end

@implementation ScreeningView {
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

- (NSString *)usersTableFilePath {
    if (!_usersTableFilePath) {
        self.dateFormatter.dateFormat = @"yyyy-MM-dd";
        NSString *xlsxName = [NSString stringWithFormat:@"%@.xls", [self.dateFormatter stringFromDate:[NSDate date]]];
        _usersTableFilePath = [self.documentPath stringByAppendingPathComponent:xlsxName];
    }
    return _usersTableFilePath;
}

- (void)createFileAtPath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.documentPath]) {
        NSLog(@"目录已经存在");
    } else {
        if ([fileManager createDirectoryAtPath:self.documentPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            NSLog(@"目录创建成功");
        } else{
            NSLog(@"目录创建失败");
        }
    }
    
    //文件是否存在
    if (![fileManager fileExistsAtPath:self.usersTableFilePath]) {
        NSLog(@"设备信息文件不存在,进行创建");
        if ([fileManager createFileAtPath:self.usersTableFilePath contents:nil attributes:nil]) {
            NSLog(@"登记文件创建成功");
            // 字符串插入"\t" (Tab键,制表键的简写）,达到换列的作用。 \n 换行符
            [self writeCheckInDataToFile:@"序号\t设备号\t开始时间\t结束时间\t总块数\t姓名\t性别\t年龄\t身高\t体重\t手机号\n"];
        } else{
            NSLog(@"登记文件创建失败");
        }
    }
    
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.wantsLayer = YES;
    self.holterGriddingView.layer.shadowOffset = CGSizeMake(0, 5);
    self.holterGriddingView.layer.shadowRadius = 5;
    self.holterGriddingView.layer.shadowOpacity = 0.5f;
    self.holterGriddingView.layer.cornerRadius = 8;
    self.holterGriddingView.layer.masksToBounds = YES;
    

    [SCBleDataHandle sharedManager].delegate = self;
}

/// 激活蓝牙连接
- (void)activeBleHandle {
    [SCBleDataHandle sharedManager].delegate = self;
}

- (IBAction)getCaptcha:(NSButton *)sender {
    
    [SCRequestHandle acceptCaptchaWithPhone:self.userPhoneValue.stringValue];
}
- (IBAction)phoneCaptchaLogin:(NSButton *)sender {
    
    self.curEcgDataBlockDetail.stringValue = @"";
    self.readingBlockProgress.doubleValue = 0;
    self.readingBlockProgressValue.stringValue = @"0/10";
    
    
    NSString *captcha = @"998080"; /// 为了筛查写的固定验证码
    if (self.captchaValue.stringValue.length == 6) {
        captcha = self.captchaValue.stringValue;
    }
    
    if (![CommonUtil validateMobile:self.userPhoneValue.stringValue]) {
        [CommonUtil showMessageWithTitle:@"请填写正确的手机号"];
        return;
    }
    
    [SCRequestHandle userLoginWithPhone:self.userPhoneValue.stringValue captcha:captcha completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            
            [SCRequestHandle getCurUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    SCUserInfoModel *userInfoModel = SCAppVaribleHandleInstance.userInfoModel;
                    
                    userInfoModel.userID = [[CommonUtil dataProcessing:responseObject title:@"userId" isInt:YES] intValue];
                    userInfoModel.memberID = [[CommonUtil dataProcessing:responseObject title:@"memberId" isInt:YES] intValue];
                    userInfoModel.phoneNum = self.userPhoneValue.stringValue;
                    userInfoModel.name = [self.nameValue.stringValue isEqualToString:@""] ? [CommonUtil dataProcessing:responseObject title:@"name" isInt:NO] : self.nameValue.stringValue;
                    userInfoModel.genderType = [@"男" isEqualToString:self.genderValue.selectedItem.title] ? GenderType_male : [@"女" isEqualToString:self.genderValue.selectedItem.title] ? GenderType_female : GenderType_unknow;
                    NSDate *changeDate = [CommonUtil getNewDateDistanceNowWithYear:-[self.ageValue.stringValue intValue] withMonth:0 withDays:0];
                    userInfoModel.birthday = [self.ageValue.stringValue isEqualToString:@""] ? [CommonUtil dataProcessing:responseObject title:@"birthdate" isInt:NO] : [CommonUtil getStrDateWithDateFormatter:@"yyyy-MM-dd" date:changeDate];
                    userInfoModel.height = [self.heightValue.stringValue isEqualToString:@""] ? [CommonUtil dataProcessing:responseObject title:@"height" isInt:NO] : self.heightValue.stringValue;
                    userInfoModel.weight = [self.weightValue.stringValue isEqualToString:@""] ? [CommonUtil dataProcessing:responseObject title:@"weight" isInt:NO] : self.weightValue.stringValue;
                    SCAppVaribleHandleInstance.userInfoModel = userInfoModel;
                    
                    [SCRequestHandle updateMemberUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                        if (success) {
                            for (DeviceObject *item in [[SCBleDataHandle sharedManager] getDeviceArray]) {
                                [[SCBleDataHandle sharedManager] setDongleTime:item]; // 设置设备时间
                            }
                        } else {
                            NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"更新用户信息失败";
                            [CommonUtil showMessageWithTitle:msg];
                        }
                    }];
                } else {
                    NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"获取用户信息失败";
                    [CommonUtil showMessageWithTitle:msg];
                }
            }];
        } else {
            NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"登录失败";
            [CommonUtil showMessageWithTitle:msg];
        }
    }];
}

- (IBAction)stopAndUploadData:(NSButton *)sender {
    
    if ([self.delegate respondsToSelector:@selector(didStopAndUploadData)]) {
        [self.delegate didStopAndUploadData];
    }
    
    [SCBleDataHandle sharedManager].isReadingAllBlock = YES;
    [SCBleDataHandle sharedManager].isNeedUploadData = YES;
    BOOL tmpIsDeleteECGData = (self.isDeleteECGData.state == NSControlStateValueOn);
    [SCBleDataHandle sharedManager].isDeleteECGData = tmpIsDeleteECGData;
    [SCAppVaribleHandleInstance.multiDeviceInfo removeAllObjects];
    self.phoneNum = self.userPhoneValue.stringValue;
    self.captchaNum = self.captchaValue.stringValue;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.holterChartView clearCanvas];
    });
    
    for (DeviceObject *pDev in [[SCBleDataHandle sharedManager] getDeviceArray]) {
        // 停止Dongle
        [[SCBleDataHandle sharedManager] setDongleActive:0x02 device:pDev];
    }
}
- (IBAction)openUsersTable:(NSButton *)sender {
    
//    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//    NSArray<NSPasteboardType> *types = @[NSPasteboardTypeString];
//    [pasteboard declareTypes:types owner:nil];
//    [pasteboard setString:self.usersTableFilePath forType:NSPasteboardTypeString];
    
    
    [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:self.documentPath];
    
}

- (void)writeCheckInDataToFile:(NSString *)dataStr {
    
    NSFileHandle *writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.usersTableFilePath];
    [writeFileHandle seekToEndOfFile];
    
    // excel使用UTF16才能显示汉字；如果显示为#######是因为格子宽度不够，拉开即可
    [writeFileHandle writeData:[dataStr dataUsingEncoding:NSUTF16StringEncoding]];
    [writeFileHandle synchronizeFile];
    
    [writeFileHandle closeFile];
}

// MARK: SCBleDataHandleDelegate
- (void)didReceiveBleBattery:(int)battery storage:(int)storage {

    dispatch_async(dispatch_get_main_queue(), ^{
        self.batteryStatus.stringValue = [NSString stringWithFormat:@"电量:%d%% ， 内存:%d%%", battery, storage];
    });
}

- (void)didReceiveBleVersion:(NSString *)version {
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.dongleVersion.stringValue = version;
//    });
}

- (void)didReceiveBleAutoSave:(SCMultiDeviceInfo *)deviceInfo {
    
    [SCRequestHandle clearCacheDataDeviceInfo:deviceInfo completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            NSLog(@"clearCacheDataCompletion");
            [SCRequestHandle saveUserProcessingTimeCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    NSLog(@"saveUserProcessingTimeCompletion");
                } else {
                    NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"设置开始时间失败";
                    [CommonUtil showMessageWithTitle:msg];
                }
            }];
        } else {
            NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"清除缓存失败";
            [CommonUtil showMessageWithTitle:msg];
        }
    }];
    
}

- (void)didReceiveBleECGDataBlockCount:(int)count {
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.ecgDataBlockCount.stringValue = [NSString stringWithFormat:@"%d", count];
//    });
}

- (void)didReceiveBleEcgDataBlockUserInfo:(SCMultiDeviceInfo *)deviceInfo {
    
    __block NSString *phone = deviceInfo.userInfoModel.phoneNum;
    if (![CommonUtil validateMobile:phone]) {
        NSLog(@"未获取到设备里手机号");
        phone = self.phoneNum;  // 如果设备里面没有手机号，在判断用户有没有输入手机号，都没有就返回，一个有就登录
        if (![CommonUtil validateMobile:phone]) {
            return;
        }
    }
    NSString *captcha = @"998080"; /// 为了筛查写的固定验证码
    if (self.captchaNum.length == 6) {
        captcha = self.captchaNum; // 如果用户自己输入了验证码，使用用户输入的验证码
    }
    
    [SCRequestHandle userLoginWithPhone:phone captcha:captcha completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            deviceInfo.token = responseObject[@"data"];
            
            [SCRequestHandle getCurUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    
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
                    
                    [SCRequestHandle getCurrentDetectionDeviceInfo:deviceInfo completion:^(BOOL success, id  _Nonnull responseObject) {
                        if (success) {
                            
                            SCDetectionInfo *detectionInfo = [SCDetectionInfo new];
                            detectionInfo.dataIndex = [[CommonUtil dataProcessing:responseObject title:@"dataIndex" isInt:YES] intValue];
                            detectionInfo.dataPageIndex = [[CommonUtil dataProcessing:responseObject title:@"dataPageIndex" isInt:YES] intValue];
                            detectionInfo.detectionId = [[CommonUtil dataProcessing:responseObject title:@"detectionId" isInt:YES] intValue];
                            detectionInfo.detectionId2Minutes = [[CommonUtil dataProcessing:responseObject title:@"detectionId2Minutes" isInt:YES] intValue];
                            detectionInfo.endPageIndex = [[CommonUtil dataProcessing:responseObject title:@"endPageIndex" isInt:YES] intValue];
                            SCAppVaribleHandleInstance.detectionInfo = detectionInfo;
                            
                            [[SCBleDataHandle sharedManager] enterReadMode:deviceInfo.deviceObject];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                /// 开始数据全部上传
                                [[SCBleDataHandle sharedManager] getEcgDataBlockCount:deviceInfo.deviceObject];
                            });
                        } else {
                            NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"获取当前检测信息失败";
                            [CommonUtil showMessageWithTitle:msg];
                            if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
                                [self.delegate didCompleteUploadData];
                            }
                        }
                    }];
                } else {
                    NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"获取用户信息失败";
                    [CommonUtil showMessageWithTitle:msg];
                    if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
                        [self.delegate didCompleteUploadData];
                    }
                }
            }];
        } else {
            NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"登录失败";
            [CommonUtil showMessageWithTitle:msg];
            if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
                [self.delegate didCompleteUploadData];
            }
        }
    }];
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

- (void)didStartUploadFirstBlockData:(SCMultiDeviceInfo *)deviceInfo {
    
    self.dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:deviceInfo.start_timestamp];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:deviceInfo.end_timestamp];
    NSString *startTime = [self.dateFormatter stringFromDate:startDate];
    NSString *tmpCheckInTime = SCAppVaribleHandleInstance.checkInTime;
    if (![startTime isEqualToString:tmpCheckInTime]) {
        SCAppVaribleHandleInstance.serialNumber = 0;
        [SCAppVaribleHandleInstance saveCurrentSerialNumber];
        SCAppVaribleHandleInstance.checkInTime = startTime;
        [SCAppVaribleHandleInstance saveCurrentCheckIn];
    }
    [self createFileAtPath];
    
    self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *gender = deviceInfo.userInfoModel.genderType == GenderType_female ? @"女" : @"男";
    NSString *dataStr = [NSString stringWithFormat:@"%ld\t%@\t%@\t%@\t%d\t%@\t%@\t%@\t%@cm\t%@kg\t%@\n", (long)SCAppVaribleHandleInstance.serialNumber, deviceInfo.curBlockInfo.deviceSerialNumber, [self.dateFormatter stringFromDate:startDate], [self.dateFormatter stringFromDate:endDate], deviceInfo.blockCount, deviceInfo.userInfoModel.name, gender, [CommonUtil calAgeByBirthday:deviceInfo.userInfoModel.birthday], deviceInfo.userInfoModel.height, deviceInfo.userInfoModel.weight, deviceInfo.userInfoModel.phoneNum];
    [self writeCheckInDataToFile:dataStr];
    
    SCAppVaribleHandleInstance.serialNumber++;
    [SCAppVaribleHandleInstance saveCurrentSerialNumber];
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
            if (deviceInfo.curUploadBlockIndex == deviceInfo.blockCount) {
                [self didFinishUploadBlockData:deviceInfo];
            } else {
                deviceInfo.curUploadBlockIndex++;
            }
        } else {
            NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"数据上传失败";
            [CommonUtil showMessageWithTitle:msg];
            [[SCBleDataHandle sharedManager] exitReadMode:deviceInfo.deviceObject];
            if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
                [self.delegate didCompleteUploadData];
            }
        }
    }];
}

- (void)didFinishUploadBlockData:(SCMultiDeviceInfo *)deviceInfo {
    SCUploadDataInfo *finishDataInfo = [self getUploadDataInfo:deviceInfo isFinish:YES];
    SCAppVaribleHandleInstance.token = deviceInfo.token;
    [SCRequestHandle finishFor24HoursWithUploadDataInfo:finishDataInfo Completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            NSLog(@"全部数据上传完成！");
            [CommonUtil showMessageWithTitle:@"数据上传完成！"];
            
            [SCRequestHandle clearCacheDataDeviceInfo:deviceInfo completion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    NSLog(@"clearCacheDataCompletion");
                } else {
                    NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"清除缓存失败";
                    [CommonUtil showMessageWithTitle:msg];
                }
                if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
                    [self.delegate didCompleteUploadData];
                }
            }];
            
        } else {
            NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : @"数据上传失败";
            [CommonUtil showMessageWithTitle:msg];
            if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
                [self.delegate didCompleteUploadData];
            }
        }
    }];
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


- (void)usbDidPlunIn:(DeviceObject *)usbObject {
    
    
}

- (void)usbDidRemove:(DeviceObject *)usbObject {
    
    if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
        [self.delegate didCompleteUploadData];
    }
    
}

- (void)usbOpenFail {
    
    if ([self.delegate respondsToSelector:@selector(didCompleteUploadData)]) {
        [self.delegate didCompleteUploadData];
    }
    
}

@end
