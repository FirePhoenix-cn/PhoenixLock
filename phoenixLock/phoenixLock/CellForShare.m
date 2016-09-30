//
//  CellForShare.m
//  phoenixLock
//
//  Created by jinou on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellForShare.h"
#import "MD5Code.h"
#import "CheckCharacter.h"
#import "KeyType.h"


@interface CellForShare()<KeyTypeDelegate,HTTPPostDelegate>
{
    httpPostType _type;
    NSInteger _selectpath;
}
@property (strong,nonatomic) KeyType *keytype;
@property (strong, nonatomic) HTTPPost *httppost;
@property (strong, nonatomic) NSString *st_time;
@property (strong, nonatomic) NSString *en_time;
@end

@implementation CellForShare

- (void)awakeFromNib
{
    [super awakeFromNib];
    _accountforshareduser.delegate = self;
    _userdefaults = [NSUserDefaults standardUserDefaults];
    _shareTable.delegate = self;
    _shareTable.dataSource = self;
    _shareTable.showsVerticalScrollIndicator = NO;
    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _appDelegate.appLibBleLock._delegate = self;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    _httppost.delegate = self;
    _datasrc = [NSMutableArray array];
   
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    //同步分享出去的锁
    
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=getdevshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@",
                     [_userdefaults objectForKey:@"account"],
                     [_userdefaults objectForKey:@"appToken"],
                     [_managerlock globalcode],
                     [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)]];
    [_httppost httpPostWithurl:url];
    _type = getdevshare;
   
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    
    switch (_type)
    {
        case getdevshare:
        {
            _datasrc = [dic objectForKey:@"data"];
            
            for (NSInteger i=0; i<_datasrc.count; i++)
            {
                if ([[_datasrc[i] objectForKey:@"authmobile"] isEqualToString:@""])
                {
                    [_datasrc removeObjectAtIndex:i];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^
            {
                //删除多余信息（effectimes < = 0）
                [_shareTable reloadData];
            });
        }
            break;
            
            
        case addshare:
        {
            
            if ([[dic objectForKey:@"status"] intValue] == 1)
            {
                //写入分享次数
                
                [self updateLockMsg:[_managerlock globalcode] withupdate:^(SmartLock *device) {
                    NSInteger sharenum = [[_managerlock sharenum] integerValue];
                    device.sharenum = [NSString stringWithFormat:@"%li",(long)sharenum-1];
                }];
                //分享成功
                //更新分享出去的锁的本地列表
                NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=getdevshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@",
                                 [_userdefaults objectForKey:@"account"],
                                 [_userdefaults objectForKey:@"appToken"],
                                 [_managerlock globalcode],
                                 [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)]];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [_httppost httpPostWithurl:url];
                    _type = getdevshare;
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                _accountforshareduser.placeholder = @"被分享人账号";
                _accountforshareduser.text = @"";
            });
            
            
        }break;
            
        case delshare:
        {
            if ([dic objectForKey:@"status"])
            {
                //在设备中删除
                NSMutableData *data = [[NSMutableData alloc] initWithData:_guid];
                NSData *uuid = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"uuid"]];
                NSData *sb = [self NSStringConversionToNSData:[self.userdefaults objectForKey:@"appToken"]];
                NSData *sf = [self NSStringConversionToNSData:[[_datasrc objectAtIndex:_selectpath] objectForKey:@"authcode"]];
                [data appendData:uuid];
                [data appendData:sb];
                [data appendData:sf];
                
                [_appDelegate.appLibBleLock bleDataSendRequest:_mac cmd_type:libBleCmdDeleteSharerOpenLockUUID param_data:data];
                //删除成功
                
                [_datasrc removeObjectAtIndex:_selectpath];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_shareTable reloadData];
                });
                
            }

        }break;
        default:
            break;
    }
}

