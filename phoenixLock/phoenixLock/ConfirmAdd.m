//
//  ConfirmAdd.m
//  phoenixLock
//
//  Created by jinou on 16/5/9.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ConfirmAdd.h"


@interface ConfirmAdd ()<HTTPPostDelegate>

@property (strong, nonatomic) HTTPPost *httppost;
@end

@implementation ConfirmAdd

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.number.text = [NSString stringWithFormat:@"云盾锁编号: %@",[self.userdefaults objectForKey:@"devid"]];
    self.manudate.text = [NSString stringWithFormat:@"生产日期: %@",[self.userdefaults objectForKey:@"productdate"]];
    self.warranty.text = [NSString stringWithFormat:@"保修日期: 至%@",[self.userdefaults objectForKey:@"warrantydate"]];
    self.numforkey.text = [NSString stringWithFormat:@"钥匙数量: %@",[self.userdefaults objectForKey:@"numforkey"]];;
    self.name.delegate = self;
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
}

-(void)addNewData
{
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=synauth&account=%@&apptoken=%@&uuid=%@",[self.userdefaults objectForKey:@"account"],
                       [self.userdefaults objectForKey:@"appToken"],
                       [self.userdefaults objectForKey:@"uuid"]];
    [self.httppost httpPostWithurl:urlStr type:synauth];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case synauth:
        {
            if ([[dic objectForKey:@"status"] integerValue] != 1)
            {
                return;
            }
            //同步到本地
            [self.userdefaults setObject:[dic objectForKey:@"money"] forKey:@"money"];
            [self.userdefaults setObject:[dic objectForKey:@"minutes"] forKey:@"minutes"];
            [self.userdefaults setObject:[dic objectForKey:@"usedminutes"] forKey:@"usedminutes"];
            [self.userdefaults setObject:[dic objectForKey:@"flows"] forKey:@"flows"];
            [self.userdefaults synchronize];
            NSArray <NSDictionary *> *data = [NSArray arrayWithArray:[dic objectForKey:@"data"]];
            for (NSDictionary *lock in data)
            {
                if ([self isNewLockWithDevuserid:[lock objectForKey:@"devuserid"]])
                {
                    //insert
                    [self insertLock:^(SmartLock *device) {
                        device.devid = [self.userdefaults objectForKey:@"devid"];
                        device.devuserid = [lock objectForKey:@"devuserid"];
                        device.globalcode = [lock objectForKey:@"globalcode"];
                        device.uuid = [lock objectForKey:@"uuid"];
                        device.authcode = [lock objectForKey:@"authcode"];
                        device.comucode = [lock objectForKey:@"comucode"];
                        device.devname = [lock objectForKey:@"devname"];
                        device.managename = [lock objectForKey:@"managename "];
                        device.ismaster = [lock objectForKey:@"ismaster"];
                        device.keytype = [lock objectForKey:@"keytype"];
                        device.effectimes = [lock objectForKey:@"effectimes"];
                        device.begin_time = [lock objectForKey:@"begin_time"];
                        device.end_time = [lock objectForKey:@"end_time"];
                        device.status = [lock objectForKey:@"status"];
                        device.sharetimes = [lock objectForKey:@"sharetimes"];
                        device.productdate = @"2016-05-01";
                        device.warrantydate = @"2021-05-01";
                        device.sharenum = @"0";
                        device.maxshare = @"15";
                        device.distance = @"0.0";
                        device.battery = @"0";
                        device.isactive = [NSNumber numberWithBool:NO];
                        device.istoppage = [NSNumber numberWithBool:NO];
                        device.isautounlock = [NSNumber numberWithBool:NO];
                        device.oper_time = [[NSDate alloc] init];
                        device.isdeleted = @"nodeleted";
                    }];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        }
            break;
          
        case redevname:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                [self addNewData];
            }
        }
            break;
        default:
            break;
    }
}

- (IBAction)confirm:(UIButton *)sender
{
    //命名
    if ([self.name.text isEqualToString:@""])
    {
        [self addNewData];
    }else
    {
        NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=redevname&account=%@&apptoken=%@&globalcode=%@&devname=%@",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"appToken"],[self.userdefaults objectForKey:@"guid"],self.name.text];
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self.httppost httpPostWithurl:urlStr type:redevname];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
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
