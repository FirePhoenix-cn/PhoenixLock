//
//  ShareTableCellTableViewCell.h
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ShareTableCellTableViewCellDelegate<NSObject>
-(void)deleteSharUser:(NSIndexPath*)path;
@end

@interface ShareTableCellTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *sharedtime;
@property (strong, nonatomic) IBOutlet UILabel *sharedaccount;
@property (strong, nonatomic) IBOutlet UILabel *activetime;
@property (strong, nonatomic) IBOutlet UILabel *unlocktimes;
- (IBAction)delete:(UIButton *)sender;
@property (strong, nonatomic) NSIndexPath *path;
@property(weak, nonatomic) id<ShareTableCellTableViewCellDelegate> delegate;

@end
