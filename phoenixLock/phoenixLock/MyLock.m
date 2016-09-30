//
//  MyLock.m
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "MyLock.h"
#import "MyCell.h"
#import "MySmartLock.h"
#import "SmartAccount.h"
#import "SmartApp.h"
#import "MBProgressHUD.h"
#import "SmartLock.h"

@interface MyLock ()<HTTPPostDelegate>
{
    httpPostType _posttype;
}
@property(strong, nonatomic) NSArray<SmartLock*>* datasrcdata;
@property(strong, nonatomic) SmartLock *selectedlock;
@property (strong,nonatomic) HTTPPost *httppost;
@property (retain,nonatomic) NSMutableArray *datasrcmanager;
@property (retain,nonatomic) NSMutableArray *datasrcshare;
@property (retain, nonatomic) AppDelegate *appDelegate;
@property (retain ,nonatomic) NSMutableArray *rssi;
@property (strong,nonatomic) NSMutableArray *wirelesslog;
@property(strong, nonatomic) MBProgressHUD *hud;
@end

@implementation MyLock
- (void)viewDidLoad
{
    [super viewDidLoad];
    /*****************导航栏初始化格式************/
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"云盾锁";
    UIColor * color = [UIColor whiteColor];
    NSDictionary * dict = [NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dict;//标题颜色
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];//按钮颜色
    self.navigationController.navigationBar.barTintColor = [UIColor darkGrayColor];//状态栏颜色
    
    UIBarButtonItem *rightitem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goma.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goset)];
    self.navigationItem.rightBarButtonItem = rightitem;
    
    /****************集合视图代初始化******************/
    _mangedLock.delegate = self;
    _mangedLock.dataSource = self;
    _sharedLock.delegate = self;
    _sharedLock.dataSource = self;
    _mangedLock.showsVerticalScrollIndicator = NO;
    _sharedLock.showsVerticalScrollIndicator = NO;
    /******************数据持久化********************/
    
    _userdefaults = [NSUserDefaults standardUserDefaults];
    
    
    
    if([_userdefaults objectForKey:@"quitapp"] == nil){
        [_userdefaults setBool:YES forKey:@"quitapp"];
    }
    
    if([_userdefaults objectForKey:@"wirelesslog"] == nil)
    {
        [_userdefaults setObject:[NSArray array] forKey:@"wirelesslog"];
    }
    
    [_userdefaults setInteger:1 forKey:@"canautounlock"];
    [_userdefaults synchronize];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _httppost = _appDelegate.delegatehttppost;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
    
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    if ([[_userdefaults objectForKey:@"quitapp"] boolValue] == YES)
    {
        //上次退出登录，去登陆页面
        dispatch_async(dispatch_get_main_queue(), ^
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            UIViewController *next = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"loginpage"];
            [self.navigationController pushViewController:next animated:YES];
            
        });
        return;
    }
    
    _datasrcmanager = [NSMutableArray arrayWithArray:[[self getAllTopPageLock] mutableCopy]];
    _datasrcshare = [NSMutableArray array];
    for (SmartLock *lock in _datasrcmanager)
    {
        if ([lock.ismaster isEqualToString:@"0"])
        {
            [_datasrcshare addObject:lock];
        }
    }
    for (SmartLock *lock in _datasrcmanager)
    {
        if ([lock.ismaster isEqualToString:@"0"])
        {
            [_datasrcmanager removeObject:lock];
        }
    }

    
    if([HTTPPost isConnectionAvailable] == YES)
    {
        /*********************进行一次心跳同步***********************/
        NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=synauth&account=%@&apptoken=%@&uuid=%@",[self.userdefaults objectForKey:@"account"],
                           [self.userdefaults objectForKey:@"appToken"],
                           [self.userdefaults objectForKey:@"uuid"]];
        _posttype = synauth;
        [_httppost httpPostWithurl:urlStr];
    }
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [_mangedLock reloadData];
    [_sharedLock reloadData];
    
    //自动开锁的搜索
    if ([[_userdefaults objectForKey:@"canautounlock"] intValue] == 1)
    {
        _datasrcdata = nil;
        _datasrcdata = [NSArray arrayWithArray:[self getAllAutoUnlockedLock]];
        if (_datasrcdata.count==0)
        {
            return;
        }
        [_userdefaults setInteger:0 forKey:@"canautounlock"];
        [_userdefaults synchronize];
        
        _appDelegate.appLibBleLock._delegate = self;
        _rssi = [[NSMutableArray alloc] init];
        [_appDelegate.appLibBleLock bleInquiry:2];//2 seconds inruiry
        
    }
}

