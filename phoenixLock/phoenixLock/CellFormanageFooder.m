//
//  CellFormanageFooder.m
//  phoenixLock
//
//  Created by jinou on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellFormanageFooder.h"
#import "MyTabbarController.h"
#import "MBProgressHUD.h"

NSInteger isedit;
BOOL isrebind;

@implementation CellFormanageFooder

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    self.outoUnlock.transform = CGAffineTransformMakeScale(0.66, 0.66);
    self.setToppage.transform = CGAffineTransformMakeScale(0.66, 0.66);
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    self.name.delegate = self;
    [self.managerlock addObserver:self forKeyPath:@"warrantydate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.managerlock addObserver:self forKeyPath:@"battery" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.managerlock addObserver:self forKeyPath:@"distance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.managerlock addObserver:self forKeyPath:@"sharenum" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    isedit = 1;
    isrebind = NO;
    self.guid = [self NSStringConversionToNSData:[self.managerlock globalcode]];
    self.mac = [self.guid subdataWithRange:NSMakeRange(0, 6)];
    self.setToppage.on = [[self.managerlock istoppage]  boolValue];
    self.outoUnlock.on = [[self.managerlock isautounlock]  boolValue];
    self.distancevalue.text = [NSString stringWithFormat:@"%.1f",self.distance.value];
    if (self.httppost)
    {
        [self syndata];
        return;
    }
    [self performSelector:@selector(syndata) withObject:nil afterDelay:0.1];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"warrantydate"]) {
        if ([change[@"old"] isEqualToString:change[@"new"]]) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dateofwarranty.text = [NSString stringWithFormat:@"保修日期: 至%@",change[@"new"]];
        });
        return;
    }
    if ([keyPath isEqualToString:@"battery"]) {
        if ([change[@"old"] isEqualToString:change[@"new"]]) {
            return;
        }
        NSInteger battery = [change[@"new"] integerValue];
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
        return;
    }
    if ([keyPath isEqualToString:@"distance"]) {
        if ([change[@"old"] isEqualToString:change[@"new"]]) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.distance.value = [change[@"new"] floatValue];
            self.distancevalue.text = [NSString stringWithFormat:@"%.1f",self.distance.value];
        });
        return;
    }
    if ([keyPath isEqualToString:@"sharenum"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.showsharednum.text = [NSString stringWithFormat:@"分享数量:%@/%@",self.managerlock.sharenum, self.managerlock.maxshare];
        });
        return;
    }
}

-(void)syndata
{
    self.httppost.delegate = self;
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=getdevshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@",[self.userdefaults objectForKey:@"account"],
                       [self.userdefaults objectForKey:@"appToken"],
                       self.managerlock.globalcode,[self.managerlock.uuid substringWithRange:NSMakeRange(68, 32)]];
    [self.httppost httpPostWithurl:urlStr type:getdevshare];
}

/**************************自定义锁名****************************/
- (IBAction)nameLock:(UIButton *)sender
{
    if (isedit)
    {
        [self.name becomeFirstResponder];
        self.name.userInteractionEnabled = YES;
        self.name.borderStyle =  UITextBorderStyleRoundedRect;
    }else
    {
        [self.name resignFirstResponder];
        self.name.userInteractionEnabled = NO;
        //http请求
        NSString *guid = [self.managerlock globalcode];
        NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=redevname&account=%@&apptoken=%@&globalcode=%@&devname=%@",
                        [self.userdefaults objectForKey:@"account"],
                        [self.userdefaults objectForKey:@"appToken"],
                        guid,self.name.text];
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self.httppost httpPostWithurl:urlStr type:redevname];
        
    }
    isedit = !isedit;
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case getdevshare:
        {
            //更新数据库
            [self updateLockMsg:self.managerlock.globalcode withupdate:^(SmartLock *device) {
                device.devid = dic[@"devid"];
                device.productdate = dic[@"productdate"];
                device.warrantydate = dic[@"warrantydate"];
                device.battery = dic[@"battery"];
                device.distance = dic[@"distance"];
                device.maxshare = dic[@"maxshare"];
                device.sharenum = dic[@"sharenum"];
            }];
            self.managerlock.warrantydate = dic[@"warrantydate"];
            self.managerlock.battery = dic[@"battery"];
            self.managerlock.distance = dic[@"distance"];
            self.managerlock.maxshare = dic[@"maxshare"];
            self.managerlock.sharenum = dic[@"sharenum"];
        }
            break;
        case redevname:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                [self updateLockMsg:self.managerlock.devuserid withupdate:^(SmartLock *device) {
                    device.devname = self.name.text;
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                self.name.borderStyle =  UITextBorderStyleNone;
                [self.name setText:self.name.text];
                });
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.name setText:[self.managerlock devname]];
                    self.name.borderStyle =  UITextBorderStyleNone;
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
    [self updateLockMsg:self.managerlock.devuserid withupdate:^(SmartLock *device) {
        device.isautounlock = [NSNumber numberWithBool:sender.on == YES ? YES : NO];
    }];
}

- (IBAction)addshareduser:(UIButton *)sender {
    
    [self.delegate addshare:self.path.row];
}

/*************************放置首页******************************/
- (IBAction)homepage:(UISwitch *)sender
{
    [self updateLockMsg:self.managerlock.devuserid withupdate:^(SmartLock *device) {
        device.istoppage = [NSNumber numberWithBool:sender.on == YES ? YES : NO];
    }];
}

