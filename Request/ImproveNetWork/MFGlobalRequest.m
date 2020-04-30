//
//  MFGlobalRequest.m
//  mofunshow
//
//  Created by 隔壁老王 on 2020/4/24.
//  Copyright © 2020 mofunsky. All rights reserved.
//

#import "MFGlobalRequest.h"
#import "AFNetworking.h"
#import "WYRequest.h"
#import "MJExtension.h"
#import "MFGlobalRequest+resendHandler.h"

#define MaxResendCount 3
#define WY_URL_HOST @"http://app3.qdaily.com"

@interface MFGlobalRequest()
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (strong, nonatomic) AFNetworkReachabilityManager *monitor;
@property (strong, nonatomic) NSURLCache *urlCache;
@property (nonatomic, strong) NSUserDefaults *cacheUrlData;
@property (strong, nonatomic) dispatch_queue_t serialQueue;
@property (strong, nonatomic) NSLock *lock;
@property (assign, nonatomic) BOOL useCache;
@property (strong, nonatomic) NSArray *lostConnects;
@property (strong, nonatomic) NSArray *falseConnects;

@end
@implementation MFGlobalRequest
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    static MFGlobalRequest* global;
    dispatch_once(&onceToken, ^{
        global = [[MFGlobalRequest alloc]init];
        global.sessionManager = [global configSession];
        global.monitor = [global configMonitor];
        global.cacheUrlData = [[NSUserDefaults alloc] initWithSuiteName:@"WYCacheUrlData"];
    });
    return global;
}

- (AFHTTPSessionManager*)configSession{
    self.baseURL = [NSURL URLWithString:WY_URL_HOST];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPShouldSetCookies = YES;
    configuration.HTTPShouldUsePipelining = NO;
    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = 60.0;
    self.urlCache = [MFGlobalRequest defaultURLCache];
    configuration.URLCache = self.urlCache;
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL sessionConfiguration:configuration];
//    manager.completionGroup = dispatch_group_create();
//    manager.completionQueue = dispatch_queue_create("WYRequestHandleQueue", DISPATCH_QUEUE_SERIAL);
    return manager;
}

+ (NSURLCache *)defaultURLCache {
    NSUInteger memoryCapacity = 20 * 1024 * 1024; // 20MB
    NSUInteger diskCapacity = 150 * 1024 * 1024; // 150MB
    NSURL *cacheURL = [[[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                             inDomain:NSUserDomainMask
                                        appropriateForURL:nil
                                               create:YES
                                               error:nil]
                       URLByAppendingPathComponent:@"globalRequest"];
    NSLog(@"cacheURL--%@",cacheURL.path);
    return [[NSURLCache alloc] initWithMemoryCapacity:memoryCapacity
                                         diskCapacity:diskCapacity
                                             diskPath:[cacheURL path]];
}

- (AFNetworkReachabilityManager*)configMonitor{
    AFNetworkReachabilityManager *monitor = [AFNetworkReachabilityManager managerForDomain:WY_URL_HOST];
    __weak typeof(self)weakself = self;
    [monitor setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
       __strong typeof(weakself)strongself = weakself;
       if (status>0) {
           [strongself.monitor stopMonitoring];
           strongself.useCache = NO;
           strongself.debug = NO;
           [MFAssembleHud showTextOnly:@"网络恢复连接了呢～" AfterDelay:2];
           [strongself startResendQueue];
       }
   }];
    return monitor;
}

- (void)startMonitor{
    [self.monitor startMonitoring];
}


- (void)clearRequestData{
    [self.urlCache removeAllCachedResponses];
    [self.cacheUrlData removeObjectForKey:@"resend"];
    [self.cacheUrlData removeObjectForKey:@"Modified"];
}

#pragma mark - Routine

/** 网络请求，get和post混用时，可设置超时时间和菊花状态 */
- (void)requestURL:(NSString *)URLString
                          postParas:(id)postParas
                          getParas:(id)getParas
                     timeoutInterval:(NSTimeInterval)timeout
                            policy:(WYRequestPolicy)policy
                             success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                             failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
                             HUDtype:(WYHUDType)HUDtype{
    NSError *serializationError = nil;
       NSMutableURLRequest *mutableRequest = [self.sessionManager.requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:getParas error:&serializationError];
       NSString *theUrl = [mutableRequest.URL absoluteString];
       if (serializationError) {
           NSLog(@"serialization 错误 : %@", serializationError);
       }
    [self requestURL:theUrl httpMethod:@"POST" parameters:postParas timeoutInterval:timeout policy:policy success:success failure:failure HUDtype:HUDtype];
}

