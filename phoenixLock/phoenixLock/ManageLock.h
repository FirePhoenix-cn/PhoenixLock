//
//  ManageLock.h
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"


@interface ManageLock : LockViewController<UITableViewDelegate,UITableViewDataSource,libBleLockDelegate>

@property(strong, nonatomic) UITableView *tabView;
@property(retain, nonatomic) NSMutableArray *dataSrc;
@property(retain, nonatomic) NSMutableArray <SmartLock*>*datasrcdata;
@property(assign,nonatomic) BOOL isEdit;
@end
