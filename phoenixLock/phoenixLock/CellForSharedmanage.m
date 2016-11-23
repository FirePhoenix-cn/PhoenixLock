//
//  CellForSharedmanage.m
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellForSharedmanage.h"
#import "MBProgressHUD.h"
#import "MD5Code.h"
@implementation CellForSharedmanage

- (void)awakeFromNib
{
    //它是个废物 level: 1
    [super awakeFromNib];
}

-(void)drawRect:(CGRect)rect
{
    //只初始化一次 level：3
    [super drawRect:rect];
    self.autounLock.transform = CGAffineTransformMakeScale(0.66, 0.66);
    self.setToppage.transform = CGAffineTransformMakeScale(0.66, 0.66);
    self.httpPost = self.appDelegate.delegatehttppost;
}

-(void)layoutSubviews
{
    //多次修改 level: 2
    [super layoutSubviews];
    self.distance.value = self.sharelock.distance.floatValue;
    self.distancevalue.text = [NSString stringWithFormat:@"%.1f",self.sharelock.distance.floatValue];
    self.setToppage.on = [[self.sharelock istoppage]  boolValue];
    self.autounLock.on = [[self.sharelock isautounlock]  boolValue];
    UIButton *btn1 = [self viewWithTag:10];
    UIButton *btn2 = [self viewWithTag:20];
    if (![self.sharelock.status isEqualToString:@"1"])
    {
        [btn1 setEnabled:NO];
        [btn2 setEnabled:NO];
        [self.autounLock setEnabled:NO];
        [self.setToppage setEnabled:NO];
    }else
    {
        [btn1 setEnabled:YES];
        [btn2 setEnabled:YES];
        [self.autounLock setEnabled:YES];
        [self.setToppage setEnabled:YES];
        ([self.sharelock.isactive boolValue])?[btn2 setEnabled:NO]:[btn1 setEnabled:NO];
    }
}

-(void)uploadlog:(NSInteger)status
{
    //上传日志
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
        
        NSString *signString = [NSString stringWithFormat:@"account=%@&apptoken=%@&authcode=%@&globalcode=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                [self.userdefaults objectForKey:@"account"],
                                [self.userdefaults objectForKey:@"appToken"],
                                self.sharelock.authcode,
                                self.sharelock.globalcode,
                                strDate,[self.userdefaults objectForKey:@"uuid"]];
        NSString *sign = [MD5Code md5:signString];
        
        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=opencheck&account=%@&apptoken=%@&globalcode=%@&authcode=%@&uuid=%@&oper_time=%@&oper_status=%li&sign=%@",
                         [self.userdefaults objectForKey:@"account"],
                         [self.userdefaults objectForKey:@"appToken"],
                         self.sharelock.globalcode,
                         self.sharelock.authcode,
                         [self.userdefaults objectForKey:@"uuid"],strDate,(long)status,sign];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.httpPost httpPostWithurl:url type:uploadlog];
            
        });
}

-(void)addWirelessLogUploadRecord:(NSInteger)status
{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
        
        NSString *signString = [NSString stringWithFormat:@"account=%@&apptoken=%@&authcode=%@&globalcode=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                [self.userdefaults objectForKey:@"account"],
                                [self.userdefaults objectForKey:@"appToken"],
                                self.sharelock.authcode,
                                self.sharelock.globalcode,
                                strDate,[self.userdefaults objectForKey:@"uuid"]];
        NSString *sign = [MD5Code md5:signString];
        
        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=opencheck&account=%@&apptoken=%@&globalcode=%@&authcode=%@&uuid=%@&oper_time=%@&oper_status=%li&sign=%@",
                         [self.userdefaults objectForKey:@"account"],
                         [self.userdefaults objectForKey:@"appToken"],
                         self.sharelock.globalcode,
                         self.sharelock.authcode,
                         [self.userdefaults objectForKey:@"uuid"],strDate,(long)status,sign];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[self.userdefaults objectForKey:@"wirelesslog"]];
            [wirelesslog addObject:url];
            [self.userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
            [self.userdefaults synchronize];
            wirelesslog = nil;
        });
        
}

- (IBAction)autounlock:(UISwitch *)sender
{
    [self updateLockMsg:self.sharelock.devuserid withupdate:^(SmartLock *device) {
        device.isautounlock = [NSNumber numberWithBool:sender.on == YES ? YES : NO];
    }];
}

/********************放置首页*****************/
- (IBAction)homepage:(UISwitch *)sender
{
    [self updateLockMsg:self.sharelock.devuserid withupdate:^(SmartLock *device) {
        device.istoppage = [NSNumber numberWithBool:sender.on == YES ? YES : NO];
    }];

}

- (IBAction)unshared:(UIButton *)sender
{
    [(UIButton*)[self viewWithTag:10] setEnabled:NO];
    [(UIButton*)[self viewWithTag:20] setEnabled:YES];
    [self updateLockMsg:self.sharelock.devuserid withupdate:^(SmartLock *device) {
        device.isactive = [NSNumber numberWithBool:NO];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self textExample:@"解除成功，您将不能使用该锁"];
    });
}

- (IBAction)reqshare:(UIButton *)sender
{
    if (![HTTPPost isConnectionAvailable])
    {
        [self textExample:@"请开启网络"];
        return;
    }
    [self checkUUID];
}

