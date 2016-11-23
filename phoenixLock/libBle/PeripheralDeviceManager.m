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
    
        if (self.dataReceiveTimer)
        {
            [self.dataReceiveTimer invalidate];
            self.dataReceiveTimer = nil;
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
        
        self.communicationEncryptKey = [[NSData alloc] initWithBytes:byte_communication_encrypt_key length:COMMUNICATION_KEY_LENGTH];
#ifdef NSLOG_DEBUG
        NSLog(@"_communicationEncryptKey:%@", self.communicationEncryptKey);
#ifdef PRINT_LOG
        [printLog printLogToFile:[[NSString alloc] initWithFormat:@"_communicationEncryptKey:%@", self.communicationEncryptKey]];
#endif
#endif
    }
}

-(void) parseReceivedRemoteDeviceData:(NSData *)received_data
{
    NSUInteger received_data_length;
    
    if (self.dataReceiveRemote == nil)
        self.dataReceiveRemote = [[NSMutableData alloc] initWithData:received_data];
    
    else
        [self.dataReceiveRemote appendData:received_data];
    
    received_data_length = [self remoteDataPacketLength:self.dataReceiveRemote encrypt_key:self.communicationEncryptKey]+1;
    if (self.dataReceiveRemote.length > received_data_length || received_data_length > MAX_LENGTH_FOR_EACH_PACKET *2)
        self.dataReceiveRemote = nil;
    else if(self.dataReceiveRemote.length == received_data_length)
    {
        [self encryptAndDecryptData:self.dataReceiveRemote encrypt_key:self.communicationEncryptKey];
        Byte *byte_decrypt_packet = (Byte *)[self.dataReceiveRemote bytes];
        bool response_finish = TRUE;
        
        switch (byte_decrypt_packet[1]) {
            case COMMAND_TYPE_CODE_BIND_MANAGER_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdBindManager param_data:((received_data_length > 3) ? [self.dataReceiveRemote subdataWithRange:NSMakeRange(3, received_data_length-3)]: nil)];
                break;
                
            case COMMAND_TYPE_CODE_ADD_MANAGER_OPEN_LOCK_UUID_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdAddManagerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_SEND_MANAGER_COMMUNICATE_UUID_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdSendManagerCommunicateUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_SEND_MANAGER_OPEN_LOCK_UUID_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdSendManagerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_CLEAR_MANAGER_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdClearManager param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_ADD_SHARER_OPEN_LOCK_UUID_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdAddSharerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_DELETE_SHARER_OPEN_LOCK_UUID_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdDeleteSharerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_EMPTY_SHARER_OPEN_LOCK_UUID_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdEmptySharerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_SEND_SHARER_COMMUNICATE_UUID_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdSendSharerCommunicateUUID param_data:nil];                break;
                
            case COMMAND_TYPE_CODE_SEND_SHARER_OPEN_LOCK_UUID_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdSendSharerOpenLockUUID param_data:nil];
                break;
                
            case COMMAND_TYPE_CODE_READ_LOCK_LOG_RSP:
                NSLog(@"lock_log:%@", self.dataReceiveRemote);
                if (byte_decrypt_packet[3] == 0x00)
                {
                    [self.delegate peripheralDeviceManager:self OpenLockLogDataInd:self.lockLogData record_count:((self.lockLogData != nil) ? [self.lockLogData count] : 0)];
                    [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdReadLockLog param_data:nil];
                }
                else
                {
                    if (received_data_length >= 8)
                    {
                        if (self.lockLogData == nil)
                            self.lockLogData = [[NSMutableArray alloc] initWithCapacity:1];
                        
                        NSDictionary *dictionaryLockRecord = [[NSDictionary alloc] initWithObjectsAndKeys:((received_data_length > 8) ? [DataTypeConversion NSDataConversionToNSString:[self.dataReceiveRemote subdataWithRange:NSMakeRange(8, received_data_length-8)]] : @""), @"lockAccount", [DataTypeConversion NSDataConversionToNSString:[self.dataReceiveRemote subdataWithRange:NSMakeRange(4, 4)]], @"lockTime", nil];
                        [self.lockLogData addObject:dictionaryLockRecord];
                    
                        if ([self.lockLogData count] % 10 == 0)
                            [self.delegate peripheralDeviceManager:self OpenLockLogDataInd:nil record_count:[self.lockLogData count]];
                    }
                    response_finish = FALSE;
                    [self didperipheralDeviceReceiveLockLogRecordReset];
                }
                    
                break;
                
            case COMMAND_TYPE_CODE_EMPTY_LOCK_LOG_RSP:
                [self.delegate peripheralDeviceManager:self didDataSendResponse:byte_decrypt_packet[2] cmd_type:libBleCmdEmptyLockLog param_data:nil];
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
        self.delegate = delegate;
        self.peerPeripheral = peripheral;
        self.peerPeripheral.delegate = self;
        self.advertisementData = nil;
        self.macAddr = nil;
        self.RSSI = nil;
        
        self->dataService = nil;
        self->dataCharacteristicRead = nil;
        self->dataCharacteristicWrite = nil;
        self->bSendedDidServiceDiscoverResultEvent = FALSE;        

        self.connTimer = nil;
        self.serviceDiscoveryTimer = nil;
        self.communicationEncryptKey = nil;
        self.cuurentSendingCommandType = libBleCmdNone;
        self.dataReceiveTimer = nil;
        self.isConnecting = FALSE;
        self.isConnected = FALSE;
        self.dataSendRemote = nil;
        self.dataSendedLength = 0;
        self.dataSendTryNumber = 0;
        self.dataReceiveRemote = nil;
        self.lockLogData = nil;
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
    
    if (self.connTimer)
    {
        [self.connTimer invalidate];
        self.connTimer = nil;
    }
    if (self.serviceDiscoveryTimer)
    {
        [self.serviceDiscoveryTimer invalidate];
        self.serviceDiscoveryTimer = nil;
    }
    self.communicationEncryptKey = nil;
    self.cuurentSendingCommandType = libBleCmdNone;
    if (self.dataReceiveTimer)
    {
        [self.dataReceiveTimer invalidate];
        self.dataReceiveTimer = nil;
    }
    self.isConnecting = FALSE;
    self.isConnected = FALSE;
    self.dataSendRemote = nil;
    self.dataSendedLength = 0;
    self.dataSendTryNumber = 0;
    self.dataReceiveRemote = nil;
    self.lockLogData = nil;
}

