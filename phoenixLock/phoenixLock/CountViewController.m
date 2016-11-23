//
//  CountViewController.m
//  phoenixLock
//
//  Created by jinou on 16/10/11.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CountViewController.h"
#import "CountLock.h"

@interface CountViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) NSMutableArray <SmartLock*>*datasrc;
@end

static NSString *cellid = @"countviewcell";

@implementation CountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"云盾锁";
    self.datasrc = [NSMutableArray arrayWithArray:[self showAllManagerLock]];
    [self.datasrc addObjectsFromArray:[self showAllShareLockByGlobalcode:YES]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datasrc.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self.tableview dequeueReusableCellWithIdentifier:cellid];
    UIImageView *imgv = [cell viewWithTag:1];
    UILabel *name = [cell viewWithTag:2];
    name.text = [self.datasrc[indexPath.row] devname];
    if ([[self.datasrc[indexPath.row] ismaster] isEqualToString:@"1"])
    {
        [imgv setImage:[UIImage imageNamed:[NSString stringWithFormat:@"countmanage.png"]]];
    }else
    {
        [imgv setImage:[UIImage imageNamed:[NSString stringWithFormat:@"countshare.png"]]];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CountLock *countlock = [sb instantiateViewControllerWithIdentifier:@"CountLock"];
    countlock.operLock = self.datasrc[indexPath.row];
    [self.navigationController pushViewController:countlock animated:YES];
}

-(void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
