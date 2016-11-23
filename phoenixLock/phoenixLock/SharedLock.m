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
    BOOL _isOpenningLock;
}
@property (strong,nonatomic) HTTPPost *httppost;
@end

@implementation SharedLock

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isEdit = 0;
    isbind = 0;
    self.title = @"云盾锁";
    self.tabView = [[UITableView alloc] initWithFrame:CGRectMake(20, 120 + 5 ,self.view.bounds.size.width-40,self.view.bounds.size.height- 120 - 5 - 60)style:UITableViewStylePlain];//数据视图的大小
    [self.tabView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tabView.delegate = self;
    self.tabView.dataSource = self;
    self.tabView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tabView];
    self.dataSrc = [NSMutableArray array];//创建一个可变数组来存放单元的数据
    self.tabView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(getNewShareLock)];
    [self loaddatasrc];
    self.httppost = self.appDelegate.delegatehttppost;
    //获取新分享锁
    self.httppost.delegate = self;
    [self getNewShareLock];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeUnlockView) name:@"closeUnlockPage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopTimers) name:@"stopSearch" object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    SENDNOTIFY(@"closeProgress")
     self.httppost.delegate = self;
    [self.appDelegate.searchTimer setFireDate:[NSDate distantFuture]];
    self.appDelegate.appLibBleLock.delegate = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.appDelegate.searchLock = NO;
    [self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
}

-(void)stopTimers
{
    self.appDelegate.searchLock = YES;
}

-(void)loaddatasrc
{
    if (self.datasrcdata)
    {
        [self.dataSrc removeAllObjects];
        [self.datasrcdata removeAllObjects];
    }
    self.datasrcdata = [NSMutableArray arrayWithArray:[self showAllShareLockByGlobalcode:NO]];
    for (int i = 0; i < [self.datasrcdata count]; i++) {
        [self.dataSrc addObject:@"CellForSharedLock"];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabView reloadData];
    });
}


