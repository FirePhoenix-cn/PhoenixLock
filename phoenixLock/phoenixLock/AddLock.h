//
//  AddLock.h
//  phoenixLock
//
//  Created by qcy on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "QRReaderViewController.h"
#import "LockViewController.h"
@interface AddLock : LockViewController<QRReaderViewControllerDelegate,libBleLockDelegate>

@property (strong, nonatomic) IBOutlet UIButton *btn;
@property (strong, nonatomic) NSString *globalcode;
@property (strong, nonatomic) NSString *sc;
@property (strong, nonatomic) NSString *sd;
@end
