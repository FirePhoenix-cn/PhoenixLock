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
@property(strong , nonatomic) HTTPPost *httpPost;

@end

@implementation Operation

- (void)viewDidLoad {
    [super viewDidLoad];
    self.httpPost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    self.version.text = [self.userdefault objectForKey:@"appversion"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=syscontent";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&action=service"];
        [self.httpPost httpPostWithurl :urlStr body:body type:syscontentservice];
    });
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httpPost.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case syscontentservice:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                self.phone.text = [dic objectForKey:@"content"];
            }
        }
            break;
            
        case version:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"2"])
            {
                    [self showText:@"已是最新版"];
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"将要转到AppStore?" preferredStyle:1];
                UIAlertAction *comfirm = [UIAlertAction actionWithTitle:@"确定" style:0 handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/cn"]];
                   
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
            [self.httpPost httpPostWithurl :urlStr body:body type:guide];
        }
            break;
            
        case 4:
        {
            self.tabBarController.selectedIndex = 3;
            NSNotification *notice = [NSNotification notificationWithName:@"servicePhone" object:nil userInfo:@{@"phone":self.phone.text}];
            [[NSNotificationCenter defaultCenter] postNotification:notice];
        }
            break;
            
        case 5:
        {
            //版本更新
            NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=version";
            NSString *body = [NSString stringWithFormat:@"&account=%@&apptoken=%@&platfrom=IOS&version=%@",[self.userdefault objectForKey:@"account"],[self.userdefault objectForKey:@"appToken"],self.version.text];
            [self.httpPost httpPostWithurl :urlStr body:body type:version];
        }
            break;
            
        case 6:
        {
            NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=syscontent";
            NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&action=about"];
        
            [self.httpPost httpPostWithurl :urlStr body:body type:aboutus];
        }
            break;

        default:
            break;
    }
}

- (void)showText:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        // Set the annular determinate mode to show task progress.
        hud.mode = MBProgressHUDModeText;
        hud.label.text = NSLocalizedString(text, @"titles");
        hud.offset = CGPointMake(0.f, 0.f);
        [hud hideAnimated:YES afterDelay:0.5f];
    });
}
@end
