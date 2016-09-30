//
//  SharedLock.m
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "SharedLock.h"
#import "CellForSharedLock.h"
#import "CellForUnlock.h"
#import "CellForSharedmanage.h"
#import "MBProgressHUD.h"
#import "HTTPPost.h"
#import "MJRefresh.h"

@interface SharedLock ()<HTTPPostDelegate>
{
    NSIndexPath *selectedCell;
    BOOL isbind;
    httpPostType _posttype;
}
@property (strong,nonatomic) HTTPPost *httppost;
@end

@implementation SharedLock

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.appLibBleLock._delegate = self;
    _isEdit = 0;
    isbind = 0;
    self.title = @"云盾锁";
    _tabView = [[UITableView alloc] initWithFrame:CGRectMake(20, 120 + 5 ,self.view.bounds.size.width-40,self.view.bounds.size.height- 120 - 5 - 60)style:UITableViewStylePlain];//数据视图的大小
    [_tabView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tabView.delegate = self;
    _tabView.dataSource = self;
    _tabView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_tabView];
    _dataSrc = [NSMutableArray array];//创建一个可变数组来存放单元的数据
    _httppost = _appDelegate.delegatehttppost;
    
    self.tabView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(getNewShareLock)];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loaddatasrc];
    _httppost.delegate = self;
    //获取新分享锁
    [self getNewShareLock];
}

-(void)loaddatasrc
{
    [_dataSrc removeAllObjects];
    [_datasrcdata removeAllObjects];
    _datasrcdata = [NSMutableArray arrayWithArray:[self showAllShareLock]];
    CellForSharedLock* cell0 = [[[NSBundle  mainBundle]  loadNibNamed:@"CellForSharedLock" owner:self options:nil]  lastObject];
    for (int i = 0; i < [_datasrcdata count]; i++) {
        [_dataSrc addObject:cell0];
    }

}


