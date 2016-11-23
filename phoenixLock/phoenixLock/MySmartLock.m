//
//  MySmartLock.m
//  phoenixLock
//
//  Created by jinou on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "MySmartLock.h"

@implementation MySmartLock

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"云盾锁";
}

-(void)goBack
{

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)addlock:(UIButton *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AddLock" bundle:nil];
        UIViewController *next = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"scanqr"];
        [self.navigationController pushViewController:next animated:YES];
    });
}
@end
