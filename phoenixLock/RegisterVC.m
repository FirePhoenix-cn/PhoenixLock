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
    NSString * orderno;
    NSString * vercodes;
    NSInteger timecount;
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
    self.setNewAccount.delegate = self;
    self.setPassword.delegate = self;
    self.confirmPassword.delegate = self;
    self.userdefaults = [NSUserDefaults standardUserDefaults];
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    vercodes = @"";
    orderno = @"";
    timecount = 60;
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
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
    timecount = 60;
    [self.vercodetimer invalidate];
    self.vercodetimer = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
}

//*********************注册验证********************
- (IBAction)userRigister:(UIButton *)sender
{
    if ([vercodes isEqualToString:@""])
    {
        [self textExampleses:@"请先通过语音验证"];
        return;
    }
    [self.verco setTitle:@"请求语音验证" forState:0];
    [self performSelector:@selector(userregist) withObject:nil afterDelay:0.1];
}

-(void)userregist
{
    
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=registry&account=%@&password=%@&mobile=%@&vercode=%@&uuid=%@",self.setNewAccount.text,self.setPassword.text,[self.setNewAccount.text.mutableCopy substringWithRange:NSMakeRange(0, 11)],vercodes,[self.userdefaults objectForKey:@"uuid"]];
    
    [self.httppost httpPostWithurl:urlStr type:registry];

}

//******************语音验证码获取**********************
- (IBAction)voiceCode:(UIButton *)sender
{
    if (iscoding)
    {
        return;
    }
    if (self.setPassword.text.length == 0 || self.setNewAccount.text.length == 0 || self.confirmPassword.text.length == 0)
    {
        [self.confirmPassword resignFirstResponder];
        [self textExampleses:@"请完善信息后再试"];
        return;
    }
    
    if ([self.setPassword.text isEqualToString:self.confirmPassword.text] == 0)
    {
        [self.confirmPassword resignFirstResponder];
        [self textExampleses:@"密码和确认密码不一致"];
        self.confirmPassword.text = @"";
        return ;
    }

    [self.confirmPassword resignFirstResponder];
    if ([HTTPPost isConnectionAvailable] == NO)
    {
        [self textExampleses:@"没有网络！"];
        return;
    }
    if(timecount == 60)
    {
        self.verco = sender;
        vercodes = @"";
        orderno = @"";
        
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=voice";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@&mobile=%@&module=register&vercode=1&veraction=1&vertype=1",self.setNewAccount.text,[self.setNewAccount.text.mutableCopy substringWithRange:NSMakeRange(0, 11)]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            [self.httppost httpPostWithurl :urlStr body:body type:voice];
        });
        if (self.vercodetimer != nil)
        {
            [self.vercodetimer invalidate];
            self.vercodetimer = nil;
        }
        iscoding = YES;
        self.vercodetimer = [[NSTimer alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.vercodetimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(changetext1) userInfo:nil repeats:YES];
        });
        
    }
}

-(void)changetext1
{
    if ([orderno isEqualToString:@""])
    {
        return;
    }
    [self.verco setTitle:[NSString stringWithFormat:@"%li s",(long)timecount--] forState:0];
    if (timecount%2 == 0)
    {
        NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=presskey&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&oerderno=%@",orderno];
       
        [self.httppost httpPostWithurl:urlStr type:keypress];
    }
    if (timecount == 1)
    {
        [self.verco setTitle:@"获取语音验证" forState:0];
        [self.vercodetimer invalidate];
        self.vercodetimer = nil;
        timecount = 60;
        iscoding = NO;
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
                vercodes = [dic objectForKey:@"keyinfo"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.verco setTitle:@"语音验证通过" forState:0];
                });
                [self.vercodetimer invalidate];
                self.vercodetimer = nil;
                timecount = 60;
                iscoding = NO;
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"-1"])
            {
                //验证失败
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [self.verco setTitle:@"语音验证失败" forState:0];
                               });
                [self.vercodetimer invalidate];
                self.vercodetimer = nil;
                timecount = 60;
                iscoding = NO;
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"0"] && ![[dic objectForKey:@"keyinfo"] isEqualToString:@""])
            {
                //验证失败
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [self.verco setTitle:@"语音验证失败" forState:0];
                               });
                [self.vercodetimer invalidate];
                self.vercodetimer = nil;
                timecount = 60;
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
            self.dataDic = dic;
            if ([self.dataDic isKindOfClass:[NSDictionary class]] == 1)
            {
                if ([[self.dataDic objectForKey:@"status"] intValue] == 1)
                {
                    [self textExampleses:@"注册成功"];
                    [self.userdefaults setObject:self.setNewAccount.text forKey:@"account"];
                    [self.userdefaults setObject:self.setPassword.text forKey:@"password"];
                    [self.userdefaults synchronize];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.navigationController popViewControllerAnimated:YES];
                    });
                }else
                {
                    //清空数据
                    self.dataDic = nil;
                    vercodes = @"";
                    orderno = @"";
                    
                    timecount = 60;
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
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@",self.setNewAccount.text];
        
        [self.httppost httpPostWithurl :urlStr body:body type:checkaccount];
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
        [self.setPassword becomeFirstResponder];
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
        [self.confirmPassword becomeFirstResponder];
        return YES;
    }
    if (textField.tag == 11)
    {
        if ([self.setPassword.text isEqualToString:self.confirmPassword.text] == 0)
        {
            [self textExampleses:@"密码和确认密码不一致"];
            self.confirmPassword.text = @"";
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
