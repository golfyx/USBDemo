//
//  SCFileHandle.m
//  USBDemo
//
//  Created by golfy on 2021/11/19.
//

#import "SCSaveDataToFileHandle.h"
#import "WDLog.h"


@interface SCSaveDataToFileHandle ()

@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSString *docuDirectoryPath;
/** 读取块原始数据的16进制*/
@property (nonatomic, strong) NSString *filePathDataHexadecimal;


@end

@implementation SCSaveDataToFileHandle


+ (instancetype)sharedManager {
    
    static SCSaveDataToFileHandle * manager = nil;
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
        
    }
    return self;
}


/// 将数据保存到本地文件
- (void)writeDataToFile  {
    
    _docuDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:self.deviceInfo.curBlockInfo.start_timestamp];
    _docuDirectoryPath = [NSString stringWithFormat:@"%@/BlockFiles/%@/%@", _docuDirectoryPath, self.deviceInfo.curBlockInfo.deviceSerialNumber,  [dateFormatter stringFromDate:tmpStartDate]];
    
    _fileManager = [NSFileManager defaultManager];
    if ([_fileManager fileExistsAtPath:_docuDirectoryPath]) {
        WDLog(LOG_MODUL_BLE, @"目录已经存在");
    } else {
        BOOL ret = [_fileManager createDirectoryAtPath:_docuDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        if (ret) {
            WDLog(LOG_MODUL_BLE, @"目录创建成功");
        } else{
            WDLog(LOG_MODUL_BLE, @"目录创建失败");
        }
    }
    
    // 保存设备数据块的信息
    NSString *filePathInfo = [self createFileAtPathWithTitle:@"INFO" startTimestamp:self.deviceInfo.curBlockInfo.start_timestamp blockIndex:self.deviceInfo.curBlockInfo.blockIndex pathExtension:@"txt"];
    [self saveDeviceInfo:filePathInfo];
    
    // 将数据进行3转4后保存为十六进制文件
    NSString *filePathData = [self createFileAtPathWithTitle:@"HEX" startTimestamp:self.deviceInfo.curBlockInfo.start_timestamp blockIndex:self.deviceInfo.curBlockInfo.blockIndex pathExtension:@"bin"];
    // 将数据保存为十进制文件
    NSString *filePathDataDecimalism = [self createFileAtPathWithTitle:@"DEC" startTimestamp:self.deviceInfo.curBlockInfo.start_timestamp blockIndex:self.deviceInfo.curBlockInfo.blockIndex pathExtension:@"txt"];
    // 将百惠数据保存为十六进制文件
    NSString *filePathBaiHuiData = [self createFileAtPathWithTitle:@"BHHEX" startTimestamp:self.deviceInfo.curBlockInfo.start_timestamp blockIndex:self.deviceInfo.curBlockInfo.blockIndex pathExtension:@"dat"];
    [self.deviceInfo.filePathDataDecimalismArray addObject:filePathDataDecimalism];
    [self.deviceInfo.filePathDataHexadecimalArray addObject:filePathData];
    [self.deviceInfo.filePathBaiHuiDataHexadecimalArray addObject:filePathBaiHuiData];
    
    [self changeAndSaveBleUploadData:filePathData filePathDataDecimalism:filePathDataDecimalism filePathBaiHuiDataDecimalism:filePathBaiHuiData];
    
}

