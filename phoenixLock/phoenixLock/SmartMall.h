//
//  SmartMall.h
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"

@interface SmartMall : LockViewController<UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webview;
@end
