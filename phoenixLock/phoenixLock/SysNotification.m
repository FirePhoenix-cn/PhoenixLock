//
//  SysNotification.m
//  phoenixLock
//
//  Created by jinou on 16/7/4.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "SysNotification.h"
#import "AboutUs.h"
@interface syscell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *titles;
@property (strong, nonatomic) IBOutlet UILabel *times;
@property (strong, nonatomic) IBOutlet UIImageView *pic;

@end

@implementation syscell

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [[UIColor grayColor] CGColor];
}

@end


@interface SysNotification ()<UITableViewDelegate,UITableViewDataSource,HTTPPostDelegate>

@property(strong,nonatomic)HTTPPost *httppost;
@property(assign,nonatomic)httpPostType posttype;
@property(strong, nonatomic) NSMutableArray *datasrc;
@property (strong, nonatomic) NSUserDefaults *userdefaults;

@end

@implementation SysNotification

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"系统消息";
    _datasrc = [NSMutableArray arrayWithArray:@[]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    
    _userdefaults = [NSUserDefaults standardUserDefaults];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=msgpush";
    NSString *body = [NSString stringWithFormat:@"&account=%@&apptoken=%@",[_userdefaults objectForKey:@"account"],[_userdefaults objectForKey:@"appToken"]];
    
    _posttype = sysmsg;
    [self.httppost httpPostWithurl:urlStr body:body];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
    switch (_posttype)
    {
        case sysmsg:
        {
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                for (NSDictionary *dict in [dic objectForKey:@"data"])
                {
                    [_datasrc addObject:dict];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_tableView reloadData];
                });
            }
        }
            break;
            
        default:
            break;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _datasrc.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    syscell *cell = [_tableView dequeueReusableCellWithIdentifier:@"syscell"];
    if (cell == nil) {
        cell = [[syscell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"syscell"];
        cell = (syscell*)[[[NSBundle  mainBundle]  loadNibNamed:@"syscell" owner:self options:nil]  lastObject];
    }
    cell.titles.text = [_datasrc[indexPath.row] objectForKey:@"title"];
    cell.times.text = [_datasrc[indexPath.row] objectForKey:@"createtime"];
    if ([self findedmsgid:[_datasrc[indexPath.row] objectForKey:@"msgid"]])
    {
        [cell.pic setImage:[UIImage imageNamed:@"openmess.png"]];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSMutableArray *newarr = [NSMutableArray arrayWithArray:[self.userdefault objectForKey:@"readedmsgid"]];
    if (![self findedmsgid:[_datasrc[indexPath.row] objectForKey:@"msgid"]]) {
        [newarr addObject:[_datasrc[indexPath.row] objectForKey:@"msgid"]];
        [self.userdefault setObject:newarr forKey:@"readedmsgid"];
        [self.userdefault synchronize];
    }
    syscell * cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell.pic setImage:[UIImage imageNamed:@"openmess.png"]];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Account" bundle:nil];
        AboutUs *next = (AboutUs*)[sb instantiateViewControllerWithIdentifier:@"AboutUs"];
        next.inittitle = @"消息内容";
        next.text = [_datasrc[indexPath.row] objectForKey:@"content"];
        [self.navigationController pushViewController:next animated:YES];
    });
}

-(BOOL)findedmsgid:(NSString*)msgid
{
    for (NSString *str in [self.userdefault objectForKey:@"readedmsgid"])
    {
        if ([str isEqualToString:msgid])
        {
            return YES;
        }
    }
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