-(void)getNewShareLock
{
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=getnewshare&account=%@&apptoken=%@&mobile=%@",[self.userdefaults objectForKey:@"account"],
                       [self.userdefaults objectForKey:@"appToken"],
                       [[[self.userdefaults objectForKey:@"account"] mutableCopy] substringWithRange:NSMakeRange(0, 11)]];
    _posttype = getnewshare;
    [_httppost httpPostWithurl:urlStr];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    switch (_posttype) {
        case getnewshare:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tabView.mj_header endRefreshing];
            });
            
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                NSArray <NSDictionary*>* data = [dic objectForKey:@"data"];
                for (NSDictionary *lock in data)
                {
                    if ([self isNewLock:[[lock objectForKey:@"globalcode"] lowercaseString]])
                    {
                        [self insertLock:^(SmartLock *device) {
                            device.devuserid = [lock objectForKey:@"devuserid"];
                            device.globalcode = [[lock objectForKey:@"globalcode"] lowercaseString];
                            device.uuid = [lock objectForKey:@"uuidd"];
                            device.authcode = [lock objectForKey:@"authcode"];
                            device.comucode = [lock objectForKey:@"comucode"];
                            device.devname = [lock objectForKey:@"devname"];
                            device.managename = [lock objectForKey:@"managename "];
                            device.ismaster = @"0";
                            device.keytype = [lock objectForKey:@"keytype"];
                            device.effectimes = [lock objectForKey:@"effectimes"];
                            device.begin_time = [lock objectForKey:@"begin_time"];
                            device.end_time = [lock objectForKey:@"end_time"];
                            
                            device.productdate = @"获取失败";
                            device.warrantydate = @"获取失败";
                            device.sharenum = @"0";
                            device.maxshare = @"15";
                            device.distance = @"0.0";
                            device.battery = @"0";
                            device.isactive = [NSNumber numberWithBool:NO];
                            device.istoppage = [NSNumber numberWithBool:NO];
                            device.isautounlock = [NSNumber numberWithBool:NO];
                            device.oper_time = [[NSDate alloc] init];
                            device.isdeleted = @"nodeleted";
                        }];
                    }else
                    {
                        [self updateLockMsg:[[lock objectForKey:@"globalcode"] lowercaseString] withupdate:^(SmartLock *device) {
                            device.uuid = [lock objectForKey:@"uuidd"];
                            device.authcode = [lock objectForKey:@"authcode"];
                            device.comucode = [lock objectForKey:@"comucode"];
                            
                            device.isactive = [NSNumber numberWithBool:NO];
                            device.isdeleted = @"nodeleted";
                        }];
                    }
                    __weak SharedLock *wkSelf = self;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [wkSelf loaddatasrc];
                        [wkSelf.tabView reloadData];
                    });
                }
            }
        }
            break;
            
        default:
            break;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return _dataSrc.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell =  [_tabView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    id obj = [_dataSrc objectAtIndex:indexPath.row];
    if ([obj isKindOfClass:[CellForSharedLock class]])
    {
        CellForSharedLock *cell0 = (CellForSharedLock *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForSharedLock" owner:self options:nil]  lastObject];
        cell0.delegate = self;
        cell0.path = indexPath;
        
        
        NSString *na = [NSString stringWithFormat:@"名称:%@",[_datasrcdata[indexPath.row] devname]];
        cell0.name.text = na;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMdd HH:mm:ss"];
        NSString *strDate = [NSString stringWithFormat:@"时间:%@",[dateFormatter stringFromDate:[_datasrcdata[indexPath.row] oper_time]]];
        
        cell0.time.text = strDate;
        
        cell = cell0;
        
    }else if ([obj isKindOfClass:[CellForUnlock class]])
    {
        //被分享者开锁
        CellForUnlock *cell0 = (CellForUnlock *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForUnlock" owner:self options:nil]  lastObject];
        cell0.path = indexPath;
        cell0.ismaster = 0;
        
        cell0.globalcode = [_datasrcdata[indexPath.row-1] globalcode];
        cell0.devcode = [_datasrcdata[indexPath.row-1] uuid] ;
        cell0.authcode = [_datasrcdata[indexPath.row-1] authcode];
        cell0.comucode = [_datasrcdata[indexPath.row-1] comucode];
        cell0.isactive = [[_datasrcdata[indexPath.row-1] isactive] boolValue];
        cell = cell0;
        
    }else if ([obj isKindOfClass:[CellForSharedmanage class]])
    {
        CellForSharedmanage *cell0 = (CellForSharedmanage *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForSharedmanage" owner:self options:nil]  lastObject];
        cell0.path = indexPath;
        cell0.name.text = [NSString stringWithFormat:@"名称: %@",[_datasrcdata[indexPath.row-1] devname]];
        cell0.sharelock = _datasrcdata[indexPath.row-1];
        
        cell0.distance.value = [[_datasrcdata[indexPath.row-1] distance] floatValue];
        
        if ([[_datasrcdata[indexPath.row-1] keytype] integerValue]%2 == 0) {

            
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"yyyyMMddHHmmss"];
            NSDate *end = [formatter dateFromString:[_datasrcdata[indexPath.row-1] end_time]];
            NSTimeInterval interval = [end timeIntervalSinceNow];
            cell0.activetime.text = [NSString stringWithFormat:@"开锁时限: %.1f小时",interval/3600.0 < 0.0 ?0.0:interval/3600.0];

        }else
        {
            cell0.activetime.text = @"开锁时限: 无限";
        }
        
        if ([[_datasrcdata[indexPath.row-1] keytype] integerValue] > 2)
        {
            cell0.countforunlock.text = [NSString stringWithFormat:@"开锁次数: %@",[_datasrcdata[indexPath.row-1] effectimes]];
        }else
        {
            cell0.countforunlock.text = @"开锁次数: 无限";
        }
        
        if ([_datasrcdata[indexPath.row-1] begin_time].length == 14)
        {
            NSMutableString *date = [[_datasrcdata[indexPath.row-1] begin_time] mutableCopy];
            [date insertString:@" " atIndex:8];
            [date insertString:@":" atIndex:11];
            [date insertString:@":" atIndex:14];
            cell0.date.text = [NSString stringWithFormat:@"分享日期: %@",date];
        }else
        {
            cell0.date.text = [NSString stringWithFormat:@"分享日期: %@",[_datasrcdata[indexPath.row-1] begin_time]];
        }
        
        cell0.namager.text = [NSString stringWithFormat:@"管理员: %@",[_datasrcdata[indexPath.row-1] managename]];
        NSInteger battery = [[_datasrcdata[indexPath.row-1] battery] integerValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (battery <= 100 && battery > 75)
            {
                [cell0.battery setImage:[UIImage imageNamed:@"battery100.png"]];
                return;
            }
            if (battery <= 75 && battery > 50)
            {
                [cell0.battery setImage:[UIImage imageNamed:@"battery75.png"]];
                return;
            }
            if (battery <= 50 && battery > 25)
            {
                [cell0.battery setImage:[UIImage imageNamed:@"battery50.png"]];
                return;
            }
            if (battery >= 25 && battery > 10)
            {
                [cell0.battery setImage:[UIImage imageNamed:@"battery25.png"]];
                return;
            }
            if (battery < 10)
            {
                [cell0.battery setImage:[UIImage imageNamed:@"battery0.png"]];
                return;
            }
        });
        cell = cell0;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    id obj = [_dataSrc objectAtIndex:indexPath.row];
    if ([obj isKindOfClass:[CellForSharedLock class]]) {
        return 50.0;
    }else if([obj isKindOfClass:[CellForUnlock class]]){
        return 250.0;
    }else
    return 315.0;
}


//头部按钮点击回调
-(void)changeTag:(NSInteger)btnTag :(NSIndexPath *)indexPath{

    while (selectedCell.row != indexPath.row)
    {
        if (_dataSrc.count != [_datasrcdata count])
        {
            self.alert = [UIAlertController alertControllerWithTitle:@"警告！" message:@"您一次只能管理一个云盾锁！" preferredStyle:UIAlertControllerStyleAlert];
            [self.alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:self.alert animated:YES completion:nil];
            });
            return;
        }else
        {
            selectedCell = indexPath;
        }
    }
    selectedCell = indexPath;
    switch (btnTag) {
        case 1:{
            _isEdit = !_isEdit;
            CellForSharedmanage* cell = (CellForSharedmanage *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForSharedmanage" owner:self options:nil]  lastObject];
            if (_isEdit == 1) {
                
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
//                               {
//                                   NSData *guid = [self NSStringConversionToNSData:[_datasrcdata[indexPath.row] globalcode]];
//                                   NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
//                                   [_appDelegate.appLibBleLock bleConnectRequest:mac forbattery:YES];
//                               });

                [_dataSrc insertObject:cell atIndex:indexPath.row+1];
                [_tabView reloadData];
                
            }else
            {
                NSData *guid = [self NSStringConversionToNSData:[_datasrcdata[indexPath.row] globalcode]];
                NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
                [_appDelegate.appLibBleLock bleDisconnectRequest:mac];
                [_dataSrc removeObjectAtIndex:indexPath.row+1];
                [_tabView reloadData];
            }
            break;
        }
        case 2:{
            if (_isEdit == 0) {//编辑状态不允许删除
                [self updateLockMsg:[_datasrcdata[indexPath.row] globalcode] withupdate:^(SmartLock *device) {
                    device.isdeleted = [device begin_time];
                }];
                [_datasrcdata removeObjectAtIndex:indexPath.row];
                [_dataSrc removeObjectAtIndex:indexPath.row];
                [_tabView reloadData];
            }
            break;
        }
        case 3:{
            _isEdit = !_isEdit;
                       
            if (_isEdit == 1) {
                NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat: @"yyyyMMddHHmmss"];
                NSDate *end = [formatter dateFromString:[_datasrcdata[indexPath.row] end_time]];
                NSTimeInterval interval = [end timeIntervalSinceNow];
                if (interval<=0 && [[_datasrcdata[indexPath.row] keytype]integerValue]%2 == 0) {
                    //密钥过期
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您没有权限" message:@"密钥已过期" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    }]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:alert animated:true completion:nil];
                    });
                    _isEdit = !_isEdit;
                }else if([[_datasrcdata[indexPath.row] effectimes] integerValue] < 1 && [[_datasrcdata[indexPath.row] keytype] integerValue] > 2){
                    //开锁次数为零不能开锁
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您没有权限" message:@"密钥使用次数不足" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    }]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:alert animated:true completion:nil];
                    });
                    _isEdit = !_isEdit;
                }else if([[_datasrcdata[indexPath.row] isactive] boolValue])
                {
            
                    CellForUnlock* cell = (CellForUnlock *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForUnlock" owner:self options:nil]  lastObject];
                    [_dataSrc insertObject:cell atIndex:indexPath.row+1];
                    [_tabView reloadData];
                    
                }else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self textExample];
                    });
                    _isEdit = !_isEdit;
                }
            }else
            {
                NSData *guid = [self NSStringConversionToNSData:[_datasrcdata[indexPath.row] globalcode]];
                NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
                [_appDelegate.appLibBleLock bleDisconnectRequest:mac];
                [_dataSrc removeObjectAtIndex:indexPath.row+1];
                [_tabView reloadData];
            }
            break;
        }
        default:
            break;
    }
}

- (void)textExample
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:_tabView animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(@"无法操作，点击“分享申请”获取权限", @"title2");
    [hud.label setFont:[UIFont systemFontOfSize:12.0]];
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:2.f];
}

//蓝牙协议空实现，其他页面跳转至此页面时，蓝牙任务未完成需要
-(void)didDiscoverComplete{}

-(void)didDisconnectIndication:(NSData *)macAddr{}

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status{}

-(void)didGetBattery:(NSInteger)battery forMac:(NSData *)mac{}

-(void) goBack
{
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


@end

//@implementation NSString(NSStringDebug)
//
//-(void)objectForKey:(NSString*) str
//{
//    NSLog(@"%@",str);
//    assert(NO);
//
//
//}
//
//@end
