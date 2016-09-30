//
//  BLEConnect.h
//  phoenixLock
//
//  Created by jinou on 16/4/28.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "AddLock.h"

@interface BLEConnect : AddLock<libBleLockDelegate>
@property (strong, nonatomic) IBOutlet UILabel *openBLE;
@property (strong, nonatomic) IBOutlet UILabel *next1;
@property (strong, nonatomic) IBOutlet UILabel *connectingBLE;
@property (strong, nonatomic) IBOutlet UILabel *next2;
@property (strong, nonatomic) IBOutlet UILabel *mateBLE;
@property (strong, nonatomic) IBOutlet UILabel *next3;
@property (strong, nonatomic) IBOutlet UILabel *checkManager;
@property (strong, nonatomic) IBOutlet UILabel *next4;
@property (strong, nonatomic) IBOutlet UILabel *addSuccess;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong,nonatomic) NSData *guid;
@property (strong,nonatomic) NSData *mac;
@property (strong,nonatomic) NSData *uuid;
@property (strong,nonatomic) NSData *scrB;
@property (strong,nonatomic) NSData *scrC;
@property (strong,nonatomic) NSData *scrD;
@end
