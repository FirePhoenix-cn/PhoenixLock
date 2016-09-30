//
//  Trouble.h
//  phoenixLock
//
//  Created by jinou on 16/7/4.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModelViewController.h"
@interface Trouble : ModelViewController<UITextFieldDelegate,UITextViewDelegate>
@property (strong, nonatomic) IBOutlet UITextField *phone;
@property (strong, nonatomic) IBOutlet UITextView *contenttext;
@property (strong, nonatomic) IBOutlet UILabel *countcontent;
- (IBAction)send:(UIButton *)sender;

@end
