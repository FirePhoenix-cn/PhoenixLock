//
//  PeripheralDeviceManager.h
//  libBleLock
//
//  Created by 金瓯科技 on 15/3/17.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <corebluetooth/CBService.h>

#define UUID_SERVICE_FOR_DATA               @"BFF0"//@"0000B350-B9E3-D6DD-B7EF-CCDABFC6BCBC"
#define UUID_SERVICE_FOR_BATTERY            @"180F"
#define UUID_CHARACTERISTIC_FOR_BATTERY     @"2A19"
#define UUID_CHARACTERISTIC_FOR_DATA_READ   @"BFF1"//@"0000B351-B9E3-D6DD-B7EF-CCDABFC6BCBC"
#define UUID_CHARACTERISTIC_FOR_DATA_WRITE  @"BFF2"//@"0000B352-B9E3-D6DD-B7EF-CCDABFC6BCBC"

#define COMMAND_TYPE_CODE_MIN                   0x01

typedef NS_ENUM(NSUInteger, packetTypeForRemoteBleDevice)
{
    COMMAND_TYPE_CODE_BIND_MANAGER_REQ = COMMAND_TYPE_CODE_MIN,
    COMMAND_TYPE_CODE_BIND_MANAGER_RSP,
    COMMAND_TYPE_CODE_ADD_MANAGER_OPEN_LOCK_UUID_REQ,
    COMMAND_TYPE_CODE_ADD_MANAGER_OPEN_LOCK_UUID_RSP,
    COMMAND_TYPE_CODE_SEND_MANAGER_COMMUNICATE_UUID_REQ,
    COMMAND_TYPE_CODE_SEND_MANAGER_COMMUNICATE_UUID_RSP,
    COMMAND_TYPE_CODE_SEND_MANAGER_OPEN_LOCK_UUID_REQ,
    COMMAND_TYPE_CODE_SEND_MANAGER_OPEN_LOCK_UUID_RSP,
    COMMAND_TYPE_CODE_CLEAR_MANAGER_REQ,
    COMMAND_TYPE_CODE_CLEAR_MANAGER_RSP,
    COMMAND_TYPE_CODE_ADD_SHARER_OPEN_LOCK_UUID_REQ,
    COMMAND_TYPE_CODE_ADD_SHARER_OPEN_LOCK_UUID_RSP,
    COMMAND_TYPE_CODE_DELETE_SHARER_OPEN_LOCK_UUID_REQ,
    COMMAND_TYPE_CODE_DELETE_SHARER_OPEN_LOCK_UUID_RSP,
    COMMAND_TYPE_CODE_EMPTY_SHARER_OPEN_LOCK_UUID_REQ,
    COMMAND_TYPE_CODE_EMPTY_SHARER_OPEN_LOCK_UUID_RSP,
    COMMAND_TYPE_CODE_SEND_SHARER_COMMUNICATE_UUID_REQ,
    COMMAND_TYPE_CODE_SEND_SHARER_COMMUNICATE_UUID_RSP,
    COMMAND_TYPE_CODE_SEND_SHARER_OPEN_LOCK_UUID_REQ,
    COMMAND_TYPE_CODE_SEND_SHARER_OPEN_LOCK_UUID_RSP,
    COMMAND_TYPE_CODE_READ_LOCK_LOG_REQ,
    COMMAND_TYPE_CODE_READ_LOCK_LOG_RSP,
    COMMAND_TYPE_CODE_EMPTY_LOCK_LOG_REQ,
    COMMAND_TYPE_CODE_EMPTY_LOCK_LOG_RSP,
    COMMAND_TYPE_CODE_DISCONNECT_REQ,
    COMMAND_TYPE_CODE_MAX,
    
    COMMAND_TYPE_CODE_UNKNOW = 0XFF
};

@class libBleLock;

@protocol PeripheralDeviceManagerDelegate;

@interface PeripheralDeviceManager : NSObject<CBPeripheralDelegate>
{
    CBService           *dataService;
    CBCharacteristic    *dataCharacteristicRead;
    CBCharacteristic    *dataCharacteristicWrite;
    Boolean             bSendedDidServiceDiscoverResultEvent;
}

/*
 *  @property delegate
 *
 *  @discussion The delegate object you want to receive device events.
 *
 */
@property (strong, nonatomic) id<PeripheralDeviceManagerDelegate> delegate;

/*
 *  @property peerPeripheral
 *
 *  @discussion 与设备关联的CBPeripheral设备
 *
 */
@property (strong, nonatomic) CBPeripheral * peerPeripheral;

/*
 *  @property advertisementData
 *
 *  @discussion 在查询时读取到的设备广播数据
 *
 */
@property (strong, nonatomic) NSDictionary * advertisementData;

/*
 *  @property macAddr
 *
 *  @discussion 从manufacturerData中提取出的Ble设备mac地址
 *
 */
@property (strong, nonatomic) NSData *macAddr;

/*
 *  @property RSSI
 *
 *  @discussion 在查询到或者连接并通过readRSSI读取之后的RSSI值，单位db
 *
 */
@property (strong, nonatomic) NSNumber *RSSI;

