//
//  libBleLock.m
//  libBleLock
//
//  Created by 金瓯科技 on 15/3/11.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import "libBleLock.h"
#import "PeripheralDeviceManager.h"
#import "DataTypeConversion.h"
#import "printLog.h"

/*用于存放搜索到的设备列表信息的文件*/
#define PERIPHERALS_LIST_FILE_NAME  @"PeripheralsList.xml"

#define DEFAULT_CONNECT_TIMEOUT      3      /* second */

@interface libBleLock () <PeripheralDeviceManagerDelegate>

@property (strong, nonatomic) NSTimer *inquiryTimer;
@property Boolean isInquiryingPeripherals;
@property Boolean isApplicationRemandInquiry;
@property (strong, nullable) NSData *remoteMacAddr;
@property (strong, nonatomic) NSMutableArray *peripheralsList;
@end

@implementation libBleLock
/*******************************定时器回调函数*********************************/

/*
 *  @method inquiryTimeoutTimer
 *
 *  @param  timer   定时器回调指针
 *
 *  @discussion
 *          搜索周围设备定时器超时后，停止CentralManager继续搜索操作
 */
-(void) inquiryTimeoutTimer:(NSTimer *)timer
{
    [self.centralManager stopScan];
    self.inquiryTimer = nil;
    self.isInquiryingPeripherals = FALSE;

    [self writePeripheralsListToFile];
    NSLog(@"%s",__func__);
    if (self.isApplicationRemandInquiry) {
        self.isApplicationRemandInquiry = FALSE;
        if (self.delegate) {
            [self.delegate didDiscoverComplete];
        }
    }
    else
    {
        PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByMacAddr:self.remoteMacAddr];
        if (peripheralDevice == nil)
        {
#ifdef NSLOG_DEBUG
            NSLog(@"inquiryTimeoutTimer deivce can't qinuiry");
#ifdef PRINT_LOG
            [printLog printLogToFile:@"inquiryTimeoutTimer deivce can't qinuiry\n"];
#endif
#endif
            [self.delegate didConnectConfirm:self.remoteMacAddr status:FALSE];
            self.remoteMacAddr = nil;
        }
        else
        {
#ifdef NSLOG_DEBUG
            NSLog(@"find deivce, will connect");
#ifdef PRINT_LOG
            [printLog printLogToFile:@"find deivce, will connect\n"];
#endif
#endif
            peripheralDevice.isConnecting = TRUE;
            [self.centralManager connectPeripheral:peripheralDevice.peerPeripheral options:nil];
            peripheralDevice.connTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_CONNECT_TIMEOUT target:self selector:@selector(connectTimeoutTimer:) userInfo:peripheralDevice repeats:NO];
        }
    }
}


/*
 *  @method connectTimeoutTimer
 *
 *  @param  timer   定时器回调指针
 *
 *  @discussion
 *          连接周围设备定时器超时后，取消CentralManager继续连接操作
 */
-(void) connectTimeoutTimer:(NSTimer *)timer
{
    PeripheralDeviceManager *peripheralDevice = timer.userInfo;
    if (peripheralDevice == nil)
        return;
    
#ifdef NSLOG_DEBUG
    NSLog(@"connectTimeoutTimer cancelPeripheralConnection");
#ifdef PRINT_LOG
    [printLog printLogToFile:@"connectTimeoutTimer cancelPeripheralConnection\n"];
#endif
#endif
    
    [self.centralManager cancelPeripheralConnection:peripheralDevice.peerPeripheral];
    
    if (peripheralDevice.isConnecting && self.delegate != nil)
    {
        [self.delegate didConnectConfirm:peripheralDevice.macAddr status:FALSE];
        self.remoteMacAddr = nil;
    }
    peripheralDevice.connTimer = nil;
    [peripheralDevice didPeripheralDeviceStateReset];
}

/*************************库函数实现*************************/

/*
 *  @method initWithDelegate
 *
 *  @param  delegate
 *
 *  @discussion
 实例初始化
 */
