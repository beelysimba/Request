//
//  ViewController.m
//  test
//
//  Created by 隔壁老王 on 2019/7/4.
//  Copyright © 2019 MF_Mofunsky. All rights reserved.
//

#import "ViewController.h"
#import "MFGlobalRequest.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *refreshBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [MFGlobalRequest sharedInstance].debug = YES;
    [self request];
    // Do any additional setup after loading the view.
}

- (void)requestDailyData:(NSString *)url{
    __weak typeof(self) weakself = self;
    //好奇心日报内容
    [[MFGlobalRequest sharedInstance] requestURL:url httpMethod:@"GET" parameters:nil timeoutInterval:0 policy:RequestEnsureDelivery success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        __strong typeof(weakself)strongself = weakself;
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = @" ";
         if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        }else {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //去除掉首尾的空白字符和换行字符
         [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongself.textView setText:jsonString];
        });
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error, id  _Nonnull responseObject) {
        NSLog(@"error--%@",error);

    } HUDtype:WYHUDTypeNormalToast];
}

- (void)request{
    NSString *url1 = @"http://app3.qdaily.com/app3/papers/index/0.json";
//          NSString *url2 = @"http://app3.qdaily.com/app3/homes/index_v2/0.json";
          [self requestDailyData:url1];
//          [self requestDailyData:url2];
}

- (IBAction)refreshData:(UIButton *)sender {
}

@end