/*
 *  @property connTimer
 *
 *  @discussion 连接超时定时器。
 *
 */
@property (strong, nonatomic) NSTimer *connTimer;

/*
 *  @property serviceDiscoveryTimer
 *
 *  @discussion 服务搜索超时定时器
 */
@property (strong, nonatomic) NSTimer *serviceDiscoveryTimer;

/*
 *  @property communicationEncryptKey
 *
 *  @discussion 对通讯过程中数据进行加密的密匙
 */
@property (strong, nonatomic) NSData *communicationEncryptKey;

/*
 *  @property dataReceiveTimer
 *
 *  @discussion 数据发送后，正常应该接收到BLE设备的应答数据包，如果在一段时间没有收到数据，应该认为BLE设备接收数据失败
 */
@property (strong, nonatomic) NSTimer *dataReceiveTimer;

/*
 *  @property isConnecting
 *
 *  @discussion 是否正在与设备建立连接
 *
 */
@property (nonatomic) Boolean isConnecting;

/*
 *  @property isConnected
 *
 *  @discussion 是否与设备建立了连接
 *
 */
@property (nonatomic) Boolean isConnected;

/*
 *  @property cuurentSendingCommandType
 *
 *  @discussion 当前正在发送的数据类型
 *
 */
@property (nonatomic) libCommandType cuurentSendingCommandType;

/*
 *  @property dataSendRemote 正在或正准备发送到远端的数据
 *
 *  @discussion
 *
 */
@property (strong, nonatomic) NSMutableData *dataSendRemote;

@property (nonatomic) NSUInteger dataSendedLength;

/*
 *  @property dataSendTryNumber 发送dataSendRemote数据包，有可能出现BLE设备无应答的情况，我们可以设置一个尝试次数
 *
 *  @discussion
 */
@property (nonatomic) NSUInteger dataSendTryNumber;

@property (strong, nonatomic) NSMutableData *dataReceiveRemote;

@property (strong, nonatomic) NSMutableArray *lockLogData;

/*
 *  @method initWithCBPeripheral:
 *
 *  @param peripheral	The peripheral device
 *         delegate     the delegate to receive the events
 *
 *  @discussion 
 *         初始化函数
 *
 */
-(id) initWithCBPeripheral:(CBPeripheral *)peripheral delegate:(id<PeripheralDeviceManagerDelegate>)delegate;

/*
 *  @method didPeripheralDeviceDisconnected
 *
 *  @discussion
 *          与BLE设备断开连接后，通过该函数复位该设备相关的变量
 */
-(void) didPeripheralDeviceStateReset;

/*
 *  @method discoverPeripheralDeviceServices
 *
 *  @discussion
 *          搜索Ble设备中是否注册有指定的服务记录
 */
-(Boolean) discoverPeripheralDeviceServices;

/*
 *  @method dataConnectPeripheralDevice
 *
 *  @discussion
 *          在连接建立后，发送数据给蓝牙门锁模块
 */
-(Boolean) dataSendToPeripheraDevice:(libCommandType)cmd_type param_data:(NSData *)param_data;

@end

/*
 *  @protocol PeripheralDeviceManagerDelegate
 *
 *  @discussion The delegate of a {@link PeripheralDeviceManager} object.
 *
 */
@protocol PeripheralDeviceManagerDelegate <NSObject>

@required

-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice GetBattery:(NSData*)battery;

/*!
 *  @method peripheralDeviceManager:didServiceDiscoverResult:
 *
 *  @param  peripheralDevice    peripheralDeviceManager指针
 *          success             服务搜索结果
 *
 *  @discussion
 *          当调用discoverPeripheralDeviceServices函数搜索设备指定的服务及特征值完成后，peripheralDeviceManager返回结果
 */
-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice didServiceDiscoverResult:(Boolean)success;

/*!
 *  @method peripheralDeviceManager:didCommunicationEncryptKeyGetTimeout:
 *
 *  @param  peripheralDevice    peripheralDeviceManager指针
 *          success             服务搜索结果
 *
 *  @discussion
 *          当获取远端设备的服务及特征值完成后，在一段时间内没有获取到通讯密匙
 */
-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice didCommunicationEncryptKeyGetTimeout:(Boolean)success;

/*
 *  @method peripheralDeviceManager:didDataSendResponse:
 *
 *  @param  peripheralDevice	PeripheralDeviceManager对象
 *          result              结果是否成功
 *          cmd_type            应答的命令类型
 *          param_data          应答返回的参数
 *  @discussion 
 *          返回发送指令的应答
 *
 */
-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice didDataSendResponse:(libBleErrorCode)result cmd_type:(libCommandType)cmd_type param_data:(NSData *)param_data;

/*
 *  @method peripheralDeviceManager:OpenLockLogDataInd:
 *
 *  @param  peripheralDevice	PeripheralDeviceManager对象
 *          log_data            日志数据
 *          record_count        已读取日志条数
 *
 *  @discussion
 *          返回正在读取的日志数据
 */
-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice OpenLockLogDataInd:(NSMutableArray *)log_data record_count:(NSInteger)record_count;

@end