-(id) initWithDelegate:(id<libBleLockDelegate>)delegate
{
    NSLog(@"initWithDelegate:%@", delegate);
    self = [super init];
    self.delegate = delegate;
    NSDictionary *options = @{CBCentralManagerOptionRestoreIdentifierKey:@"myRestoreID"};
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
    self.isInquiryingPeripherals = FALSE;
    self.inquiryTimer = nil;
    self.remoteMacAddr = nil;
    self.peripheralsList = [[NSMutableArray alloc] initWithCapacity:1];
    [self readPeripheralsListFromFile];
    return self;
}

/*
 *  @method bleInquiry
 *
 *  @param  timeoutSeconds  搜索设备超时时间
 *
 *  @discussion
 *          搜索周围BLE蓝牙设备
 */
-(Boolean) bleInquiry:(NSTimeInterval)timeoutSeconds
{
#ifdef NSLOG_DEBUG
    NSLog(@"bleInquiry\n");
#ifdef PRINT_LOG
    [printLog printLogToFile:@"bleInquiry"];
#endif
#endif
    
    if (self.centralManager.state != CBManagerStatePoweredOn)
    {
        return FALSE;
    }
    
    self.isApplicationRemandInquiry = TRUE;
    
    if (self.isInquiryingPeripherals)
    {
        return TRUE;
    }
    NSArray *uuidArray = [NSArray arrayWithObjects:[CBUUID UUIDWithString:UUID_SERVICE_FOR_DATA], nil];
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [self.centralManager scanForPeripheralsWithServices:uuidArray options:options];
    self.isInquiryingPeripherals = TRUE;
    self.inquiryTimer = [NSTimer scheduledTimerWithTimeInterval:timeoutSeconds target:self selector:@selector(inquiryTimeoutTimer:) userInfo:nil repeats:NO];
    return TRUE;
}

/*
 *  @method bleCancelInquiry
 *
 *  @discussion
 *  取消搜索周围BLE蓝牙设备
 */
-(Boolean) bleCancelInquiry
{
    if (self.isApplicationRemandInquiry && self.isInquiryingPeripherals) {
        [self.inquiryTimer fire];
        
        return TRUE;
    }
    else
        return FALSE;
}


/*
 *  @method bleConnectRequest
 *
 *  @param  macAddr         蓝牙MAC地址
 *
 *  @discussion
 *          连接指定Mac地址的Ble设备
 */
-(Boolean) bleConnectRequest:(NSData *)macAddr
{
#ifdef NSLOG_DEBUG
    NSLog(@"bleConnectRequest:%@, %d", self.remoteMacAddr, self.isInquiryingPeripherals);
#ifdef PRINT_LOG
    [printLog printLogToFile:@"bleConnectRequest\n"];
#endif
#endif
    if (macAddr.length == 0)
    {
        return FALSE;
    }
    if (self.centralManager.state != CBCentralManagerStatePoweredOn || self.remoteMacAddr != nil)
    {
        return FALSE;
    }
    
    if(_isInquiryingPeripherals)
    {
        [self.inquiryTimer fire];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self bleConnectRequest:macAddr];
        });
        return FALSE;
    }
    self.remoteMacAddr = macAddr;
    PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByMacAddr:self.remoteMacAddr];
    if (peripheralDevice == nil)
    {
        self.inquiryTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(inquiryTimeoutTimer:) userInfo:nil repeats:NO];
        NSArray *uuidArray = [NSArray arrayWithObjects:[CBUUID UUIDWithString:UUID_SERVICE_FOR_DATA], nil];
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [self.centralManager scanForPeripheralsWithServices:uuidArray options:options];
        self.isInquiryingPeripherals = TRUE;
#ifdef NSLOG_DEBUG
        NSLog(@"scanForPeripheralsWithServices");
#ifdef PRINT_LOG
        [printLog printLogToFile:@"scanForPeripheralsWithServices\n"];
