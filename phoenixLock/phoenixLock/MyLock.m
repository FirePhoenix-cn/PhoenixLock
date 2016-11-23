//
//  MyLock.m
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "MyLock.h"
#import "MySmartLock.h"
#import "SmartAccount.h"
#import "SmartApp.h"
#import "MBProgressHUD.h"
#import "MD5Code.h"
#import "CollectionViewCell.h"

@interface MyLock ()<HTTPPostDelegate>
@property(strong, nonatomic) NSArray<SmartLock*>* datasrcdata;
@property(strong, nonatomic) SmartLock *selectedlock;
@property(strong, nonatomic) HTTPPost *httppost;
@property(retain, nonatomic) NSMutableArray *datasrcmanager;
@property(retain, nonatomic) NSMutableArray *datasrcshare;
@property(retain, nonatomic) NSMutableArray *rssi;
@property(strong, nonatomic) NSMutableArray *wirelesslog;
@property(strong, nonatomic) MBProgressHUD *progressLoadingHud;
@property(strong, nonatomic) UISwipeGestureRecognizer *leftSwipe;
@property(strong, nonatomic) NSData *mac;

@end

@implementation MyLock

#pragma mark - lifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    /*****************导航栏初始化格式************/
    self.navigationItem.leftBarButtonItem = nil;;
    self.title = @"云盾锁";
    UIBarButtonItem *rightitem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goma.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goset)];
    self.navigationItem.rightBarButtonItem = rightitem;
    self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goset)];
    self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.leftSwipe];
    /****************集合视图代初始化******************/
    self.mangedLock.delegate = self;
    self.mangedLock.dataSource = self;
    self.sharedLock.delegate = self;
    self.sharedLock.dataSource = self;
    self.mangedLock.showsVerticalScrollIndicator = NO;
    self.sharedLock.showsVerticalScrollIndicator = NO;
    [self.mangedLock registerNib:[UINib nibWithNibName:@"CollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"CollectionViewCell"];
    [self.sharedLock registerNib:[UINib nibWithNibName:@"CollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"CollectionViewCell"];
    if([self.userdefaults objectForKey:@"quitapp"] == nil)
    {
        [self.userdefaults setBool:YES forKey:@"quitapp"];
    }
    if([self.userdefaults objectForKey:@"wirelesslog"] == nil)
    {
        [self.userdefaults setObject:[NSArray array] forKey:@"wirelesslog"];
    }
    self.httppost = self.appDelegate.delegatehttppost;
    self.httppost.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimer) name:@"startSearch" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeProgresshud) name:@"closeProgress" object:nil];
    if ([[self.userdefaults objectForKey:@"quitapp"] boolValue] == YES)
    {
        //上次退出登录，去登陆页面
        dispatch_async(dispatch_get_main_queue(), ^{
                           UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
                           UIViewController *next = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"loginpage"];
                           [self.navigationController pushViewController:next animated:YES];
                       });
        return;
    }
    SENDNOTIFY(@"startSearch")
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    [self loadTopPageData];
    [self synauthdate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - pravete methord

-(void)synauthdate
{
    if ([HTTPPost isConnectionAvailable])
    {
        NSString *urlStr =[NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=synauth&account=%@&apptoken=%@&uuid=%@",[self.userdefaults objectForKey:@"account"],
                           [self.userdefaults objectForKey:@"appToken"],
                           [self.userdefaults objectForKey:@"uuid"]];
        [self.httppost httpPostWithurl:urlStr type:synauth];
    }
}

-(void)startTimer
{
    if (self.appDelegate.searchTimer) {
        [self.appDelegate.searchTimer invalidate];
        self.appDelegate.searchTimer = nil;
    }
    self.appDelegate.searchTimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(searchForAutounlock) userInfo:nil repeats:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self searchForAutounlock];
    });
}

-(MBProgressHUD *)progressLoadingHud
{
    if (!_progressLoadingHud) {
        _progressLoadingHud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        _progressLoadingHud.mode = MBProgressHUDModeIndeterminate;
        _progressLoadingHud.label.text = NSLocalizedString(@"正在自动开锁", @"");
        [_progressLoadingHud hideAnimated:YES];
    }
    return _progressLoadingHud;
}

