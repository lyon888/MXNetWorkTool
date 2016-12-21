//
//  MXNetWorkTool.h
//
//  Created by lyoniOS on 16/10/31.
//  Copyright © 2016年 lyoniOS. All rights reserved.
//

#import "MXNetWorkTool.h"
///</AFNetworking.h>这个文件是否存在.如果存在，能被引入就返回YES，否则返回NO
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#import <AFNetworkActivityIndicatorManager.h>
#else
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#endif
///md5
#import <CommonCrypto/CommonDigest.h>

static NSString *mx_privateNetworkBaseUrl = nil;
static BOOL mx_isEnableInterfaceDebug = NO;
static BOOL mx_shouldAutoEncode = NO;
static BOOL mx_shouldCallbackOnCancelRequest = YES;
static BOOL mx_cacheGet = YES;
static BOOL mx_cachePost = NO;
static NSDictionary *mx_httpHeaders = nil;
static NSTimeInterval mx_timeout = 60.0f;
static BOOL mx_shoulObtainLocalWhenUnconnected = NO;
static MXNetworkStatus mx_networkStatus = MXNetworkStatusUnknown;
static NSMutableArray *mx_requestTasks;

/**
 默认请求类型和响应类型为JSON:需要跟后台统一,如果后台返回的为文本类型
 可在AppDelegate设置以下方法为文本类型
 
 + (void)configRequestType:(MXRequestType)requestType
 responseType:(MXResponseType)responseType
 shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
 callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest
 
 //[self configRequestType:kMXRequestTypePlainText
 //           responseType:kMXResponseTypeData
 //    shouldAutoEncodeUrl:NO
 //callbackOnCancelRequest:YES];
 
 */
static MXResponseType mx_responseType = MXResponseTypeJSON;
static MXRequestType  mx_requestType  = MXRequestTypeJSON;

@implementation MXNetWorkTool

#pragma mark - Initialize

static inline NSString *cachePath() {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MXNetworkToolCaches"];
}

+ (MXNetworkStatus )networkStatus {
    return mx_networkStatus;
}

