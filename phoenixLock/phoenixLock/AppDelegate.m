//
//  AppDelegate.m
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "AppDelegate.h"
#import "IQKeyboardManager.h"
#import "ShareDelegate.h"


@interface AppDelegate ()<UNUserNotificationCenterDelegate>
{
    UIBackgroundTaskIdentifier _backgroundTaskID;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)
    {
        [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError * _Nullable error) {
        }];
    }else
    {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil]];
    }
    self.searchLock = NO;
    [[NSUserDefaults standardUserDefaults] setObject:@"V 1.5.7" forKey:@"appversion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.appLibBleLock = [[libBleLock alloc] initWithDelegate:nil];
    self.delegatehttppost = [[HTTPPost alloc] init];
    [IQKeyboardManager sharedManager].enable = YES;
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = NO;
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
    [ShareDelegate registerShareSDK];
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    self.searchLock = NO;
    [self.searchTimer setFireDate:[NSDate distantPast]];
    _backgroundTaskID = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:_backgroundTaskID];
        _backgroundTaskID = UIBackgroundTaskInvalid;
    }];
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(backGroundTimer) userInfo:nil repeats:YES];
}

-(BOOL)backGroundTimer
{
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [application endBackgroundTask:_backgroundTaskID];
    _backgroundTaskID = UIBackgroundTaskInvalid;
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SENDNOTIFY(@"stopSearch")
    });
}

- (void)applicationWillTerminate:(UIApplication *)application
{
   [self saveContext];
}

//-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler
//{
//    //NSLog(@"%@",response);
//}
//
//-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
//{
//    //NSLog(@"%@",notification.userInfo);
//}

-(UILocalNotification *)localNotify
{
    if (!_localNotify) {
        _localNotify = [[UILocalNotification alloc] init];
        _localNotify.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        _localNotify.alertTitle = @"自动开锁";
        //_localNotify.alertBody = @"点我打开APP";
        _localNotify.hasAction = NO;
    }
    return _localNotify;
}

#pragma mark - Core Data stack

@synthesize privateContext = _privateContext;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"coredata" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderPath = [NSString stringWithFormat:@"%@/coredata",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
    
    if(![fileManager fileExistsAtPath:folderPath]){//如果不存在,则说明是第一次运行这个程序，那么建立这个文件夹
        
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             
                             [NSNumber numberWithBool:YES],
                             
                             NSMigratePersistentStoresAutomaticallyOption,
                             
                             [NSNumber numberWithBool:YES],
                             
                             NSInferMappingModelAutomaticallyOption, nil];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"coredata.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

-(NSManagedObjectContext *)privateContext
{
    if (_privateContext)
    {
        return _privateContext;
    }
    _privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_privateContext setParentContext:self.managedObjectContext];
    return _privateContext;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
@end
