//
//  RegisterVC.m
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "RegisterVC.h"
#import "CheckCharacter.h"
#import "MBProgressHUD.h"

@interface RegisterVC ()<HTTPPostDelegate>
{
    NSString * _orderno;
    NSString * _vercodes;
    httpPostType _type;
    NSInteger _timecount;
    BOOL iscoding;
}

@property (strong, nonatomic) HTTPPost *httppost;
@property(strong, nonatomic) NSTimer *vercodetimer;
@property(strong, nonatomic) UIButton *verco;
@end

@implementation RegisterVC


- (void)viewDidLoad
{
    [super viewDidLoad];
    _setNewAccount.delegate = self;
    _setPassword.delegate = self;
    _confirmPassword.delegate = self;
    _userdefaults = [NSUserDefaults standardUserDefaults];
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    _vercodes = @"";
    _orderno = @"";
    _timecount = 60;
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
    self.navigationController.navigationBarHidden = NO;
    
    UIColor * color = [UIColor whiteColor];
    NSDictionary * dict = [NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dict;//标题颜色
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];//按钮颜色
    self.navigationController.navigationBar.barTintColor = [UIColor darkGrayColor];//状态栏颜色
    UIBarButtonItem* leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goback.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    UIView *subview = [self.view viewWithTag:10];
    CGPoint center = self.view.center;
    center.y = center.y + 32.0;
    subview.center = center;
}

-(void) goBack
{
    _timecount = 60;
    [_vercodetimer invalidate];
    _vercodetimer = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
}

//*********************注册验证********************
- (IBAction)userRigister:(UIButton *)sender
{
    if ([_vercodes isEqualToString:@""])
    {
        [self textExampleses:@"请先通过语音验证"];
        return;
    }
    [_verco setTitle:@"请求语音验证" forState:0];
    [self performSelector:@selector(userregist) withObject:nil afterDelay:0.1];
}

-(void)userregist
{
    
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=registry&account=%@&password=%@&mobile=%@&vercode=%@&uuid=%@",_setNewAccount.text,_setPassword.text,[_setNewAccount.text.mutableCopy substringWithRange:NSMakeRange(0, 11)],_vercodes,[_userdefaults objectForKey:@"uuid"]];
    
    [_httppost httpPostWithurl:urlStr];
    _type = registry;
    
    
}

//******************语音验证码获取**********************
- (IBAction)voiceCode:(UIButton *)sender
{
    if (iscoding)
    {
        return;
    }
    if (_setPassword.text.length == 0 || _setNewAccount.text.length == 0 || _confirmPassword.text.length == 0)
    {
        [_confirmPassword resignFirstResponder];
        [self textExampleses:@"请完善信息后再试"];
        return;
    }
    
    if ([_setPassword.text isEqualToString:_confirmPassword.text] == 0)
    {
        [_confirmPassword resignFirstResponder];
        [self textExampleses:@"密码和确认密码不一致"];
        _confirmPassword.text = @"";
        return ;
    }

    [_confirmPassword resignFirstResponder];
    if ([HTTPPost isConnectionAvailable] == NO)
    {
        [self textExampleses:@"没有网络！"];
        return;
    }
    if(_timecount == 60)
    {
        _verco = sender;
        _vercodes = @"";
        _orderno = @"";
        
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=voice";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@&mobile=%@&module=register&vercode=1&veraction=1&vertype=1",_setNewAccount.text,[_setNewAccount.text.mutableCopy substringWithRange:NSMakeRange(0, 11)]];
        _type = voice;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            [_httppost httpPostWithurl :urlStr body:body];
        });
        if (_vercodetimer != nil)
        {
            [_vercodetimer invalidate];
            _vercodetimer = nil;
        }
        iscoding = YES;
        _vercodetimer = [[NSTimer alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            _vercodetimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(changetext1) userInfo:nil repeats:YES];
        });
        
    }
}

