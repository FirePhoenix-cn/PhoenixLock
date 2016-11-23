//
//  ShareUser+CoreDataProperties.h
//  phoenixLock
//
//  Created by jinou on 16/11/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ShareUser+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ShareUser (CoreDataProperties)

+ (NSFetchRequest<ShareUser *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSArray *authcode;
@property (nullable, nonatomic, copy) NSString *authmobile;
@property (nullable, nonatomic, copy) NSString *begin_time;
@property (nullable, nonatomic, copy) NSString *comucode;
@property (nullable, nonatomic, copy) NSString *devstatus;
@property (nullable, nonatomic, copy) NSString *devuserid;
@property (nullable, nonatomic, copy) NSString *effectimes;
@property (nullable, nonatomic, copy) NSString *end_time;
@property (nullable, nonatomic, copy) NSString *isdel;
@property (nullable, nonatomic, copy) NSString *usedtimes;
@property (nullable, nonatomic, copy) NSString *sharetimes;

@end

NS_ASSUME_NONNULL_END
