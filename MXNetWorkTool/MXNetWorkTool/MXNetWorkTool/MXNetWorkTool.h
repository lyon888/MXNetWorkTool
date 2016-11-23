//
//  MXNetWorkTool.h
//
//  Created by lyoniOS on 16/10/31.
//  Copyright © 2016年 lyoniOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//暴力打印(项目打包上线都不会打印日志,已处理iOS10后真机控制台不输出问题)
#ifdef DEBUG
#define MXLog(s, ... ) printf("[%s] %s [第%d行] %s\n", __TIME__, __FUNCTION__,__LINE__,[[NSString stringWithFormat:(s), ## __VA_ARGS__] UTF8String])
#else
#define MXLog(s, ... )
#endif

/*!
 *  `AFNetworking` 支持的6种方式
 */
typedef NS_ENUM(NSInteger , MXRequestMethod) {
    MXRequestMethodGet    = 1, //! GET请求
    MXRequestMethodPost   = 2, //! POST请求
    MXRequestMethodHead   = 3, //! HEAD请求
    MXRequestMethodPut    = 4, //! PUT请求
    MXRequestMethodPatch  = 5, //! PATCH请求
    MXRequestMethodDelete = 6, //! DELETE请求
};

typedef NS_ENUM(NSUInteger, MXNetworkStatus) {
    MXNetworkStatusUnknown          = 111,  //未知网络
    MXNetworkStatusNotReachable     = 0,    //网络无连接
    MXNetworkStatusReachableViaWWAN = 1,    //2，3，4G网络
    MXNetworkStatusReachableViaWiFi = 2,    //WIFI网络
};

typedef NS_ENUM(NSUInteger, MXResponseType) {
    kMXResponseTypeJSON = 1, // 默认
    kMXResponseTypeXML  = 2, // XML
    kMXResponseTypeData = 3  // 特殊情况下，一转换服务器就无法识别的，默认会尝试转换成JSON，若失败则需要自己去转换
};

typedef NS_ENUM(NSUInteger, MXRequestType) {
    kMXRequestTypeJSON = 1,         // 默认
    kMXRequestTypePlainText  = 2    // 普通text/html
};

/**
 下载进度
 
 @param bytesRead      已下载的大小
 @param totalBytesRead 文件总大小
 */
typedef void (^MXDownloadProgress)(int64_t bytesRead,
                                   int64_t totalBytesRead);

/**
 上传进度
 
 @param bytesWritten        已上传的大小
 @param totalBytesWritten   总上传大小
 */
typedef void (^MXUploadProgress)(int64_t bytesWritten,
                                 int64_t totalBytesWritten);

typedef void(^MXResponseSuccess)(id response);//请求成功回调闭包
typedef void(^MXResponseFail)(NSError *error);//请求失败回调闭包

//方便以后替换第三方框架
typedef MXDownloadProgress MXGetProgress;
typedef MXDownloadProgress MXPostProgress;
typedef NSURLSessionTask MXURLSessionTask;

@interface MXNetWorkTool : NSObject

+ (MXNetworkStatus )networkStatus;

/*!
 *
 *  用于指定网络请求接口的基础url，如：
 *  http://henishuo.com或者http://101.200.209.244
 *  通常在AppDelegate中启动时就设置一次就可以了。如果接口有来源
 *  于多个服务器，可以调用更新
 *
 *  @param baseUrl 网络接口的基础url
 */
+ (void)updateBaseUrl:(NSString *)baseUrl;

/*!
 *
 *  开启或关闭接口打印信息
 *
 *  @param isDebug 开发期，最好打开，默认是NO
 */
+ (void)enableInterfaceDebug:(BOOL)isDebug;

/*!
 *
 *  配置请求格式，默认为JSON。如果要求传XML或者PLIST，请在全局配置一下
 *
 *  @param requestType 请求格式，默认为JSON
 *  @param responseType 响应格式，默认为JSO，
 *  @param shouldAutoEncode YES or NO,默认为NO，是否自动encode url
 *  @param shouldCallbackOnCancelRequest 当取消请求时，是否要回调，默认为YES
 */