-(void)getNewShareLock
{
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=getnewshare&account=%@&apptoken=%@&mobile=%@",[self.userdefaults objectForKey:@"account"],
                       [self.userdefaults objectForKey:@"appToken"],
                       [[[self.userdefaults objectForKey:@"account"] mutableCopy] substringWithRange:NSMakeRange(0, 11)]];
    
    [self.httppost httpPostWithurl:urlStr type:getnewshare];
    [self.tabView.mj_header performSelector:@selector(endRefreshing) withObject:nil afterDelay:3.0f];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case getnewshare:
        {
            if (![[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                [self.tabView.mj_header endRefreshing];
                return;
            }

            NSArray <NSDictionary*>* data = [dic objectForKey:@"data"];
            if (data.count == 0)
            {
                [self.tabView.mj_header endRefreshing];
                return;
            }
            for (NSDictionary *lock in data)
            {
                [self clearExpireLock:lock[@"globalcode"]];
                if ([self isNewLockWithDevuserid:[lock objectForKey:@"devuserid"]])
                {
                    [self insertLock:^(SmartLock *device) {
                        device.devuserid = [lock objectForKey:@"devuserid"];
                        device.globalcode = [lock objectForKey:@"globalcode"];
                        device.uuid = [lock objectForKey:@"uuidd"];
                        device.authcode = [lock objectForKey:@"authcode"];
                        device.comucode = [lock objectForKey:@"comucode"];
                        device.devname = [lock objectForKey:@"devname"];
                        device.managename = [lock objectForKey:@"managename"];
                        device.ismaster = @"0";
                        device.keytype = [lock objectForKey:@"keytype"];
                        device.effectimes = [lock objectForKey:@"effectimes"];
                        device.begin_time = [lock objectForKey:@"begin_time"];
                        device.end_time = [lock objectForKey:@"end_time"];
                        device.sharetimes = [lock objectForKey:@"effectimes"];
                        device.usedtimes = @"0";
                        device.status = @"1";
                        device.productdate = @"";
                        device.warrantydate = @"";
                        device.sharenum = @"0";
                        device.maxshare = @"15";
                        device.distance = @"0.0";
                        device.battery = @"100";
                        device.isactive = [NSNumber numberWithBool:NO];
                        device.istoppage = [NSNumber numberWithBool:NO];
                        device.isautounlock = [NSNumber numberWithBool:NO];
                        device.oper_time = [[NSDate alloc] init];
                        device.isdeleted = @"nodeleted";
                        }];
                }else
                {
                    [self updateLockMsg:[lock objectForKey:@"devuserid"] withupdate:^(SmartLock *device) {
                        device.uuid = [lock objectForKey:@"uuidd"];
                        device.authcode = [lock objectForKey:@"authcode"];
                        device.comucode = [lock objectForKey:@"comucode"];
                        device.status = @"1";
                        device.keytype = [lock objectForKey:@"keytype"];
                        device.begin_time = [lock objectForKey:@"begin_time"];
                        device.end_time = [lock objectForKey:@"end_time"];
                    }];
                }
                [self loaddatasrc];
                [self.tabView.mj_header endRefreshing];
            }
        }
            break;
            
        default:
            break;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.dataSrc.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *obj = [self.dataSrc objectAtIndex:indexPath.row];
    if ([obj isEqualToString:@"CellForSharedLock"])
    {
        static NSString *CellForSharedLockId = @"CellForSharedLock";
        CellForSharedLock *cell = [tableView dequeueReusableCellWithIdentifier:CellForSharedLockId];
        if (!cell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"CellForSharedLock" bundle:nil] forCellReuseIdentifier:CellForSharedLockId];
            cell = [tableView dequeueReusableCellWithIdentifier:CellForSharedLockId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.delegate = self;
        cell.path = indexPath;
        NSInteger index = indexPath.row;
        if (selectedCell != nil && index > selectedCell.row)
        {
            index -= 1;
        }
        cell.name.text = [NSString stringWithFormat:@"云盾锁名称: %@",[self.datasrcdata[index] devname]];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM.dd HH:mm"];
        NSString *strDate = [NSString stringWithFormat:@"时间:%@",[dateFormatter stringFromDate:[self.datasrcdata[index] oper_time]]];
        cell.time.text = strDate;
        return cell;

    }
    
    if ([obj isEqualToString:@"CellForUnlock"])
    {
        //被分享者开锁
        static NSString *CellForUnlockId = @"CellForUnlock";
        CellForUnlock *cell = [tableView dequeueReusableCellWithIdentifier:CellForUnlockId];
        if (!cell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"CellForUnlock" bundle:nil] forCellReuseIdentifier:CellForUnlockId];
            cell = [tableView dequeueReusableCellWithIdentifier:CellForUnlockId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.ismaster = 0;
        cell.globalcode = [self.datasrcdata[indexPath.row-1] globalcode];
        cell.devcode = [self.datasrcdata[indexPath.row-1] uuid] ;
        cell.authcode = [self.datasrcdata[indexPath.row-1] authcode];
        cell.comucode = [self.datasrcdata[indexPath.row-1] comucode];
        cell.isactive = [[self.datasrcdata[indexPath.row-1] isactive] boolValue];
        cell.devuserid = [self.datasrcdata[indexPath.row-1] devuserid];
        return cell;
    }
    
    if ([obj isEqualToString:@"CellForSharedmanage"])
    {
        static NSString *CellForSharedmanageId = @"CellForSharedmanage";
        CellForSharedmanage *cell = [tableView dequeueReusableCellWithIdentifier:CellForSharedmanageId];
        if (!cell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"CellForSharedmanage" bundle:nil] forCellReuseIdentifier:CellForSharedmanageId];
            cell = [tableView dequeueReusableCellWithIdentifier:CellForSharedmanageId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.path = indexPath;
        cell.name.text = [NSString stringWithFormat:@"名称: %@",[self.datasrcdata[indexPath.row-1] devname]];
        cell.sharelock = self.datasrcdata[indexPath.row-1];
        cell.distance.value = [[self.datasrcdata[indexPath.row-1] distance] floatValue];
        if ([[self.datasrcdata[indexPath.row-1] keytype] integerValue]%2 == 0)
        {
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"yyyyMMddHHmmss"];
            NSDate *end = [formatter dateFromString:[self.datasrcdata[indexPath.row-1] end_time]];
            NSTimeInterval interval = [end timeIntervalSinceNow];
            cell.activetime.text = [NSString stringWithFormat:@"开锁时限: %.1f小时",interval/3600.0 < 0.0 ?0.0:interval/3600.0];
        }else
        {
            cell.activetime.text = @"开锁时限: 无限";
        }
        NSInteger usedtimes = [[self.datasrcdata[indexPath.row-1] usedtimes] integerValue];
        NSInteger sharetimes = [[self.datasrcdata[indexPath.row-1] sharetimes] integerValue];
        if ([[self.datasrcdata[indexPath.row-1] keytype] integerValue] > 2)
        {
            cell.countforunlock.text = [NSString stringWithFormat:@"开锁次数: %li/%li",(long)usedtimes,(long)sharetimes];
        }else
        {
            cell.countforunlock.text = [NSString stringWithFormat:@"开锁次数: %li/*",(long)usedtimes];
        }
        
        if ([self.datasrcdata[indexPath.row-1] begin_time].length == 14)
        {
            NSMutableString *date = [[self.datasrcdata[indexPath.row-1] begin_time] mutableCopy];
            [date insertString:@" " atIndex:8];
            [date insertString:@":" atIndex:11];
            [date insertString:@":" atIndex:14];
            cell.date.text = [NSString stringWithFormat:@"分享日期: %@",date];
        }else
        {
            cell.date.text = [NSString stringWithFormat:@"分享日期: %@",@"不限"];
        }
        cell.namager.text = [NSString stringWithFormat:@"管理员: %@",[self.datasrcdata[indexPath.row-1] managename]];
        NSInteger battery = [[self.datasrcdata[indexPath.row-1] battery] integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (battery <= 100 && battery > 75)
            {
                [cell.battery setImage:[UIImage imageNamed:@"battery100.png"]];
                return;
            }
            if (battery <= 75 && battery > 50)
            {
                [cell.battery setImage:[UIImage imageNamed:@"battery75.png"]];
                return;
            }
            if (battery <= 50 && battery > 25)
            {
                [cell.battery setImage:[UIImage imageNamed:@"battery50.png"]];
                return;
            }
            if (battery >= 25 && battery > 10)
            {
                [cell.battery setImage:[UIImage imageNamed:@"battery25.png"]];
                return;
            }
            if (battery < 10)
            {
                [cell.battery setImage:[UIImage imageNamed:@"battery0.png"]];
                return;
            }
        });
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *obj = [self.dataSrc objectAtIndex:indexPath.row];
    if ([obj isEqualToString:@"CellForSharedLock"]) {
        return 50.0;
    }else if([obj isEqualToString:@"CellForUnlock"]){
        return 250.0;
    }else
    return 315.0;
}

