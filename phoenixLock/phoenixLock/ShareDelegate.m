//
//  ShareDelegate.m
//  phoenixLock
//
//  Created by jinou on 16/10/26.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "ShareDelegate.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import "WXApi.h"
#import "WeiboSDK.h"

@implementation ShareDelegate

+(void)registerShareSDK
{
    [ShareSDK registerApp:@"14fe31a0ffd0c" activePlatforms:@[@(SSDKPlatformTypeSinaWeibo),
                                                             @(SSDKPlatformSubTypeQZone),
                                                             @(SSDKPlatformTypeSMS),
                                                             @(SSDKPlatformSubTypeWechatSession),
                                                             @(SSDKPlatformSubTypeQQFriend),
                                                             @(SSDKPlatformSubTypeWechatTimeline)]
              onImport:^(SSDKPlatformType platformType) {
                    switch (platformType)
                    {
                        case SSDKPlatformTypeWechat:
                            [ShareSDKConnector connectWeChat:[WXApi class]];
                        break;
                        case SSDKPlatformTypeQQ:
                        [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                        break;
                        case SSDKPlatformTypeSinaWeibo:
                        [ShareSDKConnector connectWeibo:[WeiboSDK class]];
                        break;
                        default:
                        break;
                    }
                                                                 
             }
             onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo) {
                    switch (platformType)
                    {
                    case SSDKPlatformTypeSinaWeibo:
                    //设置新浪微博应用信息,其中authType设置为使用SSO＋Web形式授权
                    [appInfo SSDKSetupSinaWeiboByAppKey:@"568898243"
                             appSecret:@"38a4f8204cc784f81f9f0daaf31e02e3"
                             redirectUri:@"http://www.sharesdk.cn"
                             authType:SSDKAuthTypeBoth];
                    break;
                    case SSDKPlatformTypeWechat:
                    [appInfo SSDKSetupWeChatByAppId:@"wx4c8b18c851b5d83a"
                             appSecret:@"f31a11fcecf1bba87f91bdbafd72e456"];
                    break;
                    case SSDKPlatformTypeQQ:
                    [appInfo SSDKSetupQQByAppId:@"100371282"
                             appKey:@"aed9b0303e3ed1e27bae87c33761161d"
                             authType:SSDKAuthTypeBoth];
                    break;
                    default:
                    break;
                    }
            }
     ];
}

@end
