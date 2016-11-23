//
//  UIColor+Hexstring.m
//  phoenixlock
//
//  Created by jinou on 16/8/11.
//  Copyright © 2016年 com.jinou.phoenixlock. All rights reserved.
//

#import "UIColor+HexstringColor.h"

@implementation UIColor (HexstringColor)

+ (UIColor *)colorFromHexString:(NSString *)hexString
{
    unsigned long red = strtoul([[hexString substringWithRange:NSMakeRange(0, 2)] UTF8String], 0, 16);
    unsigned long green = strtoul([[hexString substringWithRange:NSMakeRange(2, 2)] UTF8String], 0, 16);
    unsigned long blue = strtoul([[hexString substringWithRange:NSMakeRange(4, 2)] UTF8String], 0, 16);
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}
@end
