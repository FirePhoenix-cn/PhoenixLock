//
//  SmartAccount.m
//  phoenixLock
//
//  Created by jinou on 16/4/22.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "SmartAccount.h"
#import "shareview.h"
#import "SmartMall.h"

#import <ShareSDK/ShareSDK.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>

@interface SmartAccount ()<shareviewdelegate,HTTPPostDelegate>

@property(strong, nonatomic) shareview *sharev;
@property(strong, nonatomic) UIView *grayview;
@property(strong, nonatomic) HTTPPost *httppost;
@property(strong, nonatomic) NSMutableArray *PWData;
@end

@implementation SmartAccount

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"账号";
    self.zhanghu.layer.borderWidth = 0.5;
    self.guzhang.layer.borderWidth = 0.5;
    self.caozuo.layer.borderWidth = 0.5;
    self.fenxiang.layer.borderWidth = 0.5;
    self.grayview = [[UIView alloc] initWithFrame:self.view.frame];
    self.grayview.backgroundColor = [UIColor grayColor];
    self.grayview.alpha = 0.95;
    [self addObserver:self forKeyPath:@"PWData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    self.msg2.text = [NSString stringWithFormat:@"%@/%@",[self.userdefaults objectForKey:@"usedminutes"],[self.userdefaults objectForKey:@"minutes"]];
    self.msg3.text = [NSString stringWithFormat:@"0.0/%@",[self.userdefaults objectForKey:@"flows"]];
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
     self.PWData = @[[NSNumber numberWithInteger:0],[NSNumber numberWithInteger:0]].mutableCopy;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
    self.accountname.text = [self.userdefaults objectForKey:@"account"];
    //布局
    [self.subv setFrame:CGRectMake(8.0, 113.0 + 64.0 , self.view.bounds.size.width-16.0, 58.0)];
    [self.label1 setFrame:CGRectMake(self.subv.bounds.size.width / 3.0, 0.0, 1.0, 58.0)];
    [self.label2 setFrame:CGRectMake(self.subv.bounds.size.width / 3.0 * 2.0, 0.0, 1.0, 58.0)];
    [self.firstimg setFrame:CGRectMake(5.0, 14.0, 30.0, 30.0)];
    [self.secondimg setFrame:CGRectMake(5.0 + self.label1.frame.origin.x, 14.0, 30.0, 30.0)];
    [self.thirdimg setFrame:CGRectMake(5.0 + self.label2.frame.origin.x, 14.0, 30.0, 30.0)];
    [self.msg1 setFrame:CGRectMake(self.firstimg.frame.origin.x + 30.0, 5.0, self.subv.bounds.size.width / 3.0 - 40.0, 21.0)];
    [self.msg2 setFrame:CGRectMake(self.secondimg.frame.origin.x + 30.0, 5.0, self.subv.bounds.size.width / 3.0 - 40.0, 21.0)];
    [self.msg3 setFrame:CGRectMake(self.thirdimg.frame.origin.x + 30.0, 5.0, self.subv.bounds.size.width / 3.0 - 40.0, 21.0)];
    [self.text1 setFrame:CGRectMake(self.firstimg.frame.origin.x + 30.0, 32.0, self.subv.bounds.size.width / 3.0 - 40.0, 21.0)];
    [self.text2 setFrame:CGRectMake(self.secondimg.frame.origin.x + 30.0, 32.0, self.subv.bounds.size.width / 3.0 - 40.0, 21.0)];
    [self.text3 setFrame:CGRectMake(self.thirdimg.frame.origin.x + 30.0, 32.0, self.subv.bounds.size.width / 3.0 - 40.0, 21.0)];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSArray *locks = [self showAllManagerLock];
    NSInteger usedKey = 0;
    NSInteger totalKey = 0;
    for (SmartLock *lock in locks)
    {
        usedKey += [[lock sharenum] integerValue];
        totalKey += [[lock maxshare] integerValue];
    }
    self.PWData = @[[NSNumber numberWithInteger:usedKey],[NSNumber numberWithInteger:totalKey]].mutableCopy;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([change[@"new"] isEqual:change[@"old"]])
    {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.msg1 setText:[NSString stringWithFormat:@"%@/%@",self.PWData[0],self.PWData[1]]];
    });
}

-(void)cancel
{
    [self.grayview removeFromSuperview];
    [self.sharev removeFromSuperview];
    self.sharev = nil ;
}

- (IBAction)share:(id)sender
{
    self.sharev = (shareview*)[[[NSBundle  mainBundle]  loadNibNamed:@"shareview" owner:self options:nil]  lastObject];
    self.sharev.delegate = self;
    CGFloat X = self.view.frame.size.width - 300.0;
    CGFloat Y = self.view.frame.size.height - 153.0 - 60.0;
    CGRect rectf = CGRectMake(X/2.0, Y, 300.0, 153.0);
    self.sharev.frame = rectf;
    [self.view addSubview:self.grayview];
    [self.view addSubview:self.sharev];
    
    //请求分享信息
    NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=getpicshare&account=%@&apptoken=%@",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"appToken"]];
    [self.httppost httpPostWithurl:urlStr type:getpicshare];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    
    switch (type) {
        case getpicshare:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                self.sharev.title = [dic objectForKey:@"title"];
                self.sharev.pic = [[dic objectForKey:@"pic"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                self.sharev.url = [[dic objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
        }
            break;
            
        default:
            break;
    }
    
}

- (IBAction)charge:(UIButton *)sender
{
    self.tabBarController.selectedIndex = 1;
}
@end
