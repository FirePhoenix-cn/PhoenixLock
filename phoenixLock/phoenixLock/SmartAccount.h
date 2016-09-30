//
//  SmartAccount.h
//  phoenixLock
//
//  Created by jinou on 16/4/22.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "SmartActivity.h"

@interface SmartAccount : SmartActivity
@property (strong, nonatomic) IBOutlet UIButton *zhanghu;
@property (strong, nonatomic) IBOutlet UIButton *guzhang;
@property (strong, nonatomic) IBOutlet UIButton *caozuo;
@property (strong, nonatomic) IBOutlet UIButton *fenxiang;
- (IBAction)share:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *accountname;

- (IBAction)charge:(UIButton *)sender;
//view布局
@property (strong, nonatomic) IBOutlet UIView *subv;
@property (strong, nonatomic) IBOutlet UIImageView *firstimg;
@property (strong, nonatomic) IBOutlet UIImageView *secondimg;
@property (strong, nonatomic) IBOutlet UIImageView *thirdimg;

@property (strong, nonatomic) IBOutlet UILabel *label1;
@property (strong, nonatomic) IBOutlet UILabel *label2;
@property (strong, nonatomic) IBOutlet UILabel *text1;
@property (strong, nonatomic) IBOutlet UILabel *text2;
@property (strong, nonatomic) IBOutlet UILabel *text3;
@property (strong, nonatomic) IBOutlet UILabel *msg1;
@property (strong, nonatomic) IBOutlet UILabel *msg2;
@property (strong, nonatomic) IBOutlet UILabel *msg3;

@end
