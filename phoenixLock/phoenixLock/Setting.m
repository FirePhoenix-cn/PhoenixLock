//
//  Setting.m
//  phoenixLock
//
//  Created by jinou on 16/7/4.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "Setting.h"


@interface Setting ()
@property(strong, nonatomic) AppDelegate *appdelegete;
@end

@implementation Setting

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.appdelegete = (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)quit:(UIButton *)sender
{
    [self.userdefault setBool:YES forKey:@"quitapp"];
    [self.appdelegete.searchTimer invalidate];
    self.appdelegete.searchTimer = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
       
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        UIViewController *next = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"loginpage"];
        [self.tabBarController.viewControllers[0] pushViewController:next animated:YES];
        self.tabBarController.selectedIndex = 0;
    });
}

@end
