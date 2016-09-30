//
//  LosePasswardVC.m
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LosePasswordVC.h"
#import "IQKeyboardManager.h"
#import "MBProgressHUD.h"

@interface LosePasswordVC ()<HTTPPostDelegate>
{
    BOOL btnlock;
    
    httpPostType _postType;
    NSString * _tempPass;
    NSString * _newPass;
    NSString * _vercodes;
    NSString *_orderno;
    NSInteger _timecount;
    BOOL isvercoding;
}
@property(strong,nonatomic) HTTPPost *httppost;
@property(strong, nonatomic) NSTimer *vercodetimer;
@property(strong, nonatomic) UIButton *verco;
@end

@implementation LosePasswordVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    UIColor * color = [UIColor whiteColor];
    NSDictionary * dict = [NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dict;//标题颜色
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];//按钮颜色
    self.navigationController.navigationBar.barTintColor = [UIColor darkGrayColor];//状态栏颜色
    
    UIBarButtonItem* leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goback.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    _userdefaults = [NSUserDefaults standardUserDefaults];
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    
    
    _phonenumber.delegate = self;
    _orderno = @"";
    _vercodes = @"";
    _timecount = 60;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
    
    UIView *subview = [self.view viewWithTag:10];
    CGPoint center = self.view.center;
    center.y = center.y + 32.0;
    subview.center = center;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_vercodetimer invalidate];
    _vercodetimer = nil;
    _timecount = 60;
}

-(void) goBack
{
    _timecount = 60;
    [_vercodetimer invalidate];
    _vercodetimer = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


- (IBAction)retrievePassword:(UIButton *)sender
{
    [_phonenumber resignFirstResponder];
    if ([_vercodes isEqualToString:@""])
    {
        [self textExamples:@"请先进行语音验证"];
        return;
    }
    [_verco setTitle:@"请求语音验证" forState:0];
    [self performSelector:@selector(retrievepw) withObject:nil afterDelay:0.1];
    
}

-(void)retrievepw
{
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=rempassword&account=%@&mobile=%@&vercode=%@",_phonenumber.text,_phonenumber.text,_vercodes];
    _postType = rempassword;
    [_httppost httpPostWithurl:urlStr];
}

- (IBAction)getVercode:(UIButton *)sender
{
    if (isvercoding) {
        return;
    }
    _verco = sender;
    if (!btnlock)
    {
        [_phonenumber resignFirstResponder];
        //检测账号是否存在
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=checkaccount";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@",_phonenumber.text];
        _postType = checkaccount;
        [_httppost httpPostWithurl :urlStr body:body];
        return;
    }
    [self getcode];
}

-(void)getcode
{
    
    if ([_phonenumber.text isEqualToString:@""])
    {
        [self textExamples:@"请输入手机号"];
        return;
    }
    
    if ([HTTPPost isConnectionAvailable] == NO)
    {
        [self textExamples:@"没有网络！"];
        return;
    }
    if(_timecount == 60)
    {
        _orderno = @"";
        [self getvercode];
        if (_vercodetimer != nil)
        {
            [_vercodetimer invalidate];
            _vercodetimer = nil;
        }
        _vercodetimer = [[NSTimer alloc] init];
        _vercodetimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(changetexts) userInfo:nil repeats:YES];
        isvercoding = YES;
    }

}

-(void)changetexts
{
    if ([_orderno isEqualToString:@""])
    {
        return;
    }
    [_verco setTitle:[NSString stringWithFormat:@"%li s",(long)_timecount--] forState:0];
    if (_timecount%2 == 0)
    {
        NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=presskey&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&oerderno=%@",_orderno];
        _postType = keypress;
        [_httppost httpPostWithurl:urlStr];
    }
    if (_timecount == 1)
    {
        [_verco setTitle:@"获取语音验证" forState:0];
        [_vercodetimer invalidate];
        _vercodetimer = nil;
        _timecount = 60;
        isvercoding = NO;
    }
}

-(void)getvercode
{
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=voice";
    NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@&mobile=%@&module=repassword&vercode=4&veraction=2&vertype=1",_phonenumber.text,_phonenumber.text];
    _postType = voice;
    [_httppost httpPostWithurl :urlStr body:body];
}


-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    switch (_postType) {
            
        case voice:
        {
            
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                _orderno = [dic objectForKey:@"orderno"];
                
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    isvercoding = NO;
                    [self textExample];
                });
            }
        }
            break;
            
        case keypress:
        {
            
            
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                _vercodes = [dic objectForKey:@"keyinfo"];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_verco setTitle:@"语音验证通过" forState:0];
                });
                [_vercodetimer invalidate];
                _vercodetimer = nil;
                _timecount = 60;
                isvercoding = NO;
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"0"] && ![[dic objectForKey:@"keyinfo"] isEqualToString:@""])
            {
                //验证失败
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [_verco setTitle:@"语音验证失败" forState:0];
                               });
                [_vercodetimer invalidate];
                _vercodetimer = nil;
                _timecount = 60;
                isvercoding = NO;
            }

        }
            break;

        case rempassword:
        {
            _dataDic = dic;
            if ([_dataDic isKindOfClass:[NSDictionary class]]==1)
            {
                if ([[_dataDic objectForKey:@"status"] intValue] == 1 && [_dataDic objectForKey:@"password"] != nil)
                {
                    _tempPass = [_dataDic objectForKey:@"password"];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"找回成功" message:[NSString stringWithFormat:@"临时密码是:%@",[_dataDic objectForKey:@"password"]] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"去登陆" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if ([[_userdefaults objectForKey:@"account"] isEqualToString:@""] || [_userdefaults objectForKey:@"account"] == nil)
                        {
                            [_userdefaults setObject:self.phonenumber.text forKey:@"account"];
                        }
                        [_userdefaults setObject:[_dataDic objectForKey:@"password"] forKey:@"password"];
                        [_userdefaults synchronize];
                        [self.navigationController popViewControllerAnimated:YES];
                    }]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:alert animated:true completion:nil];
                    });
                    
                }else
                {
                    //清空数据
                    _dataDic = nil;
                    _vercodes = @"";
                    _orderno = @"";
                    [self textExamples:@"找回失败!"];
                }
            }

        }
            break;
            
        case checkaccount:
        {
            if (isvercoding)
            {
                return;
            }
            if ([[dic objectForKey:@"status"] isEqualToString:@"2"])
            {
                [self textExamples:@"该账号不存在"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _phonenumber.text = nil;
                   
                });
            }else
            {
                if (!btnlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self getcode];
                    });
                    
                }
            }
        }break;
        default:
            break;
    }
}

- (void)textExample
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(@"验证失败，请稍后重试", @"title");
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:3.f];
}

- (void)textExamples:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        
        // Set the annular determinate mode to show task progress.
        hud.mode = MBProgressHUDModeText;
        hud.label.text = NSLocalizedString(text, @"titles");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:2.f];
    });
    
}


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    btnlock = NO;
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if ([textField isEqual:_phonenumber])
    {
        if (![CheckCharacter isValidateMobileNumber:textField.text])
        {
            [self textExamples:@"手机格式有误!"];
            self.phonenumber.text = @"";
            
        }else
        {
            //检测账号是否存在
            NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=checkaccount";
            NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@",_phonenumber.text];
            _postType = checkaccount;
            [_httppost httpPostWithurl :urlStr body:body];
            btnlock = YES;
        }
    }
    if ([CheckCharacter isValidateMobilePassward:textField.text])
    {
        _newPass = textField.text;
    }else
    {
        _newPass = nil;
    }
    return YES;
}

@end
