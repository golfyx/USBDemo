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
 获取一条指定的记录
 @param phone 手机号
 @return 一条记录信息
 */
- (SCRegFormSaveInfo *)acceptRegFormItemDataWithPhone:(NSString *)phone;

/**
 保存一条记录

 @param saveInfo info
 @return YES/NO
 */
- (BOOL)saveRegFormDataWithInfo:(SCRegFormSaveInfo *)saveInfo;

@end

NS_ASSUME_NONNULL_END
