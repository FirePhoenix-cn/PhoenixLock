//
//  CellForUnlock.m
//  phoenixLock
//
//  Created by qcy on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellForUnlock.h"

@interface CellForUnlock()<HTTPPostDelegate>
{
    httpPostType _type;
}
@property(strong ,nonatomic) HTTPPost *httppost;
@end

@implementation CellForUnlock

- (void)awakeFromNib
{
    [super awakeFromNib];
    _userdefaults = [NSUserDefaults standardUserDefaults];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.appLibBleLock._delegate = self;
    _manager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    _httppost.delegate =self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval{}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    while (_path == nil) {
        return;
    }
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
        {
            _openbluetooth.text = @"蓝牙已开启";
            _next1.text = @"↓";
            _connect.text = @"正在连接蓝牙";
            //请求连接设备
            //区分开锁类型：ismaster
            
            _guid = [self NSStringConversionToNSData:_globalcode];
            _mac = [_guid subdataWithRange:NSMakeRange(0, 6)];
            
            [_appDelegate.appLibBleLock bleConnectRequest:_mac forbattery:NO];
        }break;
            
        default:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self uploadlog:1];
            });
            
            _openbluetooth.text = @"请开启蓝牙";
        }
            break;
    }
}

/****************蓝牙协议函数******************/
-(void)didDisconnectIndication:(NSData *)macAddr
{
    _next1.text = @"";
    _next2.text = @"";
    _next3.text = @"";
    _next4.text = @"";
    _connect.text = @"";
    _mate.text = @"";
    _checkkey.text = @"";
    _opened.text = @"";
}

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status
{
    if (status)
    {
        _connect.text = @"连接成功";
        _next2.text = @"↓";
        _mate.text = @"匹配完成";
        _next3.text = @"↓";
    }else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            [self uploadlog:31];
        });
        _connect.text = @"连接失败";
         
        return;
    }
    
    if (_ismaster) {
        _checkkey.text = @"正在验证管理员";
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkmanager) userInfo:nil repeats:NO];
    }else{
        _checkkey.text = @"正在验证密钥";
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(communicate) userInfo:nil repeats:NO];
    }
}

-(void)uploadlog:(NSInteger)status
{
    //上传日志
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=%li",
                     [_userdefaults objectForKey:@"account"],
                     [_userdefaults objectForKey:@"appToken"],
                     [_userdefaults objectForKey:@"uuid"],
                     _globalcode,_devcode,_authcode,strDate,(long)status];
    [_httppost httpPostWithurl:url];
    _type = uploadlog;
}

