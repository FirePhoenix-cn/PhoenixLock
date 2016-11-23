//
//  DataTypeConversion.h
//  libBleLock
//
//  Created by 金瓯科技 on 15/3/17.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataTypeConversion : NSObject

/*
 *  @method ByteConversionToNSString
 *
 *  @param byte Byte类型的数据
 *
 *  @discussion
 *          将Byte类型的数据转换为十六进制NSString类型的字符串，
 */
+ (NSString *) ByteConversionToNSString:(Byte *)byte length:(NSUInteger)length;

/*
 *  @method NSDataConversionToNSString
 *
 *  @param data NSData类型的数据
 *
 *  @discussion
 *          将NSData类型的数据转换为十六进制NSString类型的字符串，
 */
+ (NSString *) NSDataConversionToNSString:(NSData *)data;

/*
 *  @method NSStringConversionToNSData
 *
 *  @param string NSString类型的数据，字符都是十六进制数字
 *
 *  @discussion
 *          将十六进制NSString类型的字符串转换为NSData类型的数据，
 */
+ (NSData *) NSStringConversionToNSData:(NSString *)string;


@end