//头部按钮点击回调
-(void)changeTag:(NSInteger)btnTag :(NSIndexPath *)indexPath
{
    if (_isOpenningLock)
    {
        [self textExample:@"请等待开锁完成"];
        return;
    }
    if (btnTag == 3)
    {
        if (self.dataSrc.count > self.datasrcdata.count)
        {
            self.isEdit = !self.isEdit;
            selectedCell = nil;
            [self.dataSrc removeObjectAtIndex:indexPath.row+1];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tabView reloadData];
            });
            //return;
        }
        [self openLock:indexPath];
        return;
    }
    self.isEdit = !self.isEdit;
    if ((selectedCell.row != indexPath.row && selectedCell != nil) || (selectedCell.row == indexPath.row && selectedCell != nil && btnTag == 2))
    {
        //关闭之前的页面
        [self.dataSrc removeObjectAtIndex:selectedCell.row+1];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tabView reloadData];
        });
        selectedCell = nil;
        return;
    }
    selectedCell = indexPath;
    if (self.isEdit == YES)
    {
        [self updateLockMsg:[self.datasrcdata[indexPath.row] devuserid] withupdate:^(SmartLock *device) {
            device.oper_time = [[NSDate alloc] init];
        }];
    }
    switch (btnTag)
    {
        case 1:{
            if (self.isEdit == YES)
            {
                [self updateLockMsg:[self.datasrcdata[indexPath.row] devuserid] withupdate:^(SmartLock *device) {
                    device.oper_time = [[NSDate alloc] init];
                }];
                [self.dataSrc insertObject:@"CellForSharedmanage" atIndex:indexPath.row+1];
                [self.tabView reloadData];
                
            }else
            {
                NSData *guid = [self NSStringConversionToNSData:[self.datasrcdata[indexPath.row] globalcode]];
                NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
                self.appDelegate.appLibBleLock.delegate = self;
                [self.appDelegate.appLibBleLock bleDisconnectRequest:mac];
                [self.dataSrc removeObjectAtIndex:indexPath.row+1];
                [self.tabView reloadData];
                selectedCell = nil;
            }
            break;
        }
        case 2:
        {
            self.isEdit = !self.isEdit;
            if (self.isEdit == NO)
            {//编辑状态不允许删除
                [self updateLockMsg:[self.datasrcdata[indexPath.row] devuserid] withupdate:^(SmartLock *device) {
                    device.isdeleted = @"diddeleted";
                }];
                [self.datasrcdata removeObjectAtIndex:indexPath.row];
                [self.dataSrc removeObjectAtIndex:indexPath.row];
                [self.tabView reloadData];
            }
            selectedCell = nil;
        }
            break;
        default:
            break;
    }
}

