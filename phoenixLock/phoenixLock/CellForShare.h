//
//  CellForShare.h
//  phoenixLock
//
//  Created by jinou on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareTableCellTableViewCell.h"
#import "MySmartLock.h"

@interface CellForShare : UITableViewCell<UITableViewDataSource,UITableViewDelegate,ShareTableCellTableViewCellDelegate,UITextFieldDelegate,libBleLockDelegate>

@property (retain, nonatomic) IBOutlet UITableView *shareTable;
@property (retain, nonatomic) NSMutableArray *datasrc;
@property (retain, nonatomic) IBOutlet UITextField *accountforshareduser;
- (IBAction)addshareduser:(UIButton *)sender;
@property (retain, nonatomic) NSIndexPath * path;
@property (strong, nonatomic) NSUserDefaults *userdefaults;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSData *guid;
@property (strong, nonatomic) NSData *mac;
@property (strong, nonatomic) SmartLock *managerlock;
@end
