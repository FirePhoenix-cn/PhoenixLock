//
//  CollectionViewCell.m
//  phoenixLock
//
//  Created by jinou on 16/11/2.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.borderWidth = 0.5;
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
}

@end