/*************表格式图协议函数************/
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 30;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _datasrc.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell =  [_shareTable dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    ShareTableCellTableViewCell *cell0 = (ShareTableCellTableViewCell *)[[[NSBundle  mainBundle]  loadNibNamed:@"ShareTableCellTableViewCell" owner:self options:nil]  lastObject];
    cell0.path = indexPath;
    cell0.delegate = self;
    switch ([[[_datasrc objectAtIndex:indexPath.row] objectForKey:@"keytype"]intValue]) {
        case 1:
        {
            cell0.activetime.text = @"无限";
            cell0.unlocktimes.text = @"无限";
        }
            break;
        case 2:
        {
            
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"yyyyMMddHHmmss"];
            NSDate *end = [formatter dateFromString:[_datasrc[indexPath.row] objectForKey:@"end_time"]];
            NSTimeInterval interval = [end timeIntervalSinceNow];
            cell0.activetime.text = [NSString stringWithFormat:@"%.1f",interval/3600];
            cell0.unlocktimes.text = @"无限";
        }
            break;

        case 3:
        {
    
            cell0.activetime.text = @"无限";
            cell0.unlocktimes.text = [[_datasrc objectAtIndex:indexPath.row] objectForKey:@"effectimes"];
        }
            break;

        case 4:
        {
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"yyyyMMddHHmmss"];
            NSDate *end = [formatter dateFromString:[_datasrc[indexPath.row] objectForKey:@"end_time"]];
            NSTimeInterval interval = [end timeIntervalSinceNow];
            cell0.activetime.text = [NSString stringWithFormat:@"%.1f",interval/3600];
            cell0.unlocktimes.text = [[_datasrc objectAtIndex:indexPath.row] objectForKey:@"effectimes"];
        }
            break;

        default:
            break;
    }
    NSMutableString *time = (NSMutableString*)[NSMutableString stringWithString:[[_datasrc objectAtIndex:indexPath.row] objectForKey:@"begin_time"]];
    if ([time isEqualToString:@""])
    {
        cell0.sharedaccount.text = @"无限制";
    }else
    {
        [time insertString:@" " atIndex:8];
        [time insertString:@":" atIndex:11];
        [time insertString:@":" atIndex:14];
        cell0.sharedtime.text = time;

    }
    cell0.sharedaccount.text = [[_datasrc objectAtIndex:indexPath.row] objectForKey:@"authmobile"];
    cell = cell0;
    return cell;
}

/*****************添加新分享*****************/
- (IBAction)addshareduser:(UIButton *)sender
{
    
    [_accountforshareduser resignFirstResponder];
    NSString *str = [NSString stringWithFormat:@"%li",(long)([[_managerlock maxshare] integerValue]-[[_managerlock sharenum] integerValue])];
    while ([str integerValue] == 0 && str != nil)
    {
        //分享次数不足
        UIAlertController *alert = [[UIAlertController alloc] init];
        alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"分享次数不足！" preferredStyle:1];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:0 handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        return;
    }
    //选择分享类型
    
    if (![_accountforshareduser.text isEqualToString:@""])
    {
        //http请求
        while (![CheckCharacter isValidateMobileNumber:_accountforshareduser.text]) {
            _accountforshareduser.placeholder = @"手机号有误，请重输！";
            return;
        }
        
        /*选择分享密钥类型*/
        _keytype = (KeyType*)[[[NSBundle  mainBundle] loadNibNamed:@"keytype" owner:self options:nil] lastObject];
        _keytype.frame = CGRectMake(0.0, 0.0, self.superview.frame.size.width, self.superview.frame.size.height);
        _keytype.delegate = self;
        [self.superview addSubview:_keytype];
        _st_time = @"";
        _en_time = @"";
        
    }
}

-(void)onGetDate:(NSString *)date type:(DateType)type
{
    switch (type) {
        case 0:
        {
            _st_time = date;
        }
            break;
            
            
        case 1:
        {
            _en_time = date;
        }
            break;
        default:
            break;
    }
}

-(void)confirm
{
   
    [self add:_keytype.keytype :@[_st_time,_en_time] :_keytype.effectimes.text];
}

-(void)cancel
{
   
    [_keytype removeFromSuperview];
    _keytype = nil;
}

