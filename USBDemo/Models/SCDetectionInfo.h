//
//  SCDetectionInfo.h
//  USBDemo
//
//  Created by golfy on 2021/12/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCDetectionInfo : NSObject

/// 当前数据块索引
@property (nonatomic, assign) int dataIndex;
/// 当前数据页索引
@property (nonatomic, assign) int dataPageIndex;
/// 当前进行中的24小时检测ID
@property (nonatomic, assign) int detectionId;
/// 当前进行中的2分钟检测ID
@property (nonatomic, assign) int detectionId2Minutes;
/// 块页数结束索引
@property (nonatomic, assign) int endPageIndex;

@end

NS_ASSUME_NONNULL_END
