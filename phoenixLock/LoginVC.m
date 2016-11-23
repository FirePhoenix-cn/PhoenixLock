#import "LoginVC.h"
#import "CheckCharacter.h"
#import "RegisterVC.h"
#import "LosePasswordVC.h"
#import "MBProgressHUD.h"

@interface LoginVC ()<UITextFieldDelegate,HTTPPostDelegate,MBProgressHUDDelegate>
{
    NSString *orderno;
    NSString *vercodes;
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
    self.userdefaults = [NSUserDefaults standardUserDefaults];
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    self.userAccount.delegate = self;
    self.userPassword.delegate = self;
    isreuuid = NO;
    isrepassword = NO;
    [(UILabel*)[self.view viewWithTag:30] setText:[self.userdefaults objectForKey:@"appversion"]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    if ([self.userdefaults objectForKey:@"uuid"] == nil)
    {
        CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
        CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
        NSMutableString *uuid = (NSMutableString*)[NSString stringWithString:(__bridge NSString *)uuid_string_ref];
        CFRelease(uuid_ref);
        CFRelease(uuid_string_ref);
        NSArray *arr = [uuid componentsSeparatedByString:@"-"];
        NSMutableString *uuid0 = [[NSMutableString alloc] initWithString:arr[0]];
        [uuid0 appendFormat:@"%@%@%@%@",arr[1],arr[2],arr[3],arr[4]];
        [self.userdefaults setObject:uuid0 forKey:@"uuid"];
        [self.userdefaults synchronize];
        uuid = nil;
        arr = nil;
        uuid0 = nil;
        
    }
    self.userAccount.text = [self.userdefaults objectForKey:@"account"];
    if (![self.userAccount.text isEqualToString:@""])
    {
        self.userPassword.text = [self.userdefaults objectForKey:@"password"];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.userdefaults setObject:self.userAccount.text forKey:@"account"];
    [self.vercodetimer invalidate];
    self.vercodetimer = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    self.rigistervc = (RegisterVC*)[storyboard instantiateViewControllerWithIdentifier:@"registerpage"];
    self.losspass = (LosePasswordVC*)[storyboard instantiateViewControllerWithIdentifier:@"repassword"];
}

- (IBAction)userLogin:(UIButton *)sender
{
    self.dataDic = nil;
    [self.userPassword resignFirstResponder];
    if ([HTTPPost isConnectionAvailable] == NO)
    {
        [self textExamplese:@"没有网络！"];
        return;
    }
    if (![CheckCharacter isValidateMobileNumber:self.userAccount.text])
    {
        [self textExamplese:@"手机格式有误"];
        self.userAccount.text = @"";
        [self.userAccount resignFirstResponder];
        return;
    }
    if ([self.userPassword.text isEqualToString:@""]) {
        return;
    }
    //验证性登录
    logincheck = YES;
    [self login];
}

-(void)login
{
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=login&account=%@&password=%@&uuid=%@",self.userAccount.text,self.userPassword.text,[self.userdefaults objectForKey:@"uuid"]];
    [self.httppost httpPostWithurl:urlStr type:login];
    isreuuid = NO;
}

-(void)loginForNormal
{
    if (![CheckCharacter isValidateMobilePassward:self.userPassword.text])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您的密码过于简单" message:@"是否修改密码" preferredStyle:1];
        UIAlertAction *act1 = [UIAlertAction actionWithTitle:@"好的" style:0 handler:^(UIAlertAction * _Nonnull action) {
            isrepassword = YES;
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               self.vercodetimer = [[NSTimer alloc] init];
                               self.vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(presskeysuccess) userInfo:nil repeats:YES];
                               orderno = @"";
                               [self voice];
                               self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                               self.hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
                               self.hud.delegate = self;
                               [self.hud hideAnimated:YES afterDelay:60.0];
                           });
        }];
        UIAlertAction *act2 = [UIAlertAction actionWithTitle:@"不用" style:0 handler:^(UIAlertAction * _Nonnull action) {
            isrepassword = NO;
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               self.vercodetimer = [[NSTimer alloc] init];
                               self.vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(presskeysuccess) userInfo:nil repeats:YES];
                               orderno = @"";
                               [self voice];
                               self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                               self.hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
                               self.hud.delegate = self;
                               [self.hud hideAnimated:YES afterDelay:60.0];
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
                       self.vercodetimer = [[NSTimer alloc] init];
                       self.vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(presskeysuccess) userInfo:nil repeats:YES];
                       orderno = @"";
                       [self voice];
                       self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                       self.hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
                       self.hud.delegate = self;
                       [self.hud hideAnimated:YES afterDelay:60.0];
                   });
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case login:
        {
            self.dataDic = dic;
            
            if ([[self.dataDic objectForKey:@"status"] intValue] == 1)
            {
                if (logincheck)
                {
                    if ([[self.dataDic objectForKey:@"status"] isEqualToString:@"1"])
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
                    if ([[self.dataDic objectForKey:@"status"] integerValue] == 1) {
                        
                        //重置uuid
                        NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=reuuid&account=%@&apptoken=%@&uuid=%@&vercode=%@",
                                           [self.dataDic objectForKey:@"account"],
                                           [self.dataDic objectForKey:@"apptoken"],
                                           [self.userdefaults objectForKey:@"uuid"],vercodes];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                                       {
                                
                                           [self.httppost httpPostWithurl:urlStr type:reuuid];
                                       });
                        
                    }
                    return;
                }
                
                if (isrepassword == YES)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.hud.label.text = NSLocalizedString(@"修改密码中...", @"HUD loading title");
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
                            textf.placeholder = @"密码不符合数字+字母的规则";
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self presentViewController:alert animated:true completion:nil];
                            });
                            return;
                        }
                        newpw = textf.text;
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                        {

                            NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=repassword&account=%@&apptoken=%@&password=%@&passwordnew=%@&vercode=%@",self.userAccount.text,[self.dataDic objectForKey:@"apptoken"],self.userPassword.text,textf.text,vercodes];
                            
                            [self.httppost httpPostWithurl:urlStr type:repassword];
                        });
                    }]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:alert animated:true completion:nil];
                    });
                    
                    return;
                }
                
                
                //判断是否更换用户
                if ([[self.userdefaults objectForKey:@"account"] isEqualToString:self.userAccount.text] == 0)
                {
                    
                    [self clearAllData];
                }
                //数据持久化
                if ([self.userdefaults objectForKey:[self.userdefaults objectForKey:@"uuid"]] == nil)
                {
                    [self.userdefaults setObject:self.userAccount.text forKey:[self.userdefaults objectForKey:@"uuid"]];
                }
                [self.userdefaults setBool:NO forKey:@"quitapp"];
                [self.userdefaults setInteger:[[self.dataDic objectForKey:@"signminutes"] integerValue] forKey:@"signminutes"];
                [self.userdefaults setFloat:[[self.dataDic objectForKey:@"money"] floatValue] forKey:@"money"];
                [self.userdefaults setObject:self.userAccount.text forKey:@"account"];
                [self.userdefaults setObject:self.userPassword.text forKey:@"password"];
                [self.userdefaults setObject:[self.dataDic objectForKey:@"apptoken"] forKey:@"appToken"];
                [self.userdefaults synchronize];
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self.hud hideAnimated:YES];
                    SENDNOTIFY(@"startSearch")
                    [self.navigationController popToRootViewControllerAnimated:YES];
                });
            }else if([[self.dataDic objectForKey:@"status"] intValue] == -3)
            {
                //更换终端后验证
                logincheck = NO;
                isreuuid = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.vercodetimer = [[NSTimer alloc] init];
                    self.vercodetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(presskeysuccess) userInfo:nil repeats:YES];
                    orderno = @"";
                    [self voice];
                    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                    self.hud.label.text = NSLocalizedString(@"等待语音验证...", @"HUD loading title");
                    self.hud.delegate = self;
                    [self.hud hideAnimated:YES afterDelay:60.0];
                });
                
            }else if([[self.dataDic objectForKey:@"status"] intValue] == -2)
            {
                //清空数据
                logincheck = NO;
                self.dataDic = nil;
                [self textExamplese:@"账号或者密码错误，请重试！"];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self.hud hideAnimated:YES];
                });
            }else
            {
                logincheck = NO;
                self.dataDic = nil;
                [self textExamplese:@"登录失败"];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self.hud hideAnimated:YES];
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
                    orderno = [dic objectForKey:@"orderno"];
                });
            }else 
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.hud hideAnimated:YES];
                    [self textExample];
                });
                
            }
            
        }break;
            
        case keypress:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                vercodes = [dic objectForKey:@"keyinfo"];
                [self.vercodetimer invalidate];
                self.vercodetimer = nil;
                if (isreuuid == YES)
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                                   {
                                       [self reuuidLogin];
                                   });
                    
                }else
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                                   {
                                       [self login];
                                   });
                }
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    self.hud.label.text = NSLocalizedString(@"请稍候...", @"HUD loading title");
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
            
        case reuuid:
        {
            isreuuid = NO;
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                
                //判断是否更换用户
                if ([[self.userdefaults objectForKey:@"account"] isEqualToString:self.userAccount.text] == 0)
                {
                    [self clearAllData];
                }
                //数据持久化
                if ([self.userdefaults objectForKey:[self.userdefaults objectForKey:@"uuid"]] == nil)
                {
                    [self.userdefaults setObject:self.userAccount.text forKey:[self.userdefaults objectForKey:@"uuid"]];
                }
                
                [self.userdefaults setBool:NO forKey:@"quitapp"];
                [self.userdefaults setInteger:[[self.dataDic objectForKey:@"signminutes"] integerValue] forKey:@"signminutes"];
                [self.userdefaults setFloat:[[self.dataDic objectForKey:@"money"] floatValue] forKey:@"money"];
                
                
                [self.userdefaults setObject:self.userAccount.text forKey:@"account"];
                [self.userdefaults setObject:self.userPassword.text forKey:@"password"];
                [self.userdefaults setObject:[self.dataDic objectForKey:@"apptoken"] forKey:@"appToken"];
                [self.userdefaults synchronize];

                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self.hud hideAnimated:YES];
                    SENDNOTIFY(@"startSearch")
                    [self.navigationController popToRootViewControllerAnimated:YES];
                });
            }else
            {
                [self.hud hideAnimated:YES];
            }
        }break;
            
        case repassword:
        {
            
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                //判断是否更换用户
                if ([[self.userdefaults objectForKey:@"account"] isEqualToString:self.userAccount.text] == 0)
                {
                    [self clearAllData];
                }
                //数据持久化
                if ([self.userdefaults objectForKey:[self.userdefaults objectForKey:@"uuid"]] == nil)
                {
                    [self.userdefaults setObject:self.userAccount.text forKey:[self.userdefaults objectForKey:@"uuid"]];
                }
                
                [self.userdefaults setBool:NO forKey:@"quitapp"];
                [self.userdefaults setInteger:[[self.dataDic objectForKey:@"signminutes"] integerValue] forKey:@"signminutes"];
                [self.userdefaults setFloat:[[self.dataDic objectForKey:@"money"] floatValue] forKey:@"money"];
               
               
                [self.userdefaults setObject:self.userAccount.text forKey:@"account"];
                [self.userdefaults setObject:newpw forKey:@"password"];
                [self.userdefaults setObject:[dic objectForKey:@"apptoken"] forKey:@"appToken"];
                [self.userdefaults synchronize];
                
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [self.hud hideAnimated:YES];
                                   SENDNOTIFY(@"startSearch")
                                   [self.navigationController popToRootViewControllerAnimated:YES];
                               });

            }else
            {
                [self textExamplese:@"修改密码失败"];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self.hud hideAnimated:YES];
                                  
                });
                
            }
        }break;
            
        default:
            break;
    }
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    if (self.vercodetimer == nil)
    {
        return;
    }
    [self.vercodetimer invalidate];
    self.vercodetimer = nil;
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
    if ([orderno isEqualToString:@""])
    {
        return;
    }
    NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=presskey&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&oerderno=%@",orderno];
    [self.httppost httpPostWithurl:urlStr type:keypress];
}

