//
//  AppDelegate.m
//  MXNetWorkTool
//
//  Created by 刘智援 on 2016/11/16.
//  Copyright © 2016年 lyoniOS. All rights reserved.
//

#import "AppDelegate.h"
#import "MXNetWorkTool.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[MXNetWorkTool updateBaseUrl:ServerHost];//更新BaseUrl
    [MXNetWorkTool enableInterfaceDebug:YES];//开启或关闭接口打印信息
    [MXNetWorkTool cacheGetRequest:NO shoulCachePost:NO];//设置GET、POST是否取缓存
    [MXNetWorkTool obtainDataFromLocalWhenNetworkUnconnected:NO];//从本地提取数据
    [MXNetWorkTool configRequestType:kMXRequestTypePlainText
                        responseType:kMXResponseTypeData
                 shouldAutoEncodeUrl:NO
             callbackOnCancelRequest:YES];
    
    
    return YES;
}


@end
