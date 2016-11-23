//
//  MyTabbarController.m
//  phoenixLock
//
//  Created by jinou on 16/8/26.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "MyTabbarController.h"

@interface MyTabbarController ()<UITabBarControllerDelegate>

@end

@implementation MyTabbarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    self.tabBar.tintColor = [UIColor colorFromHexString:@"F8990F"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    UIViewController *localvc = [(UINavigationController*)self.selectedViewController viewControllers][0];
    UIViewController *nextvc = [(UINavigationController*)viewController viewControllers][0];
    //防止子页面直接跳转主页，导致内存不能释放
    if ([localvc isKindOfClass:[nextvc class]])
    {
        return NO;
    }
    return YES;
}

@end
