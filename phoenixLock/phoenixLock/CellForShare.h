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
#import "TableViewCell.h"

@interface CellForShare : TableViewCell<UITableViewDataSource,UITableViewDelegate,ShareTableCellTableViewCellDelegate,UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UITableView *shareTable;
@property (retain, nonatomic) NSMutableArray <NSDictionary*>*datasrc;
@property (retain, nonatomic) NSArray <NSDictionary*>*datasrcTemp;
@property (retain, nonatomic) IBOutlet UITextField *accountforshareduser;
@property (strong, nonatomic) NSData *guid;
@property (strong, nonatomic) NSData *mac;
@property (strong, nonatomic) SmartLock *managerlock;
@end