+ (void)configRequestType:(MXRequestType)requestType
             responseType:(MXResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest;

/**
 *	当检查到网络异常时，是否从从本地提取数据。默认为NO。一旦设置为YES,当设置刷新缓存时，
 *  若网络异常也会从缓存中读取数据。同样，如果设置超时不回调，同样也会在网络异常时回调，除非
 *  本地没有数据！
 *
 *	@param shouldObtain	YES/NO
 */
+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain;

/**
 *
 *	默认只缓存GET请求的数据，对于POST请求是不缓存的。如果要缓存POST获取的数据，需要手动调用设置
 *  对JSON类型数据有效，对于PLIST、XML不确定！
 *
 *	@param isCacheGet			默认为YES
 *	@param shouldCachePost	默认为NO
 */
+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost;


/*!
 *
 *  配置公共的请求头，只调用一次即可，通常放在应用启动的时候配置就可以了
 *
 *  @param httpHeaders 只需要将与服务器商定的固定参数设置即可
 */
+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders;


/**
 
 GET请求接口，若不指定baseurl，可传完整的url
 
 @param url          接口路径，如/path/getArticleList
 @param refreshCache 是否刷新缓存。由于请求成功也可能没有数据，对于业务失败，只能通过人为手动判断
 @param success      接口成功请求到数据的回调
 @param fail         接口请求数据失败的回调
 
 @return 返回的对象中有可取消请求的API
 */
+ (MXURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         success:(MXResponseSuccess)success
                            fail:(MXResponseFail)fail;
// 多一个params参数
+ (MXURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                          params:(NSMutableDictionary *)params
                         success:(MXResponseSuccess)success
                            fail:(MXResponseFail)fail;
// 多一个带进度回调
+ (MXURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                          params:(NSMutableDictionary *)params
                        progress:(MXGetProgress)progress
                         success:(MXResponseSuccess)success
                            fail:(MXResponseFail)fail;



/*!
 *
 *  POST请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param params  接口中所需的参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (MXURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSMutableDictionary *)params
                          success:(MXResponseSuccess)success
                             fail:(MXResponseFail)fail;
+ (MXURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSMutableDictionary *)params
                         progress:(MXPostProgress)progress
                          success:(MXResponseSuccess)success
                             fail:(MXResponseFail)fail;


/**
 
 图片(单张)上传接口，若不指定baseurl，可传完整的url
 
 @param image    图片对象
 @param url      上传图片的接口路径，如/path/images/
 @param filename 给图片起一个名字，默认为当前日期时间,格式为"yyyyMMddHHmmss"，后缀为`jpg`
 @param name     与指定的图片相关联的名称，这是由后端写接口的人指定的，如imagefiles
 @param mimeType 默认为image/jpeg
 @param params   参数
 @param progress 上传进度
 @param success  上传成功回调
 @param fail     上传失败回调
 
 @return MXURLSessionTask
 */
+ (MXURLSessionTask *)uploadWithImage:(UIImage *)image
                                  url:(NSString *)url
                             filename:(NSString *)filename
                                 name:(NSString *)name
                             mimeType:(NSString *)mimeType
                           parameters:(NSMutableDictionary *)params
                             progress:(MXUploadProgress)progress
                              success:(MXResponseSuccess)success
                                 fail:(MXResponseFail)fail;

/**
 @author 刘智援, 16-10-19 00:01:40
 
 图片(多张)上传接口，若不指定baseurl，可传完整的url
 
 @param images   字典
 @key   与指定的图片相关联的名称，这是由后端写接口的人指定的，如imagefiles
 @value 图片
 
 @param url      上传图片的接口路径，如/path/images/
 @param mimeType 默认为image/jpeg
 @param params   参数
 @param progress 上传进度
 @param success  上传成功回调
 @param fail     上传失败回调
 
 @return MXURLSessionTask
 */
+ (MXURLSessionTask *)uploadWithImages:(NSDictionary *)images
                                   url:(NSString *)url
                              mimeType:(NSString *)mimeType
                            parameters:(NSMutableDictionary *)params
                              progress:(MXUploadProgress)progress
                               success:(MXResponseSuccess)success
                                  fail:(MXResponseFail)fail;

/**
 
 图片(多张)上传接口，若不指定baseurl，可传完整的url
 
 使用场景：相同字段名时
 
 @param images   图片数组
 @param url      接口连接
 @param name     字段参数
 @param mimeType 文件类型 默认为image/jpeg
 @param params   参数
 @param progress 上传进度
 @param success  成功回调
 @param fail     失败会掉
 
 @return MXURLSessionTask
 */
+ (MXURLSessionTask *)uploadWithImages:(NSArray *)images
                                   url:(NSString *)url
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSMutableDictionary *)params
                              progress:(MXUploadProgress)progress
                               success:(MXResponseSuccess)success
                                  fail:(MXResponseFail)fail;

@end
