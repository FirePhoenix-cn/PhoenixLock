//
//  CountLock.h
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"

@interface CountLock : LockViewController<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *search;
@property (strong, nonatomic) IBOutlet UITableView *tabView;
@property(retain, nonatomic) NSMutableArray *dataSrc;
@property(retain, nonatomic) NSMutableArray <SmartLock*>*datasrcdata;
@end