/*************************解除绑定******************************/
- (IBAction)removebind:(UIButton *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [(UIActivityIndicatorView*)[self viewWithTag:1] startAnimating];
        [(UIActivityIndicatorView*)[self viewWithTag:1] performSelector:@selector(stopAnimating) withObject:nil afterDelay:4.0f];
    });
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleConnectRequest:self.mac];
    isrebind = NO;
    
}

/***********************重新绑定*************************/
- (IBAction)rebind:(UIButton *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [(UIActivityIndicatorView*)[self viewWithTag:2] startAnimating];
        [(UIActivityIndicatorView*)[self viewWithTag:2] performSelector:@selector(stopAnimating) withObject:nil afterDelay:4.0f];
    });
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleConnectRequest:self.mac];
    isrebind = YES;
    
}

- (IBAction)distance:(UISlider *)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //上传距离
        NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploaddevdistance&account=%@&apptoken=%@&globalcode=%@&distance=%@",
                            [self.userdefaults objectForKey:@"account"],
                            [self.userdefaults objectForKey:@"appToken"],
                            [self.managerlock globalcode],[NSString stringWithFormat:@"%.1f",sender.value]];
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self.httppost httpPostWithurl:urlStr type:uploaddevdistance];
    });
    self.distancevalue.text = [NSString stringWithFormat:@"%.1f",sender.value];
    [self updateLockMsg:self.managerlock.devuserid withupdate:^(SmartLock *device) {
        device.distance = [NSString stringWithFormat:@"%.1f",sender.value];
    }];
}

/***********************蓝牙协议函数************************/
-(void) didConnectConfirm:(NSData *)macAddr status:(Boolean)status
{
    if (!status)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [(UIActivityIndicatorView*)[self viewWithTag:1] stopAnimating];
            [(UIActivityIndicatorView*)[self viewWithTag:2] stopAnimating];
        });
        return;
    }
    dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
    dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.appDelegate.appLibBleLock.delegate = self;
        [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdBindManager param_data:self.guid];
    });
}

-(void) didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    switch (cmd_type)
    {
        case libBleCmdClearManager:
        {
            dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
            dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                self.appDelegate.appLibBleLock.delegate = self;
                [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                [(UIActivityIndicatorView*)[self viewWithTag:1] stopAnimating];
            });
            if (!result)
            {
                [self textExample:@"解除成功!"];
            }else
            {
                [self textExample:@"未绑定该锁无法解除!"];
            }
        }break;
            
        case libBleCmdBindManager:
        {
            
            if (isrebind)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(UIActivityIndicatorView*)[self viewWithTag:2] stopAnimating];
                });
                
                NSData *user = [NSData dataWithData:[self NSStringConversionToNSData:[self.managerlock.uuid substringWithRange:NSMakeRange(20, 48)]]];
                if ([param_data isEqualToData:user])
                {
                    dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                    dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        self.appDelegate.appLibBleLock.delegate = self;
                        [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                    });
                    [self textExample:@"已经绑定,无法重复绑定!"];
                    
                }else if(param_data != nil)
                {
                    dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                    dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        self.appDelegate.appLibBleLock.delegate = self;
                        [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                    });
                    [self textExample:@"已经绑定其他管理员,无法绑定!"];
                    
                }else if(param_data == nil)
                {
                    NSMutableData *uuid_c = [NSMutableData dataWithData:[self NSStringConversionToNSData:[self.managerlock uuid]]];
                    NSData *uuid_d = [self NSStringConversionToNSData:[self.managerlock authcode]];
                    [uuid_c appendData:uuid_d];
                    [uuid_c appendData:[self getCurrentTimeInterval]];
                    
                    dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                    dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        self.appDelegate.appLibBleLock.delegate = self;
                        [self.appDelegate.appLibBleLock bleDataSendRequest:macAddr cmd_type:libBleCmdAddManagerOpenLockUUID param_data:uuid_c];
                    });
                }
            }else
            {
                //解除绑定
                NSMutableData *data = [[NSMutableData alloc] initWithData:self.guid];
                [data appendData:param_data];
                dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    self.appDelegate.appLibBleLock.delegate = self;
                    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdClearManager param_data:data];
                });
            }
            
        }
            break;
            
        case libBleCmdAddManagerOpenLockUUID:{
            
            dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
            dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                self.appDelegate.appLibBleLock.delegate = self;
                [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
            });
            if (result)
            {
                [self textExample:@"您已绑定该锁,请勿重复操作!"];
            }else
            {
                [self textExample:@"恭喜您!绑定成功!"];
            }
        }break;
            
        default:
            break;
    }
    
}

//将NSData类型的数据转换为十六进制NSString类型的字符串
+ (NSString *)NSDataToHexNSString:(NSData *)data
{
    if (data == nil) {
        return @"";
    }
    
    NSMutableString *hexString = [NSMutableString string];
    
    const unsigned char *p = [data bytes];
    
    for (int i=0; i < [data length]; i++)
        [hexString appendFormat:@"%02x", *p++];
    
    return hexString;
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
    [self.name resignFirstResponder];
    return YES;
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

- (void)textExample:(NSString*)str
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.superview animated:YES];
        
        // Set the annular determinate mode to show task progress.
        hud.mode = MBProgressHUDModeText;
        hud.label.text = NSLocalizedString(str, @"title1");
        [hud.label setFont:[UIFont systemFontOfSize:12.0]];
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        
        [hud hideAnimated:YES afterDelay:2.f];
    });
}

@end
