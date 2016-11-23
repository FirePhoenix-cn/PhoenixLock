//
//  LockViewController.m
//  phoenixLock
//
//  Created by jinou on 16/8/26.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"

@interface LockViewController ()
@property (strong,nonatomic) UISwipeGestureRecognizer *rightSwipe;
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
    self.leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goback.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = self.leftItem;
    self.leftItem = nil;
    self.userdefaults = [NSUserDefaults standardUserDefaults];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.rightSwipe];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void) didGetBattery:(NSInteger)battery forMac:(NSData*)mac{}

-(void) didDiscoverResult:(NSData *)macAddr deviceName:(NSData *)deviceName rssi:(NSNumber *)rssi{}

-(void) didDiscoverComplete{}

-(void) didConnectConfirm:(NSData *)macAddr status:(Boolean)status{}

-(void) didDisconnectIndication:(NSData *)macAddr{}

-(void) didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data{}

-(void) goBack{}

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

- (NSString *) NSDataConversionToNSString:(NSData*)data
{
    if (data == nil) {
        return @"";
    }
    
    NSMutableString *hexString = [NSMutableString string];
    
    const unsigned char *p = [data bytes];
    
    for (int i=0; i < [data length]; i++)
        [hexString appendFormat:@"%02x", *p++];
    
    return hexString;
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

-(BOOL)isNewLockWithDevuserid:(NSString*)devuserid
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCKS];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"devuserid=%@",devuserid];
    [request setPredicate:predicate];
    NSArray *resultArr = [context executeFetchRequest:request error:nil];
    if (resultArr.count>0) {
        return NO;
    }
    return YES;
}

-(void)insertLock:(void(^)(SmartLock *device))addlock
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    SmartLock *lock = [NSEntityDescription insertNewObjectForEntityForName:LOCKS inManagedObjectContext:context];
    addlock(lock);
    [context performBlockAndWait:^{
        [context save:nil];
//        [context.parentContext performBlock:^{
//            [context.parentContext save:nil];
//        }];
    }];
}

-(void)updateLockMsg:(NSString*)devuserid withupdate:(void(^)(SmartLock *device))update
{
    NSManagedObjectContext *context = self.appDelegate.privateContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCKS];
    if (devuserid.length == 20)
    {
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"globalcode=%@",devuserid];
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"ismaster=1"];
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
        [request setPredicate:predicate];
    }else
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"devuserid=%@",devuserid];
        [request setPredicate:predicate];
    }
    __weak __block SmartLock *lock;
    [context performBlockAndWait:^{
        __strong typeof(lock) strongLock = lock;
        strongLock = [[context executeFetchRequest:request error:nil] lastObject];
        if (strongLock)
        {
            update(strongLock);
            [context save:nil];
            [context.parentContext performBlockAndWait:^{
                [context.parentContext save:nil];
            }];
        }
    }];
}

-(NSArray<SmartLock*>*)showAllManagerLock
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCKS];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ismaster=1"];
    [request setPredicate:predicate];
    NSArray *arr = [context executeFetchRequest:request error:nil];
    return arr;
}

-(NSArray<SmartLock*>*)showAllShareLockByGlobalcode:(BOOL)byGlobalcode
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCKS];
    if (byGlobalcode)
    {
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"status=%@",@"1"];
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"ismaster=%@",@"0"];
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
        [request setPredicate:predicate];
    }else
    {
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"ismaster=%@",@"0"];
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"isdeleted=%@",@"nodeleted"];
        NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"status=%@",@"1"];
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2, predicate3]];
        [request setPredicate:predicate];
    }
    NSArray *arr = [context executeFetchRequest:request error:nil];
    return arr;
}

-(SmartLock*)lockWithDevuserid:(NSString*)devuserid inLocks:(NSArray<SmartLock *>*)locks
{
    for (SmartLock *lock in locks)
    {
        if ([devuserid isEqualToString:lock.devuserid])
        {
            return lock;
        }
    }
    return nil;
}

-(void)removeUselessLock:(NSArray*)devuseridTemp
{
    NSManagedObjectContext *context = self.appDelegate.privateContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSMutableArray <SmartLock*>* locks = [[context executeFetchRequest:request error:nil] mutableCopy];
    for (NSString *devuserid in devuseridTemp)
    {
        SmartLock *lock = [self lockWithDevuserid:devuserid inLocks:locks];
        if (lock != nil)
        {
            [locks removeObject:lock];
        }
    }
    if (locks.count == 0)
    {
        return;
    }
    for (SmartLock *lock in locks)
    {
        [context performBlock:^{
            [context deleteObject:lock];
        }];
    }
    [context performBlock:^{
        [context save:nil];
        [context.parentContext performBlock:^{
            [context.parentContext save:nil];
        }];
    }];
}

- (NSArray<SmartLock*>*)getAllTopPageLock
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCKS];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"istoppage=%@",[NSNumber numberWithBool:YES]];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"status=%@",@"1"];
    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"isdeleted=%@",@"nodeleted"];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2,predicate3]];
    [request setPredicate:predicate];
    NSArray *arr = [context executeFetchRequest:request error:nil];
    return arr;
}

-(NSArray<SmartLock*>*)getAllAutoUnlockedLock
{
    NSManagedObjectContext *context = self.appDelegate.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCKS];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"isautounlock=%@",[NSNumber numberWithBool:YES]];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"status=%@",@"1"];
    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"isdeleted=%@",@"nodeleted"];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2,predicate3]];
    [request setPredicate:predicate];
    NSArray *arr = [context executeFetchRequest:request error:nil];
    return arr;
}

-(void)clearAllData
{
    NSManagedObjectContext *context = ((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
    [self.userdefaults removeObjectForKey:@"wirelesslog"];
    [self.userdefaults synchronize];
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOCKS inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSArray *arr = [context executeFetchRequest:request error:nil];
    for (NSManagedObject *obj in arr)
    {
        [context performBlock:^{
            [context deleteObject:obj];
        }];
    }
    [context performBlock:^{
        [context save:nil];
    }];
}

@end
