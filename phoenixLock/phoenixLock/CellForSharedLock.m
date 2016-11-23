//
//  CellForSharedLock.m
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CellForSharedLock.h"

@implementation CellForSharedLock

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}

- (IBAction)pressBtn:(UIButton *)sender
{
    [self.delegate changeTag:sender.tag :self.path];
}
@end
