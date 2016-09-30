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
    self.title = @"系统设置";
    _appdelegete = (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)quit:(UIButton *)sender
{
    [self.userdefault setBool:YES forKey:@"quitapp"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        UIViewController *next = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"loginpage"];
        [self.navigationController pushViewController:next animated:YES];
    });
}

@end
