//
//  Operation.h
//  phoenixLock
//
//  Created by jinou on 16/7/4.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModelViewController.h"
@interface Operation : ModelViewController
@property (strong, nonatomic) IBOutlet UILabel *phone;
@property (strong, nonatomic) IBOutlet UILabel *version;
- (IBAction)clickbtton:(UIButton *)sender;

@end