-(void)loadTopPageData
{
    NSMutableArray *topTemp = [NSMutableArray arrayWithArray:[[self getAllTopPageLock] mutableCopy]];
    if (self.datasrcmanager)
    {
        [self.datasrcmanager removeAllObjects];
        [self.datasrcshare removeAllObjects];
    }else
    {
        self.datasrcmanager = [NSMutableArray array];
        self.datasrcshare = [NSMutableArray array];
    }
    for (SmartLock *lock in topTemp)
    {
        if ([lock.ismaster isEqualToString:@"0"])
        {
            [self.datasrcshare addObject:lock];
        }else
        {
            [self.datasrcmanager addObject:lock];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mangedLock reloadData];
        [self.sharedLock reloadData];
    });
}

-(void)searchForAutounlock
{
    if (self.appDelegate.searchLock == YES) {
        return;
    }
    self.datasrcdata = nil;
    self.datasrcdata = [NSArray arrayWithArray:[self getAllAutoUnlockedLock]];
    if (self.datasrcdata.count==0)
    {
        return;
    }
    self.rssi = [[NSMutableArray alloc] init];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleCancelInquiry];
    [self.appDelegate.appLibBleLock bleInquiry:3];
}

-(void)closeProgresshud
{
    if (_progressLoadingHud == nil) {
        return;
    }
    [self.progressLoadingHud hideAnimated:YES];
    self.progressLoadingHud = nil;
}

-(void)uploadlog:(NSInteger)status
{
    //上传日志
    [self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
    if ([self.selectedlock.ismaster isEqualToString:@"0"])
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
        
        NSString *signString = [NSString stringWithFormat:@"account=%@&apptoken=%@&authcode=%@&globalcode=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                [self.userdefaults objectForKey:@"account"],
                                [self.userdefaults objectForKey:@"appToken"],
                                self.selectedlock.authcode,
                                self.selectedlock.globalcode,
                                strDate,[self.userdefaults objectForKey:@"uuid"]];
        NSString *sign = [MD5Code md5:signString];
        
        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=opencheck&account=%@&apptoken=%@&globalcode=%@&authcode=%@&uuid=%@&oper_time=%@&oper_status=%li&sign=%@",
                         [self.userdefaults objectForKey:@"account"],
                         [self.userdefaults objectForKey:@"appToken"],
                         self.selectedlock.globalcode,
                         self.selectedlock.authcode,
                         [self.userdefaults objectForKey:@"uuid"],strDate,(long)status,sign];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.httppost httpPostWithurl:url type:uploadlog];
            
        });
        return;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=%li",
                     [self.userdefaults objectForKey:@"account"],
                     [self.userdefaults objectForKey:@"appToken"],
                     [self.userdefaults objectForKey:@"uuid"],
                     self.selectedlock.globalcode,
                     [self.selectedlock.uuid substringWithRange:NSMakeRange(68, 32)],
                     self.selectedlock.authcode,strDate,(long)status];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.httppost httpPostWithurl:url type:uploadlog];
    });
}

