//
//  libBleLock.h
//  libBleLock
//
//  Created by 金瓯科技 on 15/3/11.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, libBleErrorCode)
{
    libBleErrorCodeNone,
    libBleErrorCodeRemoteReject,
    libBleErrorCodeNoReponse
};

typedef NS_ENUM(NSUInteger, libCommandType)
{
    libBleCmdNone,
    libBleCmdBindManager,
    libBleCmdAddManagerOpenLockUUID,
    libBleCmdSendManagerCommunicateUUID,
    libBleCmdSendManagerOpenLockUUID,
    libBleCmdClearManager,
    libBleCmdAddSharerOpenLockUUID,
    libBleCmdDeleteSharerOpenLockUUID,
    libBleCmdEmptySharerOpenLockUUID,
    libBleCmdSendSharerCommunicateUUID,
    libBleCmdSendSharerOpenLockUUID,
    libBleCmdReadLockLog,
    libBleCmdEmptyLockLog,
    libBleCmdDisconnect
};
