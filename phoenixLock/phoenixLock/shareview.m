//
//  shareview.m
//  phoenixLock
//
//  Created by jinou on 16/7/5.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "shareview.h"
#import <ShareSDK/ShareSDK.h>

@implementation shareview

- (IBAction)cancel:(UIButton *)sender
{
    [self.delegate cancel];
}

- (IBAction)share:(UIButton *)sender
{
    switch (sender.tag)
    {
        case 1:
        {
            [self doshare:SSDKPlatformSubTypeQZone];
        }
            break;
         
        case 2:
        {
             [self doshare:SSDKPlatformSubTypeQQFriend];
        }
            break;

        case 3:
        {
             [self doshare:SSDKPlatformSubTypeWechatSession];
        }
            break;

        case 4:
        {
             [self doshare:SSDKPlatformSubTypeWechatTimeline];
        }
            break;

        case 5:
        {
             [self doshare:SSDKPlatformTypeSinaWeibo];
        }
            break;

        case 6:
        {
             [self doshare:SSDKPlatformTypeSMS];
        }
            break;

        default:
            break;
    }
}

-(void)doshare:(SSDKPlatformType)plat
{
    if (self.title == nil)
    {
        return;
    }
    if (self.pic == nil) {
        return;
    }
    if (self.url == nil) {
        return;
    }
    NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
    [shareParams SSDKSetupShareParamsByText:self.title
                                     images:@[self.pic]
                                        url:[NSURL URLWithString:self.url]
                                      title:@"凰腾云盾"
                                       type:SSDKContentTypeAuto];
    [ShareSDK share:plat
         parameters:shareParams
     onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
         
         switch (state) {
             case SSDKResponseStateSuccess:
             {
                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享成功"
                                                                     message:nil
                                                                    delegate:nil
                                                           cancelButtonTitle:@"确定"
                                                           otherButtonTitles:nil];
                 [alertView show];
                 break;
             }
             case SSDKResponseStateFail:
             {
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                 message:[NSString stringWithFormat:@"%@",[error.userInfo objectForKey:@"error_message"]]
                                                                delegate:nil
                                                       cancelButtonTitle:@"确定"
                                                       otherButtonTitles:nil, nil];
                 [alert show];
                 break;
             }
             case SSDKResponseStateCancel:
             {
                 break;
             }
             case SSDKResponseStateBegin:
             {
                 break;
             }
             default:
                 break;
         }
     }];

}
@end
