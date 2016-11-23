//
//  printLog.h
//  libBleLock
//
//  Created by 金瓯科技 on 15/4/22.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSLOG_DEBUG 1

@interface printLog : NSObject

+(void) printLogToFile:(NSString *)log;

@end
