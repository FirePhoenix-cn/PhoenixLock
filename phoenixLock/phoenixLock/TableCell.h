//
//  TableCell.h
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableCell : UITableViewCell

@property (retain, nonatomic) NSIndexPath * path;
@property (strong, nonatomic) IBOutlet UIImageView *imgForCount;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *date;
@property (strong, nonatomic) IBOutlet UILabel *account;
@property (strong, nonatomic) IBOutlet UILabel *oper_status;

@end
