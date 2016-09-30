//
//  ShareTableCellTableViewCell.m
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ShareTableCellTableViewCell.h"

@implementation ShareTableCellTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (IBAction)delete:(UIButton *)sender
{
    [_delegate deleteSharUser:_path];
}
@end
