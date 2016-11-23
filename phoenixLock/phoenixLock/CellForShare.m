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
#import "MBProgressHUD.h"

@interface CellForShare()<KeyTypeDelegate,HTTPPostDelegate,libBleLockDelegate>
{
    NSIndexPath *_selectpath;
}
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) KeyType *keytype;
@property (strong, nonatomic) HTTPPost *httppost;
@property (strong, nonatomic) NSString *st_time;
@property (strong, nonatomic) NSString *en_time;
@property (strong, nonatomic) NSMutableArray *deleteAuthcode;
@end

@implementation CellForShare

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    self.accountforshareduser.delegate = self;
    self.shareTable.delegate = self;
    self.shareTable.dataSource = self;
    self.shareTable.showsVerticalScrollIndicator = NO;
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.datasrc = nil;
    self.datasrc = [NSMutableArray array];
    [self performSelector:@selector(getsharelock) withObject:nil afterDelay:0.1];
}
- (IBAction)fetchWithAccount:(id)sender
{
    if ([self.accountforshareduser.text isEqualToString:@""])
    {
        self.datasrc = self.datasrcTemp.mutableCopy;
        [self.shareTable reloadData];
        return;
    }
    if (self.accountforshareduser.text == nil)
    {
        return;
    }
    self.datasrc = [self sortFromArray:self.datasrcTemp byKeyword:self.accountforshareduser.text];
    [self.shareTable reloadData];
}

- (NSMutableArray *)sortFromArray:(NSArray*)arr byKeyword:(NSString*)keyword
{
    NSMutableArray <NSDictionary*>*result = [NSMutableArray array];
    for (NSDictionary *dict in arr)
    {
        if (keyword.length > [dict[@"authmobile"] length])
        {
            continue;
        }
        NSString *accountCut = [[dict[@"authmobile"] mutableCopy] substringWithRange:NSMakeRange(0, keyword.length)];
        if ([keyword isEqualToString:accountCut])
        {
            [result addObject:dict];
        }
    }
    return result;
}

-(NSDateFormatter *)formatter
{
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat: @"yyyyMMddHHmmss"];
    }
    return _formatter;
}

-(void)getsharelock
{
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=getdevshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@",
                     [self.userdefaults objectForKey:@"account"],
                     [self.userdefaults objectForKey:@"appToken"],
                     [self.managerlock globalcode],
                     [[self.managerlock uuid] substringWithRange:NSMakeRange(68, 32)]];
    self.httppost.delegate = self;
    [self.httppost httpPostWithurl:url type:getdevshare];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case checkaccount:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                /*选择分享密钥类型*/
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.st_time = @"";
                    self.en_time = @"";
                    self.keytype = (KeyType*)[[[NSBundle  mainBundle] loadNibNamed:@"keytype" owner:self options:nil] lastObject];
                    self.keytype.frame = CGRectMake(0.0, 0.0, self.superview.frame.size.width, self.superview.frame.size.height);
                    self.keytype.delegate = self;
                    [self.superview addSubview:self.keytype];
                });
            }else
            {
                [self textExample:@"该用户不存在"];
            }
        }
            break;
        case getdevshare:
        {
            [self.datasrc removeAllObjects];
            self.datasrc = [[dic objectForKey:@"data"] mutableCopy];
            self.datasrcTemp = self.datasrc;
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [self.shareTable reloadData];
            });
            //固化本地数据
            for (NSDictionary *dict in self.datasrcTemp)
            {
                if ([self isNewRecord:dict[@"comucode"]])
                {
                    //insert
                    [self insertShareUserWithUser:^(ShareUser *user) {
                        user.devuserid = dict[@"devuserid"];
                        user.authmobile = dict[@"authmobile"];
                        user.comucode = dict[@"comucode"];
                        user.devstatus = dict[@"devstatus"];
                        user.isdel = dict[@"isdel"];
                        user.effectimes = dict[@"effectimes"];
                        user.begin_time = dict[@"begin_time"];
                        user.end_time = dict[@"end_time"];
                        user.usedtimes = dict[@"usedtimes"];
                        user.sharetimes = dict[@"sharetimes"];
                        NSArray *authc = [NSArray arrayWithObject:dict[@"authcode"]];
                        user.authcode = authc;
                    }];
                }else
                {
                    //update
                    [self updateUser:dict[@"comucode"] withChange:^(ShareUser *user) {
                        user.devstatus = dict[@"devstatus"];
                        user.isdel = dict[@"isdel"];
                        user.effectimes = dict[@"effectimes"];
                        user.usedtimes = dict[@"usedtimes"];
                        if (![self isExsistingUser:dict[@"authcode"] inArray:user.authcode])
                        {
                            NSMutableArray *authc = [NSMutableArray arrayWithArray:user.authcode];
                            [authc addObject:dict[@"authcode"]];
                            user.authcode = authc;
                        }
                    }];
                }
            }
        }
            break;
            
        case addshare:
        {
            if ([[dic objectForKey:@"status"] intValue] == 1)
            {
                //写入分享次数
                [self updateLockMsg:self.managerlock.devuserid withupdate:^(SmartLock *device) {
                    NSInteger oversharenum = [[dic objectForKey:@"oversharenum"] integerValue];
                    NSInteger maxshare = [device.maxshare integerValue];
                    device.sharenum = [NSString stringWithFormat:@"%li",(long)(maxshare - oversharenum)];
                }];
                //分享成功
                //更新分享出去的锁的本地列表
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self getsharelock];
                   
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.accountforshareduser.placeholder = @"被分享人账号";
                self.accountforshareduser.text = @"";
            });
        }break;
            
        case delshare:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ShareTableCellTableViewCell *cell = [self.shareTable cellForRowAtIndexPath:_selectpath];
                    NSString *textString = cell.sharedaccount.text;
                    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:textString];
                    [str addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0,textString.length)];
                    cell.sharedaccount.attributedText = str;
                });
            }
        }break;
        default:
            break;
    }
}