+ (void)updateBaseUrl:(NSString *)baseUrl {
    mx_privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl
{
    return mx_privateNetworkBaseUrl;
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
    mx_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
    
    return mx_isEnableInterfaceDebug;
}

+ (void)configRequestType:(MXRequestType)requestType
             responseType:(MXResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest {
    mx_requestType = requestType;
    mx_responseType = responseType;
    mx_shouldAutoEncode = shouldAutoEncode;
    mx_shouldCallbackOnCancelRequest = shouldCallbackOnCancelRequest;
}

+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost {
    mx_cacheGet = isCacheGet;
    mx_cachePost = shouldCachePost;
}

+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain {
    mx_shoulObtainLocalWhenUnconnected = shouldObtain;
}

+ (BOOL)shouldEncode {
    return mx_shouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
    mx_httpHeaders = httpHeaders;
}

#pragma mark - Constructor

+ (MXURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         success:(MXResponseSuccess)success
                            fail:(MXResponseFail)fail {
    return [self getWithUrl:url
               refreshCache:refreshCache
                     params:nil
                    success:success
                       fail:fail];
}

+ (MXURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                          params:(NSMutableDictionary *)params
                         success:(MXResponseSuccess)success
                            fail:(MXResponseFail)fail {
    return [self getWithUrl:url
               refreshCache:refreshCache
                     params:params
                   progress:nil
                    success:success
                       fail:fail];
}

+ (MXURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                          params:(NSMutableDictionary *)params
                        progress:(MXPostProgress)progress
                         success:(MXResponseSuccess)success
                            fail:(MXResponseFail)fail {
    return [self _requestWithUrl:url
                    refreshCache:refreshCache
                      httpMethod:MXRequestMethodGet
                          params:params
                        progress:progress
                         success:success
                            fail:fail];
}



+ (MXURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSMutableDictionary *)params
                          success:(MXResponseSuccess)success
                             fail:(MXResponseFail)fail {
    return [self postWithUrl:url
                refreshCache:refreshCache
                      params:params
                    progress:nil
                     success:success
                        fail:fail];
}

+ (MXURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSMutableDictionary *)params
                         progress:(MXPostProgress)progress
                          success:(MXResponseSuccess)success
                             fail:(MXResponseFail)fail {
    return [self _requestWithUrl:url
                    refreshCache:refreshCache
                      httpMethod:MXRequestMethodPost
                          params:params
                        progress:progress
                         success:success
                            fail:fail];
}

+ (MXURLSessionTask *)_requestWithUrl:(NSString *)url
                         refreshCache:(BOOL)refreshCache
                           httpMethod:(MXRequestMethod)httpMethod
                               params:(NSMutableDictionary *)params
                             progress:(MXPostProgress)progress
                              success:(MXResponseSuccess)success
                                 fail:(MXResponseFail)fail {
    //拼接全局参数
    params=[self globalParams:params url:url];
    
    AFHTTPSessionManager *manager = [self manager];
    
    //处理传入URL，全称原样返回，不是则拼接返回
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            MXLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        NSURL *absouluteURL = [NSURL URLWithString:absolute];
        if (absouluteURL == nil) {
            MXLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    //URL转码操作
    if ([self shouldEncode]) {
        absolute = [self encodeUrl:absolute];
    }
    
    MXURLSessionTask *session = nil;
    
    if (httpMethod == MXRequestMethodGet) {
        
        if (mx_cacheGet) {//设置Get方式是否取缓存数据
            if (mx_shoulObtainLocalWhenUnconnected) {//是否从本地取缓存数据
                if (mx_networkStatus == MXNetworkStatusNotReachable || mx_networkStatus == MXNetworkStatusUnknown ) {//没有网络时
                    id response = [MXNetWorkTool cahceResponseWithURL:absolute
                                                           parameters:params];
                    if (response) {
                        if (success) {
                            [self successResponse:response callback:success];
                            
                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:absolute
                                                      params:params];
                            }
                        }
                        return nil;
                    }
                }
            }
            if (!refreshCache) {// 获取缓存
                id response = [MXNetWorkTool cahceResponseWithURL:absolute
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params];
                        }
                    }
                    return nil;
                }
            }
        }
        
        session = [manager GET:absolute parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success];
            
            if (mx_cacheGet) {
                [self cacheResponseObject:responseObject request:task.currentRequest parameters:params];
            }
            
            [[self allTasks] removeObject:task];
            
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:absolute
                                      params:params];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];
            
            if ([error code] < 0 && mx_cacheGet) {// 获取缓存
                id response = [MXNetWorkTool cahceResponseWithURL:absolute
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params];
                        }
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    
                    if ([self isDebug]) {
                        [self logWithFailError:error url:absolute params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:absolute params:params];
                }
            }
        }];
        
    } else if (httpMethod == MXRequestMethodPost) {//POST请求
        if (mx_cachePost) {// 获取缓存
            if (mx_shoulObtainLocalWhenUnconnected) {
                if (mx_networkStatus == MXNetworkStatusNotReachable ||  mx_networkStatus == MXNetworkStatusUnknown ) {
                    id response = [MXNetWorkTool cahceResponseWithURL:absolute
                                                           parameters:params];
                    if (response) {
                        if (success) {
                            [self successResponse:response callback:success];
                            
                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:absolute
                                                      params:params];
                            }
                        }
                        return nil;
                    }
                }
            }
            
            if (!refreshCache) {
                id response = [MXNetWorkTool cahceResponseWithURL:absolute
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params];
                        }
                    }
                    return nil;
                }
            }
        }
        
        session = [manager POST:absolute parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            [self successResponse:responseObject callback:success];
            
            if (mx_cachePost) {
                [self cacheResponseObject:responseObject request:task.currentRequest  parameters:params];
            }
            
            [[self allTasks] removeObject:task];
            
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:absolute
                                      params:params];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];
            
            if ([error code] < 0 && mx_cachePost) {// 获取缓存
                id response = [MXNetWorkTool cahceResponseWithURL:absolute
                                                       parameters:params];
                
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params];
                        }
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    
                    if ([self isDebug]) {
                        [self logWithFailError:error url:absolute params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:absolute params:params];
                }
            }
        }];
    }
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

