//
//  TableViewCell.m
//  phoenixLock
//
//  Created by jinou on 16/10/18.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.userdefaults = [NSUserDefaults standardUserDefaults];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
}
-(NSData *) NSStringConversionToNSData:(NSString*)string
{
    if (string == nil)
        return nil;
    const char *ch = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *data = [NSMutableData data];
    while (*ch) {
        char byte = 0;
        if ('0' <= *ch && *ch <= '9')
            byte = *ch - '0';
        else if ('a' <= *ch && *ch <= 'f')
            byte = *ch - 'a' + 10;
        else if ('A' <= *ch && *ch <= 'F')
            byte = *ch - 'A' + 10;
        else
            return nil;
        ch++;
        byte = byte << 4;
        if (*ch) {
            if ('0' <= *ch && *ch <= '9')
                byte += *ch - '0';
            else if ('a' <= *ch && *ch <= 'f')
                byte += *ch - 'a' + 10;
            else if ('A' <= *ch && *ch <= 'F')
                byte += *ch - 'A' + 10;
            else
                return nil;
            ch++;
        }
        [data appendBytes:&byte length:1];
    }
    return data;
}
-(void)didGetBattery:(NSInteger)battery forMac:(NSData*)mac{}

-(void) didDiscoverResult:(NSData *)macAddr deviceName:(NSData *)deviceName rssi:(NSNumber *)rssi{}

-(void) didDiscoverComplete{}

-(void) didConnectConfirm:(NSData *)macAddr status:(Boolean)status{}

-(void) didDisconnectIndication:(NSData *)macAddr{}

-(void) didDataSendResponse:(NSData *)macAddr cmd_type:(libCommandType)cmd_type result:(libBleErrorCode)result param_data:(NSData *)param_data{}

-(void) didOpenLockLogDataInd:(NSData *)macAddr record_count:(NSUInteger)record_count log_data:(NSMutableArray *)log_data{}

-(void)updateLockMsg:(NSString*)devuserid withupdate:(void(^)(SmartLock *device))update
{
    NSManagedObjectContext *context = self.appDelegate.privateContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCKS];
    if (devuserid.length == 20)
    {
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"globalcode=%@",devuserid];
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"ismaster=1"];
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
        [request setPredicate:predicate];
    }else
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"devuserid=%@",devuserid];
        [request setPredicate:predicate];
    }
    __weak __block SmartLock *lock;
    [context performBlockAndWait:^{
        __strong typeof(lock) strongLock = lock;
        strongLock = [[context executeFetchRequest:request error:nil] lastObject];
        if (strongLock)
        {
            update(strongLock);
            [context save:nil];
            [context.parentContext performBlock:^{
                [context.parentContext save:nil];
            }];
        }
    }];
}
@end