-(void)changetext1
{
    if ([_orderno isEqualToString:@""])
    {
        return;
    }
    [_verco setTitle:[NSString stringWithFormat:@"%li s",(long)_timecount--] forState:0];
    if (_timecount%2 == 0)
    {
        NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=presskey&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&oerderno=%@",_orderno];
        _type = keypress;
        [_httppost httpPostWithurl:urlStr];
    }
    if (_timecount == 1)
    {
        [_verco setTitle:@"获取语音验证" forState:0];
        [_vercodetimer invalidate];
        _vercodetimer = nil;
        _timecount = 60;
        iscoding = NO;
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
                
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    iscoding = NO;
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_verco setTitle:@"语音验证通过" forState:0];
                });
                [_vercodetimer invalidate];
                _vercodetimer = nil;
                _timecount = 60;
                iscoding = NO;
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"-1"])
            {
                //验证失败
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [_verco setTitle:@"语音验证失败" forState:0];
                               });
                [_vercodetimer invalidate];
                _vercodetimer = nil;
                _timecount = 60;
                iscoding = NO;
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
                iscoding = NO;
            }

        }break;
            
            
        case checkaccount:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                [self textExampleses:@"账号已被注册,请添加一个后缀"];
            }
        }break;
            
            
        case registry:
        {
            _dataDic = dic;
            if ([_dataDic isKindOfClass:[NSDictionary class]] == 1)
            {
                if ([[_dataDic objectForKey:@"status"] intValue] == 1)
                {
                    [self textExampleses:@"注册成功"];
                    [_userdefaults setObject:_setNewAccount.text forKey:@"account"];
                    [_userdefaults setObject:_setPassword.text forKey:@"password"];
                    [_userdefaults synchronize];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.navigationController popViewControllerAnimated:YES];
                    });
                }else
                {
                    //清空数据
                    _dataDic = nil;
                    _vercodes = @"";
                    _orderno = @"";
                    
                    _timecount = 60;
                    [self textExampleses:@"注册失败"];
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
    hud.label.text = NSLocalizedString(@"验证失败，请稍后重试", @"HUD message title");
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:3.f];
}

- (void)textExampleses:(NSString*)text
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == 9 && textField.text.length == 10 && ![string isEqualToString:@""])//此时的文本是发生改变之前的
    {
        
        NSMutableString *multext = [textField.text mutableCopy];
        [multext appendString:string];
        textField.text = multext;
        [textField resignFirstResponder];
        
        if (![CheckCharacter isValidateMobileNumber:textField.text])
        {
            [self textExampleses:@"手机格式有误!"];
            self.setNewAccount.text = @"";
            return YES;
        }
       
        //检测账号是否存在
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=checkaccount";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@",_setNewAccount.text];
        _type = checkaccount;
        [_httppost httpPostWithurl :urlStr body:body];
    }
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    if (textField.tag == 9)
    {
        if (textField.text.length < 11)
        {
            return NO;
        }
        [textField resignFirstResponder];
        [_setPassword becomeFirstResponder];
        return YES;
    }
    
    if(textField.tag == 10)
    {
        if(![CheckCharacter isValidateMobilePassward:textField.text])
        {
            [self textExampleses:@"密码格式不合要求"];
            self.setPassword.text = @"";
            return NO;
        }
        [textField resignFirstResponder];
        [_confirmPassword becomeFirstResponder];
        return YES;
    }
    if (textField.tag == 11)
    {
        if ([_setPassword.text isEqualToString:_confirmPassword.text] == 0)
        {
            [self textExampleses:@"密码和确认密码不一致"];
            _confirmPassword.text = @"";
            return NO;
        }
        [textField resignFirstResponder];
        return YES;
    }
    [textField resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.setNewAccount.text isEqualToString:@""])
    {
        [self.setNewAccount resignFirstResponder];
        
    }
    if ([self.setPassword.text isEqualToString:@""])
    {
        [self.setPassword resignFirstResponder];
        
    }
    if ([self.confirmPassword.text isEqualToString:@""])
    {
        [self.confirmPassword resignFirstResponder];
        
    }
}

@end