-(void)didDiscoverResult:(NSData *)macAddr deviceName:(NSData *)deviceName rssi:(NSNumber *)rssi
{
    [_rssi addObject:@{@"key":rssi,@"mac":macAddr}];
}

-(void)didDiscoverComplete
{
    //排序
    NSArray *sortDesc = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES]];
    _rssi = (NSMutableArray*)[_rssi sortedArrayUsingDescriptors:sortDesc];
    //最后一号元素
    NSData *mac = [NSData dataWithData:[_rssi.lastObject objectForKey:@"mac"]];
    [self sortlockBymac:[HTTPPost NSDataConversionToNSString:mac]];
    //距离比较
    if ([self rssiToDistance:[_rssi.lastObject objectForKey:@"key"]] > [_selectedlock.distance floatValue])
    {
        sortDesc = nil;
        mac = nil;
        _rssi = nil;
        return;
    }
    //匹配管理员
    if ([_selectedlock.ismaster isEqualToString:@"1"])
    {
        //说明搜到的是管理员
        //管理员开锁
        _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _hud.label.text = NSLocalizedString(@"自动开锁中...", @"HUD loading title");
        [_hud hideAnimated:YES afterDelay:5.0];
            //连接
        [_appDelegate.appLibBleLock bleConnectRequest:mac forbattery:NO];
    }else
    {
            //说明是分享者
            //分享者开锁
            //判定密钥的有效性
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"yyyyMMddHHmmss"];
            NSDate *end = [formatter dateFromString:_selectedlock.end_time];
            NSTimeInterval interval = [end timeIntervalSinceNow];
            __weak MyLock *wkSelf = self;
            
            if (interval<=0 && [_selectedlock.keytype integerValue]%2 == 0) {
                //密钥过期
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [wkSelf textExam:@"密钥已过期,自动开锁失败"];
                });
                
                return;
            }
            if([_selectedlock.effectimes integerValue] < 1 && [_selectedlock.keytype integerValue] > 2){
                //开锁次数为零不能开锁
                dispatch_async(dispatch_get_main_queue(), ^{
                [wkSelf textExam:@"密钥使用次数不足"];
                     });
                return;
            }
            if (!_selectedlock.isactive.boolValue)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                [wkSelf textExam:@"您已解除该密钥的使用权限"];
                     });
                return;

            }
            //连接
            _hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            _hud.label.text = NSLocalizedString(@"自动开锁中...", @"HUD loading title");
            [_hud hideAnimated:YES afterDelay:5.0];
            
            [_appDelegate.appLibBleLock bleConnectRequest:mac forbattery:NO];
        
    }
}

-(void)check:(NSTimer*)timer
{
    NSData *guid = [self NSStringConversionToNSData:_selectedlock.globalcode];
    [_appDelegate.appLibBleLock bleDataSendRequest:timer.userInfo cmd_type:libBleCmdBindManager param_data:guid];
}

