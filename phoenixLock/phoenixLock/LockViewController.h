//
//  LockViewController.h
//  phoenixLock
//
//  Created by jinou on 16/8/26.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SmartLock.h"

@interface LockViewController : UIViewController
@property (strong, nonatomic) NSUserDefaults *userdefaults;
@property (strong, nonatomic) UIBarButtonItem *leftItem;
@property (strong, nonatomic) NSTimer *timer;
@property (retain, nonatomic) UIAlertController *alert;
/*转16进制*/

-(NSData *) NSStringConversionToNSData:(NSString*)string;
-(BOOL)isNewLock:(NSString*)globalcode;
-(void)insertLock:(void(^)(SmartLock *device))addlock;
-(void)updateLockMsg:(NSString*)globalcode withupdate:(void(^)(SmartLock *device))update;
-(NSArray<SmartLock*>*)showAllManagerLock;
-(NSArray<SmartLock*>*)showAllShareLock;
@end
