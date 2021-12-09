//
//  SCDataUploadHandle.h
//  USBDemo
//
//  Created by golfy on 2021/11/23.
//

#import <Foundation/Foundation.h>
#import "SCMultiDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// 代理回调block
typedef void (^DelegateFeedbackBlock)(void);

@interface SCDataUploadHandle : NSObject

/// 解析块的个数
+ (SCMultiDeviceInfo *)analysisDataBlockCountWithDeviceInfo:(SCMultiDeviceInfo *)deviceInfo delegateFeedbackBlock:(DelegateFeedbackBlock)delegateFeedbackBlock;
/// 解析块的信息
- (void)analysisDataBlockDetail;
/// 解析块的内容
- (void)analysisDataBlockContent;

@end

NS_ASSUME_NONNULL_END
