//
//  ModelViewController.m
//  phoenixLock
//
//  Created by jinou on 16/8/22.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ModelViewController.h"

@interface ModelViewController ()

@end

@implementation ModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goback.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = _leftItem;
    _leftItem = nil;
    _userdefault = [NSUserDefaults standardUserDefaults];

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