- (NSString *)createFileAtPathWithTitle:(NSString *)title startTimestamp:(long long)startTimestamp blockIndex:(UInt16)blockIndex pathExtension:(NSString *)pathExtension {
    
    NSString *tmpTimestamp = [NSString stringWithFormat:@"R_%d_%08llX_%@.%@", blockIndex + 1, startTimestamp, title, pathExtension];
    NSString *filePath = [_docuDirectoryPath stringByAppendingPathComponent:tmpTimestamp];
    
    //文件夹是否存在
    if (![_fileManager fileExistsAtPath:filePath]) {
        WDLog(LOG_MODUL_BLE, @"设备信息文件不存在,进行创建");
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
    NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:self.deviceInfo.curBlockInfo.start_timestamp];
    NSDate *tmpEndDate = [NSDate dateWithTimeIntervalSince1970:self.deviceInfo.curBlockInfo.end_timestamp];
    NSString *deviceInfo = [NSString stringWithFormat:@"当前块信息:\n当前是第几块 = %d, 开始时间 = %@, 结束时间 = %@  \n设备序列号 = %@, 设备Mac地址 = %@ \n当前块的数据长度 = %d, \n开始页的序号 = %d, 结束页的序号 = %d", self.deviceInfo.curBlockInfo.blockIndex + 1, [dateFormatter stringFromDate:tmpStartDate], [dateFormatter stringFromDate:tmpEndDate], self.deviceInfo.curBlockInfo.deviceSerialNumber, self.deviceInfo.curBlockInfo.deviceMacAddress, self.deviceInfo.curBlockInfo.saved_datalen, self.deviceInfo.curBlockInfo.startpageIndex, self.deviceInfo.curBlockInfo.endpageIndex];

    [writeFileHandle writeData:[deviceInfo dataUsingEncoding:NSUTF8StringEncoding]];
    [writeFileHandle synchronizeFile];
    [writeFileHandle closeFile];
}

// 将数据进行3转4后保存为十六进制文件 和十进制文件 百惠十六进制数据
- (void)changeAndSaveBleUploadData:(NSString *)filePathData
            filePathDataDecimalism:(NSString *)filePathDataDecimalism
            filePathBaiHuiDataDecimalism:(NSString *)filePathBaiHuiDataDecimalism {
    
    NSFileHandle *writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePathData];
    NSFileHandle *readFileHandle = [NSFileHandle fileHandleForReadingAtPath:filePathData];
    [writeFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
    NSFileHandle *writeDataDecimalismFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePathDataDecimalism];
    [writeDataDecimalismFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
    NSFileHandle *writeBaiHuiDataDecimalismFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePathBaiHuiDataDecimalism];
    
    Byte val1,val2,val3;
    WORD_TYPE value1,value2;
    Byte *resultBytes;
    NSData *tmpData;
    NSMutableData *tmpMutData;
    
    NSArray *tmpArray = self.deviceInfo.responsePageDataArray;
    for (int i = 0; i < tmpArray.count; i++) {
        NSArray *tmpSubArray = tmpArray[i];
        for (int j = 0; j < tmpSubArray.count; j++) {
            tmpData = tmpSubArray[j];
            if ([tmpData isKindOfClass: NSNumber.class]) {
                break;
            }
            
            resultBytes = (Byte *)[tmpData bytes];
            tmpMutData = [NSMutableData data];
            for (int k = 0; k < tmpData.length; k+=3) {
                val1 = resultBytes[k];
                val2 = resultBytes[k+1];
                val3 = resultBytes[k+2];
                
                value1.DataUint = (val2 & 0xf0) * 16 + val1;
                value2.DataUint = (val2 & 0x0f) * 256 + val3;
                
                value1.DataInt = value1.DataInt - 0x800;
                value2.DataInt = value2.DataInt - 0x800;
                
//                value1.DataUint = (value1.DataUint + 0x8000) & 0xFFFF;
//                value2.DataUint = (value2.DataUint + 0x8000) & 0xFFFF;  // 不需要加0x8000
                
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
            
        }
    }
    
    [writeFileHandle synchronizeFile];
    
    /// 这样写是为了截取掉多余的字节
    NSData *tmpReadFileData = [readFileHandle readDataOfLength:self.deviceInfo.curBlockInfo.saved_datalen];
    [writeFileHandle truncateFileAtOffset:0];
    [writeFileHandle writeData:tmpReadFileData];
    [writeFileHandle synchronizeFile];
    
    [writeFileHandle closeFile];
    [readFileHandle closeFile];
    
    NSMutableData *tmpMutBaiHuiData = [NSMutableData data];
    NSMutableString *tmpDecimalismStr = @"".mutableCopy;
    int j = 0;
    int intBaiHuiValue = 0;
    HALF_WORD_TYPE value3,value4;
    for (int i = 0; i < tmpReadFileData.length; i+=2) {
        memcpy(value3.DataByte, [[tmpReadFileData subdataWithRange:NSMakeRange(i, 2)] bytes], 2);
        
        if (tmpDecimalismStr.length > 0) {
            [tmpDecimalismStr appendFormat:@"\n"];
        }
        [tmpDecimalismStr appendFormat:@"%d", value3.DataShort];
        
        
        if (j % 5 == 0) {
            value3.DataShort = value3.DataShort * 2 + 1870;
            intBaiHuiValue = value3.DataShort & 0xff;
            [tmpMutBaiHuiData appendBytes:&intBaiHuiValue length:1];
            intBaiHuiValue = (value3.DataShort >> 8) & 0xff;
            [tmpMutBaiHuiData appendBytes:&intBaiHuiValue length:1];
        }
        j++;
        
        if (i < tmpReadFileData.length - 2) {
            if (j % 5 == 0) {
                memcpy(value4.DataByte, [[tmpReadFileData subdataWithRange:NSMakeRange(i+2, 2)] bytes], 2);
                value4.DataShort = (value3.DataShort + value4.DataShort) / 2;
                value4.DataShort = value4.DataShort * 2 + 1870;
                intBaiHuiValue = value4.DataShort & 0xff;
                [tmpMutBaiHuiData appendBytes:&intBaiHuiValue length:1];
                intBaiHuiValue = (value4.DataShort >> 8) & 0xff;
                [tmpMutBaiHuiData appendBytes:&intBaiHuiValue length:1];
            }
            j++;
        }
    }
    [writeBaiHuiDataDecimalismFileHandle truncateFileAtOffset:0];
    [writeBaiHuiDataDecimalismFileHandle writeData:tmpMutBaiHuiData];
    [writeBaiHuiDataDecimalismFileHandle synchronizeFile];
    
    [writeDataDecimalismFileHandle writeData:[tmpDecimalismStr dataUsingEncoding:NSUTF8StringEncoding]];
    [writeDataDecimalismFileHandle synchronizeFile];
    
    [writeBaiHuiDataDecimalismFileHandle closeFile];
    [writeDataDecimalismFileHandle closeFile];
    
}