#endif
#endif
        return TRUE;
    }
    else if (peripheralDevice.isConnecting || peripheralDevice.isConnected)
    {
        return FALSE;
    }

    peripheralDevice.isConnecting = TRUE;
    [self.centralManager connectPeripheral:peripheralDevice.peerPeripheral options:nil];
    peripheralDevice.connTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_CONNECT_TIMEOUT target:self selector:@selector(connectTimeoutTimer:) userInfo:peripheralDevice repeats:NO];
    
    return TRUE;
}

/*
 *  @method bleConnectRequest
 *
 *  @param  macAddr         蓝牙MAC地址
 *          linkkey         鉴权链接字
 *
 *  @discussion
 *          连接指定Mac地址的Ble设备
 */
-(Boolean) bleIsConnected:(NSData *)macAddr
{
    if (self.centralManager.state != CBCentralManagerStatePoweredOn)
    {
        return FALSE;
    }
    
    PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByMacAddr:macAddr];
    if (peripheralDevice && peripheralDevice.isConnected)
        return TRUE;
    else
        return FALSE;
}

/*
 *  @method bleDisconnectRequest
 *
 *  @param  macAddr         蓝牙MAC地址
 *
 *  @discussion
 *          断开与指定Mac地址的Ble设备连接
 */
-(Boolean) bleDisconnectRequest:(NSData *)macAddr
{
    if (self.centralManager.state != CBCentralManagerStatePoweredOn)
    {
        return FALSE;
    }
    
    PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByMacAddr:macAddr];
    if (peripheralDevice == nil)
    {
        return FALSE;
    }
    else if(peripheralDevice.peerPeripheral.state == CBPeripheralStateConnected)
    {
#ifdef NSLOG_DEBUG
        NSLog(@"bleDisconnectRequest cancelPeripheralConnection");
#ifdef PRINT_LOG
        [printLog printLogToFile:@"bleDisconnectRequest cancelPeripheralConnection\n"];
#endif
#endif
        if (peripheralDevice.isConnected)
            [peripheralDevice dataSendToPeripheraDevice:libBleCmdDisconnect param_data:nil];
        [self.centralManager cancelPeripheralConnection:peripheralDevice.peerPeripheral];
    }
    
    return TRUE;
}

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
-(Boolean) bleDataSendRequest:(NSData *)macAddr cmd_type:(libCommandType)cmd_type param_data:(NSData *)param_data
{
    if (self.centralManager.state != CBCentralManagerStatePoweredOn)
    {
        return FALSE;
    }
    
    PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByMacAddr:macAddr];
    if (peripheralDevice == nil || !peripheralDevice.isConnected)
    {
        return FALSE;
    }
    
    if ([peripheralDevice dataSendToPeripheraDevice:cmd_type param_data:param_data])
        return TRUE;
    
    return FALSE;
}

#pragma mark - CBCentralManager回调函数

-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict
{
    NSLog(@"%@",dict);
}

/*
 *  @method centralManagerDidUpdateState
 *
 *  @discussion
 *          This callback when the Bluetooth Module changes State (normally power state)
 *          Bluetooth Module change of state Mainly used to check the Bluetooth is powered up 
 *          and to alert the user if it is not.
 */
