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
@property(strong, nonatomic) NSMutableArray *datasrc;
@property (strong, nonatomic) NSUserDefaults *userdefaults;

@end

@implementation SysNotification

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.datasrc = [NSMutableArray arrayWithArray:@[]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
    
    self.userdefaults = [NSUserDefaults standardUserDefaults];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.httppost.delegate = self;
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=msgpush";
    NSString *body = [NSString stringWithFormat:@"&account=%@&apptoken=%@",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"appToken"]];
    [self.httppost httpPostWithurl:urlStr body:body type:sysmsg];
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type
{
    switch (type)
    {
        case sysmsg:
        {
            if ([[dic objectForKey:@"status"] integerValue] == 1)
            {
                for (NSDictionary *dict in [dic objectForKey:@"data"])
                {
                    [self.datasrc addObject:dict];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
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
    return self.datasrc.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *syscellid = @"syscell";
    syscell *cell = [self.tableView dequeueReusableCellWithIdentifier:syscellid];
    if (!cell)
    {
        [tableView registerNib:[UINib nibWithNibName:syscellid bundle:nil] forCellReuseIdentifier:syscellid];
        cell = [self.tableView dequeueReusableCellWithIdentifier:syscellid];
    }
    cell.titles.text = [self.datasrc[indexPath.row] objectForKey:@"title"];
    cell.times.text = [self.datasrc[indexPath.row] objectForKey:@"createtime"];
    if ([self findedmsgid:[self.datasrc[indexPath.row] objectForKey:@"msgid"]])
    {
        [cell.pic setImage:[UIImage imageNamed:@"openmess.png"]];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSMutableArray *newarr = [NSMutableArray arrayWithArray:[self.userdefault objectForKey:@"readedmsgid"]];
    if (![self findedmsgid:[self.datasrc[indexPath.row] objectForKey:@"msgid"]]) {
        [newarr addObject:[self.datasrc[indexPath.row] objectForKey:@"msgid"]];
        [self.userdefault setObject:newarr forKey:@"readedmsgid"];
        [self.userdefault synchronize];
    }
    syscell * cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell.pic setImage:[UIImage imageNamed:@"openmess.png"]];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Account" bundle:nil];
        AboutUs *next = (AboutUs*)[sb instantiateViewControllerWithIdentifier:@"AboutUs"];
        next.inittitle = @"消息内容";
        next.text = [self.datasrc[indexPath.row] objectForKey:@"content"];
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
