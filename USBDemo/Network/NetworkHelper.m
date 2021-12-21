//
//  NetworkHelper.m
//  SAIAppUser
//
//  Created by golfy on 2019/4/6.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "NetworkHelper.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "ShortcutHeader.h"
#import "SCAppVaribleHandle.h"
#import "ConstServerHeader.h"



#define NSStringFormat(format, ...) [NSString stringWithFormat:format, ##__VA_ARGS__]

@implementation NetworkHelper

static BOOL _isOpenLog = NO; // 是否已开启日志打印
static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

#pragma mark - 开始监听网络
+ (void)networkStatusWithBlock:(NetworkStatus)networkStatus {
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                networkStatus ? networkStatus(NetworkStatusUnknown) : nil;
                if (_isOpenLog)
                    NSLog(@"未知网络");
                break;
            case AFNetworkReachabilityStatusNotReachable:
                networkStatus ? networkStatus(NetworkStatusNotReachable) : nil;
                if (_isOpenLog)
                    NSLog(@"无网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                networkStatus ? networkStatus(NetworkStatusReachableViaWWAN) : nil;
                if (_isOpenLog)
                    NSLog(@"手机自带网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                networkStatus ? networkStatus(NetworkStatusReachableViaWiFi) : nil;
                if (_isOpenLog)
                    NSLog(@"WIFI");
                break;
        }
    }];
}

+ (BOOL)isNetwork {
    
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

+ (void)openLog {
    _isOpenLog = YES;
}

+ (void)closeLog {
    _isOpenLog = NO;
}

//+ (void)showHub {
//    [SVProgressHUD show];
//    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
//}
//
//+ (void)showHubWithUninteractions {
//    [SVProgressHUD show];
//    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
//}
//
//+ (void)hideHub {
//    [SVProgressHUD dismiss];
//}
//
//+ (void)showAnimatedHub {
//    [SVProgressHUD show];
//    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
//}

+ (void)cancelAllRequest {
    // 锁操作
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask *_Nonnull task, NSUInteger idx, BOOL *_Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL) {
        return;
    }
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask *_Nonnull task, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

//以键值对的方式上传
+ (NSURLSessionTask *)uploadData:(NSDictionary *)dict
                             URL:(NSString *)urlStr
                         success:(HttpRequestSuccess)success
                         failure:(HttpRequestFailed)failure {
    
    //转json数据
    NSString *string = nil;
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSData *myJSONData = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@%@", ServerUrlString, urlStr];
    
    //3.创建可变的请求对象
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:postUrl]];
    //4.修改请求方法为POST
    request.HTTPMethod = @"POST";
    //5.设置请求体
    request.HTTPBody = myJSONData;
    
    //头部
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:kChannel forHTTPHeaderField:@"channel"];
    [request setValue:@"iOS" forHTTPHeaderField:@"os"];                                            //手机型号(原始)
    [request setValue:kCurrentVersion forHTTPHeaderField:@"app-ver"]; //app版本
    
    NSURLSessionDataTask *dataTask = [_sessionManager dataTaskWithRequest:request
                                                           uploadProgress:nil
                                                         downloadProgress:nil
                                                        completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
                                                            
                                                            if (error) {
                                                                [self handelFailuerWith:nil error:error failure:failure];
                                                            } else {
                                                                [self handelSuccessDataWithRequestData:responseObject task:nil success:success];
                                                            }
                                                        }];
    
    //7.执行任务
    [dataTask resume];
    
    return dataTask;
}

#pragma mark - GET请求无缓存
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(id)parameters
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure {
    return [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - POST请求无缓存
+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(nullable id)parameters
                   success:(HttpRequestSuccess)success
                   failure:(HttpRequestFailed)failure {
    return [self POST:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - PUT请求
+ (__kindof NSURLSessionTask *)PUT:(NSString *)URL
                        parameters:(id)parameters
                           success:(HttpRequestSuccess)success
                           failure:(HttpRequestFailed)failure
{
    [self addHeader];
    
    NSURLSessionTask *sessionTask = [_sessionManager PUT:URL parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self handelSuccessDataWithRequestData:responseObject task:task success:success];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self handelFailuerWith:task error:error failure:failure];
    }];
    
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}

#pragma mark - PATCH请求
+ (__kindof NSURLSessionTask *)PATCH:(NSString *)URL
                          parameters:(id)parameters
                             success:(HttpRequestSuccess)success
                             failure:(HttpRequestFailed)failure
{
    [self addHeader];
    
    NSURLSessionTask *sessionTask = [_sessionManager PATCH:URL parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self handelSuccessDataWithRequestData:responseObject task:task success:success];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self handelFailuerWith:task error:error failure:failure];
    }];
    
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}

