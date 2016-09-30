//
//  ManageLock.m
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ManageLock.h"
#import "CellForShare.h"
#import "CellForUnlock.h"
#import "MD5Code.h"
@interface ManageLock ()<HTTPPostDelegate>
{
    NSIndexPath *selectedCell;
    httpPostType _type;
    BOOL canmanage;
}
@property (strong,nonatomic) HTTPPost *httppost;

@end

@implementation ManageLock

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _isEdit = 0;
    self.title = @"云盾锁";
    
    //****************添加数据视图*************
    _tabView = [[UITableView alloc] initWithFrame:CGRectMake(20, 120 + 5 ,  self.view.bounds.size.width - 40,  self.view.bounds.size.height - 120 - 5 - 60) style:UITableViewStylePlain];//数据视图的大小
    [_tabView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tabView.delegate = self;
    _tabView.dataSource = self;
    _tabView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_tabView];
    
    //****************初始化数据源*************
    _dataSrc = [[NSMutableArray alloc] init];//创建一个可变数组来存放单元的数据
    _datasrcdata = [NSArray arrayWithArray:[self showAllManagerLock]];
    CellForManageHeader* cell0 = (CellForManageHeader *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForManageHeader" owner:self options:nil]  lastObject];
    for (int i = 0; i < [_datasrcdata count]; i++) {
        [_dataSrc addObject:cell0];
    }
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _appDelegate.appLibBleLock._delegate = self;
    //数据同步
    [self syndata];
  
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
   
}

-(void)syndata
{
    if (![HTTPPost isConnectionAvailable])
    {
        canmanage = YES;
        return;
    }
    canmanage = NO;
    _httppost.delegate = self;
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyyMMddHHmmss"];
    
    NSString *opertime = [formatter stringFromDate:[[NSDate alloc] init]];
    
    NSString *str = [NSString stringWithFormat:@"account=%@&apptoken=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",[self.userdefaults objectForKey:@"account"],
                     [self.userdefaults objectForKey:@"appToken"],opertime,
                     [self.userdefaults objectForKey:@"uuid"]];
    
    NSString *sign = [MD5Code md5:str];
    
    NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=getdevlist&account=%@&apptoken=%@&uuid=%@&oper_time=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe&sign=%@",[self.userdefaults objectForKey:@"account"],
                       [self.userdefaults objectForKey:@"appToken"],
                       [self.userdefaults objectForKey:@"uuid"],opertime,sign];
    _type = getdevlist;
    [_httppost httpPostWithurl:urlStr];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    
    if ([[dic objectForKey:@"status"] integerValue] != 1) {
        canmanage = YES;
        return;
    }
    
    switch (_type)
    {
        case getdevlist:
        {
            canmanage = YES;
            
            NSArray *data = [dic objectForKey:@"data"];
            for (NSDictionary *lock in data)
            {
                [self updateLockMsg:[lock objectForKey:@"globalcode"] withupdate:^(SmartLock *device) {
                    
                    device.productdate = [lock objectForKey:@"productdate"];
                    device.warrantydate = [lock objectForKey:@"warrantydate"];
                    device.maxshare = [lock objectForKey:@"maxshare"];
                    device.sharenum = [lock objectForKey:@"sharenum"];
                    device.battery = [lock objectForKey:@"battery"];
                    device.distance = [lock objectForKey:@"distance"];
                }];
            }
            _datasrcdata = [NSArray arrayWithArray:[self showAllManagerLock]];
        }
            break;
            
        default:
            break;
    }
}

