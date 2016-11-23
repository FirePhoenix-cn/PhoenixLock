//
//  SmartLock+CoreDataProperties.h
//  phoenixLock
//
//  Created by jinou on 16/11/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "SmartLock+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface SmartLock (CoreDataProperties)

+ (NSFetchRequest<SmartLock *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *authcode;
@property (nullable, nonatomic, copy) NSString *battery;
@property (nullable, nonatomic, copy) NSString *begin_time;
@property (nullable, nonatomic, copy) NSString *comucode;
@property (nullable, nonatomic, copy) NSString *devid;
@property (nullable, nonatomic, copy) NSString *devname;
@property (nullable, nonatomic, copy) NSString *devuserid;
@property (nullable, nonatomic, copy) NSString *distance;
@property (nullable, nonatomic, copy) NSString *effectimes;
@property (nullable, nonatomic, copy) NSString *end_time;
@property (nullable, nonatomic, copy) NSString *globalcode;
@property (nullable, nonatomic, copy) NSNumber *isactive;
@property (nullable, nonatomic, copy) NSNumber *isautounlock;
@property (nullable, nonatomic, copy) NSString *isdeleted;
@property (nullable, nonatomic, copy) NSString *ismaster;
@property (nullable, nonatomic, copy) NSNumber *istoppage;
@property (nullable, nonatomic, copy) NSString *keytype;
@property (nullable, nonatomic, copy) NSString *managename;
@property (nullable, nonatomic, copy) NSString *maxshare;
@property (nullable, nonatomic, copy) NSDate *oper_time;
@property (nullable, nonatomic, copy) NSString *productdate;
@property (nullable, nonatomic, copy) NSString *sharenum;
@property (nullable, nonatomic, copy) NSString *status;
@property (nullable, nonatomic, copy) NSString *uuid;
@property (nullable, nonatomic, copy) NSString *warrantydate;
@property (nullable, nonatomic, copy) NSString *sharetimes;
@property (nullable, nonatomic, copy) NSString *usedtimes;

@end

NS_ASSUME_NONNULL_END