-(void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
#ifdef NSLOG_DEBUG
            NSLog(@"centralManagerDidUpdateState CBCentralManagerStatePoweredOn");
#ifdef PRINT_LOG
            [printLog printLogToFile:@"centralManagerDidUpdateState CBCentralManagerStatePoweredOn\n"];
#endif
#endif
            break;
            
        case CBCentralManagerStatePoweredOff:
        {
            PeripheralDeviceManager *peripheralDevice;
#ifdef NSLOG_DEBUG
            NSLog(@"centralManagerDidUpdateState CBCentralManagerStatePoweredOff");
#ifdef PRINT_LOG
            [printLog printLogToFile:@"centralManagerDidUpdateState CBCentralManagerStatePoweredOff\n"];
#endif
#endif
            
            for(NSUInteger i = 0; i < self.peripheralsList.count; i++)
            {
                peripheralDevice = [self.peripheralsList objectAtIndex:i];
                
                if(peripheralDevice.connTimer)
                {
                    [peripheralDevice.connTimer invalidate];
                    peripheralDevice.connTimer = nil;
                }
                
                if (self.delegate != nil) {
                    if(peripheralDevice.isConnected)
                    {
                        [self.delegate didDisconnectIndication:peripheralDevice.macAddr];
                    }
                    else if(peripheralDevice.isConnecting)
                    {
                        [self.delegate didConnectConfirm:peripheralDevice.macAddr status:FALSE];
                    }
                }

                [peripheralDevice didPeripheralDeviceStateReset];
            }
            self.remoteMacAddr = nil;
            if (self.isInquiryingPeripherals)
            {
                [self.inquiryTimer fire];
            }
        }
            break;
        
        case CBCentralManagerStateResetting:
            break;
        
        default:
            break;
    }
}

/*!
 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  @param  central             CBCentralManager指针
 *          peripheral          BLE设备指针
 *          advertisementData   BLE设备广播数据指针
 *          RSSI                BLE设备与iphone设备之间的信号强度
 *  @discussion 
 *      当搜索周围BLE设备时，CBCentralManager通过该回调函数返回搜索结果
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
#ifdef NSLOG_DEBUG
    NSLog(@"didDiscoverPeripheral:%@ %@ %@", peripheral, advertisementData, RSSI);
#ifdef PRINT_LOG
    [printLog printLogToFile:[[NSString alloc] initWithFormat:@"didDiscoverPeripheral:%@ %@ %@\n", peripheral, advertisementData, RSSI]];
#endif
#endif
    
    PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByCBPeripheral:peripheral];
    NSData *nsdataManufacturerData = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
    
    if (self.isApplicationRemandInquiry) {
        NSData *deviceName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        
        if (nsdataManufacturerData.length == 6) {
            if (peripheralDevice) {
                peripheralDevice.peerPeripheral = peripheral;
            }
            else
            {
                peripheralDevice = [[PeripheralDeviceManager alloc] initWithCBPeripheral:peripheral delegate:self];
                [self.peripheralsList addObject:peripheralDevice];
            }
            peripheralDevice.advertisementData = advertisementData;
            peripheralDevice.RSSI = RSSI;
            peripheralDevice.macAddr = [[NSData alloc] initWithData:nsdataManufacturerData];
            
            if (self.delegate) {
                [self.delegate didDiscoverResult:peripheralDevice.macAddr deviceName:deviceName rssi:RSSI];
            }
        }
    }
    else if ([nsdataManufacturerData isEqualToData:self.remoteMacAddr]) {
        if (peripheralDevice) {
            peripheralDevice.peerPeripheral = peripheral;
        }
        else
        {
            peripheralDevice = [[PeripheralDeviceManager alloc] initWithCBPeripheral:peripheral delegate:self];
            [self.peripheralsList addObject:peripheralDevice];
        }
        peripheralDevice.advertisementData = advertisementData;
        peripheralDevice.RSSI = RSSI;
        peripheralDevice.macAddr = [[NSData alloc] initWithData:self.remoteMacAddr];
        
        [self.inquiryTimer fire];
    }
}

/*!
 *  @method centralManager:didConnectPeripheral:
 *
 *  @param  central             CBCentralManager指针
 *          peripheral          BLE设备指针
 *
 *  @discussion
 *      当与BLE设备成功建立连接后，CBCentralManager通过该回调函数报告连接完成
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByCBPeripheral:peripheral];
    if (peripheralDevice == nil)
    {
        peripheralDevice = [[PeripheralDeviceManager alloc] initWithCBPeripheral:peripheral delegate:self];
        peripheralDevice.isConnecting = TRUE;
        [self.peripheralsList addObject:peripheralDevice];
    }
    if (peripheralDevice.connTimer)
    {
        [peripheralDevice.connTimer invalidate];
        peripheralDevice.connTimer = nil;
    }
    if (! [peripheralDevice discoverPeripheralDeviceServices])
    {
#ifdef NSLOG_DEBUG
        NSLog(@"didConnectPeripheral service discover startup fail cancelPeripheralConnection");
#ifdef PRINT_LOG
        [printLog printLogToFile:@"didConnectPeripheral service discover startup fail cancelPeripheralConnection\n"];
#endif
#endif
        
        [self.centralManager cancelPeripheralConnection:peripheralDevice.peerPeripheral];
    }
}

/*!
 *  @method centralManager:didFailToConnectPeripheral:error:
 *
 *  @param  central             CBCentralManager指针
 *          peripheral          BLE设备指针
 *          error               连接失败原因
 *
 *  @discussion
 *          当与BLE设备建立连接失败后，CBCentralManager通过该回调函数报告
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByCBPeripheral:peripheral];
#ifdef NSLOG_DEBUG
    NSLog(@"didFailToConnectPeripheral");
#ifdef PRINT_LOG
    [printLog printLogToFile:@"didFailToConnectPeripheral\n"];
#endif
#endif
    if (peripheralDevice)
    {
        if (peripheralDevice.isConnecting && self.delegate != nil)
        {
            [self.delegate didConnectConfirm:peripheralDevice.macAddr status:FALSE];
            self.remoteMacAddr = nil;
        }
        [peripheralDevice didPeripheralDeviceStateReset];
    }
}

/*!
 *  @method centralManager:didDisconnectPeripheral:error:
 *
 *  @param  central             CBCentralManager指针
 *          peripheral          BLE设备指针
 *          error               连接断开原因
 *
 *  @discussion
 *          当与BLE设备连接断开后，CBCentralManager通过该回调函数报告
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByCBPeripheral:peripheral];
#ifdef NSLOG_DEBUG
    NSLog(@"didDisconnectPeripheral:%@, %@", peripheralDevice, self.delegate);
#ifdef PRINT_LOG
    [printLog printLogToFile:@"didDisconnectPeripheral\n"];
#endif
#endif
    if (peripheralDevice)
    {
        if (self.delegate != nil)
        {
            if (peripheralDevice.isConnected)
                [self.delegate didDisconnectIndication:peripheralDevice.macAddr];
            else if (peripheralDevice.isConnecting)
            {
                [self.delegate didConnectConfirm:peripheralDevice.macAddr status:FALSE];
            }
        }
        self.remoteMacAddr = nil;
        [peripheralDevice didPeripheralDeviceStateReset];
    }
}

/********************PeripheralDeviceManager回调函数**************************/

