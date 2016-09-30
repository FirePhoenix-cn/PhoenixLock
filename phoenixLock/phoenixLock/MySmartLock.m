//
//  MySmartLock.m
//  phoenixLock
//
//  Created by jinou on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "MySmartLock.h"

@interface MySmartLock ()<HTTPPostDelegate>
{httpPostType _posttype;}

@property (strong,nonatomic) HTTPPost *httppost;
@end

@implementation MySmartLock

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"云盾锁";
    
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
    if ([[self.userdefaults objectForKey:@"sync"] boolValue] == NO )
    {
        return;
    }
    /*********************进行一次心跳同步***********************/
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=synauth&account=%@&apptoken=%@&uuid=%@",[self.userdefaults objectForKey:@"account"],
                       [self.userdefaults objectForKey:@"appToken"],
                       [self.userdefaults objectForKey:@"uuid"]];
    _posttype = synauth;
    [_httppost httpPostWithurl:urlStr];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.userdefaults setBool:YES forKey:@"sync"];
    [self.userdefaults synchronize];

}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    switch (_posttype)
    {
        case synauth:
        {
            if ([[dic objectForKey:@"status"] integerValue] != 1) {
                return;
            }
            NSArray <NSDictionary *> *data = [NSArray arrayWithArray:[dic objectForKey:@"data"]];
            if (data.count == 0) {
                return;
            }
            //同步到本地
            for (NSDictionary *lock in data)
            {
                if ([self isNewLock:[[lock objectForKey:@"globalcode"] lowercaseString]])
                {
                    //insert
                    [self insertLock:^(SmartLock *device) {
                        device.devuserid = [lock objectForKey:@"devuserid"];
                        device.globalcode = [[lock objectForKey:@"globalcode"] lowercaseString];
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
                        
                        device.productdate = @"获取失败";
                        device.warrantydate = @"获取失败";
                        device.sharenum = @"0";
                        device.maxshare = @"15";
                        device.distance = @"0.0";
                        device.battery = @"0";
                        device.isactive = [NSNumber numberWithBool:YES];
                        device.istoppage = [NSNumber numberWithBool:NO];
                        device.isautounlock = [NSNumber numberWithBool:NO];
                        device.oper_time = [[NSDate alloc] init];
                        device.isdeleted = @"";
                    }];
                }else
                {
                    //update
                    [self updateLockMsg:[[lock objectForKey:@"globalcode"] lowercaseString] withupdate:^(SmartLock *device) {
                        device.devuserid = [lock objectForKey:@"devuserid"];
                        device.globalcode = [[lock objectForKey:@"globalcode"] lowercaseString];
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
                    }];
                }
            }
        }
            
            break;
        default:
            break;
    }
}

- (BOOL)matestring:(NSString*)string :(NSArray*)arr
{
    NSInteger count = 0;
    for (NSInteger i = 0 ; i < arr.count; i++ ) {
        if ([arr[i] isEqualToString:string] ) {
            count++;
        }
    }
    return count;
}


-(void)goBack
{

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)addlock:(UIButton *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AddLock" bundle:nil];
        UIViewController *next = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"scanqr"];
        [self.navigationController pushViewController:next animated:YES];
    });

}
@end
