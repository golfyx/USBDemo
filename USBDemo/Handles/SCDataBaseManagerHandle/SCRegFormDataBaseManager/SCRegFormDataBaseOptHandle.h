//
//  SCRegFormDataBaseOptHandle.h
//  USBDemo
//
//  Created by golfy on 2021/12/23.
//

#import "SCDataBaseAbstractOptHandle.h"
#import "SCRegFormSaveInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// 保存登记表
@interface SCRegFormDataBaseOptHandle : SCDataBaseAbstractOptHandle

/**
 获取一条指定手机号的记录
 @param phone 手机号
 @return 一条记录信息
 */
- (SCRegFormSaveInfo *)acceptRegFormItemDataWithPhone:(NSString *)phone;

/**
 获取指定日期的所有记录
 @param operating_time 操作时间
 @param operating_type 操作类型
 @return N条记录信息
 */
- (NSArray<SCRegFormSaveInfo *> *)acceptRegFormItemDataWithOperatingTime:(NSString *)operating_time  operatingType:(int)operating_type;

/**
 保存一条记录

 @param saveInfo info
 @return YES/NO
 */
- (BOOL)saveRegFormDataWithInfo:(SCRegFormSaveInfo *)saveInfo;

@end

NS_ASSUME_NONNULL_END
