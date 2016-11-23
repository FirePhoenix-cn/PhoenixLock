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
#import "MBProgressHUD.h"
#import "CellForManageHeader.h"
#import "CellFormanageFooder.h"

@interface ManageLock ()<CellForManageHeaderDelegate,CellFormanageFooderDelegate>
{
    NSIndexPath *selectedCell;
    BOOL _isOpenningLock;
}
@property (strong,nonatomic) HTTPPost *httppost;

@end

@implementation ManageLock

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isEdit = 0;
    self.title = @"云盾锁";
    //****************添加数据视图*************
    self.tabView = [[UITableView alloc] initWithFrame:CGRectMake(20, 120 + 5 ,  self.view.bounds.size.width - 40,  self.view.bounds.size.height - 120 - 5 - 60) style:UITableViewStylePlain];//数据视图的大小
    [self.tabView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tabView.delegate = self;
    self.tabView.dataSource = self;
    self.tabView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tabView];
    //****************初始化数据源*************
    self.dataSrc = [[NSMutableArray alloc] init];//创建一个可变数组来存放单元的数据
    self.datasrcdata = [[self showAllManagerLock] mutableCopy];
    for (int i = 0; i < [self.datasrcdata count]; i++)
    {
        [self.dataSrc addObject:@"CellForManageHeader"];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeUnlockView) name:@"closeUnlockPage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopTimers) name:@"stopSearch" object:nil];
    SENDNOTIFY(@"closeProgress")
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

/****************表格视图的协议函数***************/

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.dataSrc.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *obj = [self.dataSrc objectAtIndex:indexPath.row];
    if ([obj isEqualToString:@"CellForManageHeader"])
    {
        static NSString *CellForManageHeaderId = @"CellForManageHeader";
        CellForManageHeader *cell = [tableView dequeueReusableCellWithIdentifier:CellForManageHeaderId];
        if (!cell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"CellForManageHeader" bundle:nil] forCellReuseIdentifier:CellForManageHeaderId];
            cell = [tableView dequeueReusableCellWithIdentifier:CellForManageHeaderId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        NSInteger index = indexPath.row;
        if (selectedCell != nil && index > selectedCell.row)
        {
            index -= 1;
        }
        cell.delegate = self;
        cell.path = indexPath;
        cell.name.text = [NSString stringWithFormat:@"云盾锁名称: %@",[self.datasrcdata[index] devname]];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM.dd HH:mm"];
        NSString *strDate = [NSString stringWithFormat:@"时间:%@",[dateFormatter stringFromDate:[self.datasrcdata[index] oper_time]]];
        cell.time.text = strDate;
        return cell;
    }
    
    if ([obj isEqualToString:@"CellFormanageFooder"])
    {
        static NSString *CellFormanageFooderId = @"CellFormanageFooder";
        CellFormanageFooder *cell = [tableView dequeueReusableCellWithIdentifier:CellFormanageFooderId];
        if (!cell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"CellFormanageFooder" bundle:nil] forCellReuseIdentifier:CellFormanageFooderId];
            cell = [tableView dequeueReusableCellWithIdentifier:CellFormanageFooderId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.managerlock = self.datasrcdata[indexPath.row-1];
        cell.delegate = self;
        cell.path = indexPath;
        cell.name.text = [self.datasrcdata[indexPath.row-1] devname];
        cell.showsharednum.text = [NSString stringWithFormat:@"分享数量:%@/%@",[self.datasrcdata[indexPath.row-1] sharenum],[self.datasrcdata[indexPath.row-1] maxshare]];
        cell.dateofmanu.text = [NSString stringWithFormat:@"生产日期: %@",[self.datasrcdata[indexPath.row-1] productdate]];
        cell.dateofwarranty.text = [NSString stringWithFormat:@"保修日期: 至%@",[self.datasrcdata[indexPath.row-1] warrantydate]];
        cell.lockNO.text = [NSString stringWithFormat:@"云盾锁编号: %@",[self.datasrcdata[indexPath.row-1] devid]];
        cell.distance.value = [[self.datasrcdata[indexPath.row-1] distance] floatValue];
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
    
    if ([obj isEqualToString:@"CellForShare"])
    {
        static NSString *CellForShareId = @"CellForShare";
        CellForShare *cell = [tableView dequeueReusableCellWithIdentifier:CellForShareId];
        if (!cell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"CellForShare" bundle:nil] forCellReuseIdentifier:CellForShareId];
            cell = [tableView dequeueReusableCellWithIdentifier:CellForShareId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.managerlock = self.datasrcdata[indexPath.row-1];
        return cell;
    }
    
    if ([obj isEqualToString:@"CellForUnlock"])
    {
        static NSString *CellForUnlockId = @"CellForUnlock";
        CellForUnlock *cell = [tableView dequeueReusableCellWithIdentifier:CellForUnlockId];
        if (!cell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"CellForUnlock" bundle:nil] forCellReuseIdentifier:CellForUnlockId];
            cell = [tableView dequeueReusableCellWithIdentifier:CellForUnlockId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.ismaster = 1;
        cell.globalcode = [self.datasrcdata[indexPath.row-1] globalcode];
        cell.devcode = [self.datasrcdata[indexPath.row-1] uuid];
        cell.authcode = [self.datasrcdata[indexPath.row-1] authcode];
        cell.devuserid = [self.datasrcdata[indexPath.row-1] devuserid];
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *obj = [self.dataSrc objectAtIndex:indexPath.row];
    if ([obj isEqualToString:@"CellForManageHeader"])
    {
        return 50;
    }else if([obj isEqualToString:@"CellFormanageFooder"]){
        return 315;
    }else if([obj isEqualToString:@"CellForShare"]){
        return 200;
    }
    return 250;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)addshare:(NSInteger)row
{
    //打开分享页面
    CellForShare* cell = (CellForShare *)[[[NSBundle  mainBundle]  loadNibNamed:@"CellForShare" owner:self options:nil]  lastObject];
    [self.dataSrc replaceObjectAtIndex:row withObject:cell];
    [self.tabView reloadData];
}
/**************************按钮触发事件**************************/
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
        selectedCell = indexPath;
        _isOpenningLock = YES;
        [self.dataSrc insertObject:@"CellForUnlock" atIndex:indexPath.row+1];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tabView reloadData];
        });
        return;
    }
    self.isEdit = !self.isEdit;
    if (selectedCell.row != indexPath.row && selectedCell != nil)
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
    switch (btnTag) {
        case 1:
        {
            if (self.isEdit == YES)
            {
                [self.dataSrc insertObject:@"CellFormanageFooder" atIndex:indexPath.row+1];
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
            if (self.isEdit == YES)
            {
                [self.dataSrc insertObject:@"CellForShare" atIndex:indexPath.row+1];
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

        default:
            break;
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

-(void) goBack
{
    if (selectedCell) {
        NSData *globalcode = [self NSStringConversionToNSData:[self.datasrcdata[selectedCell.row] globalcode]];
        NSData *mac = [globalcode.mutableCopy subdataWithRange:NSMakeRange(0, 6)];
        [self.appDelegate.appLibBleLock bleDisconnectRequest:mac];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)textExample:(NSString*)str
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tabView animated:YES];
        
        // Set the annular determinate mode to show task progress.
        hud.mode = MBProgressHUDModeText;
        hud.label.text = NSLocalizedString(str, @"title1");
        [hud.label setFont:[UIFont systemFontOfSize:12.0]];
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:2.f];
    });
}

@end
