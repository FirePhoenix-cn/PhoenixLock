//
//  PeripheralDeviceManager.m
//  libBleLock
//
//  Created by 金瓯科技 on 15/3/17.
//  Copyright (c) 2015年 金瓯科技. All rights reserved.
//

#import "libBleLock.h"
#import "PeripheralDeviceManager.h"
#import "DataTypeConversion.h"
#import "printLog.h"

#define DEFAULT_SERVICE_DISCOVERY_TIMEOUT       5      /* second */

#define DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT     2      /* second */

#define DEFAULT_SEND_DATA_TRY_MAX_NUMBER        1

#define MAX_LENGTH_FOR_EACH_PACKET              20

#define COMMUNICATION_KEY_LENGTH                8

@implementation PeripheralDeviceManager
{
    BOOL _isbattery;
}

- (void) encryptAndDecryptData:(NSMutableData *)encrypted_data encrypt_key:(NSData *)encrypt_key
{
    NSUInteger encrypted_data_index, encrypt_key_index;
    Byte *byte_encrypted_data = (Byte *)[encrypted_data bytes];
    Byte *byte_encrypt_key = (Byte *)[encrypt_key bytes];
    
    for (encrypted_data_index = 0, encrypt_key_index = 0; encrypted_data_index < encrypted_data.length; encrypted_data_index++)
    {
        byte_encrypted_data[encrypted_data_index] ^= byte_encrypt_key[encrypt_key_index];
        encrypt_key_index = (encrypt_key_index + 1) % encrypt_key.length;
    }
}

-(packetTypeForRemoteBleDevice) getPacketTypeForSendDataPacket:(libCommandType) cmd_type
{
    packetTypeForRemoteBleDevice packet_type;
    
    switch (cmd_type) {
        case libBleCmdBindManager:
            packet_type = COMMAND_TYPE_CODE_BIND_MANAGER_REQ;
            break;
            
        case libBleCmdAddManagerOpenLockUUID:
            packet_type = COMMAND_TYPE_CODE_ADD_MANAGER_OPEN_LOCK_UUID_REQ;
            break;
            
        case libBleCmdSendManagerCommunicateUUID:
            packet_type = COMMAND_TYPE_CODE_SEND_MANAGER_COMMUNICATE_UUID_REQ;
            break;
            
        case libBleCmdSendManagerOpenLockUUID:
            packet_type = COMMAND_TYPE_CODE_SEND_MANAGER_OPEN_LOCK_UUID_REQ;
            break;
            
        case libBleCmdClearManager:
            packet_type = COMMAND_TYPE_CODE_CLEAR_MANAGER_REQ;
            break;
            
        case libBleCmdAddSharerOpenLockUUID:
            packet_type = COMMAND_TYPE_CODE_ADD_SHARER_OPEN_LOCK_UUID_REQ;
            break;
            
        case libBleCmdDeleteSharerOpenLockUUID:
            packet_type = COMMAND_TYPE_CODE_DELETE_SHARER_OPEN_LOCK_UUID_REQ;
            break;
            
        case libBleCmdEmptySharerOpenLockUUID:
            packet_type = COMMAND_TYPE_CODE_EMPTY_SHARER_OPEN_LOCK_UUID_REQ;
            break;
            
        case libBleCmdSendSharerCommunicateUUID:
            packet_type = COMMAND_TYPE_CODE_SEND_SHARER_COMMUNICATE_UUID_REQ;
            break;
            
        case libBleCmdSendSharerOpenLockUUID:
            packet_type = COMMAND_TYPE_CODE_SEND_SHARER_OPEN_LOCK_UUID_REQ;
            break;
            
        case libBleCmdReadLockLog:
            packet_type = COMMAND_TYPE_CODE_READ_LOCK_LOG_REQ;
            break;
            
        case libBleCmdEmptyLockLog:
            packet_type = COMMAND_TYPE_CODE_EMPTY_LOCK_LOG_REQ;
            break;
            
        case libBleCmdDisconnect:
            packet_type = COMMAND_TYPE_CODE_DISCONNECT_REQ;
            break;
            
        default:
            packet_type = COMMAND_TYPE_CODE_UNKNOW;
            break;
    }
    
    return packet_type;
}

