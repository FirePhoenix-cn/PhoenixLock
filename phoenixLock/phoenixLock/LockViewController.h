//
//  LockViewController.h
//  phoenixLock
//
//  Created by jinou on 16/8/26.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LockViewController : UIViewController
@property (strong, nonatomic) NSUserDefaults *userdefaults;
@property (strong, nonatomic) UIBarButtonItem *leftItem;
@property (strong, nonatomic) AppDelegate *appDelegate;
/*转16进制*/

-(NSData *) NSStringConversionToNSData:(NSString*)string;
-(NSString *) NSDataConversionToNSString:(NSData*)data;
-(NSData *) getCurrentTimeInterval;
-(BOOL)isNewLockWithDevuserid:(NSString*)devuserid;
-(void)insertLock:(void(^)(SmartLock *device))addlock;
-(void)updateLockMsg:(NSString*)devuserid withupdate:(void(^)(SmartLock *device))update;
-(NSArray<SmartLock*>*)showAllManagerLock;
-(NSArray<SmartLock*>*)showAllShareLockByGlobalcode:(BOOL)byGlobalcode;
- (NSArray<SmartLock*>*)getAllTopPageLock;
-(NSArray<SmartLock*>*)getAllAutoUnlockedLock;
-(void)removeUselessLock:(NSArray*)devuseridTemp;
-(void)clearAllData;
@end
