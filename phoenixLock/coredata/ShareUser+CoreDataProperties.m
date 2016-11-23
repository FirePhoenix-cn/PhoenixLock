//
//  ShareUser+CoreDataProperties.m
//  phoenixLock
//
//  Created by jinou on 16/11/21.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ShareUser+CoreDataProperties.h"

@implementation ShareUser (CoreDataProperties)

+ (NSFetchRequest<ShareUser *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ShareUser"];
}

@dynamic authcode;
@dynamic authmobile;
@dynamic begin_time;
@dynamic comucode;
@dynamic devstatus;
@dynamic devuserid;
@dynamic effectimes;
@dynamic end_time;
@dynamic isdel;
@dynamic usedtimes;
@dynamic sharetimes;

@end
