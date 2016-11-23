//
//  CellForUnlock.m
//  phoenixLock
//
//  Created by qcy on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellForUnlock.h"
#import "MD5Code.h"

@interface CellForUnlock()
@property(strong ,nonatomic) HTTPPost *httppost;
@end

@implementation CellForUnlock

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.guid = [self NSStringConversionToNSData:self.globalcode];
    self.mac = [self.guid subdataWithRange:NSMakeRange(0, 6)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(startOpenLock) withObject:nil afterDelay:0.5];
    });
}

-(void)startOpenLock
{
    switch (self.appDelegate.appLibBleLock.centralManager.state)
    {
        case CBCentralManagerStatePoweredOn:
        {
            self.openbluetooth.text = @"正在打开蓝牙";
            self.next1.text = @"↓";
            self.connect.text = @"正在连接蓝牙";
            self.appDelegate.appLibBleLock.delegate = self;
            [self.appDelegate.appLibBleLock bleConnectRequest:self.mac];
        }break;
            
        default:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if ([HTTPPost isConnectionAvailable] == NO)
                {
                    //无网络
                    [self addWirelessLogUploadRecord:1];
                }else
                {
                    //上传日志
                    [self uploadlog:1];
                }
            });
            self.openbluetooth.text = @"请开启蓝牙";
            SENDNOTIFY(@"closeUnlockPage")
        }
            break;
    }
}

/****************蓝牙协议函数******************/
-(void)didDisconnectIndication:(NSData *)macAddr
{
    self.next1.text = @"";
    self.next2.text = @"";
    self.next3.text = @"";
    self.next4.text = @"";
    self.connect.text = @"";
    self.mate.text = @"";
    self.checkkey.text = @"";
    self.opened.text = @"";
}

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status
{
    if (status)
    {
        self.connect.text = @"连接成功";
        self.next2.text = @"↓";
        self.mate.text = @"匹配完成";
        self.next3.text = @"↓";
    }else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if ([HTTPPost isConnectionAvailable] == NO)
            {
                //无网络
                [self addWirelessLogUploadRecord:31];
            }else
            {
                //上传日志
                [self uploadlog:31];
            }
        });
        self.connect.text = @"连接失败";
        SENDNOTIFY(@"closeUnlockPage")
        return;
    }
    
    if (self.ismaster)
    {
        self.checkkey.text = @"正在验证管理员";
       [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkmanager) userInfo:nil repeats:NO];
    }else
    {
        self.checkkey.text = @"正在验证密钥";
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(communicate) userInfo:nil repeats:NO];
    }
}

-(void)uploadlog:(NSInteger)status
{
    //上传日志
    if (self.ismaster == 0)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
        
        NSString *signString = [NSString stringWithFormat:@"account=%@&apptoken=%@&authcode=%@&globalcode=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                [self.userdefaults objectForKey:@"account"],
                                [self.userdefaults objectForKey:@"appToken"],
                                self.authcode,
                                self.globalcode,
                                strDate,[self.userdefaults objectForKey:@"uuid"]];
        NSString *sign = [MD5Code md5:signString];
        
        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=opencheck&account=%@&apptoken=%@&globalcode=%@&authcode=%@&uuid=%@&oper_time=%@&oper_status=%li&sign=%@",
                         [self.userdefaults objectForKey:@"account"],
                         [self.userdefaults objectForKey:@"appToken"],
                         self.globalcode,
                         self.authcode,
                         [self.userdefaults objectForKey:@"uuid"],strDate,(long)status,sign];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.httppost httpPostWithurl:url type:uploadlog];
            
        });
        return;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=%li",
                     [self.userdefaults objectForKey:@"account"],
                     [self.userdefaults objectForKey:@"appToken"],
                     [self.userdefaults objectForKey:@"uuid"],
                     self.globalcode,[self.devcode substringWithRange:NSMakeRange(68, 32)],self.authcode,strDate,(long)status];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.httppost httpPostWithurl:url type:uploadlog];
    });
}

