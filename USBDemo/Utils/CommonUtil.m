//
//  CommonUtil.m
//  SAIAppUser
//
//  Created by golfy on 2019/4/6.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "CommonUtil.h"
#import "SCAppVaribleHandle.h"

@implementation CommonUtil

// 手机号判断
+ (BOOL)validateMobile:(NSString *)mobile {
    NSString *phoneRegex = @"^1[3|4|5|6|7|8|9][0-9]{9}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
    return [phoneTest evaluateWithObject:mobile];
}

// 密码设置判断
+ (BOOL)validatePassword:(NSString *)passWord {
    NSString *passWordRegex = @"^(?![0-9]+$)(?![a-zA-Z]+$)[0-9A-Za-z]{6,16}$";
    NSPredicate *passWordPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",passWordRegex];
    return [passWordPredicate evaluateWithObject:passWord];
}

/// 返回值判断
+ (NSString *)validateStrValueIsNull:(id)value {
    if (!value || [value isKindOfClass:NSNull.class]) {
        return @"";
    } else {
        return value;
    }
}
/// 返回值判断
+ (NSNumber *)validateNumValueIsNull:(id)value {
    if (!value || [value isKindOfClass:NSNull.class]) {
        return @(0);
    } else {
        return value;
    }
}

//将十进制转化为十六进制
+ (NSString *)decimalismToHex:(NSInteger)tmpid {
    NSString *nLetterValue;
    NSString *str = @"";
    int ttmpig;
    for (int i = 0; i < 9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig) {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    //不够一个字节凑0
    if (str.length == 1) {
        return [NSString stringWithFormat:@"0%@",str];
    } else {
        return str;
    }
}

/// 16进制的字符串转NSData
+ (NSData *)hexToBytes:(NSString *)str {
    
    NSMutableData* data = [NSMutableData data];
    
    if (!str || str.length <= 0) {
        return data;
    }
    
    if ([str.lowercaseString hasPrefix:@"0x"]) {
        NSRange range = NSMakeRange(2, str.length - 2);
        str = [str substringWithRange:range];
    }
    
    int idx;
    for (idx = 0; idx+2 <= str.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [str substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

/// 16进制的data转成16进制的字符串
+ (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

// 16进制的字符串翻转
+ (NSString *)reverseHexStr:(NSString *)dataStr {
    
    NSInteger len = [dataStr length];
    
    if (!dataStr || len == 0) {
        return @"";
    }
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:len];
    
    if ([dataStr.lowercaseString hasPrefix:@"0x"]) {
        [string appendString:@"0x"];
        NSRange range = NSMakeRange(2, len - 2);
        dataStr = [dataStr substringWithRange:range];
    }
    
    len = [dataStr length];
    NSString *subStr;
    for (NSInteger i = len - 2; i >= 0; i-=2) {
        subStr = [dataStr substringWithRange:NSMakeRange(i, 2)];
        [string appendString:subStr];
    }
    
    return string;
}

+ (NSString *)encryptPhoneNumber:(NSString *)phone {
    NSString *encryptPhone = @"";
    for (int i = 0; i < phone.length; i++) {
        NSString *ch = [phone substringWithRange:NSMakeRange(i, 1)];
        if (i > 2 && i < 7) {
            ch = @"*";
        }
        encryptPhone = [NSString stringWithFormat:@"%@%@",encryptPhone, ch];
    }
    
    return encryptPhone;
}

// 生日转化
+ (NSString *)calAgeByBirthday:(NSString *)birthday
{
    NSCalendar *calendar = [NSCalendar currentCalendar];//定义一个NSCalendar对象
        
    NSDate *nowDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    //生日
    NSDate *birthDay = [dateFormatter dateFromString:birthday];
    
    //用来得到详细的时差
    unsigned int unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *date = [calendar components:unitFlags fromDate:birthDay toDate:nowDate options:0];
    NSString *tempAge;
    
    if([date year] >0){
        tempAge = [NSString stringWithFormat:(@"%ld岁"),(long)[date year]];
//    }else if([date month] >0){
//        tempAge = [NSString stringWithFormat:(@"%ld月"),(long)[date month]];
//    }else if([date day]>0){
//        tempAge = [NSString stringWithFormat:(@"%ld天"),(long)[date day]];
    }else {
        tempAge = @"0岁";
    }
    return tempAge;
}

/// 计算开始唯一标识
+ (NSString *)calUniqueFlag {
    
    NSDate *today = [NSDate date];
    NSTimeInterval todayTime = [today timeIntervalSince1970];
    NSString *todayStr = [NSString stringWithFormat:@"%.0f", todayTime];
    NSString *userIdStr = [NSString stringWithFormat:@"%d", SCAppVaribleHandleInstance.userInfoModel.userID];
    
    return [NSString stringWithFormat:@"%@_%@", todayStr, userIdStr];
}

+ (NSDate *)getNewDateDistanceNowWithYear:(NSInteger)year withMonth:(NSInteger)month withDays:(NSInteger)days {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = nil;
    comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[NSDate date]];
    NSDateComponents *adcomps = [[NSDateComponents alloc]init];
    [adcomps setYear:year];//year=1表示1年后的时间 year=-1为1年前的日期
    [adcomps setMonth:month];
    [adcomps setDay:days];

    NSDate *newdate = [calendar dateByAddingComponents:adcomps toDate:[NSDate date] options:0];

    return newdate;
}

+ (NSString *)getStrDateWithDateFormatter:(NSString *)formatter date:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = formatter;
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    
    return [dateFormatter stringFromDate:date];
}

/// 弹出提示框
+ (void)showMessageWithTitle:(NSString *)title {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    [alert addButtonWithTitle:@"确定"];
//    [alert addButtonWithTitle:@"取消"];
    alert.messageText = @"Tips!";
    alert.informativeText = title;

    [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            NSLog(@"确定");
        } else if (returnCode == NSAlertSecondButtonReturn) {
            NSLog(@"取消");
        } else {
            NSLog(@"else");
        }
    }];
}