- (NSUInteger) remoteDataPacketLength:(NSData *) packet encrypt_key:(NSData *)encrypt_key
{
    Byte *byte_packet = (Byte *)[packet bytes];
    Byte *byte_encrypt_key = (Byte *)[encrypt_key bytes];
    
    return (byte_packet[0]^byte_encrypt_key[0]) & 0xFF;
}

-(void) getCommunicationEncryptKey:(NSData *)random_key
{
    if(random_key.length == MAX_LENGTH_FOR_EACH_PACKET)
    {
        Byte *byte_random_key = (Byte *)[random_key bytes];
        Byte byte_communication_encrypt_key[COMMUNICATION_KEY_LENGTH];
        Byte index, init, total, select_index, nonzero_index;
    
        if (self->_dataReceiveTimer)
        {
            [self->_dataReceiveTimer invalidate];
            self->_dataReceiveTimer = nil;
        }
        
        init = (byte_random_key[1] + byte_random_key[3] + byte_random_key[5]) & 0xFF;
        total = init;
    
        for (index = 0; index < COMMUNICATION_KEY_LENGTH; index++)
        {
            select_index = total % MAX_LENGTH_FOR_EACH_PACKET;
            if (byte_random_key[select_index] != 0)
                byte_communication_encrypt_key[index] = byte_random_key[select_index];
            else
            {
                for (nonzero_index = 1; nonzero_index < MAX_LENGTH_FOR_EACH_PACKET; nonzero_index++)
                {
                    select_index = (select_index + 1) % MAX_LENGTH_FOR_EACH_PACKET;
                    if( byte_random_key[select_index] != 0)
                    {
                        byte_communication_encrypt_key[index] = byte_random_key[select_index];
                        break;
                    }
                }
            }
            total = (init + byte_random_key[select_index]) & 0xFF;
            byte_random_key[select_index] = 0;
        }
        
        self->_communicationEncryptKey = [[NSData alloc] initWithBytes:byte_communication_encrypt_key length:COMMUNICATION_KEY_LENGTH];
#ifdef NSLOG_DEBUG
        NSLog(@"_communicationEncryptKey:%@", self->_communicationEncryptKey);
#ifdef PRINT_LOG
        [printLog printLogToFile:[[NSString alloc] initWithFormat:@"_communicationEncryptKey:%@", self->_communicationEncryptKey]];
#endif
#endif
    }
}

