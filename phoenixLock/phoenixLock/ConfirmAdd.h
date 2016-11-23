//
//  ConfirmAdd.h
//  phoenixLock
//
//  Created by jinou on 16/5/9.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "LockViewController.h"

@interface ConfirmAdd : LockViewController<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *name;
@property (strong, nonatomic) IBOutlet UILabel *number;
@property (strong, nonatomic) IBOutlet UILabel *manudate;
@property (strong, nonatomic) IBOutlet UILabel *warranty;
@property (strong, nonatomic) IBOutlet UILabel *numforkey;
@end
