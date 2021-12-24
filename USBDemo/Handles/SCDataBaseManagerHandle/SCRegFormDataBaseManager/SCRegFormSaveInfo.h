//
//  SCRegFormSaveInfo.h
//  USBDemo
//
//  Created by golfy on 2021/12/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 RegForm对应关系表格:
 1.dbId
 2.name
 3.gender
 4.age
 5.height
 6.weight
 7.phone
 8.serial_number
 9.start_date
 10.end_date
 11.block_count
 */

@interface SCRegFormSaveInfo : NSObject

@property (nonatomic, assign) int dbId;
/// 操作时间
@property (nonatomic, copy) NSString *operating_time;
/// 操作状态
@property (nonatomic, assign) int operating_type;
/// 姓名
@property (nonatomic, copy) NSString *name;
/// 性别
@property (nonatomic, assign) int gender;
/// 年龄
@property (nonatomic, assign) int age;
/// 身高
@property (nonatomic, assign) int height;
/// 体重
@property (nonatomic, assign) int weight;
/// 手机号
@property (nonatomic, copy) NSString *phone;
/// 序列号
@property (nonatomic, copy) NSString *serial_number;
/// 开始时间（点击开始才会生成开始时间）
@property (nonatomic, copy) NSString *start_date;
/// 结束时间（需要从设备里获取结束时间）
@property (nonatomic, copy) NSString *end_date;
/// 数据块个数
@property (nonatomic, assign) int block_count;

@end

NS_ASSUME_NONNULL_END
