//
//  SCAppVaribleHandle.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/6/26.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCAppVaribleHandle.h"


static NSString *const tokenStoreKey = @"tokenKey";
static NSString *const serialNumberKey = @"serialNumberKey";
static NSString *const checkInTimeKey = @"checkInTimeKey";

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
        _serialNumber = [[NSUserDefaults standardUserDefaults] integerForKey:serialNumberKey];
        _checkInTime = [[NSUserDefaults standardUserDefaults] stringForKey:checkInTimeKey];
        _userInfoModel = [SCUserInfoModel new];
        _multiDeviceInfo = @[].mutableCopy;
        _isReadBlockUserInfo = NO;
        
    }
    return self;
}

// 保存token
- (void)saveCurrentTokenInfo
{
    [[NSUserDefaults standardUserDefaults] setObject:_token forKey:tokenStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 清空token
- (void)clearCurrentTokenInfo
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:tokenStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _token = nil;
}


// 保存serialNumber
- (void)saveCurrentSerialNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:@(_serialNumber) forKey:serialNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 清空serialNumber
- (void)clearCurrentSerialNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:serialNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _serialNumber = 0;
}


// 保存登记时间
- (void)saveCurrentCheckIn
{
    [[NSUserDefaults standardUserDefaults] setObject:_checkInTime forKey:checkInTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
// 清空登记时间
- (void)clearCurrentCheckIn
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:checkInTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _checkInTime = nil;
}

// 清空cookie
- (void)clearHttpCookieCache
{
    NSArray<NSHTTPCookie *> *cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies;
    NSHTTPCookie *csrfcookie = nil;
    for (NSHTTPCookie *cookie in cookies)
    {
        if ([cookie.name isEqualToString:@"csrftoken"])
        {
            csrfcookie = cookie;
        }
    }
    
    if (csrfcookie)
    {
        [NSHTTPCookieStorage.sharedHTTPCookieStorage deleteCookie:csrfcookie];
    }
    // 清除所有缓存
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}


@end
