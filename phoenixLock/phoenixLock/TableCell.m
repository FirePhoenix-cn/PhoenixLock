//
//  TableCell.m
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "TableCell.h"

@implementation TableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (_name.text.length>13)
    {
        [_name setFont:[UIFont systemFontOfSize:10]];
    }
    
}

@end
