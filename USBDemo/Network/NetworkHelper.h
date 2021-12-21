//
//  NetworkHelper.h
//  SAIAppUser
//
//  Created by golfy on 2019/4/6.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


#ifndef kIsNetwork
#define kIsNetwork [NetworkHelper isNetwork] // 一次性判断是否有网的宏
#endif

#ifndef kIsWWANNetwork
#define kIsWWANNetwork [NetworkHelper isWWANNetwork] // 一次性判断是否为手机网络的宏
#endif

#ifndef kIsWiFiNetwork
#define kIsWiFiNetwork [NetworkHelper isWiFiNetwork] // 一次性判断是否为WiFi网络的宏
#endif


#define Request_MessageStr @"message"
#define Request_DataStr @"data"
#define Request_CodeStr @"code"

//请求的消息结果
#define Request_Msg responseObject[Request_MessageStr]
//请求的data值
#define Request_Data responseObject[Request_DataStr]
//请求的code结果
#define Request_Code [responseObject[Request_CodeStr] integerValue]
//判断请求成功
#define Request_Success Request_Code == RequstCode_Success


typedef NS_ENUM(NSUInteger, RequstCode) {
    
    RequstCode_Success = 200,          // 成功
    
    RequstCode_HasBeenCertified = 300, // 已经认证过了
    RequstCode_NeedRelogin = 301,      // 需要重新登陆
    RequstCode_OtherPlaceLogin = 302,  // 别的地方登陆
    
    RequstCode_NeedVerifiyCode = 310,  // 需要输入图形验证码
    RequstCode_VerifiyCodeError = 311, // 需要输入图形验证码
    
    RequstCode_Unavailable = 320, // 申请不可用
    
    RequstCode_SystemErr = 500, //系统错误
};

typedef NS_ENUM(NSUInteger, ResponseErrCode) {
    
    ResponseErrCode_Success = 0,          // 成功
    ResponseErrCode_PhoneErr = 105,         // 账号错误
    ResponseErrCode_MsgCodeErr = 106,       // 验证码错误
    ResponseErrCode_CodeSendErr = 108,      // 验证码发送失败
    // http特殊状态码
    ResponseErrCode_BadRequest = 400,  // 客户端请求的语法错误，服务器无法理解
    ResponseErrCode_RequestTimeOut = 408,  // 服务器等待客户端发送的请求时间过长，超时
};

typedef NS_ENUM(NSUInteger, NetworkStatusType) {
    /// 未知网络
    NetworkStatusUnknown,
    /// 无网络
    NetworkStatusNotReachable,
    /// 手机网络
    NetworkStatusReachableViaWWAN,
    /// WIFI网络
    NetworkStatusReachableViaWiFi
};

typedef NS_ENUM(NSUInteger, RequestSerializer) {
    /// 设置请求数据为JSON格式
    RequestSerializerJSON,
    /// 设置请求数据为二进制格式
    RequestSerializerHTTP,
};

typedef NS_ENUM(NSUInteger, ResponseSerializer) {
    /// 设置响应数据为JSON格式
    ResponseSerializerJSON,
    /// 设置响应数据为二进制格式
    ResponseSerializerHTTP,
};

/// 请求成功的Block
typedef void (^HttpRequestSuccess)(id responseObject, NSInteger successCode);

/// 请求失败的Block
typedef void (^HttpRequestFailed)(NSError *error);

/// 缓存的Block
typedef void (^HttpRequestCache)(id responseCache);

/// 上传或者下载的进度, Progress.completedUnitCount:当前大小 - Progress.totalUnitCount:总大小
typedef void (^HttpProgress)(NSProgress *progress);

/// 网络状态的Block
typedef void (^NetworkStatus)(NetworkStatusType status);

@class AFHTTPSessionManager;


@interface NetworkHelper : NSObject

/// 有网YES, 无网:NO
+ (BOOL)isNetwork;

/// 手机网络:YES, 反之:NO
+ (BOOL)isWWANNetwork;

/// WiFi网络:YES, 反之:NO
+ (BOOL)isWiFiNetwork;

/// 取消所有HTTP请求
+ (void)cancelAllRequest;

/// 实时获取网络状态,通过Block回调实时获取(此方法可多次调用)
+ (void)networkStatusWithBlock:(NetworkStatus)networkStatus;

/// 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)URL;

/// 开启日志打印 (Debug级别)
+ (void)openLog;

/// 关闭日志打印,默认关闭
+ (void)closeLog;

//+ (void)showHub;
//+ (void)showAnimatedHub;
//+ (void)showHubWithUninteractions;
//+ (void)hideHub;

