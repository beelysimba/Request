//
//  AppDelegate.h
//  Request
//
//  Created by 隔壁老王 on 2020/4/29.
//  Copyright © 2020 WY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