- (void)asyncRequestURL:(NSString *)URLString
     getParas:(id)getParas
timeoutInterval:(NSTimeInterval)timeout
        policy:(WYRequestPolicy)policy
        success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
        failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
        groupName:(NSString*)group
                HUDtype:(WYHUDType)HUDtype{
    
}

/** 需要设置timeout时使用 */
- (void)requestURL:(NSString *)URLString
                          httpMethod:(NSString *)method
                          parameters:(id)parameters
                     timeoutInterval:(NSTimeInterval)timeout
                            policy:(WYRequestPolicy)policy
                             success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                             failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
                             HUDtype:(WYHUDType)HUDtype
    
    {
    if (!policy) {
        //默认请求不使用缓存，也不启用失败重发
        policy = 0;
    }
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:method URLString:URLString parameters:parameters policy:policy timeoutInterval:timeout success:success failure:failure HUDtype:HUDtype];
       [dataTask resume];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                        policy:(WYRequestPolicy)policy
                                      timeoutInterval:(NSTimeInterval)timeout
                                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
                                        HUDtype:(WYHUDType)HUDtype
{
    //公共参数
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
   
    //GET请求将参数拼接到请求接口中
    NSError *serialError = nil;
    NSMutableURLRequest *urlRequest = [self.sessionManager.requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:dic error:&serialError];
    NSString *theUrl = [urlRequest.URL absoluteString];
    
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:theUrl relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
     if (serializationError) {
            if (failure) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wgnu"
                dispatch_async(self.sessionManager.completionQueue ?: dispatch_get_main_queue(), ^{
                    failure(nil, serializationError ,nil);
                });
    #pragma clang diagnostic pop
            }
            return nil;
        }
    
    if (policy == RequestCacheDontLoad || self.useCache) {
           [self useCacheData:request HUDtype:HUDtype success:success failure:failure];
           return nil;
       }
        //不是强制请求最新数据的情况下，条件合适就使用缓存
    if (policy == RequestLoadOrCache) {
        //如果借助了 Last-Modified 和 ETag，那么缓存策略则必须使用 NSURLRequestReloadIgnoringCacheData 策略，忽略缓存，每次都要向服务端进行校验
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        NSString *lastModified = [self getModifiedDateWithUrl:URLString];
        if (lastModified) {
            //ETag
            [request setValue:lastModified forHTTPHeaderField:@"If-None-Match"];
            //LastModified => If-Modified-Since
        }
    }
    if (policy == RequestEnsureDelivery) {
        [self saveResendData:method url:URLString para:parameters retryCout:0];
    }
    if (self.debug) {
        return nil;
    }
    NSLog(@"request URL : %@", request.URL.absoluteString);
    //针对请求设置超时
    if (timeout > 0) {
        [request setTimeoutInterval:timeout];
    }
   
    HudView *hud = [MFAssembleHud requestHudWithType:HUDtype];
    __weak typeof(self) weakself = self;
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        __strong typeof(weakself)strongself = weakself;
        [MFAssembleHud hideHudView:hud];
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
          NSLog(@"statusCode == %@", @(httpResponse.statusCode));
          // 判断响应的状态码是否是 304 Not Modified （更多状态码含义解释： https://github.com/ChenYilong/iOSDevelopmentTips）
          if (httpResponse.statusCode == 304) {
              NSLog(@"no need to request %@",URLString);
              [strongself useCacheData:request HUDtype:HUDtype success:success failure:failure];
          }
        // 获取并且纪录 etag，区分大小写
        if (policy == RequestLoadOrCache) {
            NSString *lastModified = httpResponse.allHeaderFields[@"Etag"]; //Last-Modified
            if (lastModified) {
                [strongself saveModifiedUrl:URLString date:lastModified];
            }
        }
         if (policy == RequestResendQueue) {
             if (!error) {
                 [strongself updateCacheUrlData:URLString];
             }else{
                 [strongself removeCacheUrlData:URLString];
                 [strongself handleResendRequest:URLString task:dataTask error:error response:responseObject];
             }
         }
       
        if (error) {
            if (failure) {
                [strongself settleRequestError:error response:responseObject URLString:URLString parameters:parameters policy:policy HUDtype:HUDtype];
                failure(dataTask, error ,responseObject);
            }
        } else {
            if (success) {
                if (policy == RequestEnsureDelivery) {
                    [strongself removeCacheUrlData:URLString];
                }
                if (HUDtype & WYHUDTypeSuccessNote) {
                    [MFAssembleHud successNoteShow];
                }
                else if (HUDtype & WYHUDTypeSuccessToast) {
                    [MFAssembleHud successToastHudShow];
                }
                success(dataTask, responseObject);
            }
        }
    }];
    return dataTask;
}

