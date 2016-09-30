//
//  CellForUnlock.h
//  phoenixLock
//
//  Created by qcy on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SmartLock.h"
@interface CellForUnlock : UITableViewCell<CBCentralManagerDelegate,libBleLockDelegate>

@property (retain, nonatomic) NSUserDefaults *userdefaults;
@property (weak, nonatomic) IBOutlet UILabel *openbluetooth;
@property (weak, nonatomic) IBOutlet UILabel *next1;
@property (weak, nonatomic) IBOutlet UILabel *connect;
@property (weak, nonatomic) IBOutlet UILabel *next2;
@property (weak, nonatomic) IBOutlet UILabel *mate;
@property (weak, nonatomic) IBOutlet UILabel *next3;
@property (weak, nonatomic) IBOutlet UILabel *checkkey;
@property (weak, nonatomic) IBOutlet UILabel *next4;
@property (weak, nonatomic) IBOutlet UILabel *opened;

@property (nonatomic, strong) CBCentralManager *manager;
@property (weak, nonatomic) AppDelegate *appDelegate;

@property (retain, nonatomic) NSIndexPath * path;
@property (assign, nonatomic) NSInteger ismaster;

@property (strong,nonatomic) NSString *globalcode;

@property (strong,nonatomic) NSString *devcode;

@property (strong,nonatomic) NSString *authcode;
@property (strong,nonatomic) NSString *comucode;
@property (assign,nonatomic) BOOL isactive;
@property (strong,nonatomic) NSData *guid;
@property (strong,nonatomic) NSData *mac;
@property (weak, nonatomic) NSTimer *timer;

@end