-(void)communicate:(NSTimer*)timer
{
    
    if ([_selectedlock.ismaster isEqualToString:@"1"])
    {
        NSMutableData *uuid_c = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_selectedlock.uuid]];
        [_appDelegate.appLibBleLock bleDataSendRequest:timer.userInfo cmd_type:libBleCmdSendManagerCommunicateUUID param_data:uuid_c];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(manageropenlock:) userInfo:timer.userInfo repeats:NO];
    }else{
        NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_selectedlock.uuid]];
        NSData *uuid_e = [self NSStringConversionToNSData:_selectedlock.comucode];
        [uuid_d appendData:uuid_e];
        [_appDelegate.appLibBleLock bleDataSendRequest:timer.userInfo cmd_type:libBleCmdSendSharerCommunicateUUID param_data:uuid_d];
    }
}

-(void)manageropenlock:(NSTimer*)timer
{
    NSMutableData *uuid_c = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_selectedlock.uuid]];
    NSData *uuid_d = [self NSStringConversionToNSData:_selectedlock.authcode];
    [uuid_c appendData:uuid_d];
    [uuid_c appendData:[self getCurrentTimeInterval]];
    [_appDelegate.appLibBleLock bleDataSendRequest:timer.userInfo cmd_type:libBleCmdSendManagerOpenLockUUID param_data:uuid_c];
}

-(void)shareopenlock:(NSTimer*)timer
{
    
    NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:_selectedlock.uuid]];
    NSLog(@"%@",_selectedlock.uuid);
    NSLog(@"%@",_selectedlock.authcode);
    NSLog(@"%@",_selectedlock.comucode);
    NSData *uuid_e = [self NSStringConversionToNSData:_selectedlock.comucode];
    NSData *uuid_f = [self NSStringConversionToNSData:_selectedlock.authcode];
    [uuid_d appendData:uuid_e];
    [uuid_d appendData:uuid_f];
    [uuid_d appendData:[self getCurrentTimeInterval]];
    [_appDelegate.appLibBleLock bleDataSendRequest:timer.userInfo cmd_type:libBleCmdSendSharerOpenLockUUID param_data:uuid_d];
}



/********************************************************
 *蓝牙回调函数实现
 */

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status{
    if (status)
    {
        if ([_selectedlock.ismaster isEqualToString:@"1"]) {
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(check:) userInfo:macAddr repeats:NO];
        }else{
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(communicate:) userInfo:macAddr repeats:NO];
        }
        return;
    }
    _hud.label.text = NSLocalizedString(@"连接失败", @"HUD loading title");
}

-(void)didDisconnectIndication:(NSData *)macAddr{}

