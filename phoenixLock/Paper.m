//
//  Paper.m
//  phoenixLock
//
//  Created by jinou on 16/8/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "Paper.h"


@interface Paper ()<HTTPPostDelegate>
{
    httpPostType _type;
}

@end

@implementation Paper

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem* leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"goback.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = leftItem;
    _httppost = ((AppDelegate*)[UIApplication sharedApplication].delegate).delegatehttppost;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _httppost.delegate = self;
    NSString *urlStr = @"http://safe.gzhtcloud.com/index.php?g=Home&m=Lock&a=syscontent";
    NSString *body = [NSString stringWithFormat:@"&appid=69639238674&apptoken=jWIe3kf4ZJFfVKA2zZf8Fm8J&action=agreement"];
    _type = syscontentservice;
    [_httppost httpPostWithurl :urlStr body:body];
    
}

-(void)didRecieveData:(NSDictionary *)dic withTimeinterval:(NSTimeInterval)interval
{
   
    switch (_type)
    {
        case syscontentservice:
        {
            if ([[dic objectForKey:@"status"] isEqualToString:@"1"])
            {
                NSMutableString *content = [[dic objectForKey:@"content"] mutableCopy];
                NSString *copycontent = [content substringWithRange:NSMakeRange(3, content.length - 7)];
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    _textview.text = copycontent;
                                   
                });
                
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}


@end
