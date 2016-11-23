//
//  SmartMall.m
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "SmartMall.h"

@interface SmartMall ()

@end

@implementation SmartMall

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"商城";
    self.webview.delegate = self;
    self.webview.scalesPageToFit = YES;
    [NSThread detachNewThreadSelector:@selector(webload) toTarget:self withObject:nil];
}

-(void)webload
{
    NSString *urlstr = [NSString stringWithFormat:@"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=shop&account=%@&apptoken=%@",[self.userdefaults objectForKey:@"account"],[self.userdefaults objectForKey:@"appToken"]];
    urlstr = [urlstr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlstr];
    urlstr = nil;
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    url = nil;
    [self.webview loadRequest:req];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

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


-(void) goBack
{
    [self.webview goBack];
}
@end
