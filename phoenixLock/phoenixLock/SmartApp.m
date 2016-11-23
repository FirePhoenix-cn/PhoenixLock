//
//  SmartApp.m
//  phoenixLock
//
//  Created by jinou on 16/4/22.
//  Copyright © 2016年 jinou. All rights reserved.
// /index.php?g=Home&m=Lock&a=fanscall

#import "SmartApp.h"
#import "CheckCharacter.h"
#import "MBProgressHUD.h"

@interface SmartApp ()<HTTPPostDelegate>
{
    BOOL service;
}
@property(strong,nonatomic) NSMutableString *num_temp;
@property(strong,nonatomic) HTTPPost *httppost;
@end

@implementation SmartApp

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"应用";
    self.num_temp = [[NSMutableString alloc] init];
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    self.navigationItem.leftBarButtonItem = nil;
    self.telphone.text = ([[self.userdefaults objectForKey:@"account"] length]>11)?[[[self.userdefaults objectForKey:@"account"] mutableCopy] substringWithRange:NSMakeRange(0, 11)]:[self.userdefaults objectForKey:@"account"];
    self.bindphone.text = ([[self.userdefaults objectForKey:@"account"] length]>11)?[[[self.userdefaults objectForKey:@"account"] mutableCopy] substringWithRange:NSMakeRange(0, 11)]:[self.userdefaults objectForKey:@"account"];;
    self.used_min.text = @"0";
    self.retain_min.text = [self.userdefaults objectForKey:@"minutes"];
    self.used_min.text = [self.userdefaults objectForKey:@"usedminutes"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPhone:) name:@"servicePhone" object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.phonenum.text = @"";
    service = NO;
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    //布局
    [self.view1 setFrame:CGRectMake(8.0, 64.0 + 5.0, (self.view.bounds.size.width - 16.0 -5.0) *0.5 + 10.0, 72.0)];
    [self.view2 setFrame:CGRectMake(8.0 + self.view1.bounds.size.width + 5.0, 64.0 + 5.0,
                                (self.view.bounds.size.width - 16.0 - 5.0) *0.5 - 10.0, 72.0)];
    [self.view3 setFrame:CGRectMake(8.0, self.view1.frame.origin.y + 72.0 + 5.0, self.view.bounds.size.width - 16.0, self.view.bounds.size.height - 64.0 - 60.0 - 10.0 - 72.0 - 10.0)];
}

-(void)showPhone:(NSNotification*)notify
{
    service = YES;
    self.phonenum.text = notify.userInfo[@"phone"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

-(void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)deletenum:(UIButton *)sender
{
    if ([self.phonenum.text isEqualToString:@""])
    {
        return;
    }
    self.num_temp = [self.phonenum.text mutableCopy];
    self.num_temp = [[self.num_temp substringToIndex:self.num_temp.length - 1] mutableCopy];
    self.phonenum.text = self.num_temp;
}

- (IBAction)insertnum:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            [self.num_temp appendString:@"0"];
        }
            break;
        case 1:
        {
            [self.num_temp appendString:@"1"];
        }
            break;
        case 2:
        {
            [self.num_temp appendString:@"2"];
        }
            break;
        case 3:
        {
            [self.num_temp appendString:@"3"];
        }
            break;
        case 4:
        {
            [self.num_temp appendString:@"4"];
        }
            break;
        case 5:
        {
            [self.num_temp appendString:@"5"];
        }
            break;
        case 6:
        {
            [self.num_temp appendString:@"6"];
        }
            break;
        case 7:
        {
            [self.num_temp appendString:@"7"];
        }
            break;
        case 8:
        {
            [self.num_temp appendString:@"8"];
        }
            break;
        case 9:
        {
            [self.num_temp appendString:@"9"];
        }
            break;
        case 10:
        {
            [self.num_temp appendString:@"*"];
        }
            break;
        case 12:
        {
            [self.num_temp appendString:@"#"];
        }
            break;
        default:
            break;
    }
    self.phonenum.text = self.num_temp;
}

- (IBAction)call:(UIButton *)sender
{
    if ([self.phonenum.text isEqualToString:@""] || self.phonenum.text == nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"请输入手机号"];
        });
        return;
    }
    
    if (![CheckCharacter isValidateMobileNumber:self.phonenum.text] && service == NO)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"手机号格式不正确"];
        });
        
        return;
    }
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=fanscall&account=%@&apptoken=%@&tomobile=%@",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"appToken"],self.phonenum.text];
    [self.httppost httpPostWithurl:urlStr type:fanscall];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type) {
        case syscontentservice:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.phonenum.text = [dic objectForKey:@"content"];
                });
                
            }
        }
            break;
            
        case fanscall:
        {
            if ([dic[@"status"] isEqualToString:@"1"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self textExample:@"拨号成功"];
                });
            }
        }
            break;
        default:
            break;
    }
}

- (IBAction)charge:(UIButton *)sender
{
    //充值
    self.tabBarController.selectedIndex = 1;
}

- (IBAction)clientservice:(UIButton *)sender
{
    service = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=syscontent";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&action=service"];
    
        [self.httppost httpPostWithurl :urlStr body:body type:syscontentservice];
    });
}

- (void)textExample:(NSString*)text
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(text, @"title2");
    [hud.label setFont:[UIFont systemFontOfSize:12.0]];
    hud.offset = CGPointMake(0.f, - 20.f);
    [hud hideAnimated:YES afterDelay:2.f];
}

@end