-(void)addWirelessLogUploadRecord:(NSInteger)status
{
    [self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
    if ([self.selectedlock.ismaster isEqualToString:@"0"])
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
        NSString *signString = [NSString stringWithFormat:@"account=%@&apptoken=%@&authcode=%@&globalcode=%@&oper_time=%@&uuid=%@&signkey=22jiadfw12e1212jadf9sdafkwezzxwe",
                                [self.userdefaults objectForKey:@"account"],
                                [self.userdefaults objectForKey:@"appToken"],
                                self.selectedlock.authcode,
                                self.selectedlock.globalcode,
                                strDate,[self.userdefaults objectForKey:@"uuid"]];
        NSString *sign = [MD5Code md5:signString];
        
        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=opencheck&account=%@&apptoken=%@&globalcode=%@&authcode=%@&uuid=%@&oper_time=%@&oper_status=%li&sign=%@",
                         [self.userdefaults objectForKey:@"account"],
                         [self.userdefaults objectForKey:@"appToken"],
                         self.selectedlock.globalcode,
                         self.selectedlock.authcode,
                         [self.userdefaults objectForKey:@"uuid"],strDate,(long)status,sign];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[self.userdefaults objectForKey:@"wirelesslog"]];
            [wirelesslog addObject:url];
            [self.userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
            [self.userdefaults synchronize];
        });
        return;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *strDate = [dateFormatter stringFromDate:[[NSDate alloc] init]];
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=uploadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@&authcode=%@&oper_time=%@&oper_status=%li",
                     [self.userdefaults objectForKey:@"account"],
                     [self.userdefaults objectForKey:@"appToken"],
                     [self.userdefaults objectForKey:@"uuid"],
                     self.selectedlock.globalcode,
                     [self.selectedlock.uuid substringWithRange:NSMakeRange(68, 32)],
                     self.selectedlock.authcode,strDate,(long)status];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableArray *wirelesslog = [NSMutableArray arrayWithArray:[self.userdefaults objectForKey:@"wirelesslog"]];
    [wirelesslog addObject:url];
    [self.userdefaults setObject:wirelesslog forKey:@"wirelesslog"];
    [self.userdefaults synchronize];
    });
}

-(void)goset
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *next = [sb instantiateViewControllerWithIdentifier:@"mysmartlock"];
    [self.navigationController pushViewController:next animated:YES];
}

#pragma mark - bluetooth delegate

-(void)didDiscoverResult:(NSData *)macAddr deviceName:(NSData *)deviceName rssi:(NSNumber *)rssi
{
    [self.rssi addObject:@{@"rssi":rssi,@"mac":macAddr}];
}

-(void)didDiscoverComplete
{
    //排序
    NSLog(@"%s",__func__);
    if (self.rssi.count == 0)
    {
        return;
    }
    NSArray *sortDesc = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES]];
    self.rssi = [self.rssi sortedArrayUsingDescriptors:sortDesc].mutableCopy;
    //最后一号元素
     self.mac = [NSData dataWithData:[self.rssi.lastObject objectForKey:@"mac"]];
    [self sortlockBymac:[self NSDataConversionToNSString:self.mac]];
    //距离比较
    if ([self rssiToDistance:[self.rssi.lastObject objectForKey:@"rssi"]] > [self.selectedlock.distance floatValue])
    {
        sortDesc = nil;
        self.mac = nil;
        self.rssi = nil;
        return;
    }
    //匹配管理员
    [self.appDelegate.searchTimer setFireDate:[NSDate distantFuture]];
    if ([self.selectedlock.ismaster isEqualToString:@"1"])
    {
        //说明搜到的是管理员
        //管理员开锁
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressLoadingHud showAnimated:YES];
        });
        //连接
        self.appDelegate.appLibBleLock.delegate = self;
        [self.appDelegate.appLibBleLock bleConnectRequest:self.mac];
    }else
    {
            //说明是分享者
            //分享者开锁
            //判定密钥的有效性
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"yyyyMMddHHmmss"];
            NSDate *end = [formatter dateFromString:self.selectedlock.end_time];
            NSTimeInterval interval = [end timeIntervalSinceNow];
            if (interval<=0 && [self.selectedlock.keytype integerValue]%2 == 0) {
                //密钥过期
                [self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self progeressText:@"密钥已过期,自动开锁失败"];
                });
                
                return;
            }
            if([self.selectedlock.effectimes integerValue] < 1 && [self.selectedlock.keytype integerValue] > 2){
                //开锁次数为零不能开锁
                [self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self progeressText:@"密钥使用次数不足"];
                     });
                return;
            }
            if (!self.selectedlock.isactive.boolValue)
            {
                [self.appDelegate.searchTimer setFireDate:[NSDate distantPast]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self progeressText:@"您已解除该密钥的使用权限"];
                     });
                return;

            }
            //连接
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressLoadingHud showAnimated:YES];
        });
            self.appDelegate.appLibBleLock.delegate = self;
            [self.appDelegate.appLibBleLock bleConnectRequest:self.mac];
    }
}