-(void)openLock:(NSIndexPath*)indexPath
{
    if (![[self.datasrcdata[indexPath.row] status] isEqualToString:@"1"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"您无法使用，密钥已作废"];
        });
        selectedCell = nil;
        self.isEdit = !self.isEdit;
        return;
    }
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyyMMddHHmmss"];
    NSDate *end = [formatter dateFromString:[self.datasrcdata[indexPath.row] end_time]];
    NSTimeInterval interval = [end timeIntervalSinceNow];
    if (interval<=0 && [[self.datasrcdata[indexPath.row] keytype]integerValue]%2 == 0)
    {
        //密钥过期
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"您没有权限，密钥已过期"];
        });
        return;
    }
    
    if([[self.datasrcdata[indexPath.row] effectimes] integerValue] < 1 && [[self.datasrcdata[indexPath.row] keytype] integerValue] > 2){
        //开锁次数为零不能开锁
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"您没有权限，密钥使用次数不足"];
        });
        return;
    }
    
    if([[self.datasrcdata[indexPath.row] isactive] boolValue])
    {
        //正常开锁
        selectedCell = indexPath;
        _isOpenningLock = YES;
        [self.dataSrc insertObject:@"CellForUnlock" atIndex:indexPath.row+1];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tabView reloadData];
        });
    }else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self textExample:@"无法操作，点击“分享申请”获取权限"];
        });
    }
}

-(void)closeUnlockView
{
    if (self.datasrcdata.count == self.dataSrc.count)
    {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _isOpenningLock = NO;
        selectedCell = nil;
        [self.dataSrc removeObject:@"CellForUnlock"];
        [self.tabView reloadData];
    });
}

-(void)clearExpireLock:(NSString*)globalcode
{
    NSManagedObjectContext *context = self.appDelegate.privateContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCKS];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"globalcode=%@",globalcode];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"ismaster=0"];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
    [request setPredicate:predicate];
    NSArray <SmartLock*> *locks = [context executeFetchRequest:request error:nil];
    if (locks.count == 0)
    {
        return;
    }
    for (SmartLock *lock in locks)
    {
        [context performBlock:^{
            [context deleteObject:lock];
        }];
    }
    [context performBlock:^{
        [context save:nil];
        [context.parentContext performBlock:^{
            [context.parentContext save:nil];
        }];
    }];
}

- (void)textExample:(NSString*)text
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tabView animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(text, @"title2");
    [hud.label setFont:[UIFont systemFontOfSize:12.0]];
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:2.f];
}

-(void) goBack
{
    if (selectedCell) {
        NSData *globalcode = [self NSStringConversionToNSData:[self.datasrcdata[selectedCell.row] globalcode]];
        NSData *mac = [globalcode.mutableCopy subdataWithRange:NSMakeRange(0, 6)];
        [self.appDelegate.appLibBleLock bleDisconnectRequest:mac];
    }
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

