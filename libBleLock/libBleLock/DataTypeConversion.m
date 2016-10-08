//
//  DataTypeConversion.m
//  libBleLock
//
//  Created by 金瓯科技 on 15/3/17.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import "DataTypeConversion.h"

@implementation DataTypeConversion

/*
 *  @method ByteConversionToNSString
 *
 *  @param byte Byte类型的数据
 *
 *  @discussion 
 *          将Byte类型的数据转换为十六进制NSString类型的字符串，
 */
+ (NSString *) ByteConversionToNSString:(Byte *)byte length:(NSUInteger)length
{
    NSMutableString *hexString = [NSMutableString stringWithString:@""];

    for (int i=0; i < length; i++)
        [hexString appendFormat:@"%02x", byte[i]];

    return hexString;
}

/*
 *  @method NSDataConversionToNSString
 *
 *  @param data NSData类型的数据
 *
 *  @discussion
 *          将NSData类型的数据转换为十六进制NSString类型的字符串，
 */
+ (NSString *) NSDataConversionToNSString:(NSData*)data
{
    if (data == nil) {
        return @"";
    }
    
    NSMutableString *hexString = [NSMutableString string];
    
    const unsigned char *p = [data bytes];
    
    for (int i=0; i < [data length]; i++)
        [hexString appendFormat:@"%02x", *p++];

    return hexString;
}

/*
 *  @method NSStringConversionToNSData
 *
 *  @param string NSString类型的数据，字符都是十六进制数字
 *
 *  @discussion
 *          将十六进制NSString类型的字符串转换为NSData类型的数据，
 */
+ (NSData *) NSStringConversionToNSData:(NSString*)string
{
    if (string == nil)
        return nil;
    
    const char *ch = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *data = [NSMutableData data];
    while (*ch) {
        char byte = 0;
        if ('0' <= *ch && *ch <= '9')
            byte = *ch - '0';
        else if ('a' <= *ch && *ch <= 'f')
            byte = *ch - 'a' + 10;
        else if ('A' <= *ch && *ch <= 'F')
            byte = *ch - 'A' + 10;
        ch++;
        byte = byte << 4;
        if (*ch) {
            if ('0' <= *ch && *ch <= '9')
                byte += *ch - '0';
            else if ('a' <= *ch && *ch <= 'f')
                byte += *ch - 'a' + 10;
            else if ('A' <= *ch && *ch <= 'F')
                byte += *ch - 'A' + 10;
            ch++;
        }
        [data appendBytes:&byte length:1];
    }
    return data;
}



@end