-(void)peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice GetBattery:(NSData *)battery
{
    NSString *bat = [DataTypeConversion NSDataConversionToNSString:battery];
    int batnum = (int)strtoul([bat UTF8String],0 , 16);
    [self.delegate didGetBattery:batnum forMac:peripheralDevice.macAddr];
}


/*!
 *  @method peripheralDeviceManager:didServiceDiscoverResult:
 *
 *  @param  peripheralDevice    peripheralDeviceManager指针
 *          success             服务搜索结果
 *
 *  @discussion
 *          当调用discoverPeripheralDeviceServices函数搜索设备指定的服务及特征值完成后，peripheralDeviceManager返回结果
 */
-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice didServiceDiscoverResult:(Boolean)success
{
#ifdef NSLOG_DEBUG
    NSLog(@"didServiceDiscoverResult result(%u)", success);
#ifdef PRINT_LOG
    [printLog printLogToFile:[[NSString alloc] initWithFormat:@"didServiceDiscoverResult result(%u)\n", success]];
#endif
#endif
    
    if (!success)
    {
        if(peripheralDevice.peerPeripheral.state == CBPeripheralStateConnected)
        {
#ifdef NSLOG_DEBUG
            NSLog(@"didServiceDiscoverResult fail cancelPeripheralConnection");
#ifdef PRINT_LOG
            [printLog printLogToFile:@"didServiceDiscoverResult fail cancelPeripheralConnection\n"];
#endif
#endif
            [self.centralManager cancelPeripheralConnection:peripheralDevice.peerPeripheral];
        }
        else if (peripheralDevice.isConnecting && self.delegate != nil)
        {
            [self.delegate didConnectConfirm:peripheralDevice.macAddr status:FALSE];
            self.remoteMacAddr = nil;
        }
    }
    else if(peripheralDevice.isConnecting)
    {
        peripheralDevice.isConnecting = FALSE;
        peripheralDevice.isConnected = TRUE;
        if (self.delegate != nil)
            [self.delegate didConnectConfirm:peripheralDevice.macAddr status:TRUE];
    }
}