-(void)add:(NSInteger)keytype :(NSArray *)times :(NSString *) effectimes
{
    switch (keytype)
    {
        case 1:
        {
            NSDate *now = [[NSDate alloc] init];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
            NSString *nowdate = [dateFormatter stringFromDate:now];
            
            NSString *md5string = [NSString stringWithFormat:@"account=%@&apptoken=%@&authmobile=%@&devcode=%@&globalcode=%@&keytype=1&oper_time=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                   [self.userdefaults objectForKey:@"account"],
                                   [self.userdefaults objectForKey:@"appToken"],
                                   _accountforshareduser.text,
                                   [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                                   [_managerlock globalcode],
                                   nowdate];
            
            NSString *sign = [MD5Code md5:md5string];
            NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=addshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@&authmobile=%@&keytype=1&effectimes=0&begin_time=%@&end_time=%@&oper_time=%@&sign=%@",
                                [_userdefaults objectForKey:@"account"],
                                [_userdefaults objectForKey:@"appToken"],
                                [_managerlock globalcode],
                                [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                                _accountforshareduser.text, nowdate, @"", nowdate, sign];
            
            
            [_httppost httpPostWithurl:urlStr];
            _type = addshare;
        }
            break;
        
        case 2:
        {
            
            
            NSDate *now = [[NSDate alloc] init];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
            NSString *nowdate = [dateFormatter stringFromDate:now];
            
            NSString *md5string = [NSString stringWithFormat:@"account=%@&apptoken=%@&authmobile=%@&devcode=%@&globalcode=%@&keytype=2&oper_time=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                   [self.userdefaults objectForKey:@"account"],
                                   [self.userdefaults objectForKey:@"appToken"],
                                   _accountforshareduser.text,
                                   [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                                   [_managerlock globalcode],
                                   nowdate];
            NSString *sign = [MD5Code md5:md5string];
            
            NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=addshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@&authmobile=%@&keytype=2&effectimes=%@&begin_time=%@&end_time=%@&oper_time=%@&sign=%@",
                                [_userdefaults objectForKey:@"account"],
                                [_userdefaults objectForKey:@"appToken"],
                                [_managerlock globalcode],
                                [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                                _accountforshareduser.text, @"0", times[0], times[1], nowdate, sign];
            
            [_httppost httpPostWithurl:urlStr];
            _type = addshare;
            
        }
            break;
            
        case 3:
        {
            if ([effectimes isEqualToString:@""])
            {
                effectimes = @"0";
            }
            
            NSDate *now = [[NSDate alloc] init];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
            NSString *nowdate = [dateFormatter stringFromDate:now];
            
            NSString *md5string = [NSString stringWithFormat:@"account=%@&apptoken=%@&authmobile=%@&devcode=%@&globalcode=%@&keytype=3&oper_time=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                   [self.userdefaults objectForKey:@"account"],
                                   [self.userdefaults objectForKey:@"appToken"],
                                   _accountforshareduser.text,
                                   [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                                   [_managerlock globalcode],
                                   nowdate];
            NSString *sign = [MD5Code md5:md5string];
            NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=addshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@&authmobile=%@&keytype=3&effectimes=%@&begin_time=%@&end_time=%@&oper_time=%@&sign=%@",
                                [_userdefaults objectForKey:@"account"],
                                [_userdefaults objectForKey:@"appToken"],
                                [_managerlock globalcode],
                                [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                                _accountforshareduser.text, effectimes, times[0], times[1], nowdate, sign];
            [_httppost httpPostWithurl:urlStr];
            _type = addshare;

        }
            break;
        
        case 4:
        {

            if ([effectimes isEqualToString:@""]) {
                effectimes = @"0";
            }
            
            NSDate *now = [[NSDate alloc] init];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
            NSString *nowdate = [dateFormatter stringFromDate:now];
            
            NSString *md5string = [NSString stringWithFormat:@"account=%@&apptoken=%@&authmobile=%@&devcode=%@&globalcode=%@&keytype=4&oper_time=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                   [self.userdefaults objectForKey:@"account"],
                                   [self.userdefaults objectForKey:@"appToken"],
                                   _accountforshareduser.text,
                                   [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                                   [_managerlock globalcode],
                                   nowdate];
            NSString *sign = [MD5Code md5:md5string];
            NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=addshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@&authmobile=%@&keytype=4&effectimes=%@&begin_time=%@&end_time=%@&oper_time=%@&sign=%@",
                                [_userdefaults objectForKey:@"account"],
                                [_userdefaults objectForKey:@"appToken"],
                                [_managerlock globalcode],
                                [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                                _accountforshareduser.text, effectimes, times[0], times[1], nowdate, sign];
            [_httppost httpPostWithurl:urlStr];
            _type = addshare;
        }
            break;
        default:
            break;
    }
    
    [_keytype removeFromSuperview];
    _keytype = nil;

}
/************************删除分享者***********************/
-(void)deleteSharUser:(NSIndexPath *)path
{
    //http删除请求
    //
    NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=delshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@&devuserid=%@",
                        [_userdefaults objectForKey:@"account"],
                        [_userdefaults objectForKey:@"appToken"],
                        [_managerlock globalcode],
                        [[_managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                        [[_datasrc objectAtIndex:path.row] objectForKey:@"devuserid"]];
    [_httppost httpPostWithurl:urlStr];
    _type = delshare;
    _selectpath = path.row;
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


/*********************蓝牙协议函数********************/
-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status{}

-(void)didDisconnectIndication:(NSData *)macAddr{}

-(void)didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    switch (cmd_type) {
        case libBleCmdDeleteSharerOpenLockUUID:{
            if (!result) {
                NSLog(@"删除分享成功！");
            }else{
                NSLog(@"删除分享失败！");}
        }break;
        default:
            break;
    }
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)didGetBattery:(NSInteger)battery forMac:(NSData *)mac{}
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
