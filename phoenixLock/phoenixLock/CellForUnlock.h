//
//  CellForUnlock.h
//  phoenixLock
//
//  Created by qcy on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewCell.h"

@interface CellForUnlock : TableViewCell<libBleLockDelegate>

@property (strong, nonatomic) IBOutlet UILabel *openbluetooth;
@property (strong, nonatomic) IBOutlet UILabel *next1;
@property (strong, nonatomic) IBOutlet UILabel *connect;
@property (strong, nonatomic) IBOutlet UILabel *next2;
@property (strong, nonatomic) IBOutlet UILabel *mate;
@property (strong, nonatomic) IBOutlet UILabel *next3;
@property (strong, nonatomic) IBOutlet UILabel *checkkey;
@property (strong, nonatomic) IBOutlet UILabel *next4;
@property (strong, nonatomic) IBOutlet UILabel *opened;
@property (assign, nonatomic) NSInteger ismaster;
@property (strong,nonatomic) NSString *globalcode;
@property (strong,nonatomic) NSString *devcode;
@property (strong,nonatomic) NSString *authcode;
@property (strong,nonatomic) NSString *comucode;
@property (assign,nonatomic) BOOL isactive;
@property (strong,nonatomic) NSData *guid;
@property (strong,nonatomic) NSData *mac;
@property (strong, nonatomic) NSString *devuserid;
@end
