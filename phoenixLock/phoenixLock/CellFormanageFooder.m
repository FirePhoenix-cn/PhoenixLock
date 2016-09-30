//
//  CellFormanageFooder.m
//  phoenixLock
//
//  Created by jinou on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellFormanageFooder.h"

#import "MyTabbarController.h"

NSInteger _isedit;
Boolean didconnected;
httpPostType _type;

@implementation CellFormanageFooder

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.appLibBleLock._delegate = self;
    _userdefaults = [NSUserDefaults standardUserDefaults];
    _name.delegate = self;
    _outoUnlock.transform = CGAffineTransformMakeScale(0.66, 0.66);
    _setToppage.transform = CGAffineTransformMakeScale(0.66, 0.66);
    _isedit = 1;
    didconnected = NO;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    _httppost.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    _guid = [self NSStringConversionToNSData:[_managerlock globalcode]];
    _mac = [_guid subdataWithRange:NSMakeRange(0, 6)];
    _top.on = [[_managerlock istoppage]  boolValue];
    _outoUnlock.on = [[_managerlock isautounlock]  boolValue];
    self.distancevalue.text = [NSString stringWithFormat:@"%.1f",_distance.value];
}

/**************************自定义锁名****************************/
- (IBAction)nameLock:(UIButton *)sender
{
    if (_isedit)
    {
        [_name becomeFirstResponder];
        _name.userInteractionEnabled = YES;
        _name.borderStyle =  UITextBorderStyleRoundedRect;
    }else
    {
        [_name resignFirstResponder];
        _name.userInteractionEnabled = NO;
        //http请求
        NSString *guid = [_managerlock globalcode];
        NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=redevname&account=%@&apptoken=%@&globalcode=%@&devname=%@",
                        [_userdefaults objectForKey:@"account"],
                        [_userdefaults objectForKey:@"appToken"],
                        guid,_name.text];
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [_httppost httpPostWithurl:urlStr];
        _type = redevname;
        
    }
    _isedit = !_isedit;
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    switch (_type) {
        case redevname:
        {
            
            
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                [self updateLockMsg:[_managerlock globalcode] withupdate:^(SmartLock *device) {
                    device.devname = _name.text;
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                _name.borderStyle =  UITextBorderStyleNone;
                [_name setText:_name.text];
                });
            }else
            {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_name setText:[_managerlock devname]];
                    _name.borderStyle =  UITextBorderStyleNone;
                });
            }
        }
            
            break;
            
        default:
            break;
    }
}


/***************************自动开锁*********************************/
- (IBAction)autounlock:(UISwitch *)sender
{
    [_userdefaults setInteger:1 forKey:@"canautounlock"];
    [_userdefaults synchronize];
    
    [self updateLockMsg:[_managerlock globalcode] withupdate:^(SmartLock *device) {
        device.isautounlock = [NSNumber numberWithBool:sender.on];
    }];
}

- (IBAction)addshareduser:(UIButton *)sender {
    
    [_delegate addshare:_path.row];
}

/*************************放置首页******************************/
- (IBAction)homepage:(UISwitch *)sender
{
    [self updateLockMsg:[_managerlock globalcode] withupdate:^(SmartLock *device) {
        device.istoppage = [NSNumber numberWithBool:sender.on];
    }];
}

/*************************解除绑定******************************/
- (IBAction)removebind:(UIButton *)sender
{
    NSData *uuid = [self NSStringConversionToNSData:[_userdefaults objectForKey:@"uuid"]];
    NSData *sB = [self NSStringConversionToNSData:[_userdefaults objectForKey:@"appToken"]];
    NSMutableData *data = [[NSMutableData alloc] initWithData:_guid];
    [data appendData:uuid];
    [data appendData:sB];
    while(!didconnected) {
        [_delegate alertdisplay:@"设备未连接,请3秒后重试" :nil];
        [_appDelegate.appLibBleLock bleConnectRequest:_mac forbattery:NO];
        return;
    }
    [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdClearManager param_data:data];
}

/***********************重新绑定*************************/
- (IBAction)rebind:(UIButton *)sender {
   
    while(!didconnected) {
        [_delegate alertdisplay:@"设备未连接,请3秒后重试" :nil];
        [_appDelegate.appLibBleLock bleConnectRequest:_mac forbattery:NO];
        return;
    }
    [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdBindManager param_data:_guid];
  }

- (IBAction)distance:(UISlider *)sender
{
    self.distancevalue.text = [NSString stringWithFormat:@"%.1f",sender.value];
    [self updateLockMsg:[_managerlock globalcode] withupdate:^(SmartLock *device) {
        device.distance = [NSString stringWithFormat:@"%.1f",sender.value];
    }];
}

/***********************蓝牙协议函数************************/
-(void) didConnectConfirm:(NSData *)macAddr status:(Boolean)status
{
    didconnected = status;
}

