//
//  RegisterVC.h
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterVC : UIViewController<UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UITextField *setNewAccount;
@property (retain, nonatomic) IBOutlet UITextField *setPassword;
@property (retain, nonatomic) IBOutlet UITextField *confirmPassword;
@property (retain, nonatomic) NSDictionary *dataDic;
@property (retain, nonatomic) NSUserDefaults *userdefaults;//数据持久化

@end
