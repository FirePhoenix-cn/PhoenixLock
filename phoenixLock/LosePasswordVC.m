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
    
    
    NSString *tempPass;
    NSString *newPass;
    NSString *vercodes;
    NSString *orderno;
    NSInteger timecount;
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
    
    self.userdefaults = [NSUserDefaults standardUserDefaults];
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    self.phonenumber.delegate = self;
    self.phonenumber.text = [self.userdefaults objectForKey:@"account"];
    orderno = @"";
    vercodes = @"";
    timecount = 60;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
    
    UIView *subview = [self.view viewWithTag:10];
    CGPoint center = self.view.center;
    center.y = center.y + 32.0;
    subview.center = center;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.vercodetimer invalidate];
    self.vercodetimer = nil;
    timecount = 60;
}

-(void) goBack
{
    timecount = 60;
    [self.vercodetimer invalidate];
    self.vercodetimer = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (IBAction)retrievePassword:(UIButton *)sender
{
    [self.phonenumber resignFirstResponder];
    if ([vercodes isEqualToString:@""])
    {
        [self textExamples:@"请先进行语音验证"];
        return;
    }
    [self.verco setTitle:@"请求语音验证" forState:0];
    [self performSelector:@selector(retrievepw) withObject:nil afterDelay:0.1];
    
}

-(void)retrievepw
{
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=rempassword&account=%@&mobile=%@&vercode=%@",self.phonenumber.text,[self.phonenumber.text.mutableCopy substringWithRange:NSMakeRange(0, 11)],vercodes];
    
    [self.httppost httpPostWithurl:urlStr type:rempassword];
}

- (IBAction)getVercode:(UIButton *)sender
{
    if (isvercoding) {
        return;
    }
    self.verco = sender;
    if (!btnlock)
    {
        [self.phonenumber resignFirstResponder];
        //检测账号是否存在
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=checkaccount";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@",self.phonenumber.text];
        [self.httppost httpPostWithurl :urlStr body:body type:checkaccount];
        return;
    }
    [self getcode];
}

-(void)getcode
{
    
    if ([self.phonenumber.text isEqualToString:@""])
    {
        [self textExamples:@"请输入手机号"];
        return;
    }
    
    if ([HTTPPost isConnectionAvailable] == NO)
    {
        [self textExamples:@"没有网络！"];
        return;
    }
    if(timecount == 60)
    {
        orderno = @"";
        [self getvercode];
        if (self.vercodetimer != nil)
        {
            [self.vercodetimer invalidate];
            self.vercodetimer = nil;
        }
        self.vercodetimer = [[NSTimer alloc] init];
        self.vercodetimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(changetexts) userInfo:nil repeats:YES];
        isvercoding = YES;
    }

}

-(void)changetexts
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
        isvercoding = NO;
    }
}

-(void)getvercode
{
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=voice";
    NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@&mobile=%@&module=repassword&vercode=4&veraction=2&vertype=1",self.phonenumber.text,self.phonenumber.text];
    [self.httppost httpPostWithurl :urlStr body:body type:voice];
}


-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type) {
            
        case voice:
        {
            
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                orderno = [dic objectForKey:@"orderno"];
                
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
                vercodes = [dic objectForKey:@"keyinfo"];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self.verco setTitle:@"语音验证通过" forState:0];
                });
                [self.vercodetimer invalidate];
                self.vercodetimer = nil;
                timecount = 60;
                isvercoding = NO;
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
                isvercoding = NO;
            }

        }
            break;

        case rempassword:
        {
            self.dataDic = dic;
            if ([self.dataDic isKindOfClass:[NSDictionary class]]==1)
            {
                if ([[self.dataDic objectForKey:@"status"] intValue] == 1 && [self.dataDic objectForKey:@"password"] != nil)
                {
                    tempPass = [self.dataDic objectForKey:@"password"];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"找回成功" message:[NSString stringWithFormat:@"您的新密码是:%@，请登陆修改！该密码仅显示一次，请牢记！",[self.dataDic objectForKey:@"password"]] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"去登陆" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if ([[self.userdefaults objectForKey:@"account"] isEqualToString:@""] || [self.userdefaults objectForKey:@"account"] == nil)
                        {
                            [self.userdefaults setObject:self.phonenumber.text forKey:@"account"];
                        }
                        [self.userdefaults setObject:[self.dataDic objectForKey:@"password"] forKey:@"password"];
                        [self.userdefaults synchronize];
                        [self.navigationController popViewControllerAnimated:YES];
                    }]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:alert animated:true completion:nil];
                    });
                    
                }else
                {
                    //清空数据
                    self.dataDic = nil;
                    vercodes = @"";
                    orderno = @"";
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
                    self.phonenumber.text = nil;
                   
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
    if ([textField isEqual:self.phonenumber])
    {
        if (![CheckCharacter isValidateMobileNumber:textField.text])
        {
            [self textExamples:@"手机格式有误!"];
            self.phonenumber.text = @"";
            
        }else
        {
            //检测账号是否存在
            NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=checkaccount";
            NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@",self.phonenumber.text];
            
            [self.httppost httpPostWithurl :urlStr body:body type:checkaccount];
            btnlock = YES;
        }
    }
    if ([CheckCharacter isValidateMobilePassward:textField.text])
    {
        newPass = textField.text;
    }else
    {
        newPass = nil;
    }
    return YES;
}

@end
