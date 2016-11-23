//
//  HTTPPost.m
//  phoenixLock
//
//  Created by jinou on 16/5/12.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "HTTPPost.h"
#import "Reachability.h"
@interface HTTPPost()
//@property (nonatomic, strong) NSMutableData *datatempbuff;
@property(nonatomic, assign) httpPostType postType;
@end

@implementation HTTPPost

+ (BOOL)isConnectionAvailable
{
    
     Reachability *reachability = [Reachability reachabilityForInternetConnection];
    
    if ([reachability currentReachabilityStatus] == 0)
    {
        return NO;
    }
    return YES;
}

-(void)httpPostWithurl:(NSString*)urlString type:(httpPostType)type
{
    if([HTTPPost  isConnectionAvailable] == NO)
    {
        return;
    }
    //_datatempbuff = nil;
    
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionDataTask *task in dataTasks)
        {
            [task cancel];
            
        }
    }];
    
    self.postType = type;
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
}

-(void)httpPostWithurl:(NSString*)urlString body:(NSString*)body type:(httpPostType)type
{
    if([HTTPPost  isConnectionAvailable] == NO)
    {
        return;
    }
    //_datatempbuff = nil;
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionDataTask *task in dataTasks)
        {
            [task cancel];
        }
    }];
    self.postType = type;
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    
    NSArray *arr = [NSArray arrayWithArray:[[[(NSHTTPURLResponse*)dataTask.response allHeaderFields] objectForKey:@"date"] componentsSeparatedByString:@" "]];
    NSString *date = [NSString stringWithFormat:@"%@%@%@%@ 8",arr[1],[HTTPPost entostring:arr[2]],arr[3],arr[4]];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"ddMMyyyyHH:mm:ss z"];
    NSDate *nettime = [formatter dateFromString:date];
    
    NSLog(@"data:%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
    
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    for (NSString *key in [dic allKeys])
    {
        if ([[dic objectForKey:key] isKindOfClass:[NSNull class]])
        {
            [dic setObject:@"" forKey:key];
        }
    }
    
    [self.delegate didRecieveData:dic withTimeinterval:[nettime timeIntervalSinceNow] type:self.postType];
}

-(NSURLSession *)session
{
    if (!_session)
    {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    return _session;
}

//- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
//    didReceiveData:(NSData *)data
//{
//    if (_datatempbuff == nil)
//    {
//        _datatempbuff = [NSMutableData dataWithData:data];
//    }else
//    {
//        [_datatempbuff appendData:data];
//    }
//    id dic = [NSJSONSerialization JSONObjectWithData:_datatempbuff options:NSJSONReadingMutableContainers error:nil];
//    if (![dic isKindOfClass:[NSDictionary class]])
//    {
//        NSLog(@"data:%@",[[NSString alloc]initWithData:_datatempbuff encoding:NSUTF8StringEncoding]);
//        dic = nil;
//        return;
//    }
//    NSArray *arr = [NSArray arrayWithArray:[[[(NSHTTPURLResponse*)dataTask.response allHeaderFields] objectForKey:@"date"] componentsSeparatedByString:@" "]];
//    NSString *date = [NSString stringWithFormat:@"%@%@%@%@ 8",arr[1],[HTTPPost entostring:arr[2]],arr[3],arr[4]];
//    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat: @"ddMMyyyyHH:mm:ss z"];
//    NSDate *nettime = [formatter dateFromString:date];
//    
//    NSLog(@"data:%@",[[NSString alloc]initWithData:_datatempbuff encoding:NSUTF8StringEncoding]);
//    
//    [_delegate didRecieveData:_datatempbuff withTimeinterval:[nettime timeIntervalSinceNow]];
//    _session = nil;
//    _task = nil;
//}


//解决网络时间格式不规范的问题
+(NSString*)entostring:(NSString*)month{
    NSString *mon;
    if ([month isEqualToString:@"Jan"]) {
        mon = @"01";
    }else if([month isEqualToString:@"Feb"]){
        mon = @"02";
    }else if([month isEqualToString:@"Mar"]){
        mon = @"03";
    }else if([month isEqualToString:@"Apr"]){
        mon = @"04";
    }else if([month isEqualToString:@"May"]){
        mon = @"05";
    }else if([month isEqualToString:@"Jun"]){
        mon = @"06";
    }else if([month isEqualToString:@"June"]){
        mon = @"06";
    }else if([month isEqualToString:@"Jul"]){
        mon = @"07";
    }else if([month isEqualToString:@"July"]){
        mon = @"07";
    }else if([month isEqualToString:@"Aug"]){
        mon = @"08";
    }else if([month isEqualToString:@"Sep"]){
        mon = @"09";
    }else if([month isEqualToString:@"Sept"]){
        mon = @"09";
    }else if([month isEqualToString:@"Oct"]){
        mon = @"10";
    }else if([month isEqualToString:@"Nov"]){
        mon = @"11";
    }else if([month isEqualToString:@"Dec"]){
        mon = @"12";
    }
    return mon;
}

@end
