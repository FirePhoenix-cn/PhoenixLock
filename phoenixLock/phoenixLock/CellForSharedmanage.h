//
//  CellForSharedmanage.h
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SmartLock.h"

@interface CellForSharedmanage : UITableViewCell<libBleLockDelegate>

@property (retain, nonatomic) NSIndexPath * path;

@property (strong, nonatomic) IBOutlet UISwitch *autounLock;
@property (strong, nonatomic) IBOutlet UISwitch *setToppage;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *date;
@property (strong, nonatomic) IBOutlet UILabel *namager;
@property (strong, nonatomic) IBOutlet UILabel *countforunlock;
@property (strong, nonatomic) IBOutlet UILabel *activetime;
@property (strong, nonatomic) NSUserDefaults *userdefaults;
- (IBAction)autounlock:(UISwitch *)sender;
- (IBAction)homepage:(UISwitch *)sender;
- (IBAction)unshared:(UIButton *)sender;
- (IBAction)reqshare:(UIButton *)sender;

- (IBAction)distance:(UISlider *)sender;
@property (strong, nonatomic) IBOutlet UILabel *distancevalue;
@property (strong, nonatomic) IBOutlet UISlider *distance;
@property (strong, nonatomic) IBOutlet UIImageView *battery;
@property (retain, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) SmartLock *sharelock;
@end