-(void)didConnectConfirm:(NSData *)macAddr status:(Boolean)status{
    if (status)
    {
        if ([self.selectedlock.ismaster isEqualToString:@"1"])
        {
            [self performSelector:@selector(check) withObject:nil afterDelay:0.2];
        }else{
            [self performSelector:@selector(communicate) withObject:nil afterDelay:0.2];
        }
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressLoadingHud hideAnimated:YES];
        self.progressLoadingHud = nil;
        [self progeressText:@"连接失败"];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([HTTPPost isConnectionAvailable] == NO)
        {
            [self addWirelessLogUploadRecord:31];
        }else
        {
            [self uploadlog:31];
        }
    });
    
}

-(void)didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data
{
    if (result != libBleErrorCodeNone)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressLoadingHud hideAnimated:YES];
            self.progressLoadingHud = nil;
            [self progeressText:@"开锁失败"];
        });
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([HTTPPost isConnectionAvailable] == NO)
            {
                [self addWirelessLogUploadRecord:51];
            }else
            {
                [self uploadlog:51];
            }
        });
        dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC);
        dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.appDelegate.appLibBleLock.delegate = self;
            [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
        });
        return;
    }
    switch (cmd_type) {
        case libBleCmdBindManager:
        {
            NSData *user = [NSData dataWithData:[self NSStringConversionToNSData:[self.selectedlock.uuid substringWithRange:NSMakeRange(20, 48)]]];
            if ([param_data isEqualToData:user])
            {
                [self performSelector:@selector(communicate) withObject:nil afterDelay:0.2];
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressLoadingHud hideAnimated:YES];
                    self.progressLoadingHud = nil;
                    [self progeressText:@"开锁失败"];
                });
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        [self addWirelessLogUploadRecord:4];
                    }else
                    {
                        [self uploadlog:4];
                    }
                });
                dispatch_time_t timedelay = dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC);
                dispatch_after(timedelay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    self.appDelegate.appLibBleLock.delegate = self;
                    [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                });
                return;
            }
        }break;
        case libBleCmdSendSharerCommunicateUUID:
        {
            [self performSelector:@selector(shareopenlock) withObject:nil afterDelay:0.2];
            
        }break;
            
        case libBleCmdSendManagerOpenLockUUID:
        {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressLoadingHud hideAnimated:YES];
                    self.progressLoadingHud = nil;
                    [self progeressText:@"开锁完成"];
                });
                //断开蓝牙
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    self.rssi = nil;
                    self.appDelegate.appLibBleLock.delegate = self;
                    [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                });
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        [self addWirelessLogUploadRecord:5];
                    }else
                    {
                        [self uploadlog:5];
                    }
                });
            
        }break;
            
        case libBleCmdSendSharerOpenLockUUID:
        {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressLoadingHud hideAnimated:YES];
                    self.progressLoadingHud = nil;
                    [self progeressText:@"开锁完成"];
                });
                //断开蓝牙
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    self.rssi = nil;
                    self.appDelegate.appLibBleLock.delegate = self;
                    [self.appDelegate.appLibBleLock bleDisconnectRequest:macAddr];
                });
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([HTTPPost isConnectionAvailable] == NO)
                    {
                        [self addWirelessLogUploadRecord:5];
                    }else
                    {
                        [self uploadlog:5];
                    }
                });
                
                //修改本地数据
                [self updateLockMsg:self.selectedlock.devuserid withupdate:^(SmartLock *lock) {
                    NSInteger usedtimes = [[lock usedtimes] integerValue];
                    lock.usedtimes = [NSString stringWithFormat:@"%li",(long)usedtimes + 1];
                }];
        }break;
            
            
        default:
            break;
    }
}

#pragma mark - bluetooth private methord

-(void)check
{
    NSData *guid = [self NSStringConversionToNSData:self.selectedlock.globalcode];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdBindManager param_data:guid];
}

