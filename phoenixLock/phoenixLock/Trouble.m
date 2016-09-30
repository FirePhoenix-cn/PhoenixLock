//
//  Trouble.m
//  phoenixLock
//
//  Created by jinou on 16/7/4.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "Trouble.h"
#import "CheckCharacter.h"
#import "IQKeyboardManager.h"
#import "MBProgressHUD.h"

static  NSString *placeholder = @"您好! 感谢您对凰腾智能锁产品提出的宝贵意见及建议!";

@interface Trouble ()<HTTPPostDelegate>
{
    BOOL _startedit;
    httpPostType _type;
}
@property(strong , nonatomic) HTTPPost *httpPost;

@property(strong, nonatomic) NSTimer *cheackchtimer;
@end

@implementation Trouble

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"故障报修与反馈";
    _phone.delegate = self;
    _phone.tag = 10;
    _contenttext.delegate = self;
    _contenttext.tag = 20;
    _contenttext.text = placeholder;
    _httpPost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    
    
    _startedit = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httpPost.delegate = self;
    [IQKeyboardManager sharedManager].enableAutoToolbar = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)send:(UIButton *)sender
{
    if (![CheckCharacter isValidateMobileNumber:_phone.text])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"手机号填写错误!"];
        });
        return;
    }
    if ([_contenttext.text isEqualToString:placeholder] || [_contenttext.text isEqualToString:@""])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"您没有填写任何内容!"];
        });
        return;
    }
   
    _type = trouble;
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=sendfault";
    NSString *body = [NSString stringWithFormat:@"&account=%@&apptoken=%@&uuid=%@&mobile=%@&content=%@",[self.userdefault objectForKey:@"account"],[self.userdefault objectForKey:@"appToken"],[self.userdefault objectForKey:@"uuid"],_phone.text,_contenttext.text];
    [_httpPost httpPostWithurl :urlStr body:body];
    
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    
    switch (_type)
    {
        case trouble:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self textExample:@"提交成功！"];
                });
            }
        }
            break;
            
        default:
            break;
    }

}

- (void)textExample:(NSString*)text
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(text, @"title");
    hud.offset = CGPointMake(0.f, - 20.f);
    [hud hideAnimated:YES afterDelay:2.f];
}

//会响应
-(void)textViewDidChange:(UITextView *)textView
{
    _countcontent.text = [NSString stringWithFormat:@"%lu/2000",(unsigned long)textView.text.length];
}

//会响应
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (_startedit == YES)
    {
        textView.text = @"";
        _startedit = NO;
    }
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length == 10 && ![string isEqualToString:@""])//此时的文本是发生改变之前的
    {
        
        NSMutableString *multext = [textField.text mutableCopy];
        [multext appendString:string];
        textField.text = multext;
        [textField resignFirstResponder];
        if (![CheckCharacter isValidateMobileNumber:textField.text])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                textField.text = @"";
                [self textExample:@"手机号格式有误!"];
            });
            return YES;
        }
    }
    return YES;

}

@end
