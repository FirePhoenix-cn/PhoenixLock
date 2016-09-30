//
//  ConfirmAdd.m
//  phoenixLock
//
//  Created by jinou on 16/5/9.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ConfirmAdd.h"


@interface ConfirmAdd ()<HTTPPostDelegate>
{
    httpPostType _type;
}
@property (strong, nonatomic) HTTPPost *httppost;
@end

@implementation ConfirmAdd

- (void)viewDidLoad {
    [super viewDidLoad];
    _number.text = [NSString stringWithFormat:@"云盾锁编号: %@",[self.userdefaults objectForKey:@"devid"]];
    _manudate.text = [NSString stringWithFormat:@"生产日期: %@",[self.userdefaults objectForKey:@"productdate"]];
    _warranty.text = [NSString stringWithFormat:@"保修日期: 至%@",[self.userdefaults objectForKey:@"warrantydate"]];
    _numforkey.text = [NSString stringWithFormat:@"钥匙数量: %@",[self.userdefaults objectForKey:@"maxshare"]];;
    _name.delegate = self;
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    _httppost.delegate = self;
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval{}

- (IBAction)confirm:(UIButton *)sender {
    //命名
    if ([_name.text isEqualToString:@""])
    {
        NSMutableArray *time = [[NSMutableArray alloc] initWithArray:[self.userdefaults objectForKey:@"time"]];
        [time addObject:[[NSDate alloc] init]];
        [self.userdefaults setObject:time forKey:@"time"];
        
        dispatch_async(dispatch_get_main_queue(), ^
        {
            
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    }else
    {
        NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=redevname&account=%@&apptoken=%@&globalcode=%@&devname=%@",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"appToken"],[self.userdefaults objectForKey:@"guid"],_name.text];
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [_httppost httpPostWithurl:urlStr];
        _type = redevname;
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void) goBack
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AddLock" bundle:nil];
        UIViewController *next = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"scanqr"];
        [self.navigationController pushViewController:next animated:YES];
    });
}

@end
