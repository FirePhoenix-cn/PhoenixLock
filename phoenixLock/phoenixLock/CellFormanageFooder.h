//
//  CellFormanageFooder.h
//  phoenixLock
//
//  Created by jinou on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SmartLock.h"
@protocol CellFormanageFooderDelegate <NSObject>
-(void)alertdisplay:(NSString*)alertMessage :(NSData*)data;
-(void)addshare:(NSInteger)row;
@end

@interface CellFormanageFooder : UITableViewCell<libBleLockDelegate,UITextFieldDelegate,HTTPPostDelegate>

@property(strong, nonatomic) HTTPPost *httppost;

@property (retain, nonatomic)  id<CellFormanageFooderDelegate> delegate;
@property (retain, nonatomic) IBOutlet UISwitch *outoUnlock;
@property (retain, nonatomic) IBOutlet UISwitch *setToppage;
@property (retain, nonatomic) IBOutlet UITextField *name;
- (IBAction)nameLock:(UIButton *)sender;
@property (retain, nonatomic) IBOutlet UILabel *lockNO;
@property (retain, nonatomic) IBOutlet UILabel *dateofmanu;
@property (retain, nonatomic) IBOutlet UILabel *dateofwarranty;
- (IBAction)autounlock:(UISwitch *)sender;
@property (retain, nonatomic) IBOutlet UISwitch *autoL;
@property (retain, nonatomic) IBOutlet UILabel *showsharednum;
- (IBAction)addshareduser:(UIButton *)sender;
- (IBAction)homepage:(UISwitch *)sender;
@property (retain, nonatomic) IBOutlet UISwitch *top;
- (IBAction)removebind:(UIButton *)sender;
- (IBAction)rebind:(UIButton *)sender;

- (IBAction)distance:(UISlider *)sender;
@property (strong, nonatomic) IBOutlet UILabel *distancevalue;
@property (strong, nonatomic) IBOutlet UISlider *distance;
@property (strong, nonatomic) IBOutlet UIImageView *battery;
- (IBAction)tomall:(UIButton *)sender;

@property (retain, nonatomic) NSUserDefaults *userdefaults;
@property (retain, nonatomic) NSIndexPath * path;
@property (retain, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSData *mac;
@property (strong, nonatomic) NSData *guid;
@property (retain, nonatomic) NSTimer *timer;
@property (strong, nonatomic) SmartLock *managerlock;
@end