-(void) parseReceivedRemoteDeviceData:(NSData *)received_data
{
    NSUInteger received_data_length;
    
    if (self->_dataReceiveRemote == nil)
        self->_dataReceiveRemote = [[NSMutableData alloc] initWithData:received_data];
    
    else
        [self->_dataReceiveRemote appendData:received_data];
    
    received_data_length = [self remoteDataPacketLength:self->_dataReceiveRemote encrypt_key:self->_communicationEncryptKey]+1;
    if (self->_dataReceiveRemote.length > received_data_length || received_data_length > MAX_LENGTH_FOR_EACH_PACKET *2)
        self->_dataReceiveRemote = nil;
    else if(self->_dataReceiveRemote.length == received_data_length)
    {
        [self encryptAndDecryptData:self->_dataReceiveRemote encrypt_key:self->_communicationEncryptKey];
        Byte *byte_decrypt_packet = (Byte *)[self->_dataReceiveRemote bytes];
        bool response_finish = TRUE;
        
        switch (byte_decrypt_packet[1]) {
            case COMMAND_TYPE_CODE_BIND_MANAGER_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdBindManager param_data:((received_data_length > 3) ? [self->_dataReceiveRemote subdataWithRange:NSMakeRange(3, received_data_length-3)]: nil)];
                break;
                
            case COMMAND_TYPE_CODE_ADD_MANAGER_OPEN_LOCK_UUID_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdAddManagerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_SEND_MANAGER_COMMUNICATE_UUID_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdSendManagerCommunicateUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_SEND_MANAGER_OPEN_LOCK_UUID_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdSendManagerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_CLEAR_MANAGER_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdClearManager param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_ADD_SHARER_OPEN_LOCK_UUID_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdAddSharerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_DELETE_SHARER_OPEN_LOCK_UUID_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdDeleteSharerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_EMPTY_SHARER_OPEN_LOCK_UUID_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdEmptySharerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_SEND_SHARER_COMMUNICATE_UUID_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdSendSharerCommunicateUUID param_data:nil];                break;
                
            case COMMAND_TYPE_CODE_SEND_SHARER_OPEN_LOCK_UUID_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdSendSharerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_READ_LOCK_LOG_RSP:
                NSLog(@"lock_log:%@", self->_dataReceiveRemote);
                if (byte_decrypt_packet[3] == 0x00)
                {
                    [self->_delegate peripheralDeviceManager:self OpenLockLogDataInd:self->_lockLogData record_count:((self->_lockLogData != nil) ? [self->_lockLogData count] : 0)];
                    [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdReadLockLog param_data:nil];
                }
                else
                {
                    if (received_data_length >= 8)
                    {
                        if (self->_lockLogData == nil)
                            self->_lockLogData = [[NSMutableArray alloc] initWithCapacity:1];
                        
                        NSDictionary *dictionaryLockRecord = [[NSDictionary alloc] initWithObjectsAndKeys:((received_data_length > 8) ? [DataTypeConversion NSDataConversionToNSString:[self->_dataReceiveRemote subdataWithRange:NSMakeRange(8, received_data_length-8)]] : @""), @"lockAccount", [DataTypeConversion NSDataConversionToNSString:[self->_dataReceiveRemote subdataWithRange:NSMakeRange(4, 4)]], @"lockTime", nil];
                        [self->_lockLogData addObject:dictionaryLockRecord];
                    
                        if ([self->_lockLogData count] % 10 == 0)
                            [self->_delegate peripheralDeviceManager:self OpenLockLogDataInd:nil record_count:[self->_lockLogData count]];
                    }
                    response_finish = FALSE;
                    [self didperipheralDeviceReceiveLockLogRecordReset];
                }
                    
                break;
                
            case COMMAND_TYPE_CODE_EMPTY_LOCK_LOG_RSP:
                [self->_delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdEmptyLockLog param_data:nil];
                break;
                
            default:
                break;
        }
        
        if (response_finish)
            [self didPeripheralDeviceDataSendReset];
    }
}

/*!
 *  @method initWithCBPeripheral:
 *
 *  @param peripheral	The peripheral device
 *         delegate     the delegate to receive the events
 *
 *  @discussion
 *         初始化函数
 *
 */
-(id) initWithCBPeripheral:(CBPeripheral *)peripheral delegate:(id<PeripheralDeviceManagerDelegate>)delegate
{
    self = [super init];
    if(self)
    {
        self->_delegate = delegate;
        self->_peerPeripheral = peripheral;
        self->_peerPeripheral.delegate = self;
        self->_advertisementData = nil;
        self->_macAddr = nil;
        self->_RSSI = nil;
        
        self->dataService = nil;
        self->dataCharacteristicRead = nil;
        self->dataCharacteristicWrite = nil;
        self->bSendedDidServiceDiscoverResultEvent = FALSE;        

        self->_connTimer = nil;
        self->_serviceDiscoveryTimer = nil;
        self->_communicationEncryptKey = nil;
        self->_cuurentSendingCommandType = libBleCmdNone;
        self->_dataReceiveTimer = nil;
        self->_isConnecting = FALSE;
        self->_isConnected = FALSE;
        self->_dataSendRemote = nil;
        self->_dataSendedLength = 0;
        self->_dataSendTryNumber = 0;
        self->_dataReceiveRemote = nil;
        self->_lockLogData = nil;
    }
    
    return self;
}

/*
 *  @method didPeripheralDeviceStateReset
 *
 *  @discussion
 *          与BLE设备断开连接后，通过该函数复位该设备相关的变量
 */
