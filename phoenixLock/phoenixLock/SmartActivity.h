//
//  SmartActivity.h
//  phoenixLock
//
//  Created by jinou on 16/4/22.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"

@interface SmartActivity : LockViewController<UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webview;

@end
