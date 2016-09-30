//
//  ManageLock.h
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"
#import "CellForManageHeader.h"
#import "CellFormanageFooder.h"

@interface ManageLock : LockViewController<UITableViewDelegate,UITableViewDataSource,CellForManageHeaderDelegate,CellFormanageFooderDelegate,libBleLockDelegate>

@property(strong, nonatomic) UITableView *tabView;
@property(retain, nonatomic) NSMutableArray *dataSrc;
@property(retain, nonatomic) NSArray <SmartLock*>*datasrcdata;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property(assign,nonatomic) BOOL isEdit;
@property (strong, nonatomic) UIAlertController *aler;

@end
