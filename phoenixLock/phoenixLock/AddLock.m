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
@interface AddLock ()<HTTPPostDelegate,MBProgressHUDDelegate>
{
    httpPostType _type;
    NSInteger _status;
    NSString *_orderno;
    NSString *_vercodes;
}
@property(strong, nonatomic) HTTPPost *httppost;
@property(strong, nonatomic) NSTimer *vercodetimer;
@property(strong, nonatomic) MBProgressHUD *hud;
@end

@implementation AddLock

- (void)viewDidLoad {
    [super viewDidLoad];
    _status = 100;
    self.title = @"云盾锁";
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_vercodetimer invalidate];
    _vercodetimer = nil;
}

- (void)didReceiveMemoryWarning {
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
                           _GUID,strDate,
                           [self.userdefaults objectForKey:@"uuid"]];
    NSString *sign = [MD5Code md5:md5string];
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=adddev&account=%@&apptoken=%@&globalcode=%@&uuid=%@&oper_time=%@&sign=%@&devcode=%@&devname=phoenixlock",
                       [self.userdefaults objectForKey:@"account"],
                       [self.userdefaults objectForKey:@"appToken"],_GUID,[self.userdefaults objectForKey:@"uuid"],strDate,sign,_vercodes];
    [_httppost httpPostWithurl:urlStr];
    _type = adddev;

}

-(void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)scanQRCode:(UIButton *)sender {
    
    if (_GUID == nil )
    {
        QRReaderViewController *VC = [[QRReaderViewController alloc] init];
        VC.delegate = self;
        [self.navigationController pushViewController:VC animated:YES];
    }else if(_status == 100)
    {
        _orderno = @"";
        [self vioceCheck];
        
    }else if (_status == 1)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AddLock" bundle:nil];
            UIViewController *next = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"bleconnect"];
            [self.navigationController pushViewController:next animated:YES];
        });
    }else if(_status == -6)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            // Set the annular determinate mode to show task progress.
            hud.mode = MBProgressHUDModeText;
            hud.label.text = NSLocalizedString(@"已存在管理员用户！", @"HUD message title");
            // Move to bottm center.
            hud.offset = CGPointMake(0.f, 20.f);
            
            [hud hideAnimated:YES afterDelay:3.f];
            
            _GUID = nil;
            _status = 100;
            [_btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
        });
    }else if(_status == -7)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            // Set the annular determinate mode to show task progress.
            hud.mode = MBProgressHUDModeText;
            hud.label.text = NSLocalizedString(@"设备用户绑定有误", @"HUD message title");
            // Move to bottm center.
            hud.offset = CGPointMake(0.f, 20.f);
            
            [hud hideAnimated:YES afterDelay:3.f];
            
            _GUID = nil;
            _status = 100;
            [_btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
        });
    }else if(_status == -5)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            // Set the annular determinate mode to show task progress.
            hud.mode = MBProgressHUDModeText;
            hud.label.text = NSLocalizedString(@"添加失败,设备不存在", @"HUD message title");
            // Move to bottm center.
            hud.offset = CGPointMake(0.f, 20.f);
            
            [hud hideAnimated:YES afterDelay:3.f];
            
            _GUID = nil;
            _status = 100;
            [_btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
        });
        
    }
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{

    switch (_type)
    {
        case voice:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                _orderno = [dic objectForKey:@"orderno"];
            }else if([[dic objectForKey:@"status"] integerValue] == -12)
            {
                _GUID = nil;
                _status = 100;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_vercodetimer invalidate];
                    _vercodetimer = nil;
                    [_hud hideAnimated:YES];
                    [self textExample];
                    [_btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
                });
            }
        }
            
            break;
            
            
        case keypress:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                _vercodes = [dic objectForKey:@"keyinfo"];
                [_vercodetimer invalidate];
                _vercodetimer = nil;
                [self active];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_hud hideAnimated:YES];
                    [_btn setTitle:@"开始绑定" forState:UIControlStateNormal];
                });
                
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"0"] && ![[dic objectForKey:@"keyinfo"] isEqualToString:@""])
            {
                //验证失败
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [_vercodetimer invalidate];
                                   _vercodetimer = nil;
                                   [_hud hideAnimated:YES];
                                   [self textExample];
                               });
            }
        }break;
            
        case adddev:
        {
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                [self.userdefaults setObject:[dic objectForKey:@"maxshare"] forKey:@"maxshare"];
                [self.userdefaults setObject:[dic objectForKey:@"productdate"] forKey:@"productdate"];
                [self.userdefaults setObject:[dic objectForKey:@"warrantydate"] forKey:@"warrantydate"];
                [self.userdefaults setObject:[dic objectForKey:@"devid"] forKey:@"devid"];
                [self.userdefaults setObject:[dic objectForKey:@"devcode"] forKey:@"sc"];//nsstring临时
                [self.userdefaults setObject:[dic objectForKey:@"authcode"] forKey:@"sd"];
                [self.userdefaults synchronize];
            }
            _status = [[dic objectForKey:@"status"] integerValue];
            
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
    NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@&mobile=%@&module=adddev&vercode=3&veraction=2&vertype=1",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"account"]];
    _type = voice;
    [_httppost httpPostWithurl :urlStr body:body];

    _vercodetimer = [[NSTimer alloc] init];
    _vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(changetext) userInfo:nil repeats:YES];
    _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    _hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
    _hud.delegate = self;
    [_hud hideAnimated:YES afterDelay:35.0];
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    if (_vercodetimer == nil)
    {
        return;
    }
    [_vercodetimer invalidate];
    _vercodetimer = nil;
    _GUID = nil;
    _status = 100;
    [_btn setTitle:@"扫描全球码" forState:UIControlStateNormal];
    [self textExample];
}

- (void)textExample
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(@"验证失败，请稍后重试", @"HUD message title");
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, 20.f);
    
    [hud hideAnimated:YES afterDelay:3.f];
}


-(void)changetext
{
    if ([_orderno isEqualToString:@""])
    {
        return;
    }
    NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=presskey&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&oerderno=%@",_orderno];
    _type = keypress;
    [_httppost httpPostWithurl:urlStr];
}


/*****************QR协议函数实现***************/
- (void)didFinishedReadingQR:(NSString *)string
{
    _GUID = string;
    [self.userdefaults setObject:string forKey:@"guid"];//临时保存(添加绑定后清除)
    [self.userdefaults synchronize];
    [_btn setTitle:@"获取验证码" forState:UIControlStateNormal];
}

@end
