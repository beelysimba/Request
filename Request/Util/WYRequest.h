//
//  WYRequest.h
//  mofunshow
//
//  Created by 隔壁老王 on 2020/4/26.
//  Copyright © 2020 mofunsky. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WYRequest : NSObject

/**请求参数对*/
@property (nonatomic, strong) NSDictionary *params;

/**
 请求的url
 */
@property (nonatomic, copy) NSString *urlStr;

/**
 请求方法，默认get请求
 */
@property (nonatomic, copy) NSString *method;

/**
 请求没发送成功，重新发送的次数
 */
@property (nonatomic, assign) int retryCount;


@end

NS_ASSUME_NONNULL_END
