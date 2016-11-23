//
//  LosePasswardVC.h
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckCharacter.h"
@interface LosePasswordVC : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *phonenumber;
@property (strong, nonatomic) NSUserDefaults *userdefaults;
@property (strong, nonatomic) NSDictionary *dataDic;
@end