-(void) didDisconnectIndication:(NSData *)macAddr{}

-(void) didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data{
    switch (cmd_type)
    {
        case libBleCmdClearManager:{
            if (!result)
            {
                [_delegate alertdisplay:@"解除绑定成功!":nil];
            }else
            {
                [_delegate alertdisplay:@"未绑定该锁无法解除!":nil];
            }
        }break;
            
        case libBleCmdBindManager:
        {
            NSMutableData *user = [[NSMutableData alloc] initWithData:[self NSStringConversionToNSData:[_userdefaults objectForKey:@"uuid"]]];
            NSData *sB = [self NSStringConversionToNSData:[_userdefaults objectForKey:@"appToken"]];
            [user appendData:sB];
            if ([param_data isEqualToData:user])
            {
                [_delegate alertdisplay:@"已经绑定,无法重复绑定!":nil];
            }else if(param_data != nil){
                [_delegate alertdisplay:@"已经绑定其他管理员,无法绑定!":nil];
            }else if(param_data == nil){
                
                NSMutableData *uuid_c = [NSMutableData dataWithData:[self NSStringConversionToNSData:[_managerlock uuid]]];
                NSData *uuid_d = [self NSStringConversionToNSData:[_managerlock authcode]];
                [uuid_c appendData:uuid_d];
                [uuid_c appendData:[self getCurrentTimeInterval]];
               
                [_delegate alertdisplay:@"验证通过!请点击完成绑定!" :uuid_c];
            }
        }break;
        case libBleCmdAddManagerOpenLockUUID:{
            if (result)
            {
                [_delegate alertdisplay:@"您已绑定该锁,请勿重复操作!":nil];
            }else
            {
                [_delegate alertdisplay:@"恭喜您!绑定成功!":nil];
            }
        }break;
            
        default:
            break;
    }
    
}

-(NSData *) NSStringConversionToNSData:(NSString*)string
{
    if (string == nil)
        return nil;
    const char *ch = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *data = [NSMutableData data];
    while (*ch) {
        char byte = 0;
        if ('0' <= *ch && *ch <= '9')
            byte = *ch - '0';
        else if ('a' <= *ch && *ch <= 'f')
            byte = *ch - 'a' + 10;
        else if ('A' <= *ch && *ch <= 'F')
            byte = *ch - 'A' + 10;
        else
            return nil;
        ch++;
        byte = byte << 4;
        if (*ch) {
            if ('0' <= *ch && *ch <= '9')
                byte += *ch - '0';
            else if ('a' <= *ch && *ch <= 'f')
                byte += *ch - 'a' + 10;
            else if ('A' <= *ch && *ch <= 'F')
                byte += *ch - 'A' + 10;
            else
                return nil;
            ch++;
        }
        [data appendBytes:&byte length:1];
    }
    return data;
}

-(NSData *) getCurrentTimeInterval
{
    NSData *dataCurrentTimeInterval;
    long dateInterval = [[NSDate date] timeIntervalSince1970];
    Byte byteDateInterval[4];
    for (NSUInteger index = 0; index < sizeof(byteDateInterval); index++)
    {
        byteDateInterval[index] = (dateInterval >> ((3 - index) * 8)) & 0xFF;
    }
    dataCurrentTimeInterval = [[NSData alloc] initWithBytes:byteDateInterval length:sizeof(byteDateInterval)];
    return dataCurrentTimeInterval;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_name resignFirstResponder];
    return YES;
}

-(void)didGetBattery:(NSInteger)battery forMac:(NSData *)mac
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    if (battery <= 100 && battery > 75)
    {
        [self.battery setImage:[UIImage imageNamed:@"battery100.png"]];
        return;
    }
    if (battery <= 75 && battery > 50)
    {
        [self.battery setImage:[UIImage imageNamed:@"battery75.png"]];
        return;
    }
    if (battery <= 50 && battery > 25)
    {
        [self.battery setImage:[UIImage imageNamed:@"battery50.png"]];
        return;
    }
    if (battery >= 25 && battery > 10)
    {
        [self.battery setImage:[UIImage imageNamed:@"battery25.png"]];
        return;
    }
    if (battery < 10)
    {
        [self.battery setImage:[UIImage imageNamed:@"battery0.png"]];
        return;
    }
    });
}

- (IBAction)tomall:(UIButton *)sender
{
    
    ((MyTabbarController*)[self getCurrentVC]).selectedIndex = 1;
}

//获取当前屏幕显示的viewcontroller
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}

-(void)updateLockMsg:(NSString*)globalcode withupdate:(void(^)(SmartLock *device))update
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"globalcode=%@",globalcode];
    [request setPredicate:predicate];
    SmartLock *lock = [[((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext executeFetchRequest:request error:nil] lastObject];
    if (lock)
    {
        update(lock);
        [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext save:nil];
    }
}

@end
