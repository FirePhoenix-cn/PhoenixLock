//
//  CellForSharedmanage.h
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewCell.h"

@interface CellForSharedmanage : TableViewCell<libBleLockDelegate,HTTPPostDelegate>

@property (retain, nonatomic) NSIndexPath * path;
@property (strong, nonatomic) IBOutlet UISwitch *autounLock;
@property (strong, nonatomic) IBOutlet UISwitch *setToppage;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *date;
@property (strong, nonatomic) IBOutlet UILabel *namager;
@property (strong, nonatomic) IBOutlet UILabel *countforunlock;
@property (strong, nonatomic) IBOutlet UILabel *activetime;
@property (strong, nonatomic) IBOutlet UILabel *distancevalue;
@property (strong, nonatomic) IBOutlet UISlider *distance;
@property (strong, nonatomic) IBOutlet UIImageView *battery;
@property (strong, nonatomic) HTTPPost *httpPost;
@property (strong, nonatomic) SmartLock *sharelock;
@end