-(void)addWirelessLogUploadRecord:(NSInteger)status
{
    if (self.ismaster == 0)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
        
        NSString *signString = [NSString stringWithFormat:@"account=%@&apptoken=%@&authcode=%@&globalcode=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                [self.userdefaults objectForKey:@"account"],
                                [self.userdefaults objectForKey:@"appToken"],
                                self.authcode,
                                self.globalcode,
                                strDate,[self.userdefaults objectForKey:@"uuid"]];
        NSString *sign = [MD5Code md5:signString];
        
        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=opencheck&account=%@&apptoken=%@&globalcode=%@&authcode=%@&uuid=%@&oper_time=%@&oper_status=%li&sign=%@",
                         [self.userdefaults objectForKey:@"account"],
                         [self.userdefaults objectForKey:@"appToken"],
                         self.globalcode,
                         self.authcode,
                         [self.userdefaults objectForKey:@"uuid"],strDate,(long)status,sign];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[self.userdefaults objectForKey:@"wirelesslog"]];
            [wirelesslog addObject:url];
            [self.userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
            [self.userdefaults synchronize];
            wirelesslog = nil;
        });
        
        return;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=%li",
                     [self.userdefaults objectForKey:@"account"],
                     [self.userdefaults objectForKey:@"appToken"],
                     [self.userdefaults objectForKey:@"uuid"],
                     self.globalcode,[self.devcode substringWithRange:NSMakeRange(68, 32)],self.authcode,strDate,(long)status];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[self.userdefaults objectForKey:@"wirelesslog"]];
        [wirelesslog addObject:url];
        [self.userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
        [self.userdefaults synchronize];
        wirelesslog = nil;
    });
}

-(void)didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    switch (cmd_type) {
        case libBleCmdBindManager:
        {
            NSData *user = [NSData dataWithData:[self NSStringConversionToNSData:[self.devcode substringWithRange:NSMakeRange(20, 48)]]];
            if ([param_data isEqualToData:user])
            {
                self.checkkey.text = @"验证通过";
                self.next4.text = @"↓";
                self.opened.text = @"正在开锁";
               [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(communicate) userInfo:nil repeats:NO];
            }else if(param_data == nil)
            {
                self.checkkey.text = @"无管理员,请绑定!";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        //无网络
                        [self addWirelessLogUploadRecord:4];
                    }else
                    {
                        //上传日志
                        [self uploadlog:4];
                    }
                });
                [self bledisc];
            }else if(param_data != user)
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        //无网络
                        [self addWirelessLogUploadRecord:4];
                    }else
                    {
                        //上传日志
                        [self uploadlog:4];
                    }
                });
                self.checkkey.text = @"管理员不符,验证失败";
                [self bledisc];
            }
        }
            break;
        
