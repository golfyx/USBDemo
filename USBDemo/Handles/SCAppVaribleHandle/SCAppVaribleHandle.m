//
//  SCAppVaribleHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/6/26.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCAppVaribleHandle.h"
#import "YYModel.h"

static NSString *const tokenStoreKey = @"tokenKey";
static NSString *const startSerialNumberKey = @"startSerialNumberKey";
static NSString *const userInfoArrayKey = @"userInfoArrayKey";
static NSString *const startCheckInTimeKey = @"startCheckInTimeKey";
static NSString *const endSerialNumberKey = @"endSerialNumberKey";
static NSString *const endCheckInTimeKey = @"endCheckInTimeKey";

@implementation SCAppVaribleHandle

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken = 0;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // 读取已经存储的值
        _token = [[NSUserDefaults standardUserDefaults] stringForKey:tokenStoreKey];
        
        _userInfoArray = [[NSUserDefaults standardUserDefaults] arrayForKey:userInfoArrayKey].mutableCopy;
        _startSerialNumber = [[NSUserDefaults standardUserDefaults] integerForKey:startSerialNumberKey];
        _startCheckInTime = [[NSUserDefaults standardUserDefaults] stringForKey:startCheckInTimeKey];
        _endSerialNumber = [[NSUserDefaults standardUserDefaults] integerForKey:endSerialNumberKey];
        _endCheckInTime = [[NSUserDefaults standardUserDefaults] stringForKey:endCheckInTimeKey];
        _userInfoModel = [SCUserInfoModel new];
        _multiDeviceInfo = @[].mutableCopy;
        _deviceSerialDic = @{}.mutableCopy;
        _isReadBlockUserInfo = NO;
        _isStartMeasure = NO;
        _isStopMeasure = NO;
        _isDeleteDongleData = NO;
        
        if (!_userInfoArray) {
            _userInfoArray = @[].mutableCopy;
        }
        
    }
    return self;
}

// 保存token
- (void)saveCurrentTokenInfo {
    [[NSUserDefaults standardUserDefaults] setObject:_token forKey:tokenStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 清空token
- (void)clearCurrentTokenInfo {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:tokenStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _token = nil;
}


/// 保存登记用户信息列表
- (void)saveUserInfoArray {
    [[NSUserDefaults standardUserDefaults] setObject:_userInfoArray forKey:userInfoArrayKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
/// 清空登记用户信息列表
- (void)clearUserInfoArray {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:userInfoArrayKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _userInfoArray = nil;
}


// 保存serialNumber
- (void)saveCurrentStartSerialNumber {
    [[NSUserDefaults standardUserDefaults] setObject:@(_startSerialNumber) forKey:startSerialNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 清空serialNumber
- (void)clearCurrentStartSerialNumber {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:startSerialNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _startSerialNumber = 0;
}


// 保存登记时间
- (void)saveCurrentStartCheckIn {
    [[NSUserDefaults standardUserDefaults] setObject:_startCheckInTime forKey:startCheckInTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
// 清空登记时间
- (void)clearCurrentStartCheckIn {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:startCheckInTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _startCheckInTime = nil;
}

// 保存serialNumber
- (void)saveCurrentEndSerialNumber {
    [[NSUserDefaults standardUserDefaults] setObject:@(_endSerialNumber) forKey:endSerialNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 清空serialNumber
- (void)clearCurrentEndSerialNumber {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:endSerialNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _endSerialNumber = 0;
}


// 保存登记时间
- (void)saveCurrentEndCheckIn {
    [[NSUserDefaults standardUserDefaults] setObject:_endCheckInTime forKey:endCheckInTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
// 清空登记时间
- (void)clearCurrentEndCheckIn {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:endCheckInTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _endCheckInTime = nil;
}

// 清空cookie
- (void)clearHttpCookieCache {
    NSArray<NSHTTPCookie *> *cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies;
    NSHTTPCookie *csrfcookie = nil;
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:@"csrftoken"]) {
            csrfcookie = cookie;
        }
    }
    
    if (csrfcookie) {
        [NSHTTPCookieStorage.sharedHTTPCookieStorage deleteCookie:csrfcookie];
    }
    // 清除所有缓存
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}


@end