+ (MXURLSessionTask *)uploadWithImage:(UIImage *)image
                                  url:(NSString *)url
                             filename:(NSString *)filename
                                 name:(NSString *)name
                             mimeType:(NSString *)mimeType
                           parameters:(NSMutableDictionary *)params
                             progress:(MXUploadProgress)progress
                              success:(MXResponseSuccess)success
                                 fail:(MXResponseFail)fail
{
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            MXLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
            MXLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    params=[self globalParams:params url:url];
    
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    AFHTTPSessionManager *manager = [self manager];
    
    MXURLSessionTask *session = [manager POST:absolute parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSData *imageData = UIImageJPEGRepresentation(image, 0.1);
        
        NSString *imageFileName = filename;
        
        if (filename == nil ||
            ![filename isKindOfClass:[NSString class]] ||
            filename.length == 0){
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
        }
        
        // 上传图片，以文件流的格式
        [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allTasks] removeObject:task];
        [self successResponse:responseObject callback:success];
        
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:absolute
                                  params:params];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allTasks] removeObject:task];
        
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
            [self logWithFailError:error url:absolute params:nil];
        }
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

+ (MXURLSessionTask *)uploadWithImages:(NSDictionary *)imageDict
                                   url:(NSString *)url
                              mimeType:(NSString *)mimeType
                            parameters:(NSMutableDictionary *)params
                              progress:(MXUploadProgress)progress
                               success:(MXResponseSuccess)success
                                  fail:(MXResponseFail)fail {
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            MXLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
            MXLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    params=[self globalParams:params url:url];
    
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    AFHTTPSessionManager *manager = [self manager];
    /*manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
     @"text/html",
     @"text/json",
     @"text/javascript",
     @"image/jpeg",
     @"image/png"]];
     */
    MXURLSessionTask *session = [manager POST:absolute parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSString *imageFileName = nil;
        
        for (NSString *key in [imageDict allKeys]) {
            
            UIImage *image = imageDict[key];
            
            if (!image) {
                MXLog(@"图片不存在");
                return ;
            }
            
            //生成图片名称
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
            
            NSData *imageData = UIImageJPEGRepresentation(image, 0.0001);
            // 上传图片，以文件流的格式
            [formData appendPartWithFileData:imageData name:key fileName:imageFileName mimeType:mimeType];
        }
        
        //        for (int i = 0; i < count; i++) {
        //
        //            UIImage *image = images[i];
        //
        //            NSData *imageData = UIImageJPEGRepresentation(image, 0.0001);
        //
        //            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        //            formatter.dateFormat = @"yyyyMMddHHmmss";
        //            NSString *str = [formatter stringFromDate:[NSDate date]];
        //            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
        //
        //            // 上传图片，以文件流的格式
        //            [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
        //        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allTasks] removeObject:task];
        [self successResponse:responseObject callback:success];
        
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:absolute
                                  params:params];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [[self allTasks] removeObject:task];
        
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
            [self logWithFailError:error url:absolute params:nil];
        }
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

/**
 上传多张图片
 使用场景：相同字段名时
 */
