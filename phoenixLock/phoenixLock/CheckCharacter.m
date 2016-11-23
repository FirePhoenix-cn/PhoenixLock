//
//  CheckCharacter.m
//  phoenixLock
//
//  Created by jinou on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "CheckCharacter.h"

@implementation CheckCharacter


+ (BOOL)isValidateMobileNumber:(NSString *)mobileNumber;
{
    if (mobileNumber.length>17)
    {
        return NO;
    }
    if (mobileNumber.length>11)
    {
        NSString *suffix = [mobileNumber.mutableCopy substringWithRange:NSMakeRange(11, mobileNumber.length-11)];
        //char firstletter = [suffix characterAtIndex:0];
        //if ((firstletter >='A' && firstletter <='Z') || (firstletter >='a' && firstletter<='z'))
        //{
            
        NSString *fixregex = @"[A-Z0-9a-z]{1,6}";
        NSPredicate *fixpred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",fixregex];
        if ([fixpred evaluateWithObject:suffix])
        {
            mobileNumber = [mobileNumber.mutableCopy substringWithRange:NSMakeRange(0, 11)];
        }else
        {
            return NO;
        }
        //}else
        //{
        //    return NO;
        //}
        
    }
    NSString *mobileNumberRegex = @"[0-9]{11,11}";
    NSPredicate *mobileNumberTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileNumberRegex];
    if (![mobileNumberTest evaluateWithObject:mobileNumber]) {
        return NO;
    }
    /**
     * 移动号段正则表达式
     */
    NSString *CM_NUM = @"^((13[4-9])|(147)|(15[0-2,7-9])|(178)|(18[2-4,7-8]))\\d{8}|(1705)\\d{7}$";
    /**
     * 联通号段正则表达式
     */
    NSString *CU_NUM = @"^((13[0-2])|(145)|(15[5-6])|(176)|(18[5,6]))\\d{8}|(1709)\\d{7}$";
    /**
     * 电信号段正则表达式
     */
    NSString *CT_NUM = @"^((133)|(153)|(177)|(18[0,1,9]))\\d{8}$";
    
    
    
    NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM_NUM];
    BOOL isMatch1 = [pred1 evaluateWithObject:mobileNumber];
    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU_NUM];
    BOOL isMatch2 = [pred2 evaluateWithObject:mobileNumber];
    NSPredicate *pred3 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT_NUM];
    BOOL isMatch3 = [pred3 evaluateWithObject:mobileNumber];
    
    return isMatch1 || isMatch2 || isMatch3;
}

+ (BOOL)isValidateMobilePassward:(NSString *)password;
{
    NSString *passwordRegex = @"[A-Z0-9a-z]{6,16}";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
    if (![passwordTest evaluateWithObject:password]) {
        return NO;
    }else
    {
        BOOL containchar = NO;
        for (NSInteger i = 0; i < password.length; i ++)
        {
            NSUInteger ascii = [password characterAtIndex:i];
            containchar = (ascii >= 'A')? YES:NO;
            if (containchar)
            {
                return YES;
            }
        }
    }
    return NO;
}

@end
