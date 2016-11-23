//
//  CellForManageHeader.h
//  phoenixLock
//
//  Created by jinou on 16/4/20.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>

//定义代理协议
@protocol CellForManageHeaderDelegate <NSObject>
-(void)changeTag:(NSInteger)btnTag :(NSIndexPath*)indexPath;
@end

@interface CellForManageHeader : UITableViewCell

@property(assign,nonatomic) id<CellForManageHeaderDelegate>delegate;
@property (nonatomic) BOOL addKey;
@property (retain, nonatomic) NSIndexPath * path;
@property (strong, nonatomic) NSUserDefaults *userdefaults;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *time;

@end
