#import "LoginVC.h"
#import "CheckCharacter.h"
#import "RegisterVC.h"
#import "LosePasswordVC.h"
#import "MBProgressHUD.h"

@interface LoginVC ()<UITextFieldDelegate,HTTPPostDelegate,MBProgressHUDDelegate>
{
    httpPostType _posttype;
    NSString *_orderno;
    NSString *_vercodes;
    BOOL isreuuid;
    BOOL isrepassword;
    NSString * newpw;
    BOOL logincheck;
}

@property (strong ,nonatomic) NSHTTPURLResponse *httpresponse;
@property(strong, nonatomic) HTTPPost *httppost;
@property(strong, nonatomic) NSTimer *vercodetimer;
@property(strong, nonatomic) MBProgressHUD *hud;
@property(strong, nonatomic) LosePasswordVC *losspass;
@property(strong, nonatomic) RegisterVC *rigistervc;
@end

@implementation LoginVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    _userdefaults = [NSUserDefaults standardUserDefaults];
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    
    _userAccount.delegate = self;
    _userPassword.delegate = self;
    isreuuid = NO;
    isrepassword = NO;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    
    
    if ([_userdefaults objectForKey:@"uuid"] == nil)
    {
        CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
        CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
        NSMutableString *uuid = (NSMutableString*)[NSString stringWithString:(__bridge NSString *)uuid_string_ref];
        CFRelease(uuid_ref);
        CFRelease(uuid_string_ref);
        NSArray *arr = [uuid componentsSeparatedByString:@"-"];
        NSMutableString *uuid0 = [[NSMutableString alloc] initWithString:arr[0]];
        [uuid0 appendFormat:@"%@%@%@%@",arr[1],arr[2],arr[3],arr[4]];
        [_userdefaults setObject:uuid0 forKey:@"uuid"];
        [_userdefaults synchronize];
        uuid = nil;
        arr = nil;
        uuid0 = nil;
        
    }
    
    _userAccount.text = [_userdefaults objectForKey:@"account"];
    if (![_userAccount.text isEqualToString:@""])
    {
        _userPassword.text = [_userdefaults objectForKey:@"password"];
    }
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_vercodetimer invalidate];
    _vercodetimer = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    _rigistervc = (RegisterVC*)[storyboard instantiateViewControllerWithIdentifier:@"registerpage"];
    _losspass = (LosePasswordVC*)[storyboard instantiateViewControllerWithIdentifier:@"repassword"];
}

- (IBAction)userLogin:(UIButton *)sender
{
    
    _dataDic = nil;
    
    [_userPassword resignFirstResponder];
    
    if ([HTTPPost isConnectionAvailable] == NO)
    {
        [self textExamplese:@"没有网络！"];
        return;
    }
    
    if ([_userPassword.text isEqualToString:@""]) {
        return;
    }
    
    //验证性登录
    logincheck = YES;
    [self login];
    
}

-(void)login
{
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=login&account=%@&password=%@&uuid=%@",_userAccount.text,_userPassword.text,[_userdefaults objectForKey:@"uuid"]];
    _posttype = login;
    [self.httppost httpPostWithurl:urlStr];
    isreuuid = NO;
}