/*************表格式图协议函数************/
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datasrc.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellid = @"ShareTableCellTableViewCell";
    ShareTableCellTableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil)
    {
        [tableView registerNib:[UINib nibWithNibName:@"ShareTableCellTableViewCell" bundle:nil] forCellReuseIdentifier:cellid];
        cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    }
    cell.path = indexPath;
    cell.delegate = self;
    switch ([[[self.datasrc objectAtIndex:indexPath.row] objectForKey:@"keytype"] intValue]) {
        case 1:
        {
            cell.activetime.text = @"无限";
            cell.unlocktimes.text = [NSString stringWithFormat:@"%@/*",[self.datasrc[indexPath.row] objectForKey:@"usedtimes"]];
        }
            break;
        case 2:
        {
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"yyyyMMddHHmmss"];
            NSDate *end = [formatter dateFromString:[self.datasrc[indexPath.row] objectForKey:@"end_time"]];
            NSTimeInterval interval = [end timeIntervalSinceNow];
            if (interval < 0)
            {
                cell.activetime.text = @"0";
            }else
            {
                cell.activetime.text = [NSString stringWithFormat:@"%.1f",(interval < 0)?0.0:interval/3600];
            }
            cell.unlocktimes.text = [NSString stringWithFormat:@"%@/*",[self.datasrc[indexPath.row] objectForKey:@"usedtimes"]];;
        }
            break;

        case 3:
        {
    
            cell.activetime.text = @"无限";
            NSInteger used = [[self.datasrc[indexPath.row] objectForKey:@"usedtimes"] integerValue];
            NSInteger sharetimes = [[self.datasrc[indexPath.row] objectForKey:@"sharetimes"] integerValue];
            cell.unlocktimes.text = [NSString stringWithFormat:@"%li/%li",(long)used,(long)sharetimes];
        }
            break;

        case 4:
        {
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"yyyyMMddHHmmss"];
            NSDate *end = [formatter dateFromString:[self.datasrc[indexPath.row] objectForKey:@"end_time"]];
            NSTimeInterval interval = [end timeIntervalSinceNow];
            if (interval < 0)
            {
                cell.activetime.text = @"0";
            }else
            {
                cell.activetime.text = [NSString stringWithFormat:@"%.1f",(interval < 0)?0.0:interval/3600];
            }
            NSInteger used = [[self.datasrc[indexPath.row] objectForKey:@"usedtimes"] integerValue];
            NSInteger sharetimes = [[self.datasrc[indexPath.row] objectForKey:@"sharetimes"] integerValue];
            cell.unlocktimes.text = [NSString stringWithFormat:@"%li/%li",(long)used,(long)sharetimes];
        }
            break;
            
        default:
            break;
    }
    NSMutableString *time = [[[self.datasrc objectAtIndex:indexPath.row] objectForKey:@"begin_time"] mutableCopy];
    if ([time isEqualToString:@""])
    {
        cell.sharedtime.text = @"无限制";
    }else
    {
        [time insertString:@" " atIndex:8];
        [time insertString:@":" atIndex:11];
        [time insertString:@":" atIndex:14];
        cell.sharedtime.text = time;
    }
    NSString *phoneStr = [[self.datasrc objectAtIndex:indexPath.row] objectForKey:@"authmobile"];
    if ([[self.datasrc[indexPath.row] objectForKey:@"devstatus"] isEqualToString:@"1"])
    {
        cell.sharedaccount.text = phoneStr;
    }else
    {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:phoneStr];
        [str addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0,phoneStr.length)];
        cell.sharedaccount.attributedText = str;
    }
    return cell;
}

