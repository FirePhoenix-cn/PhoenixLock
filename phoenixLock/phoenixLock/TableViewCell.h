//
//  TableViewCell.h
//  phoenixLock
//
//  Created by jinou on 16/10/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell
@property (strong, nonatomic) NSUserDefaults *userdefaults;
@property (strong, nonatomic) AppDelegate *appDelegate;
-(void)updateLockMsg:(NSString*)devuserid withupdate:(void(^)(SmartLock *device))update;
-(NSData *) NSStringConversionToNSData:(NSString*)string;
@end
