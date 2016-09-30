//
//  CellForManageHeader.m
//  phoenixLock
//
//  Created by jinou on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellForManageHeader.h"

@implementation CellForManageHeader

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (IBAction)keyBtn:(UIButton *)sender
{
    [_delegate changeTag:sender.tag :_path];
}

@end
