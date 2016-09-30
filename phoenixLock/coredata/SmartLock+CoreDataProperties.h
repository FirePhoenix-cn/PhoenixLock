//
//  SmartLock+CoreDataProperties.h
//  phoenixLock
//
//  Created by jinou on 16/9/27.
//  Copyright © 2016年 jinou. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "SmartLock.h"

NS_ASSUME_NONNULL_BEGIN

@interface SmartLock (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *devuserid;
@property (nullable, nonatomic, retain) NSString *globalcode;
@property (nullable, nonatomic, retain) NSString *uuid;
@property (nullable, nonatomic, retain) NSString *authcode;
@property (nullable, nonatomic, retain) NSString *comucode;
@property (nullable, nonatomic, retain) NSString *devname;
@property (nullable, nonatomic, retain) NSString *managename;
@property (nullable, nonatomic, retain) NSString *ismaster;
@property (nullable, nonatomic, retain) NSString *keytype;
@property (nullable, nonatomic, retain) NSString *effectimes;
@property (nullable, nonatomic, retain) NSString *begin_time;
@property (nullable, nonatomic, retain) NSString *end_time;

@property (nullable, nonatomic, retain) NSString *productdate;
@property (nullable, nonatomic, retain) NSString *warrantydate;
@property (nullable, nonatomic, retain) NSString *maxshare;
@property (nullable, nonatomic, retain) NSString *sharenum;
@property (nullable, nonatomic, retain) NSString *distance;
@property (nullable, nonatomic, retain) NSString *battery;
@property (nullable, nonatomic, retain) NSNumber *isactive;
@property (nullable, nonatomic, retain) NSNumber *istoppage;
@property (nullable, nonatomic, retain) NSNumber *isautounlock;
@property (nullable, nonatomic, retain) NSDate *oper_time;
@property (nullable, nonatomic, retain) NSString *isdeleted;

@end

NS_ASSUME_NONNULL_END
