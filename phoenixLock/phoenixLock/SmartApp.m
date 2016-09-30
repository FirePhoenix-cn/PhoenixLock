//
//  SmartApp.m
//  phoenixLock
//
//  Created by jinou on 16/4/22.
//  Copyright © 2016年 jinou. All rights reserved.
// /index.php?g=Home&m=Lock&a=fanscall

#import "SmartApp.h"
#import "CheckCharacter.h"
@interface SmartApp ()<HTTPPostDelegate>
{
    BOOL service;
}
@property(strong,nonatomic) NSMutableString *num_temp;
@property(assign,nonatomic) httpPostType type;
@property(strong,nonatomic) HTTPPost *httppost;
@end

@implementation SmartApp

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"应用";
    
    _num_temp = [[NSMutableString alloc] init];
    _type = fanscall;
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    
    self.navigationItem.leftBarButtonItem = nil;
    
    _telphone.text = ([[self.userdefaults objectForKey:@"account"] length]>11)?[[[self.userdefaults objectForKey:@"account"] mutableCopy] substringWithRange:NSMakeRange(0, 11)]:[self.userdefaults objectForKey:@"account"];
    _bindphone.text = ([[self.userdefaults objectForKey:@"account"] length]>11)?[[[self.userdefaults objectForKey:@"account"] mutableCopy] substringWithRange:NSMakeRange(0, 11)]:[self.userdefaults objectForKey:@"account"];;
    _used_min.text = @"0";
    _retain_min.text = [self.userdefaults objectForKey:@"minutes"];
   
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
    _phonenum.text = _number;
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    //布局
    [_view1 setFrame:CGRectMake(8.0, 64.0 + 5.0, (self.view.bounds.size.width - 16.0 -5.0) *0.5 + 10.0, 72.0)];
    [_view2 setFrame:CGRectMake(8.0 + _view1.bounds.size.width + 5.0, 64.0 + 5.0,
                                (self.view.bounds.size.width - 16.0 - 5.0) *0.5 - 10.0, 72.0)];
    [_view3 setFrame:CGRectMake(8.0, _view1.frame.origin.y + 72.0 + 5.0, self.view.bounds.size.width - 16.0, self.view.bounds.size.height - 64.0 - 60.0 - 10.0 - 72.0 - 10.0)];
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
    if ([_phonenum.text isEqualToString:@""])
    {
        return;
    }
    _num_temp = [_phonenum.text mutableCopy];
    _num_temp = [[_num_temp substringToIndex:_num_temp.length - 1] mutableCopy];
    _phonenum.text = _num_temp;
}

- (IBAction)insertnum:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            [_num_temp appendString:@"0"];
        }
            break;
        case 1:
        {
            [_num_temp appendString:@"1"];
        }
            break;
        case 2:
        {
            [_num_temp appendString:@"2"];
        }
            break;
        case 3:
        {
            [_num_temp appendString:@"3"];
        }
            break;
        case 4:
        {
            [_num_temp appendString:@"4"];
        }
            break;
        case 5:
        {
            [_num_temp appendString:@"5"];
        }
            break;
        case 6:
        {
            [_num_temp appendString:@"6"];
        }
            break;
        case 7:
        {
            [_num_temp appendString:@"7"];
        }
            break;
        case 8:
        {
            [_num_temp appendString:@"8"];
        }
            break;
        case 9:
        {
            [_num_temp appendString:@"9"];
        }
            break;
        case 10:
        {
            [_num_temp appendString:@"*"];
        }
            break;
        case 12:
        {
            [_num_temp appendString:@"#"];
        }
            break;
        default:
            break;
    }
    _phonenum.text = _num_temp;
}

- (IBAction)call:(UIButton *)sender
{
    if ([_phonenum.text isEqualToString:@""])
    {
        return;
    }
    if (![CheckCharacter isValidateMobileNumber:_phonenum.text] && service == NO)
    {
        UIAlertController *aler = [UIAlertController alertControllerWithTitle:@"提示" message:@"手机号格式不正确" preferredStyle:1];
        [aler addAction:[UIAlertAction actionWithTitle:@"确定" style:0 handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _num_temp = @"".mutableCopy;
                _phonenum.text = @"";
            });
            
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:aler animated:YES completion:nil];
        });
        
        return;
    }
    service = NO;
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=fanscall&account=%@&apptoken=%@&tomobile=%@",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"appToken"],_phonenum.text];
    [_httppost httpPostWithurl:urlStr];
    _type = fanscall;
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
   
    switch (_type) {
        case syscontentservice:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _phonenum.text = [dic objectForKey:@"content"];
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
        _type = syscontentservice;
        [_httppost httpPostWithurl :urlStr body:body];
    });
}
@end