/*
 *  @method didPeripheralDeviceDataSendReset
 *
 *  @discussion
 *          接收到远端设备的数据应答并解析完成后，复位这些变量
 */
-(void) didPeripheralDeviceDataSendReset
{
    self.cuurentSendingCommandType = libBleCmdNone;
    self.dataSendRemote = nil;
    self.dataSendedLength = 0;
    self.dataSendTryNumber = 0;
    self.dataReceiveRemote = nil;
    self.lockLogData = nil;
    if (self.dataReceiveTimer) {
        [self.dataReceiveTimer invalidate];
        self.dataReceiveTimer = nil;
    }
}

-(void) didperipheralDeviceReceiveLockLogRecordReset
{
    self.dataSendRemote = nil;
    self.dataSendedLength = 0;
    self.dataSendTryNumber = 0;
    self.dataReceiveRemote = nil;
}

/*
 *  @method discoverPeripheralDeviceServices
 *
 *  @discussion
 *          搜索Ble设备中是否注册有指定的服务记录
 */
-(Boolean) discoverPeripheralDeviceServices
{
    if (self.peerPeripheral.state != CBPeripheralStateConnected)
        return FALSE;
    
    NSArray *uuidArray = [NSArray arrayWithObjects:[CBUUID UUIDWithString:UUID_SERVICE_FOR_DATA],[CBUUID UUIDWithString:UUID_SERVICE_FOR_BATTERY], nil];
    [self.peerPeripheral discoverServices:uuidArray];
    self.serviceDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_SERVICE_DISCOVERY_TIMEOUT target:self selector:@selector(serviceDiscoveryTimeoutTimer:) userInfo:nil repeats:NO];
    
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
    if (self.communicationEncryptKey) {
        Byte packetHead[2];
        NSUInteger willSendLength;
    
        packetHead[0] = [param_data length]+1;
        packetHead[1] = [self getPacketTypeForSendDataPacket:cmd_type];
    
        self.dataSendRemote = [[NSMutableData alloc] initWithBytes:packetHead length:sizeof(packetHead)];
        [self.dataSendRemote appendData:param_data];
        [self encryptAndDecryptData:self.dataSendRemote encrypt_key:self.communicationEncryptKey];
#ifdef NSLOG_DEBUG
        NSLog(@"dataSendToPeripheraDevice:%@", self.dataSendRemote);
#ifdef PRINT_LOG
        [printLog printLogToFile:[[NSString alloc] initWithFormat:@"dataSendToPeripheraDevice:%@\n", self.dataSendRemote]];
#endif
#endif
        
        self.dataSendedLength = 0;
        willSendLength = (self.dataSendRemote.length-self.dataSendedLength >= MAX_LENGTH_FOR_EACH_PACKET) ? MAX_LENGTH_FOR_EACH_PACKET : (self.dataSendRemote.length-self.dataSendedLength);
        
        NSData *sendingPacket = [self.dataSendRemote subdataWithRange:NSMakeRange(self.dataSendedLength, willSendLength)];
        self.dataSendTryNumber = 1;
        [self sendDataToRemote:sendingPacket];
        self.dataSendedLength += willSendLength;
        
        self.cuurentSendingCommandType = cmd_type;
        if (self.dataReceiveTimer)
            [self.dataReceiveTimer invalidate];
        self.dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
        
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
    if (data == nil)
    {
        return TRUE;
    }
    [self.peerPeripheral writeValue:data forCharacteristic:self->dataCharacteristicWrite type:CBCharacteristicWriteWithResponse];
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
    if (self.delegate && !self->bSendedDidServiceDiscoverResultEvent)
    {
        self->bSendedDidServiceDiscoverResultEvent = TRUE;
        [self.delegate peripheralDeviceManager:self didServiceDiscoverResult:success];
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
    if (peripheral != self.peerPeripheral)
        return;
    if (self.serviceDiscoveryTimer)
    {
        [self.serviceDiscoveryTimer invalidate];
        self.serviceDiscoveryTimer = nil;
    }
    if (!error)
    {
        //服务搜索成功
        if (peripheral.services.count > 0)
        {
            
            for (NSUInteger i = 0; i < peripheral.services.count; i++)
            {
                
                CBService *service = [peripheral.services objectAtIndex:i];
                
                if([service.UUID.UUIDString isEqualToString:UUID_SERVICE_FOR_BATTERY])
                {
                    
                    [self.peerPeripheral discoverCharacteristics:nil forService:service];
                    //self.serviceDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_SERVICE_DISCOVERY_TIMEOUT target:self selector:@selector(serviceDiscoveryTimeoutTimer:) userInfo:nil repeats:NO];
                }
                
                if([service.UUID.UUIDString isEqualToString:UUID_SERVICE_FOR_DATA])
                {
                    self->dataService = service;
                    [self.peerPeripheral discoverCharacteristics:nil forService:service];
                    self.serviceDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_SERVICE_DISCOVERY_TIMEOUT target:self selector:@selector(serviceDiscoveryTimeoutTimer:) userInfo:nil repeats:NO];
                }
                
            }
        }
        return;
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
    if (peripheral != self.peerPeripheral)
        return;
    if (self.serviceDiscoveryTimer)
    {
        [self.serviceDiscoveryTimer invalidate];
        self.serviceDiscoveryTimer = nil;
    }
    
    if (! error)
    {
        //服务特征值搜索成功
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID.UUIDString isEqualToString:UUID_CHARACTERISTIC_FOR_BATTERY])
            {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                [self.delegate peripheralDeviceManager:self GetBattery:characteristic.value];
                return;
            }
            
            if ([characteristic.UUID.UUIDString isEqualToString:UUID_CHARACTERISTIC_FOR_DATA_READ])
                self->dataCharacteristicRead = characteristic;
            else if ([characteristic.UUID.UUIDString isEqualToString:UUID_CHARACTERISTIC_FOR_DATA_WRITE])
                self->dataCharacteristicWrite = characteristic;
            
            if (characteristic.properties & CBCharacteristicPropertyNotify)
            {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                if (self.dataReceiveTimer)
                    [self.dataReceiveTimer invalidate];
                self.dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
            }
            
        }
        if (self->dataCharacteristicRead && self->dataCharacteristicWrite)
            [self didServiceDiscoveryResult:TRUE];
        else
            //在找到新的特征值情况下，如果还没有获取到所有的特征值，我们继续等待一段时间
            self.serviceDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_SERVICE_DISCOVERY_TIMEOUT target:self selector:@selector(serviceDiscoveryTimeoutTimer:) userInfo:nil repeats:NO];
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
        if (self.dataReceiveTimer)
            [self.dataReceiveTimer invalidate];
        self.dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
        
        if ([characteristic.UUID.UUIDString isEqualToString:UUID_CHARACTERISTIC_FOR_DATA_READ])
        {
            if (self.communicationEncryptKey == nil)
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
        if (self.dataSendRemote)
        {
            if (self.dataReceiveTimer)
            {
                [self.dataReceiveTimer invalidate];
                self.dataReceiveTimer = nil;
            }
            if (self.dataSendedLength < self.dataSendRemote.length)
            {
                NSUInteger willSendLength;
                
                willSendLength = (self.dataSendRemote.length-self.dataSendedLength >= MAX_LENGTH_FOR_EACH_PACKET) ? MAX_LENGTH_FOR_EACH_PACKET : (self.dataSendRemote.length-self.dataSendedLength);
            
                NSData *sendingPacket = [self.dataSendRemote subdataWithRange:NSMakeRange(self.dataSendedLength, willSendLength)];
                [self sendDataToRemote:sendingPacket];
                self.dataSendedLength += willSendLength;
            }
            self.dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
        }
        else if(self.dataReceiveTimer)
        {
            /* 系统变量异常，立刻终止接收数据定时器，终止操作*/
            [self.dataReceiveTimer fire];
        }
    }
    else
    {
        if (self.dataReceiveTimer)
        {
            /* 数据发送错误，立刻终止接收数据定时器，重新发送数据包或终止操作 */
            [self.dataReceiveTimer fire];
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
    self.serviceDiscoveryTimer = nil;
    
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
    self.dataReceiveTimer = nil;
    
#ifdef NSLOG_DEBUG
    NSLog(@"dataReceiveTimeoutTimer: try (%lu)", (unsigned long)self.dataSendTryNumber);
#ifdef PRINT_LOG
    [printLog printLogToFile:[[NSString alloc] initWithFormat:@"dataReceiveTimeoutTimer: try (%lu)\n", (unsigned long)self.dataSendTryNumber]];
#endif
#endif
    
    if (self.communicationEncryptKey == nil)
    {
        [self.delegate peripheralDeviceManager:self didCommunicationEncryptKeyGetTimeout:YES];
    }
    else
    {
        if (self.dataSendRemote && self.dataSendTryNumber < DEFAULT_SEND_DATA_TRY_MAX_NUMBER)
        {
            NSUInteger willSendLength;
        
            self.dataSendedLength = 0;
            willSendLength = (self.dataSendRemote.length-self.dataSendedLength > MAX_LENGTH_FOR_EACH_PACKET) ? MAX_LENGTH_FOR_EACH_PACKET : (self.dataSendRemote.length-self.dataSendedLength);
        
            NSData *sendingPacket = [self.dataSendRemote subdataWithRange:NSMakeRange(self.dataSendedLength, willSendLength)];
            self.dataSendTryNumber ++;
            [self sendDataToRemote:sendingPacket];
            self.dataSendedLength += willSendLength;
        
            self.dataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_REMOTE_DATA_RECEIVE_TIMEOUT target:self selector:@selector(dataReceiveTimeoutTimer:) userInfo:nil repeats:NO];
            return;
        }
    
        [self.delegate peripheralDeviceManager:self didDataSendResponse:libBleErrorCodeNoReponse cmd_type:self.cuurentSendingCommandType param_data:nil];
        [self didPeripheralDeviceDataSendReset];
    }
}

@end
