//
//  ModelViewController.m
//  phoenixLock
//
//  Created by jinou on 16/8/22.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ModelViewController.h"

@interface ModelViewController ()
@property (strong,nonatomic) UISwipeGestureRecognizer *rightSwipe;
@end

@implementation ModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"凰腾云盾-账号";
    self.leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goback.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = self.leftItem;
    self.leftItem = nil;
    self.userdefault = [NSUserDefaults standardUserDefaults];
    self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.rightSwipe];
}

-(void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
