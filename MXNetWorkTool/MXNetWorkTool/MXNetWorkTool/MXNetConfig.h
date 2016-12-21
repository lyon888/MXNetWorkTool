
#ifndef MXNetConfig_h
#define MXNetConfig_h

//平台类型：1:Android,2:IOS,3:WEB
#define kPlatformType       @"2"
//版本id
#define kVersionId          @"14"

//本地接口:
//#define ServerHost
//#define ServerUploadImgHost

//测试接口:
//#define ServerHost
//#define ServerUploadImgHost

//服务器普通接口
#define ServerHost @""
//服务器图片上传接口
#define ServerUploadImgHost @""


#define RequestAPI(__api)           [NSString stringWithFormat:@"%@%@",ServerHost,__api]
#define RequestUploadImgAPI(__api)  [NSString stringWithFormat:@"%@%@",ServerUploadImgHost,__api]

#define kResponseCode           @"status"
#define kResponseMsg            @"message"
#define kResponseResult         @"result"
#define kResponseResultList     @"resultList"


#define kUrlLogin                       @""                


#endif /* MXNetConfig_h */