-(void) didPeripheralDeviceStateReset
{
    self->dataService = nil;
    self->dataCharacteristicRead = nil;
    self->dataCharacteristicWrite = nil;
    self->bSendedDidServiceDiscoverResultEvent = FALSE;
    
    if (self->_connTimer)
    {
        [self->_connTimer invalidate];
        self->_connTimer = nil;
    }
    if (self->_serviceDiscoveryTimer)
    {
        [self->_serviceDiscoveryTimer invalidate];
        self->_serviceDiscoveryTimer = nil;
    }
    self->_communicationEncryptKey = nil;
    self->_cuurentSendingCommandType = libBleCmdNone;
    if (self->_dataReceiveTimer)
    {
        [self->_dataReceiveTimer invalidate];
        self->_dataReceiveTimer = nil;
    }
    self->_isConnecting = FALSE;
    self->_isConnected = FALSE;
    self->_dataSendRemote = nil;
    self->_dataSendedLength = 0;
    self->_dataSendTryNumber = 0;
    self->_dataReceiveRemote = nil;
    self->_lockLogData = nil;
}

/*
 *  @method didPeripheralDeviceDataSendReset
 *
 *  @discussion
 *          接收到远端设备的数据应答并解析完成后，复位这些变量
 */
-(void) didPeripheralDeviceDataSendReset
{
    self->_cuurentSendingCommandType = libBleCmdNone;
    self->_dataSendRemote = nil;
    self->_dataSendedLength = 0;
    self->_dataSendTryNumber = 0;
    self->_dataReceiveRemote = nil;
    self->_lockLogData = nil;
    if (self->_dataReceiveTimer) {
        [self->_dataReceiveTimer invalidate];
        self->_dataReceiveTimer = nil;
    }
}

-(void) didperipheralDeviceReceiveLockLogRecordReset
{
    self->_dataSendRemote = nil;
    self->_dataSendedLength = 0;
    self->_dataSendTryNumber = 0;
    self->_dataReceiveRemote = nil;
}

/*
 *  @method discoverPeripheralDeviceServices
 *
 *  @discussion
 *          搜索Ble设备中是否注册有指定的服务记录
 */
-(Boolean) discoverPeripheralDeviceServices:(BOOL)isbattery
{
    if (self->_peerPeripheral.state != CBPeripheralStateConnected)
        return FALSE;
    
    NSArray *uuidArray = [NSArray arrayWithObjects:[CBUUID UUIDWithString:UUID_SERVICE_FOR_DATA],[CBUUID UUIDWithString:UUID_SERVICE_FOR_BATTERY], nil];
    self->_isbattery = isbattery;
    [self->_peerPeripheral discoverServices:uuidArray];
    self->_serviceDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_SERVICE_DISCOVERY_TIMEOUT target:self selector:@selector(serviceDiscoveryTimeoutTimer:) userInfo:nil repeats:NO];
    
    return TRUE;
}

/*
 *  @method dataConnectPeripheralDevice
 *
 *  @discussion
 *          在连接建立后，发送数据给蓝牙门锁模块
 */
-(Boolean) dataSendToPeripheraDevice:(libCommandType)cmd_type param_data:(NSData *)param_data
{
    if (self->_communicationEncryptKey) {
        Byte packetHead[2];
        NSUInteger willSendLength;
    
        packetHead[0] = [param_data length]+1;
        packetHead[1] = [self getPacketTypeForSendDataPacket:cmd_type];
    
        self->_dataSendRemote = [[NSMutableData alloc] initWithBytes:packetHead length:sizeof(packetHead)];
        [self->_dataSendRemote appendData:param_data];
        [self encryptAndDecryptData:self->_dataSendRemote encrypt_key:self->_communicationEncryptKey];
#ifdef NSLOG_DEBUG
        NSLog(@"dataSendToPeripheraDevice:%@", self->_dataSendRemote);
#ifdef PRINT_LOG
        [printLog printLogToFile:[[NSString alloc] initWithFormat:@"dataSendToPeripheraDevice:%@\n", self->_dataSendRemote]];
#endif
#endif
        
        self->_dataSendedLength = 0;
        willSendLength = (self->_dataSendRemote.length-self->_dataSendedLength >= MAX_LENGTH_FOR_EACH_PACKET) ? MAX_LENGTH_FOR_EACH_PACKET : (self->_dataSendRemote.length-self->_dataSendedLength);
        
        NSData *sendingPacket = [self->_dataSendRemote subdataWithRange:NSMakeRange(self->_dataSendedLength, willSendLength)];
        self->_dataSendTryNumber = 1;
        [self sendDataToRemote:sendingPacket];
        self->_dataSendedLength += willSendLength;
        
        self->_cuurentSendingCommandType = cmd_type;
        if (self->_dataReceiveTimer)
            [self->_dataReceiveTimer invalidate];
        self->_dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
        
        return TRUE;
    }
    else
        return FALSE;
}