+ (NSView *)getViewFromNibName:(NSString *)nibName {
    
    NSView *view = nil;
    NSNib *xib = [[NSNib alloc] initWithNibNamed:nibName bundle:nil];
    NSArray *viewsArray = [[NSArray alloc] init];
    [xib instantiateWithOwner:nil topLevelObjects:&viewsArray];
    for (int i = 0; i < viewsArray.count; i++) {
        if ([viewsArray[i] isKindOfClass:[NSView class]]) {
            view = (NSView *)viewsArray[i];
            break;
        }
    }
    
    return view;
}

/// 计算SendBuffer的校验和
+ (void)calXortmpForSendBuffer:(uint8_t *)target len:(uint8_t)len {

    uint8_t xortmp;
    uint16_t i;
    
    xortmp = 0;
    for(i=0;i<len-1;i++)
    {
        xortmp = xortmp ^ target[i];
    }
    target[i] = xortmp;
    
}


/// 处理服务器返回的NULL或者空值
+ (id)dataProcessing:(id)responseObject title:(NSString *)title isInt:(BOOL)isInt {
    
    if (isInt) {
        return (responseObject[@"data"][title] && ![responseObject[@"data"][title] isKindOfClass:NSNull.class]) ? responseObject[@"data"][title] : @0;
    } else {
        return (responseObject[@"data"][title] && ![responseObject[@"data"][title] isKindOfClass:NSNull.class]) ? responseObject[@"data"][title] : @"";
    }
}

+(NSOpenPanel *)openPanelWithTitleMessage:(NSString *)ttMessage
                                setPrompt:(NSString *)prompt
                              chooseFiles:(BOOL)bChooseFiles
                        multipleSelection:(BOOL)bSelection
                        chooseDirectories:(BOOL)bChooseDirc
                        createDirectories:(BOOL)bCreateDirc
                          andDirectoryURL:(NSURL *)dirURL
                         AllowedFileTypes:(NSArray *)fileTypes
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt:prompt];     // 设置默认选中按钮的显示（OK 、打开，Open ...）
    [panel setMessage: ttMessage];    // 设置面板上的提示信息
    [panel setCanChooseDirectories : bChooseDirc]; // 是否可以选择文件夹
    [panel setCanCreateDirectories : bCreateDirc]; // 是否可以创建文件夹
    [panel setCanChooseFiles : bChooseFiles];      // 是否可以选择文件
    [panel setAllowsMultipleSelection : bSelection]; // 是否可以多选
    [panel setAllowedFileTypes : fileTypes];        // 所能打开文件的后缀
    [panel setDirectoryURL:dirURL];                    // 打开的文件路径
    
    return panel;
}

@end