-(void)voice
{
    self.dataDic = nil;
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=voice";
    NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@&mobile=%@&module=login&vercode=2&veraction=2&vertype=1",self.userAccount.text,self.userAccount.text];
    
    [self.httppost httpPostWithurl :urlStr body:body type:voice];
}


-(void)reuuidLogin
{
    //重新登录
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=login&account=%@&password=%@&uuid=%@&vercode=%@",self.userAccount.text,self.userPassword.text,[self.userdefaults objectForKey:@"uuid"],vercodes];
    [self.httppost httpPostWithurl:urlStr type:login];
    
}

- (IBAction)repassword:(UIButton *)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(repassword) userInfo:nil repeats:NO];
}

-(void)repassword
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.navigationController pushViewController:self.losspass animated:YES];
    });
    
}
- (IBAction)userregister:(UIButton *)sender {
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(userregister) userInfo:nil repeats:NO];
}

-(void)userregister
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.navigationController pushViewController:self.rigistervc animated:YES];
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
            [textField resignFirstResponder];
            return YES;
        }
        [textField resignFirstResponder];
        [self.userPassword becomeFirstResponder];
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
    NSManagedObjectContext *context = ((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
    [self.userdefaults removeObjectForKey:@"wirelesslog"];
    [self.userdefaults synchronize];
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSArray *arr = [context executeFetchRequest:request error:nil];
    for (NSManagedObject *obj in arr)
    {
        [context performBlock:^{
            [context deleteObject:obj];
        }];
    }
    [context performBlock:^{
        [context save:nil];
    }];
}

@end
