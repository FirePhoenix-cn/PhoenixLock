//
//  AppDelegate.m
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "AppDelegate.h"
#import "IQKeyboardManager.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
//腾讯开放平台（对应QQ和QQ空间）SDK头文件
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>

//微信SDK头文件
#import "WXApi.h"

//新浪微博SDK头文件
#import "WeiboSDK.h"
//新浪微博SDK需要在项目Build Settings中的Other Linker Flags添加"-ObjC"

@interface AppDelegate ()

@end

@implementation AppDelegate



//- (void)redirectNSLogToDocumentFolder
//{
//    //如果已经连接Xcode调试则不输出到文件
//    if(isatty(STDOUT_FILENO)) {
//        return;
//    }
//    
//    UIDevice *device = [UIDevice currentDevice];
//    if([[device model] hasSuffix:@"Simulator"]){ //在模拟器不保存到文件中
//        return;
//    }
//    
//    //将NSlog打印信息保存到Document目录下的Log文件夹下
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Log"];
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    BOOL fileExists = [fileManager fileExistsAtPath:logDirectory];
//    if (!fileExists) {
//        [fileManager createDirectoryAtPath:logDirectory  withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//    
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
//    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"]; //每次启动后都保存一个新的日志文件中
//    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
//    NSString *logFilePath = [logDirectory stringByAppendingFormat:@"/%@.log",dateStr];
//    
//    // 将log输入到文件
//    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
//    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
//    
//    //未捕获的Objective-C异常日志
//    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
//}
//
//void UncaughtExceptionHandler(NSException* exception)
//{
//    NSString* name = [ exception name ];
//    NSString* reason = [ exception reason ];
//    NSArray* symbols = [ exception callStackSymbols ]; // 异常发生时的调用栈
//    NSMutableString* strSymbols = [ [ NSMutableString alloc ] init ]; //将调用栈拼成输出日志的字符串
//    for ( NSString* item in symbols )
//    {
//        [ strSymbols appendString: item ];
//        [ strSymbols appendString: @"\r\n" ];
//    }
//    
//    //将crash日志保存到Document目录下的Log文件夹下
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Log"];
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if (![fileManager fileExistsAtPath:logDirectory]) {
//        [fileManager createDirectoryAtPath:logDirectory  withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//    
//    NSString *logFilePath = [logDirectory stringByAppendingPathComponent:@"UncaughtException.log"];
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
//    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
//    
//    NSString *crashString = [NSString stringWithFormat:@"<- %@ ->[ Uncaught Exception ]\r\nName: %@, Reason: %@\r\n[ Fe Symbols Start ]\r\n%@[ Fe Symbols End ]\r\n\r\n", dateStr, name, reason, strSymbols];
//    //把错误日志写到文件中
//    if (![fileManager fileExistsAtPath:logFilePath]) {
//        [crashString writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    }else{
//        NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
//        [outFile seekToEndOfFile];
//        [outFile writeData:[crashString dataUsingEncoding:NSUTF8StringEncoding]];
//        [outFile closeFile];
//    }
//}
//


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] setObject:@"1.5.0" forKey:@"appversion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _appLibBleLock = [[libBleLock alloc] initWithDelegate:nil];
    _delegatehttppost = [[HTTPPost alloc] init];
    //[self redirectNSLogToDocumentFolder];
    [IQKeyboardManager sharedManager].enable = YES;
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = NO;
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
    
    [ShareSDK registerApp:@"14fe31a0ffd0c" activePlatforms:@[@(SSDKPlatformTypeSinaWeibo),
                                                             @(SSDKPlatformSubTypeQZone),
                                                             @(SSDKPlatformTypeSMS),
                                                             @(SSDKPlatformSubTypeWechatSession),
                                                             @(SSDKPlatformSubTypeQQFriend),
                                                             @(SSDKPlatformSubTypeWechatTimeline)
                                                             ] onImport:^(SSDKPlatformType platformType) {
                                                                 switch (platformType)
                                                                 {
                                                                     case SSDKPlatformTypeWechat:
                                                                         [ShareSDKConnector connectWeChat:[WXApi class]];
                                                                         break;
                                                                     case SSDKPlatformTypeQQ:
                                                                         [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                                                                         break;
                                                                     case SSDKPlatformTypeSinaWeibo:
                                                                         [ShareSDKConnector connectWeibo:[WeiboSDK class]];
                                                                         break;
                                                                     default:
                                                                         break;
                                                                 }
        
    } onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo) {
        switch (platformType)
        {
            case SSDKPlatformTypeSinaWeibo:
                //设置新浪微博应用信息,其中authType设置为使用SSO＋Web形式授权
                [appInfo SSDKSetupSinaWeiboByAppKey:@"568898243"
                                          appSecret:@"38a4f8204cc784f81f9f0daaf31e02e3"
                                        redirectUri:@"http://www.sharesdk.cn"
                                           authType:SSDKAuthTypeBoth];
                break;
            case SSDKPlatformTypeWechat:
                [appInfo SSDKSetupWeChatByAppId:@"wx4c8b18c851b5d83a"
                                      appSecret:@"f31a11fcecf1bba87f91bdbafd72e456"];
                break;
            case SSDKPlatformTypeQQ:
                [appInfo SSDKSetupQQByAppId:@"100371282"
                                     appKey:@"aed9b0303e3ed1e27bae87c33761161d"
                                   authType:SSDKAuthTypeBoth];
                break;
            default:
                break;
        }
        
    }];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"canautounlock"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   
}

- (void)applicationWillTerminate:(UIApplication *)application
{
   [self saveContext];
}

#pragma mark - Core Data stack

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
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"coredata.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
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
