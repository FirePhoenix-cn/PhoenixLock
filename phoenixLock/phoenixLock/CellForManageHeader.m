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

- (IBAction)keyBtn:(UIButton *)sender
{
    [self.delegate changeTag:sender.tag :self.path];
}

@end