/*****************添加新分享*****************/
- (IBAction)addshareduser:(UIButton *)sender
{
    [self.accountforshareduser resignFirstResponder];
    if ([self.accountforshareduser.text isEqualToString:[self.userdefaults objectForKey:@"account"]])
    {
        [self textExample:@"不能分享密钥给自己"];
        return;
    }
    if([[self.managerlock maxshare] isEqualToString:[self.managerlock sharenum]])
    {
        //分享次数不足
        [self textExample:@"分享次数不足！"];
        return;
    }
    //选择分享类型
    if (![self.accountforshareduser.text isEqualToString:@""])
    {
        //http请求
        if (![CheckCharacter isValidateMobileNumber:self.accountforshareduser.text])
        {
            [self textExample:@"帐号格式有误！"];
            return;
        }
        //检测账号是否存在
        NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=checkaccount";
        NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&account=%@",self.accountforshareduser.text];
        [self.httppost httpPostWithurl :urlStr body:body type:checkaccount];
    }
}

- (void)textExample:(NSString*)str
{
        dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.superview animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = NSLocalizedString(str, @"");
        [hud.label setFont:[UIFont systemFontOfSize:12.0]];
        hud.offset = CGPointMake(0.f, 0.f);
        [hud hideAnimated:YES afterDelay:2.f];
    });
}

-(void)onGetDate:(NSString *)date type:(DateType)datetype
{
    switch (datetype) {
        case 0:
        {
            self.st_time = date;
        }
            break;
            
            
        case 1:
        {
            self.en_time = date;
        }
            break;
        default:
            break;
    }
}

-(void)confirm
{
   
    [self add:self.keytype.keytype :@[self.st_time,self.en_time] :self.keytype.effectimes.text];
}

-(void)cancel
{
   
    [self.keytype removeFromSuperview];
    self.keytype = nil;
}

-(void)addsharelock:(NSString*)beginTime :(NSString*)endTime :(NSString*)efftimes andType:(NSInteger)keytype
{
    NSString *nowdate = [self.formatter stringFromDate:[[NSDate alloc] init]];
    NSString *md5string = [NSString stringWithFormat:@"account=%@&apptoken=%@&authmobile=%@&devcode=%@&globalcode=%@&keytype=%li&oper_time=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                           [self.userdefaults objectForKey:@"account"],
                           [self.userdefaults objectForKey:@"appToken"],
                           self.accountforshareduser.text,
                           [[self.managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                           [self.managerlock globalcode],
                           (long)keytype, nowdate];
    NSString *sign = [MD5Code md5:md5string];
    NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=addshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@&authmobile=%@&keytype=%li&effectimes=%@&begin_time=%@&end_time=%@&oper_time=%@&sign=%@",
                        [self.userdefaults objectForKey:@"account"],
                        [self.userdefaults objectForKey:@"appToken"],
                        [self.managerlock globalcode],
                        [[self.managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                        self.accountforshareduser.text, (long)keytype, efftimes, beginTime, endTime, nowdate, sign];
    self.httppost.delegate = self;
    [self.httppost httpPostWithurl:urlStr type:addshare];
}

-(void)add:(NSInteger)keytype :(NSArray *)times :(NSString *) effectimes
{
    switch (keytype)
    {
        case 1:
        {
            [self addsharelock:@"" :@"" :@"0" andType:1];
            
        }
            break;
        
        case 2:
        {
            
            if ([times[0] isEqualToString:@""] || [times[1] isEqualToString:@""])
            {
                return;
            }
            [self addsharelock:times[0] :times[1] :@"0" andType:2];
        }
            break;
            
        case 3:
        {
            if ([effectimes isEqualToString:@""])
            {
                return;
            }
            [self addsharelock:@"" :@"" :effectimes andType:3];
        }
            break;
        
        case 4:
        {

            if ([times[0] isEqualToString:@""] || [times[1] isEqualToString:@""])
            {
                return;
            }
            if ([effectimes isEqualToString:@""]) {
                return;
            }
           [self addsharelock:times[0] :times[1] :effectimes andType:4];
        }
            break;
        default:
            break;
    }
    [self.keytype removeFromSuperview];
    self.keytype = nil;

}

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status
{
    if (!status)
    {
        [self textExample:@"连接蓝牙失败，删除不成功"];
        return;
    }
    NSMutableData* uuid_b = [[self NSStringConversionToNSData:[self.managerlock.uuid substringWithRange:NSMakeRange(0, 68)]] mutableCopy];
    NSData *authcode = [self NSStringConversionToNSData:self.deleteAuthcode.lastObject];
    [uuid_b appendData:authcode];
    self.appDelegate.appLibBleLock.delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.appDelegate.appLibBleLock bleDataSendRequest:macAddr cmd_type:libBleCmdDeleteSharerOpenLockUUID param_data:uuid_b];
    });
}