-(void)didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data{
    switch (cmd_type) {
        case libBleCmdBindManager:{
            NSData *uuid = [self NSStringConversionToNSData:[_userdefaults objectForKey:@"uuid"]];
            NSData *scrB = [self NSStringConversionToNSData:[_userdefaults objectForKey:@"appToken"]];
            NSMutableData *user = [[NSMutableData alloc] initWithData:uuid];
            [user appendData:scrB];
            if ([param_data isEqualToData:user]) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(communicate:) userInfo:macAddr repeats:NO];
            }
        }break;
        case libBleCmdSendSharerCommunicateUUID:{
            if (!result) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(shareopenlock:) userInfo:macAddr repeats:NO];
            }
        }break;
        case libBleCmdSendManagerOpenLockUUID:
        {
            if (!result)
            {
                [_hud hideAnimated:YES];
                [self textExam:@"开锁完成！"];
    
                //断开蓝牙
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    _rssi = nil;
                    [_appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                });
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                        NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
                        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=5",
                                         [_userdefaults objectForKey:@"account"],
                                         [_userdefaults objectForKey:@"appToken"],
                                         [_userdefaults objectForKey:@"uuid"],
                                         _selectedlock.globalcode,
                                         [_selectedlock.uuid substringWithRange:NSMakeRange(68, 32)],
                                         _selectedlock.authcode,strDate];
                        NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[_userdefaults objectForKey:@"wirelesslog"]];
                        [wirelesslog addObject:url];
                        [_userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
                        [_userdefaults synchronize];
                        wirelesslog = nil;
                    }else
                    {
                        //上传日志
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                        NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
                        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=5",
                                         [_userdefaults objectForKey:@"account"],
                                         [_userdefaults objectForKey:@"appToken"],
                                         [_userdefaults objectForKey:@"uuid"],
                                         _selectedlock.globalcode,
                                         [_selectedlock.uuid substringWithRange:NSMakeRange(68, 32)],
                                         _selectedlock.authcode,strDate];
                        [_httppost httpPostWithurl:url];
                        _posttype = uploadlog;
                    }

                });
            }else{
                [_hud hideAnimated:YES];
                [self textExam:@"开锁失败！"];
                
                //断开蓝牙
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    _rssi = nil;
                    [_appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                });

            }
        }break;
        
        case libBleCmdSendSharerOpenLockUUID:{
            if (!result) {
                [_hud hideAnimated:YES];
                [self textExam:@"开锁完成！"];
                
                //断开蓝牙
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    _rssi = nil;
                    [_appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                });

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if ([HTTPPost isConnectionAvailable] == NO)
                {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
                    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=5",
                                     [_userdefaults objectForKey:@"account"],
                                     [_userdefaults objectForKey:@"appToken"],
                                     [_userdefaults objectForKey:@"uuid"],
                                     _selectedlock.globalcode,
                                     [_selectedlock.uuid substringWithRange:NSMakeRange(68, 32)],
                                     _selectedlock.authcode,strDate];
                    NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[_userdefaults objectForKey:@"wirelesslog"]];
                    [wirelesslog addObject:url];
                    [_userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
                    [_userdefaults synchronize];
                    wirelesslog = nil;
                }else
                {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
                    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=5",
                                     [_userdefaults objectForKey:@"account"],
                                     [_userdefaults objectForKey:@"appToken"],
                                     [_userdefaults objectForKey:@"uuid"],
                                     _selectedlock.globalcode,
                                     [_selectedlock.uuid substringWithRange:NSMakeRange(68, 32)],
                                     _selectedlock.authcode,strDate];
                    [_httppost httpPostWithurl:url];
                    _posttype = uploadlog;
                }
                });
                //修改本地数据
                [self updateLockMsg:_selectedlock.globalcode withupdate:^(SmartLock *lock) {
                    lock.effectimes = [NSString stringWithFormat:@"%li",(long)lock.effectimes.integerValue-1];
                }];
                
                
            }else{
                [_hud hideAnimated:YES];
                [self textExam:@"开锁失败！"];
                
                //断开蓝牙
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    _rssi = nil;
                    [_appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                });
            }
        }break;

            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//去到下一页
-(void)goset
{
    [_userdefaults setBool:NO forKey:@"sync"];
    [_userdefaults synchronize];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *next = [sb instantiateViewControllerWithIdentifier:@"mysmartlock"];
    [self.navigationController pushViewController:next animated:YES];
}

/****************集合视图基本代理*****************/
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{

    
    if (collectionView.tag == 1)
    {
        return _datasrcmanager.count;
    }
    return _datasrcshare.count;
}

/****************集合视图数据代理*****************/
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [[UICollectionViewCell alloc] init];
    if (collectionView.tag == 1) {
        MyCell *cell0 = (MyCell *)[_mangedLock dequeueReusableCellWithReuseIdentifier:@"managecell" forIndexPath:indexPath];
        cell0.lab.text = [_datasrcmanager[indexPath.row] devname];
        cell = cell0;
    }else if (collectionView.tag == 2){
        MyCell *cell0 = (MyCell *)[_sharedLock dequeueReusableCellWithReuseIdentifier:@"sharedcell" forIndexPath:indexPath];
        cell0.labShared.text = [_datasrcshare[indexPath.row] devname];
        cell = cell0;
    }
        return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == 1) {
        UIViewController *next = [[self storyboard] instantiateViewControllerWithIdentifier:@"ManageLock"];
        [self.navigationController pushViewController:next animated:YES];
    }else{
        UIViewController *next = [[self storyboard] instantiateViewControllerWithIdentifier:@"SharedLock"];
        [self.navigationController pushViewController:next animated:YES];
    }
}

