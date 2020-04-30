//
//  MFGlobalRequest+resendHandler.h
//  test
//
//  Created by 隔壁老王 on 2020/4/29.
//  Copyright © 2020 MF_Mofunsky. All rights reserved.
//


#import "MFGlobalRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFGlobalRequest (resendHandler)

- (void)handleResendRequest:(NSString*)url task:(NSURLSessionDataTask *)task error:(NSError *)error response:(id)responseObject;
@end

NS_ASSUME_NONNULL_END