-(void)didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    switch (cmd_type) {
        case libBleCmdDeleteSharerOpenLockUUID:
        {
            [self.deleteAuthcode removeLastObject];
            if (result == libBleErrorCodeNone)
            {
                [self deleteUser];
                return;
            }
            if (self.deleteAuthcode.count != 0)
            {
                NSMutableData* uuid_b = [[self NSStringConversionToNSData:[self.managerlock.uuid substringWithRange:NSMakeRange(0, 68)]] mutableCopy];
                NSData *authcode = [self NSStringConversionToNSData:self.deleteAuthcode.lastObject];
                [uuid_b appendData:authcode];
                self.appDelegate.appLibBleLock.delegate = self;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.appDelegate.appLibBleLock bleDataSendRequest:macAddr cmd_type:libBleCmdDeleteSharerOpenLockUUID param_data:uuid_b];
                });
            }else
            {
                if ([[self.datasrc[_selectpath.row] objectForKey:@"usedtimes"] isEqualToString:@"0"])
                {
                    [self textExample:@"分享者用户还未绑定！"];
                    
                }else
                {
                    [self textExample:@"删除失败！"];
                }
            }
        }
            break;
            
        default:
            break;
    }
}

/************************删除分享者***********************/
-(void)deleteSharUser:(NSIndexPath *)path
{
    //http删除请求
    if (self.datasrc == nil || self.datasrc.count == 0)
    {
        return;
    }
    if (![[self.datasrc[path.row] objectForKey:@"devstatus"] isEqualToString:@"1"])
    {
        [self textExample:@"该分享已被取消，钥匙已失效!"];
        return;
    }
    self.deleteAuthcode = [self getAuthcode:[self.datasrc[path.row] objectForKey:@"devuserid"]].mutableCopy;
    _selectpath = path;
    NSMutableData* guid = [[self NSStringConversionToNSData:self.managerlock.globalcode] mutableCopy];
    NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleConnectRequest:mac];
}

-(void)deleteUser
{
    NSString *urlStr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=delshare&account=%@&apptoken=%@&globalcode=%@&devcode=%@&devuserid=%@&actstate=1",
                        [self.userdefaults objectForKey:@"account"],
                        [self.userdefaults objectForKey:@"appToken"],
                        [self.managerlock globalcode],
                        [[self.managerlock uuid] substringWithRange:NSMakeRange(68, 32)],
                        [[self.datasrc objectAtIndex:_selectpath.row] objectForKey:@"devuserid"]];
    self.httppost.delegate = self;
    [self.httppost httpPostWithurl:urlStr type:delshare];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - coredata

-(BOOL)isNewRecord:(NSString*)commucode
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SHARE];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"comucode=%@",commucode];
    [request setPredicate:predicate];
    NSArray *resultArr = [context executeFetchRequest:request error:nil];
    if (resultArr.count>0) {
        return NO;
    }
    return YES;
}

-(void)insertShareUserWithUser:(void(^)(ShareUser *user))insert
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    ShareUser *user = [NSEntityDescription insertNewObjectForEntityForName:SHARE inManagedObjectContext:context];
    insert(user);
    [context performBlockAndWait:^{
        [context save:nil];
    }];
}

-(void)updateUser:(NSString*)commucode withChange:(void(^)(ShareUser *user))update
{
    if (commucode.length == 0)
    {
        return;
    }
    NSManagedObjectContext *context = self.appDelegate.privateContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SHARE];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"comucode=%@",commucode];
    [request setPredicate:predicate];
    __weak __block ShareUser *user;
    [context performBlockAndWait:^{
        __strong typeof(user) strongUser = user;
        strongUser = [[context executeFetchRequest:request error:nil] lastObject];
        if (strongUser)
        {
            update(strongUser);
            [context save:nil];
            [context.parentContext performBlock:^{
                [context.parentContext save:nil];
            }];
        }
    }];
}

-(NSArray*)getAuthcode:(NSString*)devuserid
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SHARE];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"devuserid=%@",devuserid];
    [request setPredicate:predicate];
    __block ShareUser *user;
    [context performBlockAndWait:^{
        user = [[context executeFetchRequest:request error:nil] lastObject];
    }];
    return user.authcode;
}

-(BOOL)isExsistingUser:(NSString *)authcode inArray:(NSArray*)array
{
    for (NSString *string in array)
    {
        if ([string isEqualToString:authcode])
        {
            return YES;
        }
    }
    return NO;
}
@end
