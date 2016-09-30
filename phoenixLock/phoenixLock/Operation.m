//
//  Operation.m
//  phoenixLock
//
//  Created by jinou on 16/7/4.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "Operation.h"
#import "SmartApp.h"
#import "AboutUs.h"
@interface Operation ()<HTTPPostDelegate>

{
    httpPostType _type;
}
@property(strong , nonatomic) HTTPPost *httpPost;

@end

@implementation Operation

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"操作指南与服务";
    _httpPost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    _version.text = [self.userdefault objectForKey:@"appversion"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=syscontent";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&action=service"];
        _type = syscontentservice;
        [_httpPost httpPostWithurl :urlStr body:body];
    });
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httpPost.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    
    switch (_type)
    {
        case syscontentservice:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                _phone.text = [dic objectForKey:@"content"];
            }
        }
            break;
            
        case version:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"2"])
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"通知" message:@"已是最新版" preferredStyle:1];
                UIAlertAction *comfirm = [UIAlertAction actionWithTitle:@"确定" style:0 handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [alert addAction:comfirm];
                dispatch_async(dispatch_get_main_queue(), ^{
                     [self presentViewController:alert animated:YES completion:nil];
                });
               
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"通知" message:[NSString stringWithFormat:@"有更新:%@",[dic objectForKey:@"version"]] preferredStyle:1];
                UIAlertAction *comfirm = [UIAlertAction actionWithTitle:@"去AppStore" style:0 handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/cn/app/jie-zou-da-shi/id493901993?mt=8"]];
                   
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:0 handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [alert addAction:comfirm];
                [alert addAction:cancel];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentViewController:alert animated:YES completion:nil];
                });
            }
        }break;
         
            
        case aboutus:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Account" bundle:nil];
                    AboutUs *next = (AboutUs*)[storyboard instantiateViewControllerWithIdentifier:@"AboutUs"];
                    next.text = [dic objectForKey:@"content"];
                    next.inittitle = @"关于我们";
                    [self.navigationController pushViewController:next animated:YES];
                });
            }
            
        }break;
            
        case guide:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Account" bundle:nil];
                    AboutUs *next = (AboutUs*)[storyboard instantiateViewControllerWithIdentifier:@"AboutUs"];
                    next.text = [dic objectForKey:@"content"];
                    next.inittitle = @"操作指南";
                    [self.navigationController pushViewController:next animated:YES];
                });
                
            }
            
        }break;
        
        default:
            break;
            
    }
    
}

- (IBAction)clickbtton:(UIButton *)sender
{
    switch (sender.tag)
    {
        case 1:
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            UIViewController *next = [storyboard instantiateViewControllerWithIdentifier:@"Paper"];
            [self.navigationController pushViewController:next animated:YES];
        }
            break;
            
        case 2:
        {
            NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=syscontent";
            NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&action=guide"];
            _type = guide;
            [_httpPost httpPostWithurl :urlStr body:body];
        }
            break;
            
            
        case 4:
        {
            self.tabBarController.selectedIndex = 3;
            SmartApp *next = (SmartApp*)[(UINavigationController*)self.tabBarController.viewControllers[3] viewControllers][0];
            next.number = _phone.text;
        }
            break;
            
        case 5:
        {
            //版本更新
            NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=version";
            NSString *body = [NSString stringWithFormat:@"&account=%@&apptoken=%@&platfrom=IOS&version=%@",[self.userdefault objectForKey:@"account"],[self.userdefault objectForKey:@"appToken"],_version.text];
            _type = version;
            [_httpPost httpPostWithurl :urlStr body:body];
        }
            break;
            
        case 6:
        {
            NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=syscontent";
            NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&action=about"];
            _type = aboutus;
            [_httpPost httpPostWithurl :urlStr body:body];
        }
            break;

        default:
            break;
    }
}
@end