//网络请求回调
-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    if ( -120 > interval || interval > 120 )
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"系统时间错误" preferredStyle:1];
        [alert addAction:[UIAlertAction actionWithTitle:@"去更正时间" style:0 handler:^(UIAlertAction * _Nonnull action) {
            [_timer invalidate];
            _timer = nil;
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if([[UIApplication sharedApplication] canOpenURL:url]) {
                
                NSURL*url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:url];
            }
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });
        return;
    }
    switch (_posttype)
    {
        case synauth:
        {
            if ([[dic objectForKey:@"status"] integerValue] != 1) {
                return;
            }
            NSArray <NSDictionary *> *data = [NSArray arrayWithArray:[dic objectForKey:@"data"]];
            if (data.count == 0) {
                return;
            }
            //同步到本地
            [self.userdefaults setObject:[dic objectForKey:@"money"] forKey:@"money"];
            [self.userdefaults setObject:[dic objectForKey:@"minutes"] forKey:@"minutes"];
            [self.userdefaults setObject:[dic objectForKey:@"flows"] forKey:@"flows"];
            for (NSDictionary *lock in data)
            {
                //删除
                //[self removeUselessLock:data];
                
                if ([self isNewLock:[[lock objectForKey:@"globalcode"] lowercaseString]])
                {
                    //insert
                    [self insertLock:^(SmartLock *device) {
                        device.devuserid = [lock objectForKey:@"devuserid"];
                        device.globalcode = [[lock objectForKey:@"globalcode"] lowercaseString];
                        device.uuid = [lock objectForKey:@"uuid"];
                        device.authcode = [lock objectForKey:@"authcode"];
                        device.comucode = [lock objectForKey:@"comucode"];
                        device.devname = [lock objectForKey:@"devname"];
                        device.managename = [lock objectForKey:@"managename "];
                        device.ismaster = [lock objectForKey:@"ismaster"];
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
                    //update
                    [self updateLockMsg:[[lock objectForKey:@"globalcode"] lowercaseString] withupdate:^(SmartLock *device) {
                        device.devuserid = [lock objectForKey:@"devuserid"];
                        device.globalcode = [[lock objectForKey:@"globalcode"] lowercaseString];
                        device.uuid = [lock objectForKey:@"uuid"];
                        device.authcode = [lock objectForKey:@"authcode"];
                        device.comucode = [lock objectForKey:@"comucode"];
                        device.devname = [lock objectForKey:@"devname"];
                        device.managename = [lock objectForKey:@"managename "];
                        device.ismaster = [lock objectForKey:@"ismaster"];
                        device.keytype = [lock objectForKey:@"keytype"];
                        device.effectimes = [lock objectForKey:@"effectimes"];
                        device.begin_time = [lock objectForKey:@"begin_time"];
                        device.end_time = [lock objectForKey:@"end_time"];
                    }];
                }
            }
            
            if([[_userdefaults objectForKey:@"wirelesslog"] count] > 0)
            {

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                               {
                                    //上传日志
                                   _wirelesslog = [NSMutableArray arrayWithArray:[_userdefaults objectForKey:@"wirelesslog"]];
                                   _posttype = uploadlog;
                                   [_httppost httpPostWithurl:[_wirelesslog firstObject]];
                
                               });
            }
        }
            
        break;
          
        case uploadlog:
        {
        
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                [_wirelesslog removeObjectAtIndex:0];
                
                if (_wirelesslog.count == 0)
                {
                    [_userdefaults setObject:[NSArray array] forKey:@"wirelesslog"];
                    [_userdefaults synchronize];
                    return;
                }
                _posttype = uploadlog;
                [_httppost httpPostWithurl:[_wirelesslog firstObject]];
                
            }else
            {
                _posttype = uploadlog;
                [_httppost httpPostWithurl:[_wirelesslog firstObject]];
            }
        }
            break;
        default:
            break;
    }
}

