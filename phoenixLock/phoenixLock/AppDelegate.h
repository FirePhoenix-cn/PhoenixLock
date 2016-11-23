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
#import "SmartLock+CoreDataClass.h"
#import "ShareUser+CoreDataClass.h"
#import <CoreData/CoreData.h>
#import <UserNotifications/UserNotifications.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate,libBleLockDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) BOOL searchLock;
@property(strong, nonatomic) NSTimer *searchTimer;
@property (strong, nonatomic) libBleLock *appLibBleLock;
@property (strong, nonatomic) HTTPPost *delegatehttppost;
@property (strong, nonatomic) UILocalNotification *localNotify;
@property (strong, nonatomic) NSManagedObjectContext * privateContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
- (void)saveContext;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
@end

