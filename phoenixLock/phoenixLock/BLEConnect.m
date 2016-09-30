//
//  BLEConnect.m
//  phoenixLock
//
//  Created by jinou on 16/4/28.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "BLEConnect.h"

@interface BLEConnect ()<CBCentralManagerDelegate>
@property (nonatomic, strong) CBCentralManager *manager;
@end

@implementation BLEConnect

- (void)viewDidLoad {
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.appLibBleLock._delegate = self;
    _guid = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"guid"]];
    _mac = [_guid subdataWithRange:NSMakeRange(0, 6)];
    _uuid = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"uuid"]];
    _scrB = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"appToken"]];
    _scrC = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"sc"]];
    _scrD = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"sd"]];
    _manager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
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

//******************判断蓝牙打开与否**********************
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:{
            _openBLE.text = @"蓝牙已开启";
            _next1.text = @"↓";
            _connectingBLE.text = @"正在连接蓝牙";
            //请求连接设备
            BOOL isConnected = [_appDelegate.appLibBleLock bleConnectRequest:_mac forbattery:NO];
            if (isConnected == YES)
            {
                _next2.text = @"↓";
                _mateBLE.text = @"正在匹配";
            }else{
                _connectingBLE.text = @"匹配失败";
            }
        }
            break;
        default:
            _openBLE.text = @"请开启蓝牙";
            break;
    }
}

/*************************蓝牙协议函数的实现**************************/

-(void) didConnectConfirm:(NSData *)macAddr status:(Boolean)status{

    if (status) {
        _connectingBLE.text = @"匹配完成";
        _mateBLE.text = @"连接成功";
        _next3.text = @"↓";
        _checkManager.text = @"正在验证管理员唯一性";
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkmanager) userInfo:nil repeats:NO];
    }else
    {
        _next2.text = @"";
        _mateBLE.text = @"";
    }
    
}

-(void) didDisconnectIndication:(NSData *)macAddr{

    _next1.text = @"";
    _connectingBLE.text = @"";
    _next2.text = @"";
    _mateBLE.text = @"";
    _next3.text = @"";
    _checkManager.text = @"";
    _next4.text = @"";
    _addSuccess.text = @"";
}

-(void) didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data{
        switch (cmd_type) {
        case libBleCmdBindManager:{
            if (result){//已存在，清除掉
                NSMutableData *data = [[NSMutableData alloc] initWithData:_guid];
                [data appendData:param_data];
                self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(clearmanager:) userInfo:data repeats:NO];
            }else{
                _checkManager.text = @"验证通过";
                self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addmanager) userInfo:nil repeats:NO];
            }
        }break;
            
        case libBleCmdAddManagerOpenLockUUID:{
            if (!result) {
                _next4.text = @"↓";
                _addSuccess.text = @"添加成功";
                self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(nextpage) userInfo:nil repeats:NO];
            }else{
                _next4.text = @"↓";
                _addSuccess.text = @"添加失败";
            }
        }break;
        
            case libBleCmdClearManager:{
                if (!result) {//清除后绑定新用户
                _checkManager.text = @"验证通过";
                self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addmanager) userInfo:nil repeats:NO];
                }
            }break;
        default:
            break;
    }
}
/**************定时指定方法实现**************/
-(void)addmanager{
    NSMutableData *data = [[NSMutableData alloc] initWithData:_guid];
    [data appendData:_uuid];
    [data appendData:_scrB];
    [data appendData:_scrC];
    [data appendData:_scrD];
    [data appendData:[self getCurrentTimeInterval]];
    [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdAddManagerOpenLockUUID param_data:data];
}

-(void)clearmanager:(NSTimer*)timer{
     [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdClearManager param_data:timer.userInfo];
}

-(void)checkmanager{
    [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdBindManager param_data:_guid];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)nextpage{
    
    [_appDelegate.appLibBleLock bleDisconnectRequest:_mac];
    [self performSegueWithIdentifier:@"confirmadd" sender:self];
}
-(void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
    
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_appDelegate.appLibBleLock bleDisconnectRequest:_mac];
}

@end
