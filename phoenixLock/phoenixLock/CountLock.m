//
//  CountLock.m
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CountLock.h"
#import "TableCell.h"

@interface CountLock ()<HTTPPostDelegate>
{
    NSInteger _downloadcount;
    httpPostType _type;
}
@property (strong, nonatomic) HTTPPost *httppost;
@property (strong ,nonatomic) NSMutableArray *tempdic;
@end

@implementation CountLock

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"云盾锁";
    
    _tabView.delegate =self;
    _tabView.dataSource =self;
    _tabView.showsVerticalScrollIndicator = NO;
    [_tabView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.search.delegate = self;
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    
    
    _dataSrc = [NSMutableArray array];
    _tempdic = [NSMutableArray array];
}

-(void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    _httppost.delegate = self;
    _downloadcount = 0;
    //下载日志（全部）先管理员后分享者
    _datasrcdata = [NSMutableArray arrayWithArray:[self showAllManagerLock]];
    [_datasrcdata addObjectsFromArray:[self showAllShareLock]];
    if (_datasrcdata.count>0)
    {
        [self downloadlog];
    }
}

-(void)downloadlog
{
    NSString *url = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=downloadlog&account=%@&apptoken=%@&uuid=%@&globalcode=%@&devcode=%@",
                     [self.userdefaults objectForKey:@"account"],
                     [self.userdefaults objectForKey:@"appToken"],
                     [self.userdefaults objectForKey:@"uuid"],
                     [_datasrcdata[_downloadcount] globalcode],
                     [[_datasrcdata[_downloadcount] uuid] substringWithRange:NSMakeRange(68, 32)]];
    
    [_httppost httpPostWithurl:url];
    _type = downloadlog;
}



-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    switch (_type)
    {
        case downloadlog:
        {
            
            NSArray *rdata = [dic objectForKey:@"data"];
            for (NSInteger i=0; i<rdata.count; i++)
            {
                [_dataSrc addObject:rdata[i]];
                [_tempdic addObject:rdata[i]];
            }
            _downloadcount ++;
            if (_downloadcount < _datasrcdata.count) {
                [self downloadlog];
                return;
            }
            //排序
            NSArray *sortDesc = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"oper_time" ascending:YES]];
            _dataSrc = (NSMutableArray*)[_dataSrc sortedArrayUsingDescriptors:sortDesc];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_tabView reloadData];
            });

        }
        break;
            
        default:
            break;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    TableCell *cell0 =  [_tabView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell0 == nil)
    {
        cell0 = [[TableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell0 = (TableCell *)[[[NSBundle  mainBundle]  loadNibNamed:@"TableCell" owner:self options:nil]  lastObject];
    }
    cell0.path = indexPath;
    
    if ([[_dataSrc[indexPath.row]  objectForKey:@"username"] isEqualToString:[self.userdefaults objectForKey:@"account"]]) {
        [cell0.imgForCount setImage:[UIImage imageNamed:[NSString stringWithFormat:@"countmanage.png"]]];
    }else{
        [cell0.imgForCount setImage:[UIImage imageNamed:[NSString stringWithFormat:@"countshare.png"]]];
    }
    
    NSMutableString *name = (NSMutableString*)[[_dataSrc objectAtIndex:indexPath.row] objectForKey:@"content"];
    
    NSString *name0 =  [name substringWithRange:NSMakeRange(3, name.length-3)];
    
    cell0.name.text = name0;
    
    NSMutableString *time = [[NSMutableString stringWithString:[[_dataSrc objectAtIndex:indexPath.row] objectForKey:@"oper_time"]] mutableCopy];
    if (![time isEqualToString:@""])
    {
        time = [[time substringWithRange:NSMakeRange(4, 8)] mutableCopy];
        [time insertString:@"." atIndex:2];
        [time insertString:@" " atIndex:5];
        [time insertString:@":" atIndex:8];
    }
    cell0.date.text = time;
    
    cell0.account.text = [[_dataSrc objectAtIndex:indexPath.row] objectForKey:@"username"];
    
    switch ([[[_dataSrc objectAtIndex:indexPath.row] objectForKey:@"oper_status"] integerValue])
    {
        case 1:
        {
            cell0.oper_status.text = @"打开蓝牙";
        }
            break;
            
        case 2:
        {
            cell0.oper_status.text = @"连接蓝牙";
        }
            break;
        case 3:
        {
            cell0.oper_status.text = @"连接成功";
        }
            break;
        case 31:
        {
            cell0.oper_status.text = @"连接失败";
        }
            break;
        case 4:
        {
            cell0.oper_status.text = @"校验密钥";
        }
            break;
        case 5:
        {
            cell0.oper_status.text = @"开锁成功";
        }
            break;
        case 51:
        {
            cell0.oper_status.text = @"开锁失败";
        }
            break;
        default:
            break;
    }
    return cell0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return _dataSrc.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
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

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *passwordNumberRegex = @"[0-9]{4,12}";
    NSPredicate *mobileNumberTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordNumberRegex];
    
    if ([mobileNumberTest evaluateWithObject:textField.text])
    {
        _dataSrc = _tempdic;
        [self search:textField.text];
    }
    else
    {
        _dataSrc = _tempdic;
        [_tabView reloadData];
    }
}

-(void)search:(NSString*)str
{
    NSMutableArray *arr = [_dataSrc mutableCopy];
    for (NSInteger i = 0; i < _dataSrc.count; i++)
    {
        NSMutableString *time = (NSMutableString*)[NSMutableString stringWithString:[arr[i-(_dataSrc.count-arr.count)] objectForKey:@"oper_time"]];
        time = (NSMutableString*)[time substringWithRange:NSMakeRange(0, str.length)];
        if ([time doubleValue] < [str doubleValue]) {
            [arr removeObjectAtIndex:(i-(_dataSrc.count-arr.count))];
        }
        time = nil;
    }
    _dataSrc = [arr mutableCopy];
    arr = nil;
    [_tabView reloadData];

}
@end
