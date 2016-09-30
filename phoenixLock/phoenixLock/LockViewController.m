//
//  LockViewController.m
//  phoenixLock
//
//  Created by jinou on 16/8/26.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"

@interface LockViewController ()

@end

@implementation LockViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor * color = [UIColor whiteColor];
    NSDictionary * dict = [NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dict;//标题颜色
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];//按钮颜色
    self.navigationController.navigationBar.barTintColor = [UIColor darkGrayColor];//状态栏颜色
    
    _leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goback.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = _leftItem;
    _leftItem = nil;
    
    _userdefaults = [NSUserDefaults standardUserDefaults];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
}

//返回键方法重新实现
-(void) goBack
{
    
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(void)updateLockMsg:(NSString*)globalcode withupdate:(void(^)(SmartLock *device))update
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

-(NSArray<SmartLock*>*)showAllManagerLock
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ismaster=%@",@"1"];
    [request setPredicate:predicate];
    return [((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext executeFetchRequest:request error:nil];
}

-(NSArray<SmartLock*>*)showAllShareLock
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ismaster=%@",@"0"];
    [request setPredicate:predicate];
    NSMutableArray *arr = [[((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext executeFetchRequest:request error:nil] mutableCopy];
    for (SmartLock *lock in arr)
    {
        if ([lock.begin_time isEqualToString:lock.isdeleted])
        {
            [arr removeObject:lock];
        }
    }
    return arr;
}

@end
