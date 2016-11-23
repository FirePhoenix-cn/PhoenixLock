//
//  SmartLock+CoreDataProperties.m
//  phoenixLock
//
//  Created by jinou on 16/11/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "SmartLock+CoreDataProperties.h"

@implementation SmartLock (CoreDataProperties)

+ (NSFetchRequest<SmartLock *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"SmartLock"];
}

@dynamic authcode;
@dynamic battery;
@dynamic begin_time;
@dynamic comucode;
@dynamic devid;
@dynamic devname;
@dynamic devuserid;
@dynamic distance;
@dynamic effectimes;
@dynamic end_time;
@dynamic globalcode;
@dynamic isactive;
@dynamic isautounlock;
@dynamic isdeleted;
@dynamic ismaster;
@dynamic istoppage;
@dynamic keytype;
@dynamic managename;
@dynamic maxshare;
@dynamic oper_time;
@dynamic productdate;
@dynamic sharenum;
@dynamic status;
@dynamic uuid;
@dynamic warrantydate;
@dynamic sharetimes;
@dynamic usedtimes;

@end
