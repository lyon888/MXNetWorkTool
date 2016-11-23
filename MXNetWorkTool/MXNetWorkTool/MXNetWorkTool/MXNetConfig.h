
#ifndef MXNetConfig_h
#define MXNetConfig_h

//平台类型：1:Android,2:IOS,3:WEB
#define kPlatformType       @"2"
//版本id
#define kVersionId          @"14"

//本地接口:
//#define ServerHost              @"http://vtcr2mcex6.proxy.qqbrowser.cc/zhihuisuo"
//#define ServerUploadImgHost     @"http://vtcr2mcex6.proxy.qqbrowser.cc/zhihuisuo"

//测试接口:
//#define ServerHost            @"http://2421cbb4.ngrok.io/zhihuisuo"
//#define ServerUploadImgHost   @"http://2421cbb4.ngrok.io/zhihuisuo"

//服务器普通接口
#define ServerHost            @"http://test7.messcat.com/zhihuisuo"
//服务器图片上传接口
#define ServerUploadImgHost   @"http://test7.messcat.com/zhihuisuo"


#define RequestAPI(__api)           [NSString stringWithFormat:@"%@%@",ServerHost,__api]
#define RequestUploadImgAPI(__api)  [NSString stringWithFormat:@"%@%@",ServerUploadImgHost,__api]

#define kResponseCode           @"status"
#define kResponseMsg            @"message"
#define kResponseResult         @"result"
#define kResponseResultList     @"resultList"


#define kUrlLogin                       @"/member/app/login"                //2.1.4登陆


#endif /* MXNetConfig_h */
