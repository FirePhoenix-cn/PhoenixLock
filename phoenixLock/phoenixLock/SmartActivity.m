//
//  SmartActivity.m
//  phoenixLock
//
//  Created by jinou on 16/4/22.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "SmartActivity.h"

@interface SmartActivity ()

@end

@implementation SmartActivity

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"活动";
    self.webview.delegate = self;
    self.webview.scalesPageToFit = YES;
    self.navigationItem.leftBarButtonItem = nil;
    [NSThread detachNewThreadSelector:@selector(webload) toTarget:self withObject:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}
-(void)webload
{
    NSString *urlstr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=activity&account=%@&apptoken=%@",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"appToken"]];
    urlstr = [urlstr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlstr];
    urlstr = nil;
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    url = nil;
    [self.webview loadRequest:req];
}
//开始加载时调用的方法
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

//结束加载时调用的方法
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
}

//加载失败时调用的方法
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) goBack{
    [self.navigationController popViewControllerAnimated:YES];
}


@end