/*******************************内部函数*********************************/

-(Boolean) sendDataToRemote:(NSData *) data
{
#ifdef NSLOG_DEBUG
    NSLog(@"sendDataToRemote:%@", data);
#ifdef PRINT_LOG
    [printLog printLogToFile:[[NSString alloc] initWithFormat:@"sendDataToRemote:%@\n", data]];
#endif
#endif
    
    [self->_peerPeripheral writeValue:data forCharacteristic:self->dataCharacteristicWrite type:CBCharacteristicWriteWithResponse];
    return TRUE;
}

/*
 *  @method didServiceDiscoveryResult
 *
 *  @param  success 服务搜索结果
 *
 *  @discussion
 *      服务搜索完成后的结果报告
 */
-(void) didServiceDiscoveryResult:(Boolean)success
{
    if (self->_delegate && !self->bSendedDidServiceDiscoverResultEvent)
    {
        self->bSendedDidServiceDiscoverResultEvent = TRUE;
        [self->_delegate peripheralDeviceManager:self didServiceDiscoverResult:success];
    }
}


/****************************peripheral回调函数*********************************/
/*
 *  @method didDiscoverServices
 *
 *  @param peripheral Pheripheral that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverServices is called when CoreBluetooth has discovered services on a
 *  peripheral after the discoverServices routine has been called on the peripheral
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (peripheral != self->_peerPeripheral)
        return;
    if (self->_serviceDiscoveryTimer)
    {
        [self->_serviceDiscoveryTimer invalidate];
        self->_serviceDiscoveryTimer = nil;
    }
    if (!error)
    {
        //服务搜索成功
        if (peripheral.services.count > 0)
        {
            
            for (NSUInteger i = 0; i < peripheral.services.count; i++)
            {
                
                CBService *service = [peripheral.services objectAtIndex:i];
                if (self->_isbattery)
                {
                    if([service.UUID.UUIDString isEqualToString:UUID_SERVICE_FOR_BATTERY])
                    {
                        self->dataService = service;
                        [self->_peerPeripheral discoverCharacteristics:nil forService:service];
                        self->_serviceDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_SERVICE_DISCOVERY_TIMEOUT target:self selector:@selector(serviceDiscoveryTimeoutTimer:) userInfo:nil repeats:NO];
                        return;
                    }
                   
                }else
                {
                    if([service.UUID.UUIDString isEqualToString:UUID_SERVICE_FOR_DATA])
                    {
                        self->dataService = service;
                        [self->_peerPeripheral discoverCharacteristics:nil forService:service];
                        
                        self->_serviceDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_SERVICE_DISCOVERY_TIMEOUT target:self selector:@selector(serviceDiscoveryTimeoutTimer:) userInfo:nil repeats:NO];
                        return;
                    }

                }
                
            }
        }
    }

    //服务搜索失败
    [self didServiceDiscoveryResult:FALSE];
}

/*
 *  @method didDiscoverCharacteristicsForService
 *
 *  @param peripheral Pheripheral that got updated
 *  @param service Service that characteristics where found on
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverCharacteristicsForService is called when CoreBluetooth has discovered
 *  characteristics on a service, on a peripheral after the discoverCharacteristics routine has been called on the service
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (peripheral != self->_peerPeripheral)
        return;
    if (self->_serviceDiscoveryTimer)
    {
        [self->_serviceDiscoveryTimer invalidate];
        self->_serviceDiscoveryTimer = nil;
    }
    
    if (! error)
    {
        if (self->_isbattery)
        {
            for (CBCharacteristic *characteristic in service.characteristics)
            {

                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                [self->_delegate peripheralDeviceManager:self GetBattery:characteristic.value];
            }
            [self didServiceDiscoveryResult:FALSE];
            return;
        }
        //服务特征值搜索成功
        if(service.characteristics.count > 0)
        {
            for (NSUInteger i = 0; i < service.characteristics.count; i++)
            {
                CBCharacteristic *characteristic = [service.characteristics objectAtIndex:i];
                if ([characteristic.UUID.UUIDString isEqualToString:UUID_CHARACTERISTIC_FOR_DATA_READ])
                    self->dataCharacteristicRead = characteristic;
                else if ([characteristic.UUID.UUIDString isEqualToString:UUID_CHARACTERISTIC_FOR_DATA_WRITE])
                    self->dataCharacteristicWrite = characteristic;
                if (characteristic.properties & CBCharacteristicPropertyNotify)
                {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                    if (self->_dataReceiveTimer)
                        [self->_dataReceiveTimer invalidate];
                    self->_dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
                }
            }
            if (self->dataCharacteristicRead && self->dataCharacteristicWrite)
                [self didServiceDiscoveryResult:TRUE];
            else
                //在找到新的特征值情况下，如果还没有获取到所有的特征值，我们继续等待一段时间
                self->_serviceDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_SERVICE_DISCOVERY_TIMEOUT target:self selector:@selector(serviceDiscoveryTimeoutTimer:) userInfo:nil repeats:NO];
            return;
        }
    }

    //服务特征值搜索失败
    [self didServiceDiscoveryResult:FALSE];
}

/*
 *  @method didUpdateNotificationStateForCharacteristic
 *
 *  @param peripheral Pheripheral that got updated
 *  @param characteristic Characteristic that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didUpdateNotificationStateForCharacteristic is called when CoreBluetooth has updated a
 *  notification state for a characteristic
 *
 */- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
}

