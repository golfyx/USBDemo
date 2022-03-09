//
//  CommonUtil.h
//  SAIAppUser
//
//  Created by golfy on 2019/4/6.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CompleteBlock)(void);

@interface CommonUtil : NSObject

/// 手机号判断
+ (BOOL)validateMobile:(NSString *)mobile;
/// 密码设置判断
+ (BOOL)validatePassword:(NSString *)passWord;
/// 用户名判断是否为中文英文数字组合
+ (BOOL)validateUserName:(NSString *)userName;
/// 用户名判断是否为中文英文数字组合,有就截取非法字符之前的
+ (NSString *)validateUserNameAndInterception:(NSString *)userName;
/// 返回值判断
+ (NSString *)validateStrValueIsNull:(id)value;
+ (NSNumber *)validateNumValueIsNull:(id)value;


///十进制转成十六进制
+ (NSString *)decimalismToHex:(NSInteger)tmpid;
/// 16进制的字符串转NSData
+ (NSData *)hexToBytes:(NSString *)str;
/// 16进制的data转成16进制的字符串
+ (NSString *)convertDataToHexStr:(NSData *)data;
/// 16进制的字符串翻转
+ (NSString *)reverseHexStr:(NSString *)dataStr;

/// 加密手机号
+ (NSString *)encryptPhoneNumber:(NSString *)phone;

/// 出生日期转化为年龄
+ (NSString *)calAgeByBirthday:(NSString *)birthday;
/// 年龄转化为出生日期
+ (NSString *)calBirthdayByAge:(NSString *)age;

/// 计算开始唯一标识
+ (NSString *)calUniqueFlag;

/**
 获取距离当前时间多久的一个日期
 @param year year=1表示1年后的时间 year=-1为1年前的日期
 @param month 距离现在几个月
 @param days 距离现在几天
 @return 返回一个新的日期
 */
+ (NSDate *)getNewDateDistanceNowWithYear:(NSInteger)year withMonth:(NSInteger)month withDays:(NSInteger)days;

+ (NSString *)getStrDateWithDateFormatter:(NSString *)formatter date:(NSDate *)date;

/// 弹出提示框
+ (void)showMessageWithTitle:(NSString *)title
            firstButtonTitle:(NSString *)firstButtonTitle
                  firstBlock:(CompleteBlock)firstBlock
           secondButtonTitle:(NSString *)secondButtonTitle
                 secondBlock:(CompleteBlock)secondBlock;

/// 弹出提示框
+ (void)showMessageWithTitle:(NSString *)title;

/// 通过XIB 名称获取View
+ (NSView *)getViewFromNibName:(NSString *)nibName;

/// 计算SendBuffer的校验和
+ (void)calXortmpForSendBuffer:(uint8_t *)target len:(uint8_t)len;

/// 处理服务器返回的NULL或者空值
+ (id)dataProcessing:(id)responseObject title:(NSString *)title isInt:(BOOL)isInt;

@end

NS_ASSUME_NONNULL_END