+ (MXURLSessionTask *)uploadWithImages:(NSArray *)images
                                   url:(NSString *)url
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSMutableDictionary *)params
                              progress:(MXUploadProgress)progress
                               success:(MXResponseSuccess)success
                                  fail:(MXResponseFail)fail {
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            MXLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
            MXLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    params=[self globalParams:params url:url];
    
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    AFHTTPSessionManager *manager = [self manager];
    /*manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
     @"text/html",
     @"text/json",
     @"text/javascript",
     @"image/jpeg",
     @"image/png"]];
     */
    MXURLSessionTask *session = [manager POST:absolute parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSInteger count = [images count];
        
        for (int i = 0; i < count; i++) {
            
            UIImage *image = images[i];
            
            NSData *imageData = UIImageJPEGRepresentation(image, 0.0001);
            
            NSString *imageFileName = nil;
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
            
            // 上传图片，以文件流的格式
            [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allTasks] removeObject:task];
        [self successResponse:responseObject callback:success];
        
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:absolute
                                  params:params];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [[self allTasks] removeObject:task];
        
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
            [self logWithFailError:error url:absolute params:params];
        }
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

#pragma mark - Private Method

// 进行缓存操作
+ (void)cacheResponseObject:(id)responseObject request:(NSURLRequest *)request parameters:params
{
    if (request && responseObject && ![responseObject isKindOfClass:[NSNull class]])
    {
        NSString *directoryPath = cachePath();
        
        NSError *error = nil;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                MXLog(@"create cache dir error: %@\n", error);
                return;
            }
        }
        
        NSString *absoluteURL = [self generateGETAbsoluteURL:request.URL.absoluteString params:params delDynamicParams:YES];
        NSLog(@"%s absoluteURL:%@ \nrequest.URL.absoluteString:%@",__FUNCTION__,absoluteURL,request.URL.absoluteString);
        NSString *key = [self md5:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        NSData *data = nil;
        if ([dict isKindOfClass:[NSData class]]) {
            data = responseObject;
        } else {
            data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        }
        
        if (data && error == nil) {
            MXLog(@"createFileAtPath data from cache for path: %@\n", path);
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            if (isOk) {
                MXLog(@"cache file ok for request: %@\n", absoluteURL);
            } else {
                MXLog(@"cache file error for request: %@\n", absoluteURL);
            }
        }
    }
}

+ (id)cahceResponseWithURL:(NSString *)url parameters:params
{
    id cacheData = nil;
    
    if (url) {
        // Try to get datas from disk
        NSString *directoryPath = cachePath();
        NSLog(@"%@",directoryPath);
        NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params delDynamicParams:YES];
        NSLog(@"%s absoluteURL:%@",__FUNCTION__,absoluteURL);
        NSString *key = [self md5:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        MXLog(@"Read data from cache for path: %@\n", path);
        if (data) {
            cacheData = data;
        }
    }
    
    return cacheData;
}

// 将经过json处理的数据传到外部
+ (void)successResponse:(id)responseData callback:(MXResponseSuccess)success
{
    if (success) {
        success([self tryToParseData:responseData]);
    }
}

