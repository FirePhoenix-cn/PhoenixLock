//
//  CellFormanageFooder.h
//  phoenixLock
//
//  Created by jinou on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewCell.h"

@protocol CellFormanageFooderDelegate <NSObject>
-(void)addshare:(NSInteger)row;
@end
@interface CellFormanageFooder : TableViewCell<libBleLockDelegate,UITextFieldDelegate,HTTPPostDelegate>
@property(strong, nonatomic) HTTPPost *httppost;
@property (retain, nonatomic)  id<CellFormanageFooderDelegate> delegate;
@property (retain, nonatomic) IBOutlet UISwitch *outoUnlock;
@property (retain, nonatomic) IBOutlet UISwitch *setToppage;
@property (retain, nonatomic) IBOutlet UITextField *name;
@property (retain, nonatomic) IBOutlet UILabel *lockNO;
@property (retain, nonatomic) IBOutlet UILabel *dateofmanu;
@property (retain, nonatomic) IBOutlet UILabel *dateofwarranty;
@property (retain, nonatomic) IBOutlet UILabel *showsharednum;
@property (strong, nonatomic) IBOutlet UILabel *distancevalue;
@property (strong, nonatomic) IBOutlet UISlider *distance;
@property (strong, nonatomic) IBOutlet UIImageView *battery;
@property (retain, nonatomic) NSIndexPath * path;
@property (strong, nonatomic) NSData *mac;
@property (strong, nonatomic) NSData *guid;
@property (retain, nonatomic) NSTimer *timer;
@property (strong, nonatomic) SmartLock *managerlock;
@end