/*!
 *  @method peripheralDeviceManager:didCommunicationEncryptKeyGetTimeout:
 *
 *  @param  peripheralDevice    peripheralDeviceManager指针
 *          success             服务搜索结果
 *
 *  @discussion
 *          当获取远端设备的服务及特征值完成后，在一段时间内没有获取到通讯密匙
 */
-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice didCommunicationEncryptKeyGetTimeout:(Boolean)success
{
    [self.centralManager cancelPeripheralConnection:peripheralDevice.peerPeripheral];
}

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
-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice didDataSendResponse:(libBleErrorCode)result cmd_type:(libCommandType)cmd_type param_data:(NSData *)param_data
{
    if (self.delegate != nil)
        [self.delegate didDataSendResponse:peripheralDevice.macAddr cmd_type:cmd_type result:result param_data:param_data];
    else
    {
        [peripheralDevice dataSendToPeripheraDevice:libBleCmdDisconnect param_data:nil];
        [self.centralManager cancelPeripheralConnection:peripheralDevice.peerPeripheral];
    }
}

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
-(void) peripheralDeviceManager:(PeripheralDeviceManager *)peripheralDevice OpenLockLogDataInd:(NSMutableArray *)log_data record_count:(NSInteger)record_count
{
    if (self.delegate != nil)
        [self.delegate didOpenLockLogDataInd:peripheralDevice.macAddr record_count:record_count log_data:log_data];
    else
    {
        [peripheralDevice dataSendToPeripheraDevice:libBleCmdDisconnect param_data:nil];
        [self.centralManager cancelPeripheralConnection:peripheralDevice.peerPeripheral];
    }
}

/****************************数据存储和处理函数*********************************/

/*
 *  @method readPeripheralsListFromFile
 *
 *  @discussion
 *          从文件中读取之前保存的搜索到的BLE设备的UUID，通过retrievePeripheralsWithIdentifiers获取系统已知设备的CBPeripheral的指针
 */
-(void) readPeripheralsListFromFile
{
    NSString *folderDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] ;
    NSString *filePath = [folderDirectory stringByAppendingPathComponent:PERIPHERALS_LIST_FILE_NAME];
    NSArray *reader = [NSArray arrayWithContentsOfFile:filePath];

    if (reader.count % 2 != 0)
    {
        /* uuid and macAddr */
        return;
    }
    
    NSMutableArray *uuidMutableArray = [[NSMutableArray alloc] init];
    NSArray *peripheralsArray = nil;
    NSString *sUUID, *sMacAddr;
    NSUInteger i, j;
    
    for (i = 0; i < reader.count; i+=2)
    {
        sUUID = [reader objectAtIndex:i];
        if ([[sUUID substringToIndex:5] compare:@"UUID:"] == NSOrderedSame)
        {
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[sUUID substringFromIndex:5]];
            if (uuid)
                [uuidMutableArray addObject:uuid];
        }
    }
    
    if (uuidMutableArray.count > 0)
    {
        peripheralsArray = [self.centralManager retrievePeripheralsWithIdentifiers:uuidMutableArray];

        for (i = 0; i < peripheralsArray.count; i++)
        {
            CBPeripheral *peripheral = [peripheralsArray objectAtIndex:i];
            PeripheralDeviceManager *peripheralDevice = [self getPeripheralDeviceFromPeripheralListByCBPeripheral:peripheral];
            if (peripheralDevice == nil)
            {
                peripheralDevice = [[PeripheralDeviceManager alloc] initWithCBPeripheral:peripheral delegate:self];
                [self.peripheralsList addObject:peripheralDevice];
            }
            for (j = 0; j < reader.count; j+=2)
            {
                sUUID = [reader objectAtIndex:j];
                if ([[sUUID substringFromIndex:5] isEqualToString:peripheral.identifier.UUIDString])
                {
                    sMacAddr = [reader objectAtIndex:j+1];
                    if ([[sMacAddr substringToIndex:5] compare:@"ADDR:"] == NSOrderedSame)
                    {
                        peripheralDevice.macAddr = [DataTypeConversion NSStringConversionToNSData:[sMacAddr substringFromIndex:5]];
                    }
                }
            }
        }
    }
    [self writePeripheralsListToFile];
}