-(void)didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    switch (cmd_type) {
        case libBleCmdBindManager:
        {
            NSData *uuid = [self NSStringConversionToNSData:[_userdefaults objectForKey:@"uuid"]];
            NSData *scrB = [self NSStringConversionToNSData:[_userdefaults objectForKey:@"appToken"]];
            NSMutableData *user = [[NSMutableData alloc] initWithData:uuid];
            [user appendData:scrB];
            
            if ([param_data isEqualToData:user]) {
                _checkkey.text = @"验证通过";
                _next4.text = @"↓";
                _opened.text = @"正在开锁";
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(communicate) userInfo:nil repeats:NO];
            }else if(param_data == nil){
                _checkkey.text = @"无管理员,请绑定!";
            }else if(param_data != user)
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self uploadlog:4];
                });
                _checkkey.text = @"已绑定其他管理员,验证失败";
            }
        }break;
        
        case libBleCmdAddSharerOpenLockUUID:
        {
            if (!result)
            {
                if ([HTTPPost isConnectionAvailable] == NO)
                {
                    //无网络
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
                    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=5",
                                     [_userdefaults objectForKey:@"account"],
                                     [_userdefaults objectForKey:@"appToken"],
                                     [_userdefaults objectForKey:@"uuid"],
                                     _globalcode,
                                     _devcode,
                                     _authcode,strDate];
                    NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[_userdefaults objectForKey:@"wirelesslog"]];
                    [wirelesslog addObject:url];
                    [_userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
                    [_userdefaults synchronize];
                    wirelesslog = nil;
                }else
                {
                    //上传日志
                    [self uploadlog:5];
                }
                
                //修改本地数据
                [self updateLockMsg:_globalcode withupdate:^(SmartLock *device) {
                    NSInteger effectimes = [[device effectimes] integerValue];
                    device.effectimes = [NSString stringWithFormat:@"%li",(long)effectimes-1];
                }];
                
                [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
                
            }else
            {
                _opened.text = @"开锁失败";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self uploadlog:51];
                });
                [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
            }
        }
            break;
        case libBleCmdSendManagerOpenLockUUID:
        {
            if (!result) {
                _opened.text = @"开锁成功";
                
                if ([HTTPPost isConnectionAvailable] == NO)
                {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
                    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=5",
                                     [_userdefaults objectForKey:@"account"],
                                     [_userdefaults objectForKey:@"appToken"],
                                     [_userdefaults objectForKey:@"uuid"],
                                     _globalcode,
                                     _devcode,
                                     _authcode,strDate];
                    NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[_userdefaults objectForKey:@"wirelesslog"]];
                    [wirelesslog addObject:url];
                    [_userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
                    [_userdefaults synchronize];
                    wirelesslog = nil;
                    
                }else
                {
                    //上传日志
                    [self uploadlog:5];
                }
                
                [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
                
            }else{
                _opened.text = @"开锁失败";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self uploadlog:51];
                });
                [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
            }
        }break;
            
        case libBleCmdSendSharerCommunicateUUID:{
            if (!result) {
                _checkkey.text = @"验证通过";
                _next4.text = @"↓";
                _opened.text = @"正在开锁";
                //开锁开始
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(shareopenlock) userInfo:nil repeats:NO];
            }else{
                _checkkey.text = @"验证失败";
            }
        }break;
        case libBleCmdSendSharerOpenLockUUID:{
            if (!result) {
                _opened.text = @"开锁成功";
               
                if ([HTTPPost isConnectionAvailable] == NO)
                {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
                    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=5",
                                     [_userdefaults objectForKey:@"account"],
                                     [_userdefaults objectForKey:@"appToken"],
                                     [_userdefaults objectForKey:@"uuid"],
                                     _globalcode,
                                     _devcode,
                                     _authcode,strDate];
                    NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[_userdefaults objectForKey:@"wirelesslog"]];
                    [wirelesslog addObject:url];
                    [_userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
                    [_userdefaults synchronize];
                    wirelesslog = nil;
                    
                }else
                {
                    [self uploadlog:5];
                }
                
                //修改本地数据
                [self updateLockMsg:_globalcode withupdate:^(SmartLock *device) {
                    NSInteger effectimes = [[device effectimes] integerValue];
                    device.effectimes = [NSString stringWithFormat:@"%li",(long)effectimes-1];
                }];
                
                [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
                
            }else{
                _opened.text = @"开锁失败";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self uploadlog:51];
                });
                [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(bledisc) userInfo:nil repeats:0];
            }
        }break;
            
        default:
        break;
    }
}

-(void)bledisc
{
    [_appDelegate.appLibBleLock bleDisconnectRequest:_mac];
}

-(void)didDiscoverComplete{}

/********************定时指定方法实现*********************/

-(void)checkmanager
{
    [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdBindManager param_data:_guid];
}

-(void)communicate
{
    
    if (_ismaster) {
        NSMutableData *uuid_c = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_devcode]];
        [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdSendManagerCommunicateUUID param_data:uuid_c];
        _timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(manageropenlock) userInfo:nil repeats:NO];
    }else{
        NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_devcode]];
        NSData *uuid_e = [self NSStringConversionToNSData:_comucode];
        [uuid_d appendData:uuid_e];
        [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdSendSharerCommunicateUUID param_data:uuid_d];
    }
}

-(void)manageropenlock
{
    NSMutableData *uuid_c = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_devcode]];;
    NSData *uuid_d = [self NSStringConversionToNSData:_authcode];
    [uuid_c appendData:uuid_d];
    [uuid_c appendData:[self getCurrentTimeInterval]];
    [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdSendManagerOpenLockUUID param_data:uuid_c];
}

-(void)shareopenlock
{
    NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_devcode]];
    NSData *uuid_e = [self NSStringConversionToNSData:_comucode];
    NSData *uuid_f = [self NSStringConversionToNSData:_authcode];
    [uuid_d appendData:uuid_e];
    [uuid_d appendData:uuid_f];
    [uuid_d appendData:[self getCurrentTimeInterval]];
        [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdSendSharerOpenLockUUID param_data:uuid_d];
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
