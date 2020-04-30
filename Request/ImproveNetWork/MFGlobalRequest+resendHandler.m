//
//  MFGlobalRequest+resendHandler.m
//  test
//
//  Created by 隔壁老王 on 2020/4/29.
//  Copyright © 2020 MF_Mofunsky. All rights reserved.
//

#import "MFGlobalRequest+resendHandler.h"


@implementation MFGlobalRequest (resendHandler)

- (void)handleResendRequest:(NSString*)url task:(NSURLSessionDataTask *)task error:(NSError *)error response:(id)responseObject{
    NSLog(@"啦啦啦 ～ %@",url);
    //TODO: handle response

}

@end
