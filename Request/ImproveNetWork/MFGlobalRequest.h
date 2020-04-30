//
//  MFGlobalRequest.h
//  mofunshow
//
//  Created by 隔壁老王 on 2020/4/24.
//  Copyright © 2020 mofunsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFAssembleHud.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WYRequestPolicy) {
    RequestReloadIgnoreCache = 0,
    RequestCacheDontLoad = 1,
    RequestLoadOrCache = 2,
    RequestEnsureDelivery = 3,
    RequestResendQueue = 4,
};

@interface MFGlobalRequest : NSObject
@property (nonatomic, assign) BOOL debug;

+ (instancetype)sharedInstance;

/** 需要设置timeout时使用 */
- (void)requestURL:(NSString *)URLString
                          httpMethod:(NSString *)method
                          parameters:(id)parameters
                     timeoutInterval:(NSTimeInterval)timeout
                            policy:(WYRequestPolicy)policy
                             success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                             failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
                             HUDtype:(WYHUDType)HUDtype;
                          

/** 网络请求，get和post混用时，可设置超时时间和菊花状态 */
- (void)requestURL:(NSString *)URLString
                          postParas:(id)postParas
                          getParas:(id)getParas
                     timeoutInterval:(NSTimeInterval)timeout
                            policy:(WYRequestPolicy)policy
                             success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                             failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
                             HUDtype:(WYHUDType)HUDtype;

/** 网络请求，并发一组请求 */
- (void)asyncRequestURL:(NSString *)URLString
     getParas:(id)getParas
timeoutInterval:(NSTimeInterval)timeout
        policy:(WYRequestPolicy)policy
        success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
        failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
        groupName:(NSString*)group
        HUDtype:(WYHUDType)HUDtype;

/** 取消固定path的全部网络请求 */
- (void)cancelAllHTTPOperationsWithPath:(NSString *)path;

- (void)clearRequestData;

- (NSString*)getModifiedDateWithUrl:(NSString*)url;

@end

NS_ASSUME_NONNULL_END