-(void)loginForNormal
{
    if (![CheckCharacter isValidateMobilePassward:_userPassword.text])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您的密码过于简单" message:@"是否修改密码" preferredStyle:1];
        UIAlertAction *act1 = [UIAlertAction actionWithTitle:@"好的" style:0 handler:^(UIAlertAction * _Nonnull action) {
            isrepassword = YES;
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               _vercodetimer = [[NSTimer alloc] init];
                               _vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(presskeysuccess) userInfo:nil repeats:YES];
                               _orderno = @"";
                               [self voice];
                               _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                               _hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
                               _hud.delegate = self;
                               [_hud hideAnimated:YES afterDelay:60.0];
                           });
        }];
        UIAlertAction *act2 = [UIAlertAction actionWithTitle:@"不用" style:0 handler:^(UIAlertAction * _Nonnull action) {
            isrepassword = NO;
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               _vercodetimer = [[NSTimer alloc] init];
                               _vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(presskeysuccess) userInfo:nil repeats:YES];
                               _orderno = @"";
                               [self voice];
                               _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                               _hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
                               _hud.delegate = self;
                               [_hud hideAnimated:YES afterDelay:60.0];
                           });
        }];
        [alert addAction:act1];
        [alert addAction:act2];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });
        
        return;
    }
    //合法密码
    isrepassword = NO;
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       _vercodetimer = [[NSTimer alloc] init];
                       _vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(presskeysuccess) userInfo:nil repeats:YES];
                       _orderno = @"";
                       [self voice];
                       _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                       _hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
                       _hud.delegate = self;
                       [_hud hideAnimated:YES afterDelay:60.0];
                   });
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    
    switch (_posttype)
    {
        case login:
        {
            _dataDic = dic;
            
            if ([[_dataDic objectForKey:@"status"] intValue] == 1)
            {
                if (logincheck)
                {
                    if ([[_dataDic objectForKey:@"status"] isEqualToString:@"1"])
                    {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [self loginForNormal];
                        });
                    }
                    
                    logincheck = NO;
                    return;
                }

                if (isreuuid == YES)
                {
                    if ([[_dataDic objectForKey:@"status"] integerValue] == 1) {
                        
                        //重置uuid
                        NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=reuuid&account=%@&apptoken=%@&uuid=%@&vercode=%@",
                                           [_dataDic objectForKey:@"account"],
                                           [_dataDic objectForKey:@"apptoken"],
                                           [self.userdefaults objectForKey:@"uuid"],_vercodes];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                                       {
                                           _posttype = reuuid;
                                           [_httppost httpPostWithurl:urlStr];
                                       });
                        
                    }
                    return;
                }
                
                if (isrepassword == YES)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _hud.label.text = NSLocalizedString(@"修改密码中...", @"HUD loading title");
                    });
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改密码" message:@"请输入新的密码，并且自动登录" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                        textField.placeholder = @"请输入6-16位的数字加字母的密码";
                        textField.delegate = self;
                        textField.tag = 100;
                    }];
                    [alert addAction:[UIAlertAction actionWithTitle:@"修改并登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                    {
                        UITextField *textf = [alert.view viewWithTag:100];
                        if (![CheckCharacter isValidateMobilePassward:textf.text])
                        {
                            textf.text = @"";
                            textf.placeholder = @"您的密码依然过于简单";
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self presentViewController:alert animated:true completion:nil];
                            });
                            return;
                        }
                        newpw = textf.text;
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                        {

                            NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=repassword&account=%@&apptoken=%@&password=%@&passwordnew=%@&vercode=%@",_userAccount.text,[_dataDic objectForKey:@"apptoken"],_userPassword.text,textf.text,_vercodes];
                            _posttype = repassword;
                            [_httppost httpPostWithurl:urlStr];
                        });
                    }]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:alert animated:true completion:nil];
                    });
                    
                    return;
                }
                
                
                //判断是否更换用户
                if ([[_userdefaults objectForKey:@"account"] isEqualToString:_userAccount.text] == 0)
                {
                    
                    [self clearAllData];
                }
                //数据持久化
                if ([_userdefaults objectForKey:[_userdefaults objectForKey:@"uuid"]] == nil)
                {
                    [_userdefaults setObject:_userAccount.text forKey:[_userdefaults objectForKey:@"uuid"]];
                }
                
                [_userdefaults setBool:NO forKey:@"quitapp"];
                [_userdefaults setInteger:[[_dataDic objectForKey:@"signminutes"] integerValue] forKey:@"signminutes"];
                [_userdefaults setFloat:[[_dataDic objectForKey:@"money"] floatValue] forKey:@"money"];
                
               
                [_userdefaults setObject:_userAccount.text forKey:@"account"];
                [_userdefaults setObject:_userPassword.text forKey:@"password"];
                [_userdefaults setObject:[_dataDic objectForKey:@"apptoken"] forKey:@"appToken"];
                [self.userdefaults synchronize];
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_hud hideAnimated:YES];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                });
            }else if([[_dataDic objectForKey:@"status"] intValue] == -3)
            {
                //更换终端后验证
                logincheck = NO;
                isreuuid = YES;
                __weak LoginVC *wkSelf = self;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _vercodetimer = [[NSTimer alloc] init];
                    _vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(presskeysuccess) userInfo:nil repeats:YES];
                    _orderno = @"";
                    [wkSelf voice];
                    _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                    _hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
                    _hud.delegate = self;
                    [_hud hideAnimated:YES afterDelay:60.0];
                });
                
            }else if([[_dataDic objectForKey:@"status"] intValue] == -2)
            {
                //清空数据
                logincheck = NO;
                _dataDic = nil;
                [self textExamplese:@"账号或者密码错误，请重试！"];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_hud hideAnimated:YES];
                });
            }else
            {
                logincheck = NO;
                _dataDic = nil;
                [self textExamplese:@"登录失败"];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_hud hideAnimated:YES];
                });
            }
        }
            break;
        
            
        case voice:
        {
            
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                {
                    _orderno = [dic objectForKey:@"orderno"];
                });
            }else 
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_hud hideAnimated:YES];
                    [self textExample];
                });
                
            }
            
        }break;
            
            
        case keypress:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                _vercodes = [dic objectForKey:@"keyinfo"];
                [_vercodetimer invalidate];
                _vercodetimer = nil;
                __weak LoginVC *wkSelf = self;
                if (isreuuid == YES)
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                                   {
                                       [wkSelf reuuidLogin];
                                   });
                    
                }else
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                                   {
                                       [wkSelf login];
                                   });
                }
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    _hud.label.text = NSLocalizedString(@"请稍候...", @"HUD loading title");
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
            
        case reuuid:
        {
            isreuuid = NO;
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                
                //判断是否更换用户
                if ([[_userdefaults objectForKey:@"account"] isEqualToString:_userAccount.text] == 0)
                {
                    [self clearAllData];
                }
                //数据持久化
                if ([_userdefaults objectForKey:[_userdefaults objectForKey:@"uuid"]] == nil)
                {
                    [_userdefaults setObject:_userAccount.text forKey:[_userdefaults objectForKey:@"uuid"]];
                }
                
                [_userdefaults setBool:NO forKey:@"quitapp"];
                [_userdefaults setInteger:[[_dataDic objectForKey:@"signminutes"] integerValue] forKey:@"signminutes"];
                [_userdefaults setFloat:[[_dataDic objectForKey:@"money"] floatValue] forKey:@"money"];
                
                
                [_userdefaults setObject:_userAccount.text forKey:@"account"];
                [_userdefaults setObject:_userPassword.text forKey:@"password"];
                [_userdefaults setObject:[_dataDic objectForKey:@"apptoken"] forKey:@"appToken"];
                [self.userdefaults synchronize];

                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_hud hideAnimated:YES];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                });
            }else
            {
                [_hud hideAnimated:YES];
            }

        }break;
            
        case repassword:
        {
            
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                //判断是否更换用户
                if ([[_userdefaults objectForKey:@"account"] isEqualToString:_userAccount.text] == 0)
                {
                    [self clearAllData];
                }
                //数据持久化
                if ([_userdefaults objectForKey:[_userdefaults objectForKey:@"uuid"]] == nil)
                {
                    [_userdefaults setObject:_userAccount.text forKey:[_userdefaults objectForKey:@"uuid"]];
                }
                
                [_userdefaults setBool:NO forKey:@"quitapp"];
                [_userdefaults setInteger:[[_dataDic objectForKey:@"signminutes"] integerValue] forKey:@"signminutes"];
                [_userdefaults setFloat:[[_dataDic objectForKey:@"money"] floatValue] forKey:@"money"];
               
               
                [_userdefaults setObject:_userAccount.text forKey:@"account"];
                [_userdefaults setObject:newpw forKey:@"password"];
                [_userdefaults setObject:[dic objectForKey:@"apptoken"] forKey:@"appToken"];
                [self.userdefaults synchronize];
                
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [_hud hideAnimated:YES];
                                   [self.navigationController popToRootViewControllerAnimated:YES];
                               });

            }else
            {
                [self textExamplese:@"修改密码失败"];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_hud hideAnimated:YES];
                                  
                });
                
            }
        }break;
            
        default:
            break;
    }
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    if (_vercodetimer == nil)
    {
        return;
    }
    [_vercodetimer invalidate];
    _vercodetimer = nil;
    [self textExample];
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