-(void)communicate
{
    if ([self.selectedlock.ismaster isEqualToString:@"1"])
    {
        NSMutableData *uuid_c = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.selectedlock.uuid]];
        self.appDelegate.appLibBleLock.delegate = self;
        [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdSendManagerCommunicateUUID param_data:uuid_c];
        [self performSelector:@selector(manageropenlock) withObject:nil afterDelay:0.2];
    }else
    {
        NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.selectedlock.uuid]];
        NSData *uuid_e = [self NSStringConversionToNSData:self.selectedlock.comucode];
        [uuid_d appendData:uuid_e];
        self.appDelegate.appLibBleLock.delegate = self;
        [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdSendSharerCommunicateUUID param_data:uuid_d];
    }
}

-(void)manageropenlock
{
    NSMutableData *uuid_c = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.selectedlock.uuid]];
    NSData *uuid_d = [self NSStringConversionToNSData:self.selectedlock.authcode];
    [uuid_c appendData:uuid_d];
    [uuid_c appendData:[self getCurrentTimeInterval]];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdSendManagerOpenLockUUID param_data:uuid_c];
}

-(void)shareopenlock
{
    NSMutableData *uuid_d = [[NSMutableData alloc]initWithData:[self NSStringConversionToNSData:self.selectedlock.uuid]];
    NSData *uuid_e = [self NSStringConversionToNSData:self.selectedlock.comucode];
    NSData *uuid_f = [self NSStringConversionToNSData:self.selectedlock.authcode];
    [uuid_d appendData:uuid_e];
    [uuid_d appendData:uuid_f];
    [uuid_d appendData:[self getCurrentTimeInterval]];
    self.appDelegate.appLibBleLock.delegate = self;
    [self.appDelegate.appLibBleLock bleDataSendRequest:self.mac cmd_type:libBleCmdSendSharerOpenLockUUID param_data:uuid_d];
}

