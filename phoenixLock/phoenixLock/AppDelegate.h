//
//  AppDelegate.h
//  phoenixLock
//
//  Created by jinou on 16/4/15.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "libBleLock.h"
#import "HTTPPost.h"
#import <CoreData/CoreData.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate,libBleLockDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (retain, nonatomic) libBleLock *appLibBleLock;

@property (strong, nonatomic) HTTPPost *delegatehttppost;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;


@end

