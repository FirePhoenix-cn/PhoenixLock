//
//  CountLock.m
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CountLock.h"
#import "TableCell.h"
#import "HZQDatePickerView.h"

@interface CountLock ()<HTTPPostDelegate,HZQDatePickerViewDelegate>
@property (strong, nonatomic) HTTPPost *httppost;
@property (strong, nonatomic) NSMutableArray *dataSrc;
@property (strong, nonatomic) NSMutableArray *tempdic;
@property (strong, nonatomic) HZQDatePickerView *dateView;
@end

@implementation CountLock

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"云盾锁";
    
    self.tabView.delegate = self;
    self.tabView.dataSource = self;
    self.tabView.showsVerticalScrollIndicator = NO;
    [self.tabView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.search.delegate = self;
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    self.dataSrc = [NSMutableArray array];
    self.tempdic = [NSMutableArray array];
    self.httppost.delegate = self;
    [self downloadlog];
}

-(HZQDatePickerView *)dateView
{
    if (!_dateView) {
        _dateView = [HZQDatePickerView instanceDatePickerView];
        _dateView.frame = CGRectMake(0, 0, ScreenRectWidth, ScreenRectHeight + 20);
        [_dateView setBackgroundColor:[UIColor clearColor]];
        _dateView.delegate = self;
        _dateView.type = DateTypeOfStart;
        [_dateView.datePickerView setMinimumDate:[NSDate dateWithTimeIntervalSince1970:0]];
    }
    return _dateView;
}

-(void)getSelectDate:(NSString *)date :(NSDate *)pickdate type:(DateType)type
{
    self.search.text = date;
    self.dataSrc = self.tempdic;
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyyMMddHHmmss"];
    [self search:[dateformatter stringFromDate:pickdate]];
}

-(void)downloadlog
{
    [self.tempdic removeAllObjects];
    [self.dataSrc removeAllObjects];
    if ([self.operLock.ismaster isEqualToString:@"1"])
    {
        //管理员下载
        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=downloadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@",
                         [self.userdefaults objectForKey:@"account"],
                         [self.userdefaults objectForKey:@"appToken"],
                         [self.userdefaults objectForKey:@"uuid"],
                         [self.operLock globalcode],
                         [[self.operLock uuid] substringWithRange:NSMakeRange(68, 32)]];
        
        [self.httppost httpPostWithurl:url type:downloadlog];
    }else
    {
        //分享者下载
        NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=downloadmylog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@",
                         [self.userdefaults objectForKey:@"account"],
                         [self.userdefaults objectForKey:@"appToken"],
                         [self.userdefaults objectForKey:@"uuid"],
                         [self.operLock globalcode],
                         [[self.operLock uuid] substringWithRange:NSMakeRange(68, 32)]];
        
        [self.httppost httpPostWithurl:url type:downloadmylog];
        
    }
    

}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case downloadlog:
        {
            NSArray *rdata = [dic objectForKey:@"data"];
            for (NSInteger i=0; i<rdata.count; i++)
            {
                [self.tempdic addObject:rdata[i]];
            }
            //排序
            NSArray *sortDesc = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"oper_time" ascending:NO]];
            self.dataSrc = [[self.tempdic sortedArrayUsingDescriptors:sortDesc] mutableCopy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tabView reloadData];
            });
            
        }
        break;
           
            
        case downloadmylog:
        {
            NSArray *rdata = [dic objectForKey:@"data"];
            for (NSInteger i = 0; i<rdata.count; i++)
            {
                [self.dataSrc addObject:rdata[i]];
                [self.tempdic addObject:rdata[i]];
            }
            //排序
            NSArray *sortDesc = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"oper_time" ascending:NO]];
            self.dataSrc = (NSMutableArray*)[self.dataSrc sortedArrayUsingDescriptors:sortDesc];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tabView reloadData];
            });
        }
            break;
        default:
            break;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellid = @"TableCell";
    TableCell *cell =  [self.tabView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil)
    {
        [tableView registerNib:[UINib nibWithNibName:@"TableCell" bundle:nil] forCellReuseIdentifier:cellid];
        cell =  [self.tabView dequeueReusableCellWithIdentifier:cellid];
    }
    cell.path = indexPath;
    if ([[self.dataSrc[indexPath.row]  objectForKey:@"username"] isEqualToString:[self.userdefaults objectForKey:@"account"]] && [self.operLock.ismaster isEqualToString:@"1"])
    {
        [cell.imgForCount setImage:[UIImage imageNamed:[NSString stringWithFormat:@"countmanage.png"]]];
    }else
    {
        [cell.imgForCount setImage:[UIImage imageNamed:[NSString stringWithFormat:@"countshare.png"]]];
    }
    NSMutableString *name = (NSMutableString*)[[self.dataSrc objectAtIndex:indexPath.row] objectForKey:@"content"];
    NSString *name0 =  [name substringWithRange:NSMakeRange(3, name.length-3)];
    cell.name.text = name0;
    
    NSMutableString *time = [[NSMutableString stringWithString:[[self.dataSrc objectAtIndex:indexPath.row] objectForKey:@"oper_time"]] mutableCopy];
    if (![time isEqualToString:@""])
    {
        time = [[time substringWithRange:NSMakeRange(4, 8)] mutableCopy];
        [time insertString:@"." atIndex:2];
        [time insertString:@" " atIndex:5];
        [time insertString:@":" atIndex:8];
    }
    cell.date.text = time;
    cell.account.text = [[self.dataSrc objectAtIndex:indexPath.row] objectForKey:@"username"];
    switch ([[[self.dataSrc objectAtIndex:indexPath.row] objectForKey:@"oper_status"] integerValue])
    {
        case 1:
        {
            cell.oper_status.text = @"打开蓝牙";
        }
            break;
            
        case 2:
        {
            cell.oper_status.text = @"连接蓝牙";
        }
            break;
        case 3:
        {
            cell.oper_status.text = @"连接成功";
        }
            break;
        case 31:
        {
            cell.oper_status.text = @"连接失败";
        }
            break;
        case 4:
        {
            cell.oper_status.text = @"校验密钥";
        }
            break;
        case 5:
        {
            cell.oper_status.text = @"开锁成功";
        }
            break;
        case 51:
        {
            cell.oper_status.text = @"开锁失败";
        }
            break;
        default:
            break;
    }
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return self.dataSrc.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

-(void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self.view addSubview:self.dateView];
    self.dateView.alpha = 1;
    [self.view bringSubviewToFront:self.dateView];
    return NO;
}

-(void)search:(NSString*)str
{
    NSMutableArray *arr = [self.dataSrc mutableCopy];
    for (NSInteger i = 0; i < self.dataSrc.count; i++)
    {
        NSMutableString *time = (NSMutableString*)[NSMutableString stringWithString:[arr[i-(self.dataSrc.count-arr.count)] objectForKey:@"oper_time"]];
        time = (NSMutableString*)[time substringWithRange:NSMakeRange(0, str.length)];
        if ([time doubleValue] >= [str doubleValue]) {
            [arr removeObjectAtIndex:(i-(self.dataSrc.count-arr.count))];
        }
        time = nil;
    }
    self.dataSrc = [arr mutableCopy];
    arr = nil;
    [self.tabView reloadData];

}
@end
