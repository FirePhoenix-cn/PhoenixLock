//
//  BLEConnect.m
//  phoenixLock
//
//  Created by jinou on 16/4/28.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "BLEConnect.h"

@implementation BLEConnect

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mac = [self.guid subdataWithRange:NSMakeRange(0, 6)];
    self.uuid = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"uuid"]];
    self.scrB = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"appToken"]];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performSelector:@selector(startBindLock) withObject:nil afterDelay:0.2];
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
-(void)startBindLock
{
    switch (self.appDelegate.appLibBleLock.centralManager.state) {
        case CBCentralManagerStatePoweredOn:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.openBLE.text = @"正在打开蓝牙";
                self.next1.text = @"↓";
                self.connectingBLE.text = @"正在连接蓝牙";
            });
            
            //请求连接设备
            self.appDelegate.appLibBleLock.delegate = self;
            BOOL isConnected = [self.appDelegate.appLibBleLock bleConnectRequest:self.mac];
            if (isConnected == YES)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.next2.text = @"↓";
                    self.mateBLE.text = @"正在匹配";
                });
                
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.connectingBLE.text = @"匹配失败";
                });
                
            }
        }
            break;
        default:
            dispatch_async(dispatch_get_main_queue(), ^{
                self.openBLE.text = @"请开启蓝牙";
            });
            
            break;
    }
}

/*************************蓝牙协议函数的实现**************************/

-(void) didConnectConfirm:(NSData *)macAddr status:(Boolean)status
{
  
    if (status)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connectingBLE.text = @"匹配完成";
            self.mateBLE.text = @"连接成功";
            self.next3.text = @"↓";
            self.checkManager.text = @"正在验证管理员唯一性";
            dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
            dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self checkmanager];
            });
            
        });
        
    }else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.next2.text = @"";
            self.mateBLE.text = @"";
        });
        
    }
    
}

-(void) didDisconnectIndication:(NSData *)macAddr
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.next1.text = @"";
        self.connectingBLE.text = @"";
        self.next2.text = @"";
        self.mateBLE.text = @"";
        self.next3.text = @"";
        self.checkManager.text = @"";
        self.next4.text = @"";
        self.addSuccess.text = @"";
    });
    
}

-(void) didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    switch (cmd_type) {
        case libBleCmdBindManager:
        {
            if (result)
            {//已存在，清除掉
                NSMutableData *data = [[NSMutableData alloc] initWithData:self.guid];
                [data appendData:param_data];
                dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self clearmanager:data];
                });
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.checkManager.text = @"验证通过";
                    dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                    dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self addmanager];
                    });
                });
            }
        }break;
            
        case libBleCmdAddManagerOpenLockUUID:{
            if (!result)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.next4.text = @"↓";
                    self.addSuccess.text = @"添加成功";
                    [self performSelector:@selector(nextpage) withObject:nil afterDelay:1.0f];
                });
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.next4.text = @"↓";
                    self.addSuccess.text = @"添加失败";
                });
                
            }
        }break;
        
        case libBleCmdClearManager:
        {
                if (!result)
                {//清除后绑定新用户
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.checkManager.text = @"验证通过";
                        dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                        dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [self addmanager];
                        });
                    });
                }
            }break;
        default:
            break;
    }
}
/**************定时指定方法实现**************/
-(void)addmanager
{
    NSMutableData *data = [[NSMutableData alloc] initWithData:self.guid];
    [data appendData:self.uuid];
    [data appendData:self.scrB];
    [data appendData:self.scrC];
    [data appendData:self.scrD];
    [data appendData:[self getCurrentTimeInterval]];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdAddManagerOpenLockUUID param_data:data];
}

-(void)clearmanager:(NSData*)mac
{
    self.appDelegate.appLibBleLock.delegate = self;
     [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdClearManager param_data:mac];
}

-(void)checkmanager
{
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdBindManager param_data:self.guid];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)nextpage
{
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDisconnectRequest:self.mac];
    [self performSegueWithIdentifier:@"confirmadd" sender:self];
}
-(void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
    
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDisconnectRequest:self.mac];
}

@end