/**
 *  GET请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(nullable id)parameters
                           success:(HttpRequestSuccess)success
                           failure:(HttpRequestFailed)failure;

/**
 *  GET请求,自动缓存
 *
 *  @param URL           请求地址
 *  @param parameters    请求参数
 *  @param responseCache 缓存数据的回调
 *  @param success       请求成功的回调
 *  @param failure       请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(nullable id)parameters
                     responseCache:(HttpRequestCache)responseCache
                           success:(HttpRequestSuccess)success
                           failure:(HttpRequestFailed)failure;

/**
 *  POST请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(nullable id)parameters
                            success:(HttpRequestSuccess)success
                            failure:(HttpRequestFailed)failure;

/**
 *  PUT请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)PUT:(NSString *)URL
                        parameters:(id)parameters
                           success:(HttpRequestSuccess)success
                           failure:(HttpRequestFailed)failure;

/**
 *  PATCH请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
#pragma mark - PATCH请求
+ (__kindof NSURLSessionTask *)PATCH:(NSString *)URL
                          parameters:(id)parameters
                             success:(HttpRequestSuccess)success
                             failure:(HttpRequestFailed)failure;

/**
 DELETE请求

 @param URL 请求地址
 @param parameters 请求参数
 @param success 请求成功的回调
 @param failure 请求失败的回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)DELETE:(NSString *)URL
                           parameters:(nullable id)parameters
                              success:(HttpRequestSuccess)success
                              failure:(HttpRequestFailed)failure;

/**
 *  POST请求,自动缓存
 *
 *  @param URL           请求地址
 *  @param parameters    请求参数
 *  @param responseCache 缓存数据的回调
 *  @param success       请求成功的回调
 *  @param failure       请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(nullable id)parameters
                      responseCache:(HttpRequestCache)responseCache
                            success:(HttpRequestSuccess)success
                            failure:(HttpRequestFailed)failure;

/// 请求头增加mac地址
/// @param device_mac 设备mac地址
+ (void)addDeviceMacHeader:(NSString *)device_mac;

/**
 上传单张图片文件

 @param URL 请求地址
 @param parameters 请求参数
 @param name 图片对应服务器上的字段
 @param imagefilepath 图片本地路径
 @param imageName 图片保存名称
 @param imageType 图片文件的类型,例:png、jpg(默认类型)....
 @param progress 上传进度信息
 @param success 请求成功的回调
 @param failure 请求失败的回调
 @return 返回的对象可取消请求,调用cancel方法
 */
#pragma mark - PATCH上次单张图片文件
+ (NSURLSessionTask *)uploadPATCHImageFileWithURL:(NSString *)URL
                                  parameters:(nullable id)parameters
                                        name:(NSString *)name
                               imagefilepath:(NSString *)imagefilepath
                                   imageName:(NSString *)imageName
                                   imageType:(NSString *)imageType
                                    progress:(nullable HttpProgress)progress
                                     success:(HttpRequestSuccess)success
                                     failure:(HttpRequestFailed)failure;


/**
 *  下载文件
 *
 *  @param URL      请求地址
 *  @param fileDir  文件存储目录(默认存储目录为Download)
 *  @param progress 文件下载的进度信息
 *  @param success  下载成功的回调(回调参数filePath:文件的路径)
 *  @param failure  下载失败的回调
 *
 *  @return 返回NSURLSessionDownloadTask实例，可用于暂停继续，暂停调用suspend方法，开始下载调用resume方法
 */
+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)URL
                                       fileDir:(NSString *)fileDir
                                      progress:(HttpProgress)progress
                                       success:(void (^)(NSString *filePath))success
                                       failure:(HttpRequestFailed)failure;

/*
 **************************************  说明  **********************************************
 *
 * 在一开始设计接口的时候就想着方法接口越少越好,越简单越好,只有GET,POST,上传,下载,监测网络状态就够了.
 *
 * 无奈的是在实际开发中,每个A与后台服务器的数据交互都有不同的请求格式,如果要修改请求格式,就要在此封装
 * 内修改,再加上此封装在支持CocoaPods后,如果使用者pod update最新NetworkHelper,那又要重新修改此
 * 封装内的相关参数.
 *
 * 依个人经验,在项目的开发中,一般都会将网络请求部分封装 2~3 层,第2层配置好网络请求工具的在本项目中的各项
 * 参数,其暴露出的方法接口只需留出请求URL与参数的入口就行,第3层就是对整个项目请求API的封装,其对外暴露出的
 * 的方法接口只留出请求参数的入口.这样如果以后项目要更换网络请求库或者修改请求URL,在单个文件内完成配置就好
 * 了,大大降低了项目的后期维护难度
 *
 * 综上所述,最终还是将设置参数的接口暴露出来,如果通过CocoaPods方式使用NetworkHelper,在设置项目网络
 * 请求参数的时候,强烈建议开发者在此基础上再封装一层,通过以下方法配置好各种参数与请求的URL,便于维护
 *
 **************************************  说明  **********************************************
 */

#pragma mark - 设置AFHTTPSessionManager相关属性
#pragma mark 注意: 因为全局只有一个AFHTTPSessionManager实例,所以以下设置方式全局生效
/**
 在开发中,如果以下的设置方式不满足项目的需求,就调用此方法获取AFHTTPSessionManager实例进行自定义设置
 (注意: 调用此方法时在要导入AFNetworking.h头文件,否则可能会报找不到AFHTTPSessionManager的❌)
 @param sessionManager AFHTTPSessionManager的实例
 */
+ (void)setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager;

/**
 *  设置网络请求参数的格式:默认为二进制格式
 *
 *  @param requestSerializer RequestSerializerJSON(JSON格式),RequestSerializerHTTP(二进制格式),
 */
+ (void)setRequestSerializer:(RequestSerializer)requestSerializer;

/**
 *  设置服务器响应数据格式:默认为JSON格式
 *
 *  @param responseSerializer ResponseSerializerJSON(JSON格式),ResponseSerializerHTTP(二进制格式)
 */
+ (void)setResponseSerializer:(ResponseSerializer)responseSerializer;

/**
 *  设置请求超时时间:默认为30S
 *
 *  @param time 时长
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;

/// 设置请求头
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 *  是否打开网络状态转圈菊花:默认打开
 *
 *  @param open YES(打开), NO(关闭)
 */
+ (void)openNetworkActivityIndicator:(BOOL)open;

/**
 配置自建证书的Https请求
 
 @param cerPath 自建Https证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO; 即服务器使用其他可信任机构颁发
 的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外
 一个域名。因为SSL证书上的域名是独立的,假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;


/**
 以body的形式上传一个字典
 
 @param dict 字典
 */
+ (NSURLSessionTask *)uploadData:(NSDictionary *)dict
                             URL:(NSString *)urlStr
                         success:(HttpRequestSuccess)success
                         failure:(HttpRequestFailed)failure;


@end

NS_ASSUME_NONNULL_END