-(void)checkUUID
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
    
    NSString *signString = [NSString stringWithFormat:@"account=%@&apptoken=%@&authcode=%@&globalcode=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                            [self.userdefaults objectForKey:@"account"],
                            [self.userdefaults objectForKey:@"appToken"],
                            self.sharelock.authcode,
                            self.sharelock.globalcode,
                            strDate,[self.userdefaults objectForKey:@"uuid"]];
    NSString *sign = [MD5Code md5:signString];
    
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=opencheck&account=%@&apptoken=%@&globalcode=%@&authcode=%@&uuid=%@&oper_time=%@&oper_status=0&sign=%@",
                     [self.userdefaults objectForKey:@"account"],
                     [self.userdefaults objectForKey:@"appToken"],
                     self.sharelock.globalcode,
                     self.sharelock.authcode,
                     [self.userdefaults objectForKey:@"uuid"],strDate,sign];
    self.httpPost.delegate = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.httpPost httpPostWithurl:url type:uploadlog];
    });
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type) {
        case uploadlog:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"] && [[dic objectForKey:@"logid"] isEqualToString:@"0"])
            {
                NSMutableData* guid = [[self NSStringConversionToNSData:self.sharelock.globalcode] mutableCopy];
                NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
                self.appDelegate.appLibBleLock.delegate = self;
                [self.appDelegate.appLibBleLock bleConnectRequest:mac];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(UIActivityIndicatorView*)[self viewWithTag:30] startAnimating];
                    [(UIActivityIndicatorView*)[self viewWithTag:30] performSelector:@selector(stopAnimating) withObject:nil afterDelay:10];
                });
            }else if([[dic objectForKey:@"status"] isEqualToString:@"1007"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self textExample:@"登陆终端已改变！"];
                });
                
            }else if ([[dic objectForKey:@"status"] isEqualToString:@"2006"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self textExample:@"该分享已被取消，密钥已失效！"];
                });
                
            }
        }
            break;
            
        default:
            break;
    }
}

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status
{
    if (status) {
        dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
        dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.sharelock.uuid]];
            NSData *uuid_e = [self NSStringConversionToNSData:self.sharelock.comucode];
            [uuid_d appendData:uuid_e];
            self.appDelegate.appLibBleLock.delegate = self;
            [self.appDelegate.appLibBleLock bleDataSendRequest:macAddr cmd_type:libBleCmdSendSharerCommunicateUUID param_data:uuid_d];
        });
    }else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [(UIActivityIndicatorView*)[self viewWithTag:30] stopAnimating];
        });
    }
}

-(void)didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    if (result != libBleErrorCodeNone)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.appDelegate.appLibBleLock.delegate = self;
            [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [(UIActivityIndicatorView*)[self viewWithTag:30] stopAnimating];
        });
        return;
    }
    switch (cmd_type) {
        case libBleCmdSendSharerCommunicateUUID:
        {
            dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
            dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //写入密钥到设备
                NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.sharelock.uuid]];
                NSData *uuid_e = [self NSStringConversionToNSData:self.sharelock.comucode];
                NSData *uuid_f = [self NSStringConversionToNSData:self.sharelock.authcode];
                [uuid_d appendData:uuid_e];
                [uuid_d appendData:uuid_f];
                [uuid_d appendData:[self getCurrentTimeInterval]];
                self.appDelegate.appLibBleLock.delegate = self;
                [self.appDelegate.appLibBleLock bleDataSendRequest:macAddr cmd_type:libBleCmdAddSharerOpenLockUUID param_data:uuid_d];
                });
        }
            break;
          
        case libBleCmdAddSharerOpenLockUUID:
        {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                self.appDelegate.appLibBleLock.delegate = self;
                [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                [(UIButton*)[self viewWithTag:20] setEnabled:NO];
                [(UIButton*)[self viewWithTag:10] setEnabled:YES];
                [self updateLockMsg:self.sharelock.devuserid withupdate:^(SmartLock *device) {
                    device.isactive = [NSNumber numberWithBool:YES];
                }];
                [(UIActivityIndicatorView*)[self viewWithTag:30] stopAnimating];
                [self textExample:@"申请成功，您可以继续使用该锁"];
            });
//                if ([HTTPPost isConnectionAvailable]) {
//                    [self uploadlog:5];
//                }else
//                {
//                    [self addWirelessLogUploadRecord:5];
//                }
//                [self updateLockMsg:self.sharelock.devuserid withupdate:^(SmartLock *device) {
//                    NSInteger effectimes = [[device effectimes] integerValue];
//                    device.effectimes = [NSString stringWithFormat:@"%li",(long)effectimes-1];
//                }];
        }
            break;
            
        default:
            break;
    }
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

- (IBAction)distance:(UISlider *)sender
{
    self.distancevalue.text = [NSString stringWithFormat:@"%.1f",sender.value];
    [self updateLockMsg:self.sharelock.devuserid withupdate:^(SmartLock *device) {
        device.distance = [NSString stringWithFormat:@"%.1f",sender.value];
    }];
}

- (void)textExample:(NSString*)str
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.superview animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(str, @"title1");
    [hud.label setFont:[UIFont systemFontOfSize:12.0]];
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:2.f];
}
@end
