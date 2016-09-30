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
- (IBAction)retrievePassword:(UIButton *)sender;
@property (strong, nonatomic) NSUserDefaults *userdefaults;
- (IBAction)getVercode:(UIButton *)sender;
@property (strong, nonatomic) NSDictionary *dataDic;
@end