-(BOOL)isNewLock:(NSString*)globalcode
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"globalcode=%@",globalcode];
    [request setPredicate:predicate];
    NSArray *resultArr = [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext executeFetchRequest:request error:nil];
    if (resultArr.count>0) {
        return NO;
    }
    return YES;
}

-(void)insertLock:(void(^)(SmartLock *device))addlock
{
    SmartLock *lock = [NSEntityDescription insertNewObjectForEntityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    addlock(lock);
    [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext save:nil];
}

-(void)updateLockMsg:(NSString*)globalcode withupdate:(void(^)(SmartLock *lock))update
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

- (BOOL)matestring:(NSString*)string :(NSArray*)arr
{
    NSInteger count = 0;
    for (NSInteger i = 0 ; i < arr.count; i++ ) {
        if ([arr[i] isEqualToString:string] ) {
            count++;
        }
    }
    return count;
}

//提示框显示
- (void)textExam:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        
        // Set the annular determinate mode to show task progress.
        hud.mode = MBProgressHUDModeText;
        hud.label.text = NSLocalizedString(text, @"titles");
        hud.offset = CGPointMake(0.f, 10.f);
        [hud hideAnimated:YES afterDelay:2.f];
    });
}


//根据信号估算距离
-(CGFloat) rssiToDistance:(NSNumber *)RSSI
{
    int rssi = abs([RSSI intValue]);
    CGFloat ci = (rssi - 70) / (10 * 4.0);
    
    return pow(10, ci);
}

-(void)removeUselessLock:(NSArray<NSDictionary*>*)data
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSMutableArray <SmartLock*>* locks = [[((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext executeFetchRequest:request error:nil] mutableCopy];
    for (SmartLock *lock in locks)
    {
        if ([self isValidateGlobalcode:lock.globalcode indata:data])
        {
            [locks removeObject:lock];
        }
    }
    for (SmartLock *lock in locks)
    {
        [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext deleteObject:lock];
    }
    [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext save:nil];
}

-(BOOL)isValidateGlobalcode:(NSString*)globalcode indata:(NSArray<NSDictionary *>*)data
{
    for (NSDictionary *lock in data)
    {
        if ([globalcode isEqualToString:[lock objectForKey:@"globalcode"]])
        {
            return YES;
        }
    }
    return NO;
}

-(NSArray<SmartLock*>*)getAllAutoUnlockedLock
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isautounlock=%@",[NSNumber numberWithBool:YES]];
    [request setPredicate:predicate];
    NSMutableArray <SmartLock*>*arr = [[((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext executeFetchRequest:request error:nil] mutableCopy];
    for (SmartLock* lock in arr)
    {
        if ([lock.begin_time isEqualToString:lock.isdeleted])
        {
            [arr removeObject:lock];
        }
    }
    return arr;
}

-(NSArray<SmartLock*>*)getAllTopPageLock
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"istoppage=%@",[NSNumber numberWithBool:YES]];
    [request setPredicate:predicate];
    NSMutableArray <SmartLock*>*arr = [[((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext executeFetchRequest:request error:nil] mutableCopy];
    for (SmartLock* lock in arr)
    {
        if ([lock.begin_time isEqualToString:lock.isdeleted])
        {
            [arr removeObject:lock];
        }
    }
    return arr;
}

-(BOOL)sortlockBymac:(NSString*)mac
{
    for (SmartLock *lock in _datasrcdata)
    {
        if ([[lock.globalcode.lowercaseString.mutableCopy substringWithRange:NSMakeRange(0, 12)] isEqualToString:mac])
        {
            _selectedlock = lock;
            return YES;
        }
    }
    return NO;
}



@end