/*!
 *  @method writePeripheralsListToFile:
 *
 *  @returns none
 *
 *  @discussion 将设备列表信息写入文件，以便下次使用，写入时，保存设备的UUID及名称两种信息
 *
 */
-(void) writePeripheralsListToFile
{
    PeripheralDeviceManager *peripheralDevice;
    NSString *folderDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] ;
    NSString *filePath = [folderDirectory stringByAppendingPathComponent:PERIPHERALS_LIST_FILE_NAME];

    //创建数据缓冲
    NSMutableArray *writer = [[NSMutableArray alloc] init];
    
    for(NSUInteger i = 0;i < self.peripheralsList.count; i++)
    {
        peripheralDevice = [self.peripheralsList objectAtIndex: i];
        [writer addObject:[NSString stringWithFormat:@"UUID:%@", peripheralDevice.peerPeripheral.identifier.UUIDString]];
        [writer addObject:[NSString stringWithFormat:@"ADDR:%@", [DataTypeConversion NSDataConversionToNSString:peripheralDevice.macAddr]]];
    }
    [writer writeToFile:filePath atomically:YES];
}

/****************************设备列表管理函数*********************************/

/*
 *  @method getPeripheralDeviceFromPeripheralListByCBPeripheral
 *
 *  @param  peripheral  CBPeripheral对象
 *
 *  @discussion 
 *          根据给定的 CBPeripheral对象获取PeripheralDeviceManager类指针
 *
 */
-(PeripheralDeviceManager *) getPeripheralDeviceFromPeripheralListByCBPeripheral:(CBPeripheral *)peripheral
{
    PeripheralDeviceManager *peripheralDevice;
    
    for(NSUInteger i = 0; i < self.peripheralsList.count; i++)
    {
        peripheralDevice = [self.peripheralsList objectAtIndex:i];
        if ((peripheralDevice != nil) && (peripheralDevice.peerPeripheral != nil)
            && [peripheralDevice.peerPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
        {
            return peripheralDevice;
        }
    }
    
    return nil;
}

/*
 *  @method getPeripheralDeviceFromPeripheralListByMacAddr
 *
 *  @param  macAddr  BLE设备的MAC地址
 *
 *  @discussion
 *          根据给定的MAC地址获取PeripheralDeviceManager类指针
 *
 */
-(PeripheralDeviceManager *) getPeripheralDeviceFromPeripheralListByMacAddr:(NSData *)macAddr
{
    PeripheralDeviceManager *peripheralDevice;

    for(NSUInteger i = 0; i < self.peripheralsList.count; i++)
    {
        peripheralDevice = [self.peripheralsList objectAtIndex:i];
        if ((peripheralDevice != nil) && [peripheralDevice.macAddr isEqualToData:macAddr])
        {
            return peripheralDevice;
        }
    }
    
    return nil;
}

@end