/** 取消制定path的全部网络请求 */
- (void)cancelAllHTTPOperationsWithPath:(NSString *)path{
    [[self.sessionManager session] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        [self cancelTasksInArray:dataTasks withPath:path];
        [self cancelTasksInArray:uploadTasks withPath:path];
        [self cancelTasksInArray:downloadTasks withPath:path];
    }];
}

/** 取消固定path的网络请求 */
- (void)cancelTasksInArray:(NSArray *)tasksArray withPath:(NSString *)path{
    for (NSURLSessionTask *task in tasksArray) {
        NSRange range = [[[[task currentRequest]URL] absoluteString] rangeOfString:path];
        if (range.location != NSNotFound) {
            [task cancel];
        }
    }
}

#pragma mark -

- (void)useCacheData:(NSURLRequest*)request HUDtype:(WYHUDType)HUDtype
             success:(void (^)(NSURLSessionDataTask *, id))success
            failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure{
    NSCachedURLResponse *cacheResponse =  [self.urlCache cachedResponseForRequest:request];
            // 拿到缓存的数据
    NSError *error;
    NSData *data = cacheResponse.data;
    BOOL isSpace = [data isEqualToData:[NSData dataWithBytes:" " length:1]];
    if (data.length == 0 || isSpace) {
       failure(nil, nil ,nil);
    }
   NSError *serializationError = nil;
   id responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
    if (!responseObject || error) {
        [MFAssembleHud showFailedView:HUDtype];
        failure(nil, error ,nil);
    }else{
        success(nil, responseObject);
    }
}

- (void)saveModifiedUrl:(NSString*)url date:(NSString*)date{
    BOOL locked = [self.lock tryLock];
    NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
    NSDictionary *dic = [self.cacheUrlData objectForKey:@"Modified"];
    if (dic) {
        [mdic addEntriesFromDictionary:dic];
    }
    [mdic setObject:date forKey:url];
    [self.cacheUrlData setObject:mdic forKey:@"Modified"];
    if (locked) {
        [self.lock unlock];
    }
}

- (NSString*)getModifiedDateWithUrl:(NSString*)url{
   BOOL locked = [self.lock tryLock];
   NSDictionary *dic = [self.cacheUrlData objectForKey:@"Modified"];
    if (locked) {
          [self.lock unlock];
    }
   if (!dic) {
       return nil;
   }
    if (dic && [dic.allKeys containsObject:url]){
        return [dic objectForKey:url];
    }
    return nil;
}

- (void)settleRequestError:(NSError*)error response:(id)responseObject
          URLString:(NSString *)URLString
        parameters:(id)parameters
            policy:(WYRequestPolicy)policy
           HUDtype:(WYHUDType)HUDtype{
    if (!responseObject) {
        if (error && error.code != -999){
            [MFAssembleHud showFailedView:HUDtype];
        }
    }else if ([self.lostConnects containsObject: @(error.code)]){
#warning 先使用缓存数据_保障用户体验（具体看业务和接口）
        self.useCache = YES;
        //开启监控网络，网络恢复时重发
        [self.monitor startMonitoring];
    }else if ([self.falseConnects containsObject:@(error.code)] && (policy == RequestResendQueue || policy == RequestEnsureDelivery)){
        //错误的请求，如果有缓存入resend就移除
        [self removeCacheUrlData:URLString];
    }else{
    }
}

