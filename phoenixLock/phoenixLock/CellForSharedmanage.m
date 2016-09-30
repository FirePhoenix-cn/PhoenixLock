//
//  CellForSharedmanage.m
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellForSharedmanage.h"
#import "MBProgressHUD.h"

@implementation CellForSharedmanage

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _userdefaults = [NSUserDefaults standardUserDefaults];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.appLibBleLock._delegate = self;
    _autounLock.transform = CGAffineTransformMakeScale(0.66, 0.66);
    _setToppage.transform = CGAffineTransformMakeScale(0.66, 0.66);
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    UIButton *btn1 = [self viewWithTag:10];
    UIButton *btn2 = [self viewWithTag:20];
    ([_sharelock.isactive boolValue])?[btn2 setEnabled:NO]:[btn1 setEnabled:NO];
    _distance.value = _sharelock.distance.floatValue;
    self.distancevalue.text = [NSString stringWithFormat:@"%.1f",_distance.value];
    _setToppage.on = [[_sharelock istoppage]  boolValue];
    _autounLock.on = [[_sharelock isautounlock]  boolValue];
    
}

- (IBAction)autounlock:(UISwitch *)sender
{
    [_userdefaults setInteger:1 forKey:@"canautounlock"];
    [_userdefaults synchronize];
    [self updateLockMsg:[_sharelock globalcode] withupdate:^(SmartLock *device) {
        device.isautounlock = [NSNumber numberWithBool:sender.on];
    }];
}

/********************放置首页*****************/
- (IBAction)homepage:(UISwitch *)sender
{
    [self updateLockMsg:[_sharelock globalcode] withupdate:^(SmartLock *device) {
        device.istoppage = [NSNumber numberWithBool:sender.on];
    }];

}

- (IBAction)unshared:(UIButton *)sender
{
    
    [(UIButton*)[self viewWithTag:10] setEnabled:NO];
    [(UIButton*)[self viewWithTag:20] setEnabled:YES];
    [self updateLockMsg:[_sharelock globalcode] withupdate:^(SmartLock *device) {
        device.isactive = [NSNumber numberWithBool:NO];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self textExample1];
    });
}

- (IBAction)reqshare:(UIButton *)sender
{
    NSMutableData* guid = [[self NSStringConversionToNSData:_sharelock.globalcode] mutableCopy];
    NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
    [_appDelegate.appLibBleLock bleConnectRequest:mac forbattery:NO];
    
}

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status
{
    if (status) {
        dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
        dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_sharelock.uuid]];
            NSData *uuid_e = [self NSStringConversionToNSData:_sharelock.comucode];
            [uuid_d appendData:uuid_e];
            [_appDelegate.appLibBleLock bleDataSendRequest:macAddr cmd_type:libBleCmdSendSharerCommunicateUUID param_data:uuid_d];
        });
    }
}

-(void)didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    switch (cmd_type) {
        case libBleCmdSendSharerCommunicateUUID:
        {
            if (result!=libBleErrorCodeNone) {
                return;
            }
            dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
            dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //写入密钥到设备
                NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_sharelock.uuid]];
                NSData *uuid_e = [self NSStringConversionToNSData:_sharelock.comucode];
                NSData *uuid_f = [self NSStringConversionToNSData:_sharelock.authcode];
                [uuid_d appendData:uuid_e];
                [uuid_d appendData:uuid_f];
                [uuid_d appendData:[self getCurrentTimeInterval]];
                [_appDelegate.appLibBleLock bleDataSendRequest:macAddr cmd_type:libBleCmdAddSharerOpenLockUUID param_data:uuid_d];
                });
        }
            break;
          
            
        case libBleCmdAddSharerOpenLockUUID:
        {
            if (!result)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(UIButton*)[self viewWithTag:20] setEnabled:NO];
                    [(UIButton*)[self viewWithTag:10] setEnabled:YES];
                    [self updateLockMsg:[_sharelock globalcode] withupdate:^(SmartLock *device) {
                        device.isactive = [NSNumber numberWithBool:YES];
                    }];
                    [self textExample2];
                });
                
            }
        }
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


- (IBAction)distance:(UISlider *)sender
{
    self.distancevalue.text = [NSString stringWithFormat:@"%.1f",sender.value];
    [self updateLockMsg:[_sharelock globalcode] withupdate:^(SmartLock *device) {
        device.distance = [NSString stringWithFormat:@"%.1f",sender.value];
    }];
}

- (void)textExample1
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.superview animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(@"解除成功，您将不能使用该锁", @"title0");
    [hud.label setFont:[UIFont systemFontOfSize:12.0]];
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:2.f];
}

- (void)textExample2
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.superview animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(@"申请成功，您可以继续使用该锁", @"title1");
    [hud.label setFont:[UIFont systemFontOfSize:12.0]];
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:2.f];
}

-(void)didDiscoverComplete{}

-(void)didDisconnectIndication:(NSData *)macAddr{}

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
