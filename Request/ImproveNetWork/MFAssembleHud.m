//
//  MFAssembleHud.m
//  mofunshow
//
//  Created by 隔壁老王 on 2020/4/24.
//  Copyright © 2020 mofunsky. All rights reserved.
//

#import "MFAssembleHud.h"
#import "MBProgressHUD.h"
#import "JDStatusBarNotification.h"
#import <objc/runtime.h>

@implementation MFAssembleHud
//试用于单个请求，请求队列最好另外处理
+ (HudView*)requestHudWithType:(WYHUDType)HUDtype{
    MBProgressHUD *HUD;
    UIView *waitingNoteHud;
    HudView *hudView = {(__bridge HudView *)(HUD),waitingNoteHud,HUDtype};
    if (HUDtype & WYHUDTypeWaitToast) {
        HUD = [MFAssembleHud waitingToastHudShow];
    }
    else if (HUDtype & WYHUDTypeWaitNote)
    {
        waitingNoteHud = [MFAssembleHud waitingNoteShowWithTitle:@"正在请求···"];
    }
    return hudView;
}

+ (void)hideHudView:(HudView*)hud{
    if (!hud ) {
        return;
    }
    if (hud->hud) {
        [hud->hud hideAnimated:YES];
    }
    else if(hud->note){
        [JDStatusBarNotification dismiss];
    }
}

+ (void)showFailedView:(WYHUDType)HUDtype{
    if (HUDtype & WYHUDTypeFailedNote) {
                   [MFAssembleHud failedNoteShow];
               }
               else if (HUDtype & WYHUDTypeFailedToast) {
                   [MFAssembleHud failedToastHudShow];
               }
}

#pragma mark - Note

+ (void)successNoteShow{
    [JDStatusBarNotification showWithStatus:@"发布成功" dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
}

+ (void)failedNoteShow{
    [JDStatusBarNotification showWithStatus:@"网络请求失败" dismissAfter:2.0 styleName:JDStatusBarStyleError];
}

+ (void)successNoteShowWithTipString:(NSString *)tipString{
  [JDStatusBarNotification showWithStatus:tipString dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
}

+ (UIView *)waitingNoteShowWithTitle:(NSString*)title{
    return [JDStatusBarNotification showWithStatus:title styleName:JDStatusBarStyleWarning];
}

#pragma mark - MBProgressHUD

+ (MBProgressHUD *)HUDinit
{
    UIView *container = [self getCurrentVC].view;
    if (!container) {
      NSLog(@"HUDinit failed");
      return nil;
    }
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:container];
    [container addSubview:HUD];
    return HUD;
}

+ (MBProgressHUD *)waitingToastHudShow{
    MBProgressHUD *HUD = [self HUDinit];
    if (HUD) {
       HUD.label.text = @"正在载入";
       [HUD showAnimated:YES];
       return HUD;
    }
    return nil;
}

+ (MBProgressHUD *)waitingToastHudShowWithTitle:(NSString *)title{
    MBProgressHUD *HUD = [self HUDinit];
    if (HUD) {
       HUD.label.text = title;
       [HUD showAnimated:YES];
       return HUD;
    }
    return nil;
}

#pragma mark - Toast
+ (void)successToastHudShow{
   MBProgressHUD *HUD = [self HUDinit];
   if (HUD) {
       HUD.mode = MBProgressHUDModeCustomView;
       HUD.label.text = @"发布成功";
       [HUD showAnimated:YES];
       [HUD hideAnimated:YES afterDelay:2];
  }
}

+ (void)failedToastHudShow{
   MBProgressHUD *HUD = [self HUDinit];
   if (HUD) {
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.label.text = @"网络请求失败提醒";
    [HUD showAnimated:YES];
    [HUD hideAnimated:YES afterDelay:1.5];
   }
}

+ (void)ShowHudWithTitle:(NSString *)title Detail:(NSString *)text AfterDelay:(NSTimeInterval)delay{
    MBProgressHUD *HUD = [self HUDinit];
    if (HUD) {
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.label.text = title;
        HUD.detailsLabel.text = text;
        [HUD showAnimated:YES];
        [HUD hideAnimated:YES afterDelay:delay];
    }
}

+ (void)showTextOnly:(NSString *)text AfterDelay:(NSTimeInterval)delay{
    MBProgressHUD *MBhud = [self HUDinit];
    if (MBhud) {
        MBhud.mode = MBProgressHUDModeText;
        MBhud.label.text = text;
        MBhud.margin = 10.f;
        [MBhud showAnimated:YES];
        [MBhud hideAnimated:YES afterDelay:delay];
    }
}


+ (UIViewController *)getCurrentVC {
    __block UIViewController *result = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
      UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        if (window.windowLevel != UIWindowLevelNormal) {
            NSArray *windows = [[UIApplication sharedApplication] windows];
            for (UIWindow *temp in windows) {
                if (temp.windowLevel == UIWindowLevelNormal) {
                    window = temp;
                    break;
                }
            }
        }
        //取当前展示的控制器
        result = window.rootViewController;
        while (result.presentedViewController) {
            result = result.presentedViewController;
        }
        //如果为UITabBarController：取选中控制器
        if ([result isKindOfClass:[UITabBarController class]]) {
            result = [(UITabBarController *)result selectedViewController];
        }
        //如果为UINavigationController：取可视控制器
        if ([result isKindOfClass:[UINavigationController class]]) {
            result = [(UINavigationController *)result visibleViewController];
        }
    });
    return result;
}

@end