#pragma mark - DELETE请求
+ (__kindof NSURLSessionTask *)DELETE:(NSString *)URL
                           parameters:(nullable id)parameters
                              success:(HttpRequestSuccess)success
                              failure:(HttpRequestFailed)failure
{
    [self addHeader];
    
    NSURLSessionTask *sessionTask = [_sessionManager DELETE:URL parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self handelSuccessDataWithRequestData:responseObject task:task success:success];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self handelFailuerWith:task error:error failure:failure];
    }];
    
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}

#pragma mark - GET请求自动缓存
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(id)parameters
            responseCache:(HttpRequestCache)responseCache
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure {
    //读取缓存
//    responseCache != nil ? responseCache([NetworkCache httpCacheForURL:URL parameters:parameters]) : nil;
    
    [self addHeader];
    
    NSURLSessionTask *sessionTask = [_sessionManager GET:URL
                                              parameters:parameters
                                                progress:^(NSProgress *_Nonnull uploadProgress) {
                                                    
                                                }
                                                 success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {

                                                     [self handelSuccessDataWithRequestData:responseObject task:task success:success];
                                                     //对数据进行异步缓存
//                                                     responseCache != nil ? [NetworkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
                                                 }
                                                 failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                                                     
                                                     [self handelFailuerWith:task error:error failure:failure];
                                                     
                                                 }];
    // 添加sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - POST请求自动缓存
+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(nullable id)parameters
             responseCache:(HttpRequestCache)responseCache
                   success:(HttpRequestSuccess)success
                   failure:(HttpRequestFailed)failure {
    //读取缓存
//    responseCache != nil ? responseCache([NetworkCache httpCacheForURL:URL parameters:parameters]) : nil;
    
    [self addHeader];
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL
                                               parameters:parameters
                                                 progress:^(NSProgress *_Nonnull uploadProgress) {
                                                     
                                                 }
                                                  success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                                                      
                                                      [self handelSuccessDataWithRequestData:responseObject task:task success:success];
                                                      //对数据进行异步缓存
//                                                      responseCache != nil ? [NetworkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
                                                  }
                                                  failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                                                      
                                                      [self handelFailuerWith:task error:error failure:failure];
                                                      
                                                  }];
    
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}

+ (void)showError:(NSError *)error {
    
    NSData *data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
    NSLog(@"*----------错误信息---------*\n\n%@\n\n*---------*---------*\n", [self jsonValueDecoded:data]);
}

+ (id)jsonValueDecoded:(NSData *)data {
    NSError *error = nil;
    id value = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error) {
        NSLog(@"jsonValueDecoded error:%@", error);
    }
    return value;
}

#pragma mark - 上传文件
+ (void)addDeviceMacHeader:(NSString *)device_mac
{
    [_sessionManager.requestSerializer setValue:device_mac forHTTPHeaderField:@"x-device-mac"];
}

