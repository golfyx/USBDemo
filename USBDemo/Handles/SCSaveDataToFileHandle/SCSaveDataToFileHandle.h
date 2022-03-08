//
//  SCFileHandle.h
//  USBDemo
//
//  Created by golfy on 2021/11/19.
//

#import <Foundation/Foundation.h>
#import "SCDeviceAllBlockInfo.h"
#import "SCMultiDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef union __WORD_TYPE__
{
   unsigned char DataByte[4];
   unsigned int DataUint;
   signed int DataInt;
}WORD_TYPE;

typedef union __HALF_WORD_TYPE__
{
   unsigned char DataByte[2];
   unsigned short DataUShort;
   signed short DataShort;
}HALF_WORD_TYPE;

@interface SCSaveDataToFileHandle : NSObject

/// 多设备信息
@property (nonatomic, strong) SCMultiDeviceInfo *deviceInfo;


+ (instancetype)sharedManager;

/// 将数据保存到本地文件
- (void)writeDataToFile;
/// 将百惠数据保存到本地文件
- (void)writeBaiHuiDataToFile;
/// 合并所有文件
- (void)saveMergedBleDataFilePath;


@end

NS_ASSUME_NONNULL_END
