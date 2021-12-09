//
//  ShortcutHeader.h
//  SAIAppUser
//
//  Created by golfy on 2019/4/6.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//
// 快捷宏

#ifndef ShortcutHeader_h
#define ShortcutHeader_h

typedef NS_ENUM(NSUInteger, AppCodeType) {
    AppCodeType_MetaHealth = 1,
    AppCodeType_MetaBeat,
    AppCodeType_MetaBP,
    AppCodeType_MetaBand,
    AppCodeType_PainDoctor,
};

typedef NS_ENUM(NSUInteger, DeviceSystemType) {
    DeviceSystemType_iOS = 1,
    DeviceSystemType_Android,
};

#define kMainBundleInfo [[NSBundle mainBundle] infoDictionary]                            //
#define kCurrentName [kMainBundleInfo objectForKey:@"CFBundleDisplayName"]           //获取当前 k 的名字
#define kAppBundleName [kMainBundleInfo objectForKey:@"CFBundleName"]
#define kCurrentBundleID [[NSBundle mainBundle] bundleIdentifier]                      //获取当前 app 的 bundleID
#define kCurrentVersion [kMainBundleInfo objectForKey:@"CFBundleShortVersionString"] //获取当前 app 的 版本号
#define kCurrentBuild [kMainBundleInfo objectForKey:@"CFBundleVersion"]              //获取当前 app 的 build 号
#define kUserDefaults [NSUserDefaults standardUserDefaults]                               //获取UserDefaults
#define kNotificationCenter [NSNotificationCenter defaultCenter]                          //defaultCenter
#define kChannel @"appstore"                                                              //获取渠道 上架还是企业包

//弱引用/强引用
#define kWeakSelf(type) __weak typeof(type) weak##type = type;
#define kStrongSelf(type) __strong typeof(type) type = weak##type;

/// socket获取identifier并且需要退出登录通知
#define WebSocketGetUUIDAndLogoutNotification @"WebSocketGetUUIDAndLogoutNotification"

/// 绑定用户到服务器通知
#define BindingUserToServerNotification @"BindingUserToServerNotification"

/// socket连接成功通知
#define WebSocketConnectedNotification @"WebSocketConnectedNotification"


#pragma mark-----------沙盒目录文件-----------

#define kPathTem NSTemporaryDirectory() //获取Temp 目录

//获取沙盒 Document
#define kPathDocument \
[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

//获取沙盒 Cache
#define kPathCache \
[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];

#pragma mark-----------View操作-----------

//设置 View 边框粗细和颜色
#define kViewBorderRadius(View, Width, color) \
\
[View.layer setBorderWidth:(Width)];       \
[View.layer setBorderColor:color]

//设置圆角
#define kViewSetRadius(View, Radius)      \
\
[View.layer setCornerRadius:(Radius)]; \
[View.layer setMasksToBounds:YES];

//定义UIImage对象

#define kImageWithFile(_pointer)                                                                                                     \
[UIImage imageWithContentsOfFile:([[NSBundle mainBundle]                                                                          \
pathForResource:[NSString stringWithFormat:@"%@@%dx",                                        \
_pointer, (int)[UIScreen mainScreen].nativeScale] \
ofType:@"png"])]

#define kIMAGE_NAMED(name) [UIImage imageNamed:name]

#pragma mark-----------GCD-----------

//GCD - 一次性执行

#define kDISPATCH_ONCE_BLOCK(onceBlock) \
static dispatch_once_t onceToken;    \
dispatch_once(&onceToken, onceBlock);

//GCD - 在Main线程上运行
#define kDISPATCH_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(), mainQueueBlock);

//GCD - 开启异步线程
#define kDISPATCH_GLOBAL_QUEUE_DEFAULT(globalQueueBlock) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), globalQueueBlock);

//单例
#define kSHAREINSTANCE_FOR_CLASS(__CLASSNAME__) \
\
static __CLASSNAME__ *instance = nil;        \
\
+(__CLASSNAME__ *)sharedInstance {           \
static dispatch_once_t onceToken;        \
dispatch_once(&onceToken, ^{             \
if (nil == instance) {                 \
instance = [[self alloc] init];    \
}                                      \
});                                      \
\
return instance;                         \
}

#endif

#pragma mark-----------打印日志-----------

//DEBUG 模式下打印日志,当前行
#ifdef DEBUG

#define DLog(format, ...) printf("%s [Line %d]  \n%s\n", __PRETTY_FUNCTION__, __LINE__, [[NSString stringWithFormat:(format), ##__VA_ARGS__] UTF8String])

#else

#define DLog(...)

#define KHRGB(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define KHRGBA(r,g,b,a) [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:a]
#define KHRGBCSS(rgb) KHRGB((double)(rgb >> 16 & 0xff), (double)(rgb >> 8 & 0xff), (double)(rgb & 0xff))
#define KHRGBCSSA(rgb,a) KHRGBA((double)(rgb >> 16 & 0xff), (double)(rgb >> 8 & 0xff), (double)(rgb & 0xff), a)

#endif /* ShortcutHeader_h */
