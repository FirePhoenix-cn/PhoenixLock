//
//  AddLock.m
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "AddLock.h"
#import "MD5Code.h"
#import "MBProgressHUD.h"
#import "BLEConnect.h"

@interface AddLock ()<HTTPPostDelegate,MBProgressHUDDelegate>
{
    NSInteger status;
    NSString *orderno;
    NSString *vercodes;
}
@property(strong, nonatomic) HTTPPost *httppost;
@property(strong, nonatomic) NSTimer *vercodetimer;
@property(strong, nonatomic) MBProgressHUD *hud;
@end

@implementation AddLock

- (void)viewDidLoad
{
    [super viewDidLoad];
    status = 100;
    self.title = @"云盾锁";
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopTimers) name:@"stopSearch" object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
    [self.appDelegate.searchTimer setFireDate:[NSDate distantFuture]];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.appDelegate.searchLock = NO;
    //[self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
}

-(void)stopTimers
{
    self.appDelegate.searchLock = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)active
{
    /***********激活绑定**********/
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
    NSString *md5string = [NSString stringWithFormat:@"account=%@&apptoken=%@&globalcode=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                           [self.userdefaults objectForKey:@"account"],
                           [self.userdefaults objectForKey:@"appToken"],
                           self.globalcode,strDate,
                           [self.userdefaults objectForKey:@"uuid"]];
    NSString *sign = [MD5Code md5:md5string];
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=adddev&account=%@&apptoken=%@&globalcode=%@&uuid=%@&oper_time=%@&sign=%@&devcode=%@&devname=PHLock",
                       [self.userdefaults objectForKey:@"account"],
                       [self.userdefaults objectForKey:@"appToken"],self.globalcode,[self.userdefaults objectForKey:@"uuid"],strDate,sign,vercodes];
    [self.httppost httpPostWithurl:urlStr type:adddev];

}

-(void) goBack
{
    [self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)scanQRCode:(UIButton *)sender
{
    if (self.globalcode == nil )
    {
        QRReaderViewController *VC = [[QRReaderViewController alloc] init];
        VC.delegate = self;
        [self.navigationController pushViewController:VC animated:YES];
    }else if(status == 100)
    {
        orderno = @"";
        [self vioceCheck];
        
    }else if (status == 1)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AddLock" bundle:nil];
        BLEConnect *next = (BLEConnect*)[storyboard instantiateViewControllerWithIdentifier:@"bleconnect"];
        next.guid = [self NSStringConversionToNSData:self.globalcode];
        next.scrC = [self NSStringConversionToNSData:self.sc];
        next.scrD = [self NSStringConversionToNSData:self.sd];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:next animated:YES];
        });
    }else if(status == -6)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            // Set the annular determinate mode to show task progress.
            hud.mode = MBProgressHUDModeText;
            hud.label.text = NSLocalizedString(@"已存在管理员用户！", @"HUD message title");
            // Move to bottm center.
            hud.offset = CGPointMake(0.f, 20.f);
            
            [hud hideAnimated:YES afterDelay:3.f];
            
            self.globalcode = nil;
            status = 100;
            [self.btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
        });
    }else if(status == -7)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            // Set the annular determinate mode to show task progress.
            hud.mode = MBProgressHUDModeText;
            hud.label.text = NSLocalizedString(@"设备用户绑定有误", @"HUD message title");
            // Move to bottm center.
            hud.offset = CGPointMake(0.f, 20.f);
            
            [hud hideAnimated:YES afterDelay:3.f];
            
            self.globalcode = nil;
            status = 100;
            [self.btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
        });
    }else if(status == -5)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            // Set the annular determinate mode to show task progress.
            hud.mode = MBProgressHUDModeText;
            hud.label.text = NSLocalizedString(@"添加失败,设备不存在", @"HUD message title");
            // Move to bottm center.
            hud.offset = CGPointMake(0.f, 20.f);
            [hud hideAnimated:YES afterDelay:3.f];
            self.globalcode = nil;
            status = 100;
            [self.btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
        });
        
    }
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case voice:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                orderno = [dic objectForKey:@"orderno"];
            }else if([[dic objectForKey:@"status"] integerValue] == -12)
            {
                self.globalcode = nil;
                status = 100;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.vercodetimer invalidate];
                    self.vercodetimer = nil;
                    [self.hud hideAnimated:YES];
                    [self textExample];
                    [self.btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
                });
            }
        }
            
            break;
            
            
        case keypress:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                vercodes = [dic objectForKey:@"keyinfo"];
                [self.vercodetimer invalidate];
                self.vercodetimer = nil;
                [self active];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.hud hideAnimated:YES];
                    [self.btn setTitle:@"绑定云盾锁" forState:UIControlStateNormal];
                });
                
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"0"] && ![[dic objectForKey:@"keyinfo"] isEqualToString:@""])
            {
                //验证失败
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [self.vercodetimer invalidate];
                                   self.vercodetimer = nil;
                                   [self.hud hideAnimated:YES];
                                   [self textExample];
                               });
            }
        }break;
            
        case adddev:
        {
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                [self.userdefaults setObject:[dic objectForKey:@"maxshare"] forKey:@"numforkey"];
                [self.userdefaults setObject:[dic objectForKey:@"productdate"] forKey:@"productdate"];
                [self.userdefaults setObject:[dic objectForKey:@"warrantydate"] forKey:@"warrantydate"];
                [self.userdefaults setObject:[dic objectForKey:@"devid"] forKey:@"devid"];
                [self.userdefaults synchronize];
                self.sc = [dic objectForKey:@"devcode"];
                self.sd = [dic objectForKey:@"authcode"];
            }
            status = [[dic objectForKey:@"status"] integerValue];
            
        }break;
            
        default:
            break;
    }
}

/******************************验证UUID的绑定状态***************************/
- (void)vioceCheck
{
    /**********语音验证***********/
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=voice";
    NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@&mobile=%@&module=adddev&vercode=5&veraction=2&vertype=1",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"account"]];
    [self.httppost httpPostWithurl :urlStr body:body type:voice];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.vercodetimer = [[NSTimer alloc] init];
        self.vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(changetext) userInfo:nil repeats:YES];
        self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        self.hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
        self.hud.delegate = self;
        [self.hud hideAnimated:YES afterDelay:35.0];
    });
    
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    if (self.vercodetimer == nil)
    {
        return;
    }
    [self.vercodetimer invalidate];
    self.vercodetimer = nil;
    self.globalcode = nil;
    status = 100;
    [self.btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
    [self textExample];
}

- (void)textExample
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = NSLocalizedString(@"验证失败，请稍后重试", @"HUD message title");
        hud.offset = CGPointMake(0.f, 20.f);
        [hud hideAnimated:YES afterDelay:3.f];
    });
}

-(void)changetext
{
    if ([orderno isEqualToString:@""])
    {
        return;
    }
    NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=presskey&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&oerderno=%@",orderno];
    [self.httppost httpPostWithurl:urlStr type:keypress];
}


/*****************QR协议函数实现***************/
- (void)didFinishedReadingQR:(NSString *)string
{
    self.globalcode = string;
    [self.userdefaults setObject:string forKey:@"guid"];//临时保存(添加绑定后清除)
    [self.userdefaults synchronize];
    [self.btn setTitle:@"获取验证码" forState:UIControlStateNormal];
}

@end
