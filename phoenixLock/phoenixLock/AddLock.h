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

- (IBAction)scanQRCode:(UIButton *)sender;
@property (retain, nonatomic) IBOutlet UIButton *btn;
@property (retain, nonatomic) NSString *GUID;
@end
