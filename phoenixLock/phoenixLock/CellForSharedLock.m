//
//  CellForSharedLock.m
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellForSharedLock.h"

@implementation CellForSharedLock

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (IBAction)pressBtn:(UIButton *)sender
{
    [_delegate changeTag:sender.tag :_path];
}
@end
