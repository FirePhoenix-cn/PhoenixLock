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

static  NSString *placeholder = @"您好! 感谢您对凰腾智能锁产品提出的宝贵意见及建议!";

@interface Trouble ()<HTTPPostDelegate>
{
    BOOL startedit;
}
@property(strong , nonatomic) HTTPPost *httpPost;

@property(strong, nonatomic) NSTimer *cheackchtimer;
@end

@implementation Trouble

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.phone.delegate = self;
    self.phone.tag = 10;
    self.contenttext.delegate = self;
    self.contenttext.tag = 20;
    self.contenttext.text = placeholder;
    self.httpPost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    self.phone.text = [[[self.userdefault objectForKey:@"account"] mutableCopy] substringWithRange:NSMakeRange(0, 11)];
    startedit = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httpPost.delegate = self;
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
    if (![CheckCharacter isValidateMobileNumber:self.phone.text])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"手机号填写错误!"];
        });
        return;
    }
    if ([self.contenttext.text isEqualToString:placeholder] || [self.contenttext.text isEqualToString:@""])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"您没有填写任何内容!"];
        });
        return;
    }
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=sendfault";
    NSString *body = [NSString stringWithFormat:@"&account=%@&apptoken=%@&uuid=%@&mobile=%@&content=%@",[self.userdefault objectForKey:@"account"],[self.userdefault objectForKey:@"appToken"],[self.userdefault objectForKey:@"uuid"],self.phone.text,self.contenttext.text];
    [self.httpPost httpPostWithurl :urlStr body:body type:trouble];
    
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
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
    self.countcontent.text = [NSString stringWithFormat:@"%lu/2000",(unsigned long)textView.text.length];
}

//会响应
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (startedit == YES)
    {
        textView.text = @"";
        startedit = NO;
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
