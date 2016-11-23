//
//  SmartApp.h
//  phoenixLock
//
//  Created by jinou on 16/4/22.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"

@interface SmartApp : LockViewController
@property (strong, nonatomic) IBOutlet UIView *view1;
@property (strong, nonatomic) IBOutlet UILabel *telphone;
@property (strong, nonatomic) IBOutlet UILabel *bindphone;
@property (strong, nonatomic) IBOutlet UIView *view2;
@property (strong, nonatomic) IBOutlet UILabel *used_min;
@property (strong, nonatomic) IBOutlet UILabel *retain_min;
@property (strong, nonatomic) IBOutlet UIView *view3;
@property (strong, nonatomic) IBOutlet UILabel *phonenum;
@end
