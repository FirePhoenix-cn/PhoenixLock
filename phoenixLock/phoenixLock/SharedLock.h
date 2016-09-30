//
//  SharedLock.h
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"
#import "CellForSharedLock.h"

@interface SharedLock : LockViewController<UITableViewDelegate,UITableViewDataSource,CellForSharedLockDelegate,libBleLockDelegate>

@property(strong, nonatomic) UITableView *tabView;
@property(retain, nonatomic) NSMutableArray *dataSrc;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property(assign,nonatomic) BOOL isEdit;
@property(retain, nonatomic) NSMutableArray <SmartLock*>*datasrcdata;
@end
