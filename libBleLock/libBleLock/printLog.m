//
//  printLog.m
//  libBleLock
//
//  Created by 金瓯科技 on 15/4/22.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import "printLog.h"

@implementation printLog

+(void) printLogToFile:(NSString *)log
{
    NSLog(@"printLogToFile.................");
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filename = [cacheDir stringByAppendingPathComponent:@"prinfLog.tmp"];
    NSFileHandle *fileHandle = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename])
        [[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename])
    {
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:filename];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
}

@end