/// 将百惠数据保存到本地文件
- (void)writeBaiHuiDataToFile {
    
}

// 合并所有文件
- (void)saveMergedBleDataFilePath {
    _docuDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSDate *tmpStartDate = [NSDate dateWithTimeIntervalSince1970:self.deviceInfo.curBlockInfo.start_timestamp];
    _docuDirectoryPath = [NSString stringWithFormat:@"%@/MergedFiles/%@/%@", _docuDirectoryPath, self.deviceInfo.curBlockInfo.deviceSerialNumber,  [dateFormatter stringFromDate:tmpStartDate]];
    
    if ([_fileManager fileExistsAtPath:_docuDirectoryPath]) {
        WDLog(LOG_MODUL_BLE, @"目录已经存在");
    } else {
        BOOL ret = [_fileManager createDirectoryAtPath:_docuDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        if (ret) {
            WDLog(LOG_MODUL_BLE, @"目录创建成功");
        } else{
            WDLog(LOG_MODUL_BLE, @"目录创建失败");
        }
    }

    NSString *mergedFilePathDataHexadecimal;
    NSString *mergedFilePathBaiHuiDataHexadecimal;
    NSString *mergedFilePathDataDecimalism;

    NSFileHandle *writeDataHexadecimalFileHandle;
    NSFileHandle *writeBaiHuiDataHexadecimalFileHandle;
    NSFileHandle *writeDataDecimalismFileHandle;

    NSString *tmpDecimalismOfRawDataStr;
    NSData *tmpHexadecimalData;
    NSData *tmpHexadecimalBaiHuiData;

    long long lastEndTimestamp = 0;
    long long curStartTimestamp = 0;
    SCDeviceBlockInfo *tmpDeviceBlockInfo;

    for (int i = 0; i < self.deviceInfo.filePathDataDecimalismArray.count; i++) {
        
        tmpDeviceBlockInfo = self.deviceInfo.allBlockInfo.allBlockInfoArray[i];
        curStartTimestamp = tmpDeviceBlockInfo.start_timestamp;
        // 计算是不是一次新的开始测量 第0个和 当前块的开始时间减去上一个块的结束时间的差值小于1就是连续的,否则重新创建文件
        if ((i == 0) || (curStartTimestamp - lastEndTimestamp > 2)) {
            mergedFilePathDataHexadecimal = [self createFileAtPathWithTitle:@"hexadecimal" startTimestamp:curStartTimestamp blockIndex:tmpDeviceBlockInfo.blockIndex pathExtension:@"bin"];
            mergedFilePathBaiHuiDataHexadecimal = [self createFileAtPathWithTitle:@"baihuihexadecimal" startTimestamp:curStartTimestamp blockIndex:tmpDeviceBlockInfo.blockIndex pathExtension:@"dat"];
            mergedFilePathDataDecimalism = [self createFileAtPathWithTitle:@"decimalism" startTimestamp:curStartTimestamp blockIndex:tmpDeviceBlockInfo.blockIndex pathExtension:@"txt"];

            
            writeDataHexadecimalFileHandle = [NSFileHandle fileHandleForWritingAtPath:mergedFilePathDataHexadecimal];
            [writeDataHexadecimalFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
            writeBaiHuiDataHexadecimalFileHandle = [NSFileHandle fileHandleForWritingAtPath:mergedFilePathBaiHuiDataHexadecimal];
            [writeBaiHuiDataHexadecimalFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
            writeDataDecimalismFileHandle = [NSFileHandle fileHandleForWritingAtPath:mergedFilePathDataDecimalism];
            [writeDataDecimalismFileHandle truncateFileAtOffset:0]; // 将文件字节截短至0，相当于将文件清空，可供文件填写
            
            tmpDecimalismOfRawDataStr = [NSString stringWithContentsOfFile:self.deviceInfo.filePathDataDecimalismArray[i] encoding:NSUTF8StringEncoding error:nil];
            [writeDataDecimalismFileHandle writeData:[tmpDecimalismOfRawDataStr dataUsingEncoding:NSUTF8StringEncoding]];
            [writeDataDecimalismFileHandle seekToEndOfFile];
        } else {
            
            [writeDataDecimalismFileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [writeDataDecimalismFileHandle seekToEndOfFile];
            
            tmpDecimalismOfRawDataStr = [NSString stringWithContentsOfFile:self.deviceInfo.filePathDataDecimalismArray[i] encoding:NSUTF8StringEncoding error:nil];
            [writeDataDecimalismFileHandle writeData:[tmpDecimalismOfRawDataStr dataUsingEncoding:NSUTF8StringEncoding]];
            [writeDataDecimalismFileHandle seekToEndOfFile];
        }
        
        tmpHexadecimalData = [NSData dataWithContentsOfFile:self.deviceInfo.filePathDataHexadecimalArray[i]];
        [writeDataHexadecimalFileHandle writeData:tmpHexadecimalData];
        [writeDataHexadecimalFileHandle seekToEndOfFile];
        
        tmpHexadecimalBaiHuiData = [NSData dataWithContentsOfFile:self.deviceInfo.filePathBaiHuiDataHexadecimalArray[i]];
        [writeBaiHuiDataHexadecimalFileHandle writeData:tmpHexadecimalBaiHuiData];
        [writeBaiHuiDataHexadecimalFileHandle seekToEndOfFile];
        
        lastEndTimestamp = tmpDeviceBlockInfo.end_timestamp;
    }

    [writeDataDecimalismFileHandle synchronizeFile];
    [writeDataDecimalismFileHandle closeFile];
    
    [writeDataHexadecimalFileHandle synchronizeFile];
    [writeDataHexadecimalFileHandle closeFile];
    
    [writeBaiHuiDataHexadecimalFileHandle synchronizeFile];
    [writeBaiHuiDataHexadecimalFileHandle closeFile];

}

@end