+ (id)tryToParseData:(id)responseData
{
    //1.字符串转JSON
    if ([responseData isKindOfClass:[NSString class]]) {
        
        return [NSJSONSerialization JSONObjectWithData:[((NSString *)responseData) dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
        
    }else if ([responseData isKindOfClass:[NSData class]]) {//2.二进制转JSON
        
        if (responseData == nil) {
            return responseData;
        } else {
            NSError *error = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                NSString *responseString = [[NSString alloc] initWithData:responseData encoding:(NSUTF8StringEncoding)];
                MXLog(@"JSON数据转换错误,尝试转换为字符串。错误(ERROR)输出:=======>%@\n字符串数据:============>%@",error,responseString);
                return responseString;
            } else {
                //#warning 自定义
                //          //19901 - 19999 范围内要求弹框
                //          NSInteger code=[[response objectForKey:kResponseCode]integerValue];
                //          if (19901<=code && code<=19999) {
                //              [[NSNotificationCenter defaultCenter] postNotificationName:kProhibitNotification object:response];
                //          }
                return response;
            }
        }
    } else {
        return responseData;
    }
}

+ (void)handleCallbackWithError:(NSError *)error fail:(MXResponseFail)fail
{
    //        __weak typeof(AppDelegate ) *weakAppDelegate=(AppDelegate *)[UIApplication sharedApplication].delegate;
    
    if ([error code] == NSURLErrorCancelled)
    {
        if (mx_shouldCallbackOnCancelRequest) {
            if (fail) {
                fail(error);
            }
        }
    }
#warning 自定义
    //        else if ([error code] == NSURLErrorCannotConnectToHost)
    //        {
    //            if (fail) {
    //                fail(error);
    //                [weakAppDelegate showMessage:@"服务器404错误"];
    //            }
    //        }
    //        else if ([error code] == NSURLErrorNetworkConnectionLost)
    //        {
    //            if (fail) {
    //                fail(error);
    //                [weakAppDelegate showMessage:@"网络连接失败,请检查网络设置"];
    //            }
    //        }
    //        else {
    //            if (fail) {
    //                fail(error);
    //                if ([[error debugDescription] containsString:@"The request timed out"]) {
    //                    [weakAppDelegate showMessage:@"网络请求超时"];
    //                }else{
    //                    [weakAppDelegate showMessage:[error localizedDescription]];//@"请求失败"
    //                }
    //            }
    //        }
}

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params
{
    MXLog(@"\n");
    MXLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
          [self generateGETAbsoluteURL:url params:params delDynamicParams:NO],
          params,
          [self tryToParseData:response]);
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params
{
    NSString *format = @" params: ";
    if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
        format = @"";
        params = @"";
    }
    
    MXLog(@"\n");
    if ([error code] == NSURLErrorCancelled) {
        MXLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
              [self generateGETAbsoluteURL:url params:params delDynamicParams:NO],
              format,
              params);
    } else {
        MXLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n Error : %@\n",
              [self generateGETAbsoluteURL:url params:params delDynamicParams:NO],
              format,
              params,
              [error localizedDescription],
              error);
    }
}


//仅对一级字典结构起作用
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params delDynamicParams:(BOOL)delDynamicParams
{
    if (params == nil ||
        ![params isKindOfClass:[NSDictionary class]] ||
        [params count] == 0) {
        return url;
    }
    
    NSString *queries = @"";
    for (NSString *key in params) {
        
#warning 换书吧\
//排除动态参数
        if ([key isEqualToString:@"timestamp"]||[key isEqualToString:@"sign"])
            continue;
        
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@", url, queries];
        }
    }
    
    return url.length == 0 ? queries : url;
}

/**该方法用来处理传入的URL：*/
+ (NSString *)absoluteUrlWithPath:(NSString *)path
{
    //如果URLPath为空
    if (path == nil || path.length == 0) {
        return @"";
    }
    //如果Base URLPath为空 返回path
    if ([self baseUrl] == nil || [[self baseUrl] length] == 0) {
        return path;
    }
    
    NSString *absoluteUrl = path;
    
    //HTTP跟H如果URL前缀不是TTPS时，即传入的URL不是全称，需拼接
    if (![path hasPrefix:@"http://"] && ![path hasPrefix:@"https://"]) {
        if ([[self baseUrl] hasSuffix:@"/"]) {
            if ([path hasPrefix:@"/"]) {
                NSMutableString * mutablePath = [NSMutableString stringWithString:path];
                [mutablePath deleteCharactersInRange:NSMakeRange(0, 1)];
                absoluteUrl = [NSString stringWithFormat:@"%@%@",
                               [self baseUrl], mutablePath];
            }else {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
            }
        }else {
            if ([path hasPrefix:@"/"]) {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
            }else {
                absoluteUrl = [NSString stringWithFormat:@"%@/%@",
                               [self baseUrl], path];
            }
        }
    }
    
    return absoluteUrl;
}
// 中文转码
+ (NSString *)encodeUrl:(NSString *)url {
    NSString *newString =
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)url,
                                                              NULL,
                                                              CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    if (newString) {
        return newString;
    }
    
    return url;
    
}

