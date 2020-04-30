//
//  RequestTests.m
//  RequestTests
//
//  Created by 隔壁老王 on 2020/4/29.
//  Copyright © 2020 WY. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MFGlobalRequest.h"
@interface RequestTests : XCTestCase
@property (strong, nonatomic) MFGlobalRequest *request;
@end

@implementation RequestTests

- (void)setUp {
    self.request = [MFGlobalRequest sharedInstance];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    NSString *mo = [self.request getModifiedDateWithUrl:@"www.baidu.com"];
    XCTAssertNil(mo);
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