/*
 *  @method didUpdateValueForCharacteristic
 *
 *  @param peripheral Pheripheral that got updated
 *  @param characteristic Characteristic that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didUpdateValueForCharacteristic is called when CoreBluetooth has updated a
 *  characteristic for a peripheral. All reads and notifications come here to be processed.
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#ifdef NSLOG_DEBUG
    NSLog(@"didUpdateValueForCharacteristic: %@ : error:%@", characteristic, error);
#ifdef PRINT_LOG
    [printLog printLogToFile:[[NSString alloc] initWithFormat:@"didUpdateValueForCharacteristic: %@ : error:%@\n", characteristic, error]];
#endif
#endif
    if (! error)
    {
        /* 重新初始化接收数据定时器 */
        if (self->_dataReceiveTimer)
            [self->_dataReceiveTimer invalidate];
        self->_dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
        
        if ([characteristic.UUID.UUIDString isEqualToString:UUID_CHARACTERISTIC_FOR_DATA_READ])
        {
            if (self->_communicationEncryptKey == nil)
            {
                [self getCommunicationEncryptKey:characteristic.value];
            }
            else
            {
                [self parseReceivedRemoteDeviceData:characteristic.value];
            }
        }
    }
}

/*!
 *  @method peripheral:didWriteValueForCharacteristic:error:
 *
 *  @discussion Invoked upon completion of a -[writeValue:forCharacteristic:] request.
 *      If unsuccessful, "error" is set with the encountered failure.
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#ifdef NSLOG_DEBUG
    NSLog(@"didWriteValueForCharacteristic %@ : error: %@", characteristic, error);
#ifdef PRINT_LOG
    [printLog printLogToFile:[[NSString alloc] initWithFormat:@"didWriteValueForCharacteristic %@ : error: %@\n", characteristic, error]];
#endif
#endif
    
    if (!error)
    {
        if (self->_dataSendRemote)
        {
            if (self->_dataReceiveTimer)
            {
                [self->_dataReceiveTimer invalidate];
                self->_dataReceiveTimer = nil;
            }
            if (self->_dataSendedLength < self->_dataSendRemote.length)
            {
                NSUInteger willSendLength;
                
                willSendLength = (self->_dataSendRemote.length-self->_dataSendedLength >= MAX_LENGTH_FOR_EACH_PACKET) ? MAX_LENGTH_FOR_EACH_PACKET : (self->_dataSendRemote.length-self->_dataSendedLength);
            
                NSData *sendingPacket = [self->_dataSendRemote subdataWithRange:NSMakeRange(self->_dataSendedLength, willSendLength)];
                [self sendDataToRemote:sendingPacket];
                self->_dataSendedLength += willSendLength;
            }
            self->_dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
        }
        else if(self->_dataReceiveTimer)
        {
            /* 系统变量异常，立刻终止接收数据定时器，终止操作*/
            [self->_dataReceiveTimer fire];
        }
    }
    else
    {
        if (self->_dataReceiveTimer)
        {
            /* 数据发送错误，立刻终止接收数据定时器，重新发送数据包或终止操作 */
            [self->_dataReceiveTimer fire];
        }
    }
}


