//
//  SCDeviceAllBagInfo.h
//  SAIAppUser
//
//  Created by He Kerous on 2019/12/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define MAC_LEN                              8
#define ID_NUM_BUFFER_LEN                    23
#define USER_ID_BUFFER_LEN                   32
#define SAVE_DATA_ONLY_FLAG_LEN              32
#define HEAD_BUFFER_LEN                      128

typedef struct
{
   unsigned short  SampleRate;   //采样率
   unsigned char   LeadCnt;      //导联个数
   unsigned char   LeadType;     //导联类型                          //...3
   unsigned int  StartTimeStamp; //开始时间戳                        //...7
   unsigned int  EndTimeStamp;   //结束时间戳                        //...11
 
   unsigned int  SaveDataLen;    //保存的数据长度                    //...15
   unsigned int  BeginPageIndex; //开始的页的索引                    //...19

   unsigned int  EndPageIndex;   //结束页的索引                      //...23
   unsigned char MacAddr[MAC_LEN]; //Mac地址                         //...31
    
   unsigned char IDNumberLen;    //IDnum的长度(序列号)                       //...32
   unsigned char IdNumberBuf[ID_NUM_BUFFER_LEN];  //ID号的内容(序列号)       //...55

   unsigned char UserIdLen;      //用户ID的长度                      //
   unsigned char SaveDataOnlyFlagLen;//保存数据唯一标识的长度
   unsigned char EndBlkValue;    //结束块的值
   unsigned char ReserveByte3;                                       //...59
    
   unsigned char UserIDStrBuf[USER_ID_BUFFER_LEN]; //用户ID字符串缓冲区   //...91

//保存唯一标识的缓冲区
   unsigned char SaveDataOnlyFlagBuf[SAVE_DATA_ONLY_FLAG_LEN];            //...123
   
}SAVE_DATA_PROPERTY_T;
//--------------------
typedef union
{
   unsigned char HeadBuffer[HEAD_BUFFER_LEN]; //128
   SAVE_DATA_PROPERTY_T DataHead;

}SAVE_DATA_HEAD;


/// 块详细信息
/// 每一页2048个字节,通过计算得到需要获取数据的起始结束页序号
@interface SCDeviceBlockInfo : NSObject

@property (nonatomic, assign) SAVE_DATA_HEAD saveDataHead;

/* 块总数 */
@property (nonatomic, assign) UInt16 blockCount;
/* 块index */
@property (nonatomic, assign) UInt16 blockIndex;
/* 起始时间start_timestamp */
@property (nonatomic, assign) long long start_timestamp;
/* 结束时间end_timestamp(计算得到) */
@property (nonatomic, assign) long long end_timestamp;
/* 当前块数据长度saved_datalen */
@property (nonatomic, assign) int saved_datalen;
/* 起始页序号 */
@property (nonatomic, assign) int startpageIndex;
/* 结束页序号 */
@property (nonatomic, assign) int endpageIndex;
/* 原始数据 */
@property (nonatomic, copy) NSData *buffer;

/* 设备序列号 */
@property (nonatomic, copy) NSString *deviceSerialNumber;
/* 设备MAC地址 */
@property (nonatomic, copy) NSString *deviceMacAddress;
/* 心电采样率 */
@property (nonatomic, assign) int samplingRate;
/// 导联数
@property (nonatomic, assign) int leadCount;
/// 导联类型
@property (nonatomic, assign) int leadTpye;
/// 用户ID
@property (nonatomic, copy) NSString *userId;
/// 唯一标示
@property (nonatomic, copy) NSString *onlyFlag;

/* 本地缓存文件路径 */
@property (nonatomic, copy) NSString *localFilePath;
/* 读取进度(0:等待读取, 1:读取完成) */
@property (nonatomic, assign) CGFloat readProgress;
@property (nonatomic, assign) NSTimeInterval readBeginTimeInterval;
@property (nonatomic, assign) NSTimeInterval readEndTimeInterval;
/* 上传进度(0:等待上传, 1:上传完成) */
@property (nonatomic, assign) CGFloat uploadProgress;
@property (nonatomic, assign) BOOL uploadSuccessed;

+ (instancetype)infoWithBlockIndex:(UInt16)blockIndex start_timestamp:(long long)start_timestamp end_timestamp:(long long)end_timestamp saved_datalen:(int)saved_datalen startpageIndex:(int)startpageIndex endpageIndex:(int)endpageIndex;
- (instancetype)initWithBlockIndex:(UInt16)blockIndex start_timestamp:(long long)start_timestamp end_timestamp:(long long)end_timestamp saved_datalen:(int)saved_datalen startpageIndex:(int)startpageIndex endpageIndex:(int)endpageIndex;

@end

@interface SCDeviceAllBlockInfo : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<SCDeviceBlockInfo *> *allBlockInfoArray;

@end

NS_ASSUME_NONNULL_END