//        case libBleCmdAddSharerOpenLockUUID:
//        {
//            if (!result)
//            {
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    if ([HTTPPost isConnectionAvailable] == NO)
//                    {
//                        //无网络
//                        [self addWirelessLogUploadRecord:5];
//                    }else
//                    {
//                        //上传日志
//                        [self uploadlog:5];
//                    }
//                });
//                //修改本地数据
//                [self updateLockMsg:self.devuserid withupdate:^(SmartLock *device) {
//                    NSInteger effectimes = [[device effectimes] integerValue];
//                    device.effectimes = [NSString stringWithFormat:@"%li",(long)effectimes-1];
//                }];
//            }else
//            {
//                self.opened.text = @"开锁失败";
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    if ([HTTPPost isConnectionAvailable] == NO)
//                    {
//                        //无网络
//                        [self addWirelessLogUploadRecord:51];
//                    }else
//                    {
//                        //上传日志
//                        [self uploadlog:51];
//                    }
//                });
//            }
//            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
//        }
//            break;
            
        case libBleCmdSendManagerOpenLockUUID:
        {
            if (!result)
            {
                self.opened.text = @"开锁成功";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        //无网络
                        [self addWirelessLogUploadRecord:5];
                    }else
                    {
                        //上传日志
                        [self uploadlog:5];
                    }
                });
            }else
            {
                self.opened.text = @"开锁失败";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        //无网络
                        [self addWirelessLogUploadRecord:51];
                    }else
                    {
                        //上传日志
                        [self uploadlog:51];
                    }
                });
            }
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
        }
            break;
            
        case libBleCmdSendSharerCommunicateUUID:
        {
            if (!result)
            {
                self.checkkey.text = @"验证通过";
                self.next4.text = @"↓";
                self.opened.text = @"正在开锁";
                //开锁开始
                [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(shareopenlock) userInfo:nil repeats:NO];
            }else
            {
                self.checkkey.text = @"验证失败";
                [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
            }
        }
            break;
            
        case libBleCmdSendSharerOpenLockUUID:
        {
            if (!result)
            {
                self.opened.text = @"开锁成功";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        //无网络
                        [self addWirelessLogUploadRecord:5];
                    }else
                    {
                        //上传日志
                        [self uploadlog:5];
                    }
                });
                
                //修改本地数据
                [self updateLockMsg:self.devuserid withupdate:^(SmartLock *device) {
                    NSInteger usedtimes = [[device usedtimes] integerValue];
                    device.usedtimes = [NSString stringWithFormat:@"%li",(long)usedtimes + 1];
                }];
            }else
            {
                self.opened.text = @"开锁失败";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        //无网络
                        [self addWirelessLogUploadRecord:51];
                    }else
                    {
                        //上传日志
                        [self uploadlog:51];
                    }
                });
            }
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
        }
            break;
            
        default:
        break;
    }
}

-(void)bledisc
{
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDisconnectRequest:self.mac];
    SENDNOTIFY(@"closeUnlockPage")
}

/********************定时指定方法实现*********************/

-(void)checkmanager
{
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdBindManager param_data:self.guid];
}

-(void)communicate
{
    
    if (self.ismaster) {
        NSMutableData *uuid_c = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.devcode]];
        self.appDelegate.appLibBleLock.delegate = self;
        [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdSendManagerCommunicateUUID param_data:uuid_c];
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(manageropenlock) userInfo:nil repeats:NO];
    }else{
        NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.devcode]];
        NSData *uuid_e = [self NSStringConversionToNSData:self.comucode];
        [uuid_d appendData:uuid_e];
        self.appDelegate.appLibBleLock.delegate = self;
        [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdSendSharerCommunicateUUID param_data:uuid_d];
    }
}

-(void)manageropenlock
{
    NSMutableData *uuid_c = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.devcode]];;
    NSData *uuid_d = [self NSStringConversionToNSData:self.authcode];
    [uuid_c appendData:uuid_d];
    [uuid_c appendData:[self getCurrentTimeInterval]];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdSendManagerOpenLockUUID param_data:uuid_c];
}

-(void)shareopenlock
{
    NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.devcode]];
    NSData *uuid_e = [self NSStringConversionToNSData:self.comucode];
    NSData *uuid_f = [self NSStringConversionToNSData:self.authcode];
    [uuid_d appendData:uuid_e];
    [uuid_d appendData:uuid_f];
    [uuid_d appendData:[self getCurrentTimeInterval]];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdSendSharerOpenLockUUID param_data:uuid_d];
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

-(void)didGetBattery:(NSInteger)battery forMac:(NSData *)mac
{
    if (self.ismaster == 1)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //上传电量
            NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploaddevbattery&account=%@&apptoken=%@&globalcode=%@&battery=%li",
                                [self.userdefaults objectForKey:@"account"],
                                [self.userdefaults objectForKey:@"appToken"],
                                self.globalcode,(long)battery];
            urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [self.httppost httpPostWithurl:urlStr type:uploaddevbattery];
        });
    }else
    {
        [self updateLockMsg:self.devuserid withupdate:^(SmartLock *device) {
            device.battery = [NSString stringWithFormat:@"%li",(long)battery];
        }];
    }
}
@end