/*******************************定时器回调函数*********************************/

/*
 *  @method serviceDiscoveryTimeoutTimer
 *
 *  @param  timer   定时器回调指针
 *
 *  @discussion
 *          连接周围设备定时器超时后，取消CentralManager继续连接操作
 */
-(void) serviceDiscoveryTimeoutTimer:(NSTimer *)timer
{
    self->_serviceDiscoveryTimer = nil;
    
    if (self->dataService
        && self->dataCharacteristicRead
        && self->dataCharacteristicWrite)
        [self didServiceDiscoveryResult:TRUE];
    else
        [self didServiceDiscoveryResult:FALSE];
}

/*
 *  @method dataReceiveTimeoutTimer
 *
 *  @param  timer   定时器回调指针
 *
 *  @discussion
 *          手机发送数据后，在设定的时间内没有收到远端设备发送的数据
 */
-(void) dataReceiveTimeoutTimer:(NSTimer *)timer
{
    self->_dataReceiveTimer = nil;
    
#ifdef NSLOG_DEBUG
    NSLog(@"dataReceiveTimeoutTimer: try (%lu)", (unsigned long)self->_dataSendTryNumber);
#ifdef PRINT_LOG
    [printLog printLogToFile:[[NSString alloc] initWithFormat:@"dataReceiveTimeoutTimer: try (%lu)\n", (unsigned long)self->_dataSendTryNumber]];
#endif
#endif
    
    if (self->_communicationEncryptKey == nil)
    {
        [self->_delegate peripheralDeviceManager:self didCommunicationEncryptKeyGetTimeout:YES];
    }
    else
    {
        if (self->_dataSendRemote && self->_dataSendTryNumber < DEFAULT_SEND_DATA_TRY_MAX_NUMBER)
        {
            NSUInteger willSendLength;
        
            self->_dataSendedLength = 0;
            willSendLength = (self->_dataSendRemote.length-self->_dataSendedLength > MAX_LENGTH_FOR_EACH_PACKET) ? MAX_LENGTH_FOR_EACH_PACKET : (self->_dataSendRemote.length-self->_dataSendedLength);
        
            NSData *sendingPacket = [self->_dataSendRemote subdataWithRange:NSMakeRange(self->_dataSendedLength, willSendLength)];
            self->_dataSendTryNumber ++;
            [self sendDataToRemote:sendingPacket];
            self->_dataSendedLength += willSendLength;
        
            self->_dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
            return;
        }
    
        [self->_delegate peripheralDeviceManager:self didDataSendResponse:libBleErrorCodeNoReponse cmd_type:self->_cuurentSendingCommandType param_data:nil];
        [self didPeripheralDeviceDataSendReset];
    }
}

@end
