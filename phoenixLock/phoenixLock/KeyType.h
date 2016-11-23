//
//  KeyType.h
//  phoenixLock
//
//  Created by jinou on 16/6/16.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZQDatePickerView.h"

@protocol KeyTypeDelegate <NSObject>

-(void)confirm;
-(void)cancel;
-(void)onGetDate:(NSString*)date type:(DateType)datetype;

@end

@interface KeyType : UIView

@property(weak, nonatomic) id<KeyTypeDelegate> delegate;
- (IBAction)tapseg:(UISegmentedControl *)sender;
@property (strong, nonatomic) IBOutlet UITextField *effectimes;
- (IBAction)comfirm:(UIButton *)sender;
- (IBAction)cancel:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UITextField *start_time;
@property (strong, nonatomic) IBOutlet UITextField *end_times;
@property (assign ,nonatomic) NSInteger keytype;

@end
