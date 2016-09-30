//
//  LoginVC.h
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginVC : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *userAccount;
@property (strong, nonatomic) IBOutlet UITextField *userPassword;
- (IBAction)userLogin:(UIButton *)sender;
- (IBAction)repassword:(UIButton *)sender;
- (IBAction)userregister:(UIButton *)sender;
@property (strong, nonatomic) NSUserDefaults *userdefaults;
@property (strong, nonatomic) NSDictionary *dataDic;

@end