/****************表格视图的协议函数***************/

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
    if ([obj isKindOfClass:[CellForManageHeader class]])
    {
        CellForManageHeader *cell0 = (CellForManageHeader *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForManageHeader" owner:self options:nil]  lastObject];
        cell0.delegate = self;
        cell0.path = indexPath;
        cell0.name.text = [_datasrcdata[indexPath.row] devname];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMdd HH:mm:ss"];
        NSString *strDate = [NSString stringWithFormat:@"时间:%@",[dateFormatter stringFromDate:[_datasrcdata[indexPath.row] oper_time]]];
        cell0.time.text = strDate;
        cell = cell0;
        
    }else if ([obj isKindOfClass:[CellFormanageFooder class]])
    {
        CellFormanageFooder *cell0 = (CellFormanageFooder *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellFormanageFooder" owner:self options:nil]  lastObject];
        cell0.managerlock = _datasrcdata[indexPath.row-1];
        cell0.delegate = self;
        cell0.path = indexPath;
        cell0.name.text = [_datasrcdata[indexPath.row-1] devname];
        cell0.showsharednum.text = [NSString stringWithFormat:@"分享数量:%@/%@",[_datasrcdata[indexPath.row-1] sharenum],[_datasrcdata[indexPath.row-1] maxshare]];
        cell0.dateofmanu.text = [NSString stringWithFormat:@"生产日期: %@",[_datasrcdata[indexPath.row-1] productdate]];
        cell0.dateofwarranty.text = [NSString stringWithFormat:@"保修日期: 至%@",[_datasrcdata[indexPath.row-1] warrantydate]];
        
        cell0.lockNO.text = [NSString stringWithFormat:@"云盾锁编号: %@",[_datasrcdata[indexPath.row-1] devuserid]];
        cell0.distance.value = [[_datasrcdata[indexPath.row-1] distance] floatValue];
        
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
        
    }else if ([obj isKindOfClass:[CellForShare class]])
    {
        CellForShare *cell0 = (CellForShare *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForShare" owner:self options:nil]  lastObject];
        cell0.path = indexPath;
         cell0.managerlock = _datasrcdata[indexPath.row-1];
        cell = cell0;
    }else if ([obj isKindOfClass:[CellForUnlock class]])
    {
        CellForUnlock *cell0 = (CellForUnlock *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForUnlock" owner:self options:nil]  lastObject];
        cell0.ismaster = 1;
        cell0.path = indexPath;
        
        cell0.globalcode = [_datasrcdata[indexPath.row-1] globalcode];
        cell0.devcode = [_datasrcdata[indexPath.row-1] uuid];
        cell0.authcode = [_datasrcdata[indexPath.row-1] authcode];
        
        cell = cell0;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    CGFloat hight;
    id obj = [_dataSrc objectAtIndex:indexPath.row];
    if ([obj isKindOfClass:[CellForManageHeader class]])
    {
        hight = 50;
    }else if([obj isKindOfClass:[CellFormanageFooder class]]){
        hight = 315;
    }else if([obj isKindOfClass:[CellForShare class]]){
        hight = 200;
    }else if([obj isKindOfClass:[CellForUnlock class]]){
        hight = 250;
    }

    return hight;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
/**************************警告显示*************************/

-(void)alertdisplay:(NSString *)alertMessage :(NSData*)data{

    _aler = [UIAlertController alertControllerWithTitle:@"提示" message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    [_aler addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        if(data != nil) {
            
            NSData *mac = [data subdataWithRange:NSMakeRange(0, 6)];
            [_appDelegate.appLibBleLock bleDataSendRequest:mac cmd_type:libBleCmdAddManagerOpenLockUUID param_data:data];
        }
    }]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:_aler animated:YES completion:nil];
    });
}

-(void)addshare:(NSInteger)row
{

    //打开分享页面
    CellForShare* cell = (CellForShare *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForShare" owner:self options:nil]  lastObject];
    [_dataSrc replaceObjectAtIndex:row withObject:cell];
    [_tabView reloadData];
}
/**************************按钮触发事件**************************/
-(void)changeTag:(NSInteger)btnTag :(NSIndexPath *)indexPath
{
    
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
            if (!canmanage)
            {
                return;
            }
            _isEdit = !_isEdit;
            CellFormanageFooder* cell = (CellFormanageFooder *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellFormanageFooder" owner:self options:nil]  lastObject];
            if (_isEdit == 1)
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                {
                    NSData *guid = [self NSStringConversionToNSData:[_datasrcdata[indexPath.row] globalcode]];
                    NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
                    [_appDelegate.appLibBleLock bleConnectRequest:mac forbattery:YES];
                });
                [self updateLockMsg:[_datasrcdata[indexPath.row] globalcode] withupdate:^(SmartLock *device) {
                    device.oper_time = [[NSDate alloc] init];
                }];
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
            _isEdit = !_isEdit;
            CellForShare* cell = (CellForShare *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForShare" owner:self options:nil]  lastObject];
            if (_isEdit == 1) {
                
                [_dataSrc insertObject:cell atIndex:indexPath.row+1];
                [_tabView reloadData];
            }else
            {
                canmanage = NO;
                [self syndata];
                
                NSData *guid = [self NSStringConversionToNSData:[_datasrcdata[indexPath.row] globalcode]];
                NSData *mac = [guid subdataWithRange:NSMakeRange(0, 6)];
                [_appDelegate.appLibBleLock bleDisconnectRequest:mac];
                [_dataSrc removeObjectAtIndex:indexPath.row+1];
                [_tabView reloadData];
            }
            break;
        }
        case 3:{
            _isEdit = !_isEdit;
            CellForUnlock* cell = (CellForUnlock *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForUnlock" owner:self options:nil]  lastObject];
            if (_isEdit == 1) {
                
                [_dataSrc insertObject:cell atIndex:indexPath.row+1];
                [_tabView reloadData];
            }else
            {
               
                NSString *globalcode = [_datasrcdata[indexPath.row] globalcode];
                NSData *guid = [self NSStringConversionToNSData:globalcode];
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

-(void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)didGetBattery:(NSInteger)battery forMac:(NSData *)mac{}

-(void)didDiscoverComplete{}

-(void)didDisconnectIndication:(NSData *)macAddr{}

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status{}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
