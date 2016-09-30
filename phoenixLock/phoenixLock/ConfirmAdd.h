//
//  ConfirmAdd.h
//  phoenixLock
//
//  Created by jinou on 16/5/9.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "BLEConnect.h"

@interface ConfirmAdd : BLEConnect<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *name;
@property (strong, nonatomic) IBOutlet UILabel *number;
@property (strong, nonatomic) IBOutlet UILabel *manudate;
@property (strong, nonatomic) IBOutlet UILabel *warranty;
@property (strong, nonatomic) IBOutlet UILabel *numforkey;

- (IBAction)confirm:(UIButton *)sender;

@end
