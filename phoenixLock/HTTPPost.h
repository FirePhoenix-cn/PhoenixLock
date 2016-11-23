//
//  HTTPPost.h
//  phoenixLock
//
//  Created by jinou on 16/5/12.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, httpPostType)
{
    registry = 0,
    login,
    voice,
    keypress,
    adddev,
    reuuid,
    repassword,
    addshare,
    synauth,
    getdevlist,
    redevname,
    rempassword,
    getnewshare,
    getdevshare,
    delshare,
    uploadlog,
    downloadlog,
    fanscall,
    guide,sysmsg,
    version,
    syscontentservice,
    trouble,
    aboutus,
    checkaccount,
    uploaddevbattery,
    uploaddevdistance,
    getpicshare,
    opencheck,
    downloadmylog
    
};

@protocol HTTPPostDelegate <NSObject>

-(void)didRecieveData:(NSDictionary*)dic withTimeinterval:(NSTimeInterval)interval type:(httpPostType)type;

@end

@interface HTTPPost : NSObject<NSURLSessionDataDelegate>
@property(weak, nonatomic) id<HTTPPostDelegate> delegate;
@property (nonatomic, strong) NSURLSession *session;
+ (BOOL)isConnectionAvailable;
-(void)httpPostWithurl:(NSString*)urlString type:(httpPostType)type;
-(void)httpPostWithurl:(NSString*)urlString body:(NSString*)body type:(httpPostType)type;
@end