#pragma mark - collection delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView.tag == 1)
    {
        return self.datasrcmanager.count;
    }
    return self.datasrcshare.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"CollectionViewCell";
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    if (!cell) {
        [collectionView registerNib:[UINib nibWithNibName:@"CollectionViewCell" bundle:nil] forCellWithReuseIdentifier:cellID];
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    }
    UILabel *label = [cell viewWithTag:1];
    UIImageView *imgv = [cell viewWithTag:2];
    if (collectionView.tag == 1)
    {
        label.text = [self.datasrcmanager[indexPath.row] devname];
        [imgv setImage:[UIImage imageNamed:@"unlock"]];
    }else
    {
        label.text = [self.datasrcshare[indexPath.row] devname];
        [imgv setImage:[UIImage imageNamed:@"key"]];
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

#pragma mark - network delegate

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    if ( -120 > interval || interval > 120)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"系统时间错误" preferredStyle:1];
        [alert addAction:[UIAlertAction actionWithTitle:@"去更正时间" style:0 handler:^(UIAlertAction * _Nonnull action) {
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
    switch (type)
    {
        case synauth:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"-3"])
            {
                [self clearAllData];
                [self loadTopPageData];
                return;
            }
            if ([[dic objectForKey:@"status"] integerValue] != 1)
            {
                [self loadTopPageData];
                return;
            }
            //同步到本地
            [self.userdefaults setObject:[dic objectForKey:@"money"] forKey:@"money"];
            [self.userdefaults setObject:[dic objectForKey:@"minutes"] forKey:@"minutes"];
            [self.userdefaults setObject:[dic objectForKey:@"usedminutes"] forKey:@"usedminutes"];
            [self.userdefaults setObject:[dic objectForKey:@"flows"] forKey:@"flows"];
            [self.userdefaults synchronize];
            NSMutableArray <NSDictionary *> *data = [NSMutableArray arrayWithArray:[dic objectForKey:@"data"]];
            NSMutableArray *deviuseridTemp = [NSMutableArray array];
            for (NSDictionary *lock in data)
            {
                [deviuseridTemp addObject:[lock objectForKey:@"devuserid"]];
                if ([self isNewLockWithDevuserid:[lock objectForKey:@"devuserid"]])
                {
                    //insert
                    [self insertLock:^(SmartLock *device) {
                        device.devuserid = [lock objectForKey:@"devuserid"];
                        device.globalcode = [lock objectForKey:@"globalcode"] ;
                        device.uuid = [lock objectForKey:@"uuid"];
                        device.authcode = [lock objectForKey:@"authcode"];
                        device.comucode = [lock objectForKey:@"comucode"];
                        device.devname = [lock objectForKey:@"devname"];
                        device.managename = [lock objectForKey:@"managename"];
                        device.ismaster = [lock objectForKey:@"ismaster"];
                        device.keytype = [lock objectForKey:@"keytype"];
                        device.effectimes = [lock objectForKey:@"effectimes"];
                        device.begin_time = [lock objectForKey:@"begin_time"];
                        device.end_time = [lock objectForKey:@"end_time"];
                        device.status = [lock objectForKey:@"status"];
                        device.sharetimes = [lock objectForKey:@"sharetimes"];
                        device.usedtimes = [lock objectForKey:@"usedtimes"];
                        device.productdate = @"2016-05-01";
                        device.warrantydate = @"2021-05-01";
                        device.sharenum = @"0";
                        device.maxshare = @"50";
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
                    //update
                    [self updateLockMsg:[lock objectForKey:@"devuserid"] withupdate:^(SmartLock *device) {
                        device.managename = [lock objectForKey:@"managename"];
                        device.devname = [lock objectForKey:@"devname"];
                        device.effectimes = [lock objectForKey:@"effectimes"];
                        device.usedtimes = [lock objectForKey:@"usedtimes"];
                        device.status = [lock objectForKey:@"status"];
                        device.authcode = [lock objectForKey:@"authcode"];
                        device.comucode = [lock objectForKey:@"comucode"];
                    }];
                }
            }
            //删除无用的锁
            [self removeUselessLock:deviuseridTemp];
            [self loadTopPageData];
            if([[self.userdefaults objectForKey:@"wirelesslog"] count] > 0)
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    self.wirelesslog = [NSMutableArray arrayWithArray:[self.userdefaults objectForKey:@"wirelesslog"]];
                    [self.httppost httpPostWithurl:[self.wirelesslog firstObject] type:uploadlog];
                });
            }
        }
            
        break;
          
        case uploadlog:
        {
            if (self.wirelesslog.count == 0) {
                return;
            }
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"] || [[dic objectForKey:@"status"] isEqualToString:@"-4"] || [[dic objectForKey:@"status"] isEqualToString:@"-5"])
            {
                if (self.wirelesslog.count>0)
                {
                    [self.wirelesslog removeObjectAtIndex:0];
                }
                if (self.wirelesslog.count == 0)
                {
                    [self synauthdate];
                    [self.userdefaults setObject:[NSArray array] forKey:@"wirelesslog"];
                    [self.userdefaults synchronize];
                    return;
                }
                [self.httppost httpPostWithurl:[self.wirelesslog firstObject] type:uploadlog];
                
            }else
            {
                [self.httppost httpPostWithurl:[self.wirelesslog firstObject] type:uploadlog];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - other methord

- (void)progeressText:(NSString*)text
{
    SHOWALERTNOTIFY(text)
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(text, @"");
    hud.offset = CGPointMake(0.f, 0.f);
    [hud hideAnimated:YES afterDelay:2.f];
}

-(CGFloat) rssiToDistance:(NSNumber *)RSSI
{
    int rssi = abs([RSSI intValue]);
    CGFloat ci = (rssi - 70) / (10 * 4.0);
    
    return pow(10, ci);
}

-(BOOL)sortlockBymac:(NSString*)mac
{
    for (SmartLock *lock in self.datasrcdata)
    {
        if ([[lock.globalcode.lowercaseString.mutableCopy substringWithRange:NSMakeRange(0, 12)] isEqualToString:mac])
        {
            self.selectedlock = lock;
            return YES;
        }
    }
    return NO;
}

@end