#pragma mark - PATCH上次单张图片文件
+ (NSURLSessionTask *)uploadPATCHImageFileWithURL:(NSString *)URL
                                  parameters:(nullable id)parameters
                                        name:(NSString *)name
                               imagefilepath:(NSString *)imagefilepath
                                   imageName:(NSString *)imageName
                                   imageType:(NSString *)imageType
                                    progress:(nullable HttpProgress)progress
                                     success:(HttpRequestSuccess)success
                                     failure:(HttpRequestFailed)failure
{
    
    [self addHeader];
    
    NSURLSessionTask *sessionTask = [_sessionManager PATCH:URL
                                               parameters:parameters
                                constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                    
                                    NSData *imageData = [NSData dataWithContentsOfFile:imagefilepath];
                                    [formData appendPartWithFileData:imageData
                                                                name:name
                                                            fileName:imageName
                                                            mimeType:NSStringFormat(@"image/%@", imageType ?: @"jpg")];
                                    
                                } progress:^(NSProgress * _Nonnull uploadProgress) {
                                    
                                    dispatch_sync(dispatch_get_main_queue(), ^{
                                        progress ? progress(uploadProgress) : nil;
                                    });
                                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                    
                                    [self handelSuccessDataWithRequestData:responseObject task:task success:success];
                                    
                                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                    
                                    [self handelFailuerWith:task error:error failure:failure];
                                }];
    
    // 添加sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - 下载文件
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(HttpProgress)progress
                              success:(void (^)(NSString *))success
                              failure:(HttpRequestFailed)failure {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request
                                                                                     progress:^(NSProgress *_Nonnull downloadProgress) {
                                                                                         //下载进度
                                                                                         dispatch_sync(dispatch_get_main_queue(), ^{
                                                                                             progress ? progress(downloadProgress) : nil;
                                                                                         });
                                                                                     }
                                                                                  destination:^NSURL *_Nonnull(NSURL *_Nonnull targetPath, NSURLResponse *_Nonnull response) {
                                                                                      //拼接缓存目录
                                                                                      NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
                                                                                      //打开文件管理器
                                                                                      NSFileManager *fileManager = [NSFileManager defaultManager];
                                                                                      //创建Download目录
                                                                                      [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
                                                                                      //拼接文件路径
                                                                                      NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
                                                                                      //返回文件位置的URL路径
                                                                                      return [NSURL fileURLWithPath:filePath];
                                                                                      
                                                                                  }
                                                                            completionHandler:^(NSURLResponse *_Nonnull response, NSURL *_Nullable filePath, NSError *_Nullable error) {
                                                                                
                                                                                [[self allSessionTask] removeObject:downloadTask];
                                                                                if (failure && error) {
                                                                                    failure(error);
                                                                                    return;
                                                                                };
                                                                                success ? success(filePath.absoluteString /** NSURL->NSString*/) : nil;
                                                                                
                                                                            }];
    //开始下载
    [downloadTask resume];
    // 添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
    
    return downloadTask;
}


#pragma mark 返回值成功回调处理
+ (void)handelSuccessDataWithRequestData:(id)responseObject task:(NSURLSessionDataTask *)task success:(HttpRequestSuccess)success {
    
    // 此处增加json格式数据解析
    responseObject = [[self class] jsonParseDataWith:responseObject];
    
//    success ? [NetworkHelper hideHub] : nil;
    if (_isOpenLog)
        NSLog(@"responseObject = %@", responseObject);
    
    [[self allSessionTask] removeObject:task];
    
    NSInteger statusCode = 500;
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)task.response;
        statusCode = urlResponse.statusCode;
    }
    int statusValue = (int)statusCode/100;
    if (2 == statusValue)
    {
        // 成功
        success ? success(responseObject, 0) : nil;
    }
    else
    {
        // 有失败,解析信息
        NSInteger successCode = statusCode;
        if ([responseObject isKindOfClass:[NSDictionary class]])
        {
            if (responseObject[@"number"])
            {
                successCode = ResponseErrCode_PhoneErr;
            }
            else if (responseObject[@"verification_code"])
            {
                successCode = ResponseErrCode_MsgCodeErr;
            }
        }
        success ? success(responseObject, successCode) : nil;
    }
}

/**
 解析得到json数据
 
 @param responseObject data数据
 @return json格式数据
 */
+ (nullable id)jsonParseDataWith:(id _Nullable)responseObject
{
    if (responseObject == nil)
    {
        return nil;
    }
    
    NSError *serializationError = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&serializationError];
    if (!jsonObj)
    {
        NSLog( @"json serialization error, %@", serializationError);
    }
    
    return jsonObj;
}

