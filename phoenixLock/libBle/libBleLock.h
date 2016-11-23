//
//  libBleLock.h
//  libBleLock
//
//  Created by 金瓯科技 on 15/3/11.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AdSupport/ASIdentifierManager.h>

#import "libBleLockState.h"

@protocol libBleLockDelegate;


/*!
 *  @class libBleLock
 *
 *  @discussion Entry point to the central role.
 *
 */
@interface libBleLock : NSObject<CBCentralManagerDelegate>

/*!
 *  @property delegate
 *
 *  @discussion The delegate object that will receive ble lock events.
 *
 */

@property (strong, nonatomic) CBCentralManager *centralManager;

@property(weak, nonatomic) id<libBleLockDelegate> delegate;

/*
 *  @method initWithDelegate
 *
 *  @param  delegate        
 *
 *  @discussion
            实例初始化
 */
-(id) initWithDelegate:(id<libBleLockDelegate>)delegate;


/*
 *  @method bleInquiry
 *
 *  @param  timeoutSeconds  搜索设备超时时间
 *
 *  @discussion
 *          搜索周围BLE蓝牙设备
 */
-(Boolean) bleInquiry:(NSTimeInterval)timeoutSeconds;

/*
 *  @method bleCancelInquiry
 *
 *  @discussion
 *          取消搜索周围BLE蓝牙设备
 */
-(Boolean) bleCancelInquiry;

/*
 *  @method bleConnectRequest
 *
 *  @param  macAddr         蓝牙MAC地址
 *
 *  @discussion
 *          连接指定Mac地址的Ble设备
 */
-(Boolean) bleConnectRequest:(NSData *)macAddr;

/*
 *  @method bleConnectRequest
 *
 *  @param  macAddr         蓝牙MAC地址
 *
 *  @discussion
 *          连接指定Mac地址的Ble设备
 */
-(Boolean) bleIsConnected:(NSData *)macAddr;

/*
 *  @method bleDisconnectRequest
 *
 *  @param  macAddr         蓝牙MAC地址
 *
 *  @discussion
 *          断开与指定Mac地址的Ble设备连接
 */
-(Boolean) bleDisconnectRequest:(NSData *)macAddr;

/*
 *  @method bleDataSendRequest
 *
 *  @param  macAddr         蓝牙MAC地址
 *          cmd_type        数据包命令类型
 *          param_data      数据包参数
 *
 *  @discussion
 *          数据发送请求
 */
-(Boolean) bleDataSendRequest:(NSData *)macAddr cmd_type:(libCommandType)cmd_type param_data:(NSData *)param_data;

@end



/*!
 *  @protocol libBleLockDelegate
 *
 *  @discussion The delegate of a {@link libBleLock} object.
 *
 */
@protocol libBleLockDelegate <NSObject>

@optional

-(void) didGetBattery:(NSInteger)battery forMac:(NSData*)mac;

/*
 *  @method didDiscoverResult
 *
 *  @param  macAddr             蓝牙MAC地址
 *          deviceName          设备名称
 *          rssi                信号强度
 *
 *  @discussion
 *          调用bleInquiry搜索周围BLE蓝牙设备后，查询到设备时通过该消息进行通知
 */
-(void) didDiscoverResult:(NSData *)macAddr deviceName:(NSData *)deviceName rssi:(NSNumber *)rssi;

/*
 *  @method didDiscoverComplete
 *
 *  @discussion
 *          调用bleInquiry搜索周围BLE蓝牙设备超时后，通过该消息进行通知
 */
-(void) didDiscoverComplete;

/*
 *  @method didConnectConfirm
 *
 *  @param  macAddr         蓝牙MAC地址
 *          status          连接结果
 *                  0       失败
 *                  1       成功
 *
 *  @discussion
 *          调用bleConnectRequest请求连接蓝牙设备，连接结束后通过该消息通知连接结果。
 */
-(void) didConnectConfirm:(NSData *)macAddr status:(Boolean)status;

/*
 *  @method didDisconnectIndication
 *
 *  @param  macAddr         蓝牙MAC地址
 *
 *  @discussion
 *          当与蓝牙设备断开连接后，通过该消息进行通知。
 */
-(void) didDisconnectIndication:(NSData *)macAddr;

/*
 *  @method didDataSendResponse
 *
 *  @param  macAddr         蓝牙MAC地址
 *          cmd_type        数据包命令类型
 *          result                  结果
 *                                  libBleErrorCode
 *          param_data      数据包参数
 *
 *  @discussion
 *          数据命令发送应答
 */
-(void) didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data;

/*
 *  @method didOpenLockLogDataInd
 *
 *  @param  macAddr         蓝牙MAC地址
 *          record_count    已读取日志记录条数
 *          log_data        日志数据
 *
 *  @discussion
 *          数据命令发送应答
 */
-(void) didOpenLockLogDataInd:(NSData *)macAddr record_count:(NSUInteger)record_count log_data:(NSMutableArray *)log_data;

@required

@end