static int TimeSpace = 0;
- (void)startResendQueue{
    NSMutableArray *mArr = [self.cacheUrlData objectForKey:@"resend"];
    __weak typeof(self)weakself = self;
    if (mArr && mArr.count>0) {
        NSArray *taskArr = mArr.mutableCopy;
        int i = 0;
        while (i<taskArr.count) {
            __block NSDictionary *item = taskArr[i];
             i++;
            NSLog(@"i--%d",i);
            dispatch_async(self.serialQueue, ^{
                 WYRequest *request = [WYRequest mj_objectWithKeyValues:item];
                [weakself requestURL:request.urlStr httpMethod:request.method parameters:request.params timeoutInterval:0 policy:RequestResendQueue success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                                        NSLog(@"task--%@",task);

                } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error, id  _Nonnull responseObject) {
                                        NSLog(@"error--%@",error);

                } HUDtype:WYHUDTypeNone];
             });
        } ;
    }else{
        return;
    }
    TimeSpace++;
   //每个请求预设为15s
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(mArr.count * NSEC_PER_SEC*15 + TimeSpace*60)), dispatch_get_main_queue(), ^{
        [self startResendQueue];
    });
}

- (void)saveResendData:(NSString*)method url:(NSString*)url para:(NSDictionary*)para retryCout:(NSInteger)count{
    BOOL locked = [self.lock tryLock];
    NSMutableArray *mArr = [self removeCacheUrlData:url];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:@{@"urlStr":url,@"method":method,@"retryCount":@(count)}];
    if (para!=nil) {
        dic[@"params"] = para;
    }
    //保证请求的顺序是从最新的开始
    [mArr insertObject:dic atIndex:0];
    [self.cacheUrlData setObject:mArr forKey:@"resend"];
    if (locked) {
        [self.lock unlock];
    }
}

- (void)updateCacheUrlData:(NSString *)url{
   BOOL locked = [self.lock tryLock];
   NSArray *arr = [self.cacheUrlData objectForKey:@"resend"];
   NSMutableArray *mArr = arr.mutableCopy;
   if (mArr && mArr.count>0) {
       int index = 0;
       for (int i=0; i<mArr.count; i++) {
           NSDictionary *item = mArr[i];
           if ([item[@"urlStr"] isEqualToString:url]) {
               index = i;
           }
       }
    NSDictionary *item = mArr[index];
    NSMutableDictionary *mdic = item.mutableCopy;
    NSNumber *count = item[@"retryCount"];
      if (count.integerValue>=MaxResendCount) {
          [mArr removeObject:item];
      }else{
        [mdic setValue:@(count.integerValue+1) forKey:@"retryCount"];
          mArr[index] = mdic;
      }
       [self.cacheUrlData setObject:mArr forKey:@"resend"];
  }
   if (locked) {
       [self.lock unlock];
   }
}

- (NSMutableArray*)removeCacheUrlData:(NSString *)url{
    NSArray *arr = [self.cacheUrlData objectForKey:@"resend"];
    NSMutableArray *mArr = arr.mutableCopy;
    if (mArr) {
        [mArr enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj[@"urlStr"] isEqualToString:url]) {
                [mArr removeObject:obj];
                *stop = YES;
            }
        }];
    }else{
        mArr = [NSMutableArray arrayWithCapacity:1];
    }
    return mArr;
}

#pragma mark - getter

- (NSArray*)falseConnects{
    if (!_falseConnects) {
        _falseConnects = @[@(-1000),@(-1002),@(-1003),@(-1004)];
    }
    return _falseConnects;
}

- (NSArray*)lostConnects{
    if (!_lostConnects) {
        _lostConnects = @[@(-1001),@(-1005),@(-1006),@(-1009),@(-1011)];
    }
    return _lostConnects;
}

- (dispatch_queue_t)serialQueue{
    if (!_serialQueue) {
        _serialQueue = dispatch_queue_create("QueueToResend", DISPATCH_QUEUE_SERIAL);
    }
    return _serialQueue;
}

- (NSLock*)lock{
    if (!_lock) {
        _lock = [[NSLock alloc]init];
    }
    return _lock;
}
@end