#pragma mark - 拼接全局参数(自定义修改)
//拼接全局参数  打印URL
+ (NSMutableDictionary *)globalParams:(NSMutableDictionary *)params url:(NSString *)url
{
    if (params) {
        //先判断参数是否存在
        if ([[params allKeys] containsObject:@""]) {
            MXLog(@"参数已存在 不用追加");
        } else {
            //统一追加全局参数
            //NSString *userId=[[NSUserDefaults standardUserDefaults] objectForKey:kUserId];
            //            SharedPreferences *spf=[SharedPreferences shareInstance];
            //            NSString *userId=spf.loginModel.user_id;
            //            if (!userId) {
            //                userId=@"0";
            //            }
            //            [params setObject:[NSString otherToken] forKey:@"token"];
            MXLog(@"追加 token 参数");
        }
        //        NSTimeInterval timestamp=[[NSDate date] timeIntervalSince1970]*1000;//毫秒
        //        [params setObject:kVersionId forKey:@"version_id"];
        //        [params setObject:[NSString stringWithFormat:@"%.f",timestamp] forKey:@"timestamp"];
        //        [params setObject:kPlatformType forKey:@"platform_type"];
        //        NSString *sign = [MD5Util md5MakeByDic:params md5key:nil];
        //        [params setObject:sign forKey:@"sign"];
    }
    
    //拼接链接
    if ([self isDebug]) {
        NSMutableString *urlString=[[NSMutableString alloc] init];
        if (![url hasPrefix:@"http://"]&&![url hasPrefix:@"https://"]) {
            [urlString appendString:[self baseUrl]];
        }
        [urlString appendString:url];
        [urlString appendString:@"?"];
        for (NSString *key in params) {
            [urlString appendString:key];
            [urlString appendString:@"="];
            id value=[params objectForKey:key];
            [urlString appendString:[NSString stringWithFormat:@"%@",value]];
            [urlString appendString:@"&"];
        }
        MXLog(@"请求url:%@",[urlString substringToIndex:urlString.length-1]);
    }
    
    return params;
}

//md5加密
+ (NSString *)md5:(NSString *)string
{
    if (string == nil || [string length] == 0) {
        return nil;
    }
    
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    int length = (int)strlen(cStr);
    CC_MD5( cStr, length, digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

#pragma mark - Getter and Setter

+ (AFHTTPSessionManager *)manager
{
    // 开启转圈圈
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPSessionManager *manager = nil;;
    if ([self baseUrl] != nil) {
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
    } else {
        manager = [AFHTTPSessionManager manager];
    }
    
    switch (mx_requestType) {
        case MXRequestTypeJSON: {
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        }
        case MXRequestTypePlainText: {
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        }
        default: {
            break;
        }
    }
    
    switch (mx_responseType) {
        case MXResponseTypeJSON: {
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        }
        case MXResponseTypeXML: {
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        }
        case MXResponseTypeData: {
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        }
        default: {
            break;
        }
    }
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    for (NSString *key in mx_httpHeaders.allKeys) {
        if (mx_httpHeaders[key] != nil) {
            [manager.requestSerializer setValue:mx_httpHeaders[key] forHTTPHeaderField:key];
        }
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomment"
    /*
     manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[
     @"application/json",
     @"text/html",
     @"text/json",
     @"text/plain",
     @"text/javascript",
     @"text/xml",
     @"image/*"]];
     */
#pragma clang diagnostic pop
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/javascript"]];
    
    manager.requestSerializer.timeoutInterval = mx_timeout;
    
    // 设置允许同时最大并发数量，过大容易出问题
    manager.operationQueue.maxConcurrentOperationCount = 3;
    
    if (mx_shoulObtainLocalWhenUnconnected && (mx_cacheGet || mx_cachePost ) ) {
    //   [self detectNetwork];
    }
    return manager;
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (mx_requestTasks == nil) {
            mx_requestTasks = [[NSMutableArray alloc] init];
        }
    });
    
    return mx_requestTasks;
}

@end
