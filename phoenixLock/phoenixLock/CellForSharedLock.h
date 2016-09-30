//
//  CellForSharedLock.h
//  phoenixLock
//
//  Created by jinou on 16/4/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CellForSharedLockDelegate <NSObject>

-(void)changeTag:(NSInteger)btnTag :(NSIndexPath*)indexPath;

@end

@interface CellForSharedLock : UITableViewCell
- (IBAction)pressBtn:(UIButton *)sender;

@property(assign,nonatomic) id<CellForSharedLockDelegate> delegate;
@property (strong, nonatomic) IBOutlet UILabel *time;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (retain, nonatomic) NSIndexPath * path;

@end
