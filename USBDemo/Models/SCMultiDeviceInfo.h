//
//  SCMultiDeviceInfo.h
//  USBDemo
//
//  Created by golfy on 2021/11/22.
//

#import <Foundation/Foundation.h>
#import "DeviceObject.h"
#import "SCBulkDataHandle.h"
#import "SCDeviceAllBlockInfo.h"
#import "SCUserInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCMultiDeviceInfo : NSObject


/* 总共多少块 */
@property (nonatomic, assign) int blockCount;
/* 当前块序号 */
@property (nonatomic, assign) int curBlockIndex;
/* 页的内部索引的个数 短包一页有11蓝牙包，长包一页有7个蓝牙包 */
@property (nonatomic, assign) int intervalPageIndex;

/// 读取时的块内部索引序号
@property (nonatomic, assign) int readBlockInternalIndex;
/// 读取时的页内部索引序号
@property (nonatomic, assign) int readPageInternalIndex;

/// 当前上传的块数
@property (nonatomic, assign) int curUploadBlockIndex;
/* 块的读取索引*/
@property (nonatomic, strong) SCDeviceAllBlockInfo *allBlockInfo;
@property (nonatomic, strong) SCDeviceBlockInfo *curBlockInfo;



/* 起始时间start_timestamp */
@property (nonatomic, assign) long long start_timestamp;
/* 结束时间end_timestamp(计算得到) */
@property (nonatomic, assign) long long end_timestamp;

/* 保存返回页的内容 */
@property (nonatomic, strong) NSMutableArray<NSMutableArray *> *responsePageDataArray;

/// 十进制的文件路径
@property (nonatomic, strong) NSMutableArray *filePathDataDecimalismArray;
/// 十六进制的文件路径
@property (nonatomic, strong) NSMutableArray *filePathDataHexadecimalArray;
/// 百惠十六进制的文件路径
@property (nonatomic, strong) NSMutableArray *filePathBaiHuiDataHexadecimalArray;


@property (nonatomic, strong) NSMutableString *rawDataHexadecimalStr;

@property (nonatomic, assign) uint bleCmdType;  // 该包的类型
@property (nonatomic, assign) uint subBleCmdType; // 该包(读取页的内容时有效)是否为短包还是长包
@property (nonatomic, assign) uint validPacketLen; // 该包(读取页的内容时有效)的有效数据长度,短包最后一段为0x90,长包的最后一段为0xDE
@property (nonatomic, assign) uint type;
@property (nonatomic, assign) uint bagIndex;
@property (nonatomic, assign) uint bagContentLen;
@property (nonatomic, assign) uint checkSum;
@property (nonatomic, assign) uint bagCount;

@property (nonatomic, assign) ObjectOfOperationState oooState;
@property (nonatomic, assign) PacketSendingReceivingState psrState;
/// 每个包的合并数据
@property (nonatomic, strong) NSMutableData *perBagData;
@property (nonatomic, strong) NSMutableString *receiveMStr;

///  页序号
@property (nonatomic, assign) int pageIndex;
///  块序号
@property (nonatomic, assign) int blockIndex;
///  读取时页的长度
@property (nonatomic, assign) int readDataLen;

/// 设备信息
@property (nonatomic, strong) DeviceObject *deviceObject;

/// 用户信息
@property (nonatomic, strong) SCUserInfoModel *userInfoModel;
/// 登录TOKEN
@property (nonatomic, copy) NSString *token;

/// 初始化file数组
- (void)clearFileCache;

@end

NS_ASSUME_NONNULL_END