- (void)textExamplese:(NSString*)text
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

-(void)presskeysuccess
{
    if ([_orderno isEqualToString:@""])
    {
        return;
    }
    NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=presskey&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&oerderno=%@",_orderno];
    _posttype = keypress;
    [_httppost httpPostWithurl:urlStr];
}

-(void)voice
{
    _dataDic = nil;
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=voice";
    NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@&mobile=%@&module=login&vercode=2&veraction=2&vertype=1",_userAccount.text,_userAccount.text];
    _posttype = voice;
    [_httppost httpPostWithurl :urlStr body:body];
}


-(void)reuuidLogin
{
    //重新登录
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=login&account=%@&password=%@&uuid=%@&vercode=%@",_userAccount.text,_userPassword.text,[_userdefaults objectForKey:@"uuid"],_vercodes];
    [_httppost httpPostWithurl:urlStr];
    _posttype = login;
}

- (IBAction)repassword:(UIButton *)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(repassword) userInfo:nil repeats:NO];
}

-(void)repassword{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.navigationController pushViewController:_losspass animated:YES];
    });
    
}
- (IBAction)userregister:(UIButton *)sender {
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(userregister) userInfo:nil repeats:NO];
}

-(void)userregister
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.navigationController pushViewController:_rigistervc animated:YES];
    });
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.tag == 10)
    {
        
        if (![CheckCharacter isValidateMobileNumber:textField.text])
        {
            [self textExamplese:@"手机格式有误"];
            self.userAccount.text = @"";
            return NO;
        }
        [textField resignFirstResponder];
        [_userPassword becomeFirstResponder];
        return YES;
    }
    [textField resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.userAccount.text isEqualToString:@""])
    {
        [self.userAccount resignFirstResponder];
        
    }
    if ([self.userPassword.text isEqualToString:@""])
    {
        [self.userPassword resignFirstResponder];
        return;
    }
}

-(void)clearAllData
{
    [_userdefaults removeObjectForKey:@"canautounlock"];
    [_userdefaults removeObjectForKey:@"wirelesslog"];
    [_userdefaults synchronize];
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSArray *arr = [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext executeFetchRequest:request error:nil];
    for (NSManagedObject *obj in arr)
    {
        [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext deleteObject:obj];
    }
    [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext save:nil];
}

@end
