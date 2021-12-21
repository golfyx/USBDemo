//
//  SCReportInfo.h
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCDoctorInfoVOS : NSObject

@property (nonatomic, assign) int detectionDoctorInfoId;
@property (nonatomic, assign) int reportId;
@property (nonatomic, strong) NSString *reportTime;
@property (nonatomic, strong) NSString *reportUrl;
@property (nonatomic, assign) int state;

@end

@interface SCReportInfo : NSObject
/// 心率
@property (nonatomic, assign) int bpm;
/// 检测ID
@property (nonatomic, assign) int detectionId;
/// 检测状态
@property (nonatomic, assign) int detectionStatus;
/// 检测时间
@property (nonatomic, strong) NSString *detectionTime;
/// 检测类型
@property (nonatomic, assign) int detectionType;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *doctorInfoVOS;
/// 医生端状态
@property (nonatomic, assign) int doctorState;
/// 心率异性
@property (nonatomic, strong) NSString *sdnn;

@end

NS_ASSUME_NONNULL_END
