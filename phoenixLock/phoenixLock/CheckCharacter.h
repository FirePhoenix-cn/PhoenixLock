//
//  CheckCharacter.h
//  phoenixLock
//
//  Created by jinou on 16/4/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CheckCharacter : NSObject

+ (BOOL)isValidateMobileNumber:(NSString *)mobileNumber;
+ (BOOL)isValidateMobilePassward:(NSString *)password;
@end
