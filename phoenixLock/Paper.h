//
//  Paper.h
//  phoenixLock
//
//  Created by jinou on 16/8/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ModelViewController.h"

@interface Paper : ModelViewController

@property(strong, nonatomic) HTTPPost *httppost;

@property (strong, nonatomic) IBOutlet UITextView *textview;

@end
