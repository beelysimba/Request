//
//  MFAssembleHud.h
//  mofunshow
//
//  Created by 隔壁老王 on 2020/4/24.
//  Copyright © 2020 mofunsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"
#import "JDStatusBarNotification.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, WYHUDType){
    WYHUDTypeNone = 0,
    WYHUDTypeWaitNote = 1 << 0,
    WYHUDTypeWaitToast = 1 << 1,
    WYHUDTypeSuccessNote = 1 << 2,
    WYHUDTypeSuccessToast = 1 << 3,
    WYHUDTypeFailedNote = 1 << 4,
    WYHUDTypeFailedToast = 1 << 5,
    WYHUDTypeCancelNote = 1 << 6,
    WYHUDTypeCancelToast = 1 << 7,
    WYHUDTypeAlert = 1 << 8,
};

typedef struct {
    MBProgressHUD *hud;
    UIView *note;
    WYHUDType type;
}HudView;

static const WYHUDType WYHUDTypeNormalToast = WYHUDTypeWaitToast | WYHUDTypeSuccessToast | WYHUDTypeFailedToast | WYHUDTypeCancelToast;
static const WYHUDType WYResponseOnlyFailInform = WYHUDTypeFailedToast|WYHUDTypeAlert;
static const WYHUDType WYHUDTypeNormalNote = WYHUDTypeWaitNote | WYHUDTypeSuccessNote | WYHUDTypeFailedNote;
static const WYHUDType WYResponseOnlyFailNote = WYHUDTypeFailedNote | WYHUDTypeAlert ;

@interface MFAssembleHud : NSObject

+ (void)successNoteShow;
+ (void)failedNoteShow;
+ (void)successNoteShowWithTipString:(NSString *)tipString;
+ (UIView *)waitingNoteShowWithTitle:(NSString*)title;

+ (MBProgressHUD *)waitingToastHudShow;
+ (MBProgressHUD *)waitingToastHudShowWithTitle:(NSString *)title;

+ (void)successToastHudShow;
+ (void)failedToastHudShow;
+ (void)ShowHudWithTitle:(NSString *)title Detail:(NSString *)text AfterDelay:(NSTimeInterval)delay;
+ (void)showTextOnly:(NSString *)text AfterDelay:(NSTimeInterval)delay;

+ (HudView*)requestHudWithType:(WYHUDType)HUDtype;
+ (void)hideHudView:(HudView*)hud;
+ (void)showFailedView:(WYHUDType)HUDtype;
+ (UIViewController *)getCurrentVC;
@end

NS_ASSUME_NONNULL_END