#pragma mark - 返回错误处理
+ (void)handelFailuerWith:(NSURLSessionDataTask *)task error:(NSError *)error failure:(HttpRequestFailed)failure {
    
    if (failure) {
//        [NetworkHelper hideHub];
        NSLog(@"网络错误");
        // 屏蔽显示网络错误 --modiyf by hexs, 2019.11.29
//        [SVProgressHUD showErrorWithStatus:@"网络错误"];
    }
    
    if (_isOpenLog)
        [self showError:error];
    
    [[self allSessionTask] removeObject:task];
    
    failure ? failure(error) : nil;
}

/**
 存储着所有的请求task数组
 */
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

#pragma mark - 头部处理
/**
 此方法处理上传的通用参数
 */
+ (void)addHeader {
    
    NSArray<NSHTTPCookie *> *cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies;
    NSString *csrftokenValue = nil;
    for (NSHTTPCookie *cookie in cookies)
    {
        if ([cookie.name isEqualToString:@"csrftoken"])
        {
            csrftokenValue = cookie.value;
        }
    }
    // 增加判断，如果token为空，但是csrftokenValue不为空，则认为系统缓存未清空, 立即再次清空
    if (csrftokenValue != nil &&
        ((SCAppVaribleHandleInstance.token == nil) || ([SCAppVaribleHandleInstance.token isEqualToString:@""])))
    {
        [NSHTTPCookieStorage.sharedHTTPCookieStorage removeCookiesSinceDate:[[NSDate alloc] initWithTimeIntervalSince1970:0]];
        csrftokenValue = nil;
    }
    
    if (csrftokenValue)
    {
        [_sessionManager.requestSerializer setValue:csrftokenValue forHTTPHeaderField:@"X-CSRFToken"];
    }
    
    if (SCAppVaribleHandleInstance.token != nil && (![SCAppVaribleHandleInstance.token isEqualToString:@""]))
    {
        [_sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"%@", SCAppVaribleHandleInstance.token] forHTTPHeaderField:@"Authorization"];
    }
    // 增加时区
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger secondsFromGMT = [zone secondsFromGMT];
    NSInteger minuteFromGMT = secondsFromGMT/60;
    [_sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"%ld", (long)minuteFromGMT] forHTTPHeaderField:@"Tz-Offset"];
    
#if __has_include("SCKeyChainStore.h")
    // 添加设备UUID
    [_sessionManager.requestSerializer setValue:[SCKeyChainStore getUUIDByKeyChain] forHTTPHeaderField:@"Terminal-Identifier"];
#endif
}

#pragma mark - 初始化AFHTTPSessionManager相关属性
/**
 开始监测网络状态
 */
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}
/**
 *  所有的HTTP请求共享一个AFHTTPSessionManager
 */
+ (void)initialize {
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:ServerUrlString]];
    //无条件的信任服务器上的证书
    AFSecurityPolicy *securityPolicy =  [AFSecurityPolicy defaultPolicy];
    // 客户端是否信任非法证书
    securityPolicy.allowInvalidCertificates = YES;
    // 是否在证书域字段中验证域名
    securityPolicy.validatesDomainName = NO;
    _sessionManager.securityPolicy = securityPolicy;
    
    _sessionManager.requestSerializer.timeoutInterval = 10.f;
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    //
    ((AFJSONResponseSerializer *)_sessionManager.responseSerializer).removesKeysWithNullValues = YES;
    _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];  // update by golfy at 2019.6.20 运来配置的服务是HTTP返回格式
    
    // 打开状态栏的等待菊花
//    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

#pragma mark - 重置AFHTTPSessionManager相关属性

+ (void)setAFHTTPSessionManagerProperty:(void (^)(AFHTTPSessionManager *))sessionManager {
    sessionManager ? sessionManager(_sessionManager) : nil;
}

+ (void)setRequestSerializer:(RequestSerializer)requestSerializer {
    _sessionManager.requestSerializer = requestSerializer == RequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(ResponseSerializer)responseSerializer {
    _sessionManager.responseSerializer = responseSerializer == ResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time {
    _sessionManager.requestSerializer.timeoutInterval = time;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

+ (void)openNetworkActivityIndicator:(BOOL)open{
//    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
    
}

+(void)setSecurityPolicyWithCerPath : (NSString *)cerPath validatesDomainName : (BOOL)validatesDomainName {
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    
    [_sessionManager setSecurityPolicy:securityPolicy];
}

@end
