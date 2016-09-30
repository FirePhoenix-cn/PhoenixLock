//
//  shareview.h
//  phoenixLock
//
//  Created by jinou on 16/7/5.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol shareviewdelegate <NSObject>
-(void)cancel;
@end
@interface shareview : UIView
- (IBAction)cancel:(UIButton *)sender;
- (IBAction)share:(UIButton *)sender;
@property(strong, nonatomic) NSString* title;
@property(strong, nonatomic) NSString* pic;
@property(strong, nonatomic) NSString* url;
@property(weak,nonatomic) id<shareviewdelegate> delegate;
@end
