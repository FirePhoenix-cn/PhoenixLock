//
//  KeyType.m
//  phoenixLock
//
//  Created by jinou on 16/6/16.
//  Copyright © 2016年 jinou. All rights reserved.
//

#import "KeyType.h"


@interface KeyType()<UITextFieldDelegate,HZQDatePickerViewDelegate>
{
    HZQDatePickerView *_pikerView;
}
@end

@implementation KeyType
-(void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.borderWidth = 1.0f;
    self.keytype = 1;
    self.effectimes.delegate = self;
    self.start_time.delegate = self;
    self.end_times.delegate = self;
    self.start_time.enabled = NO;
    self.end_times.enabled = NO;
    self.effectimes.enabled = NO;
}


- (IBAction)comfirm:(UIButton *)sender
{
    [self.delegate confirm];
}

- (IBAction)cancel:(UIButton *)sender {
    [self.delegate cancel];
}

- (IBAction)tapseg:(UISegmentedControl *)sender
{
    self.keytype = sender.selectedSegmentIndex + 1;
    switch (sender.selectedSegmentIndex) {
        case 0:
        {
            self.start_time.enabled = NO;
            self.end_times.enabled = NO;
            self.effectimes.enabled = NO;
        }
            break;
            
            
        case 1:
        {
            self.start_time.enabled = YES;
            self.end_times.enabled = YES;
            self.effectimes.enabled = NO;
        }
            break;
            
        case 2:
        {
            self.start_time.enabled = NO;
            self.end_times.enabled = NO;
            self.effectimes.enabled = YES;
        }
            break;
            
        case 3:
        {
            self.start_time.enabled = YES;
            self.end_times.enabled = YES;
            self.effectimes.enabled = YES;
        }
            break;
        default:
            break;
    }
}

- (void)setupDateViewdatetype:(DateType)type
{
    
    _pikerView = [HZQDatePickerView instanceDatePickerView];
    _pikerView.frame = CGRectMake(0, 0, ScreenRectWidth, ScreenRectHeight + 20);
    [_pikerView setBackgroundColor:[UIColor clearColor]];
    _pikerView.delegate = self;
    _pikerView.type = type;
    [_pikerView.datePickerView setMinimumDate:[NSDate date]];
    [self.superview.superview.superview addSubview:_pikerView];
    [self.superview.superview.superview bringSubviewToFront:_pikerView];
}

- (void)getSelectDate:(NSString *)date :(NSDate *)pickdate type:(DateType)type
{
    switch (type)
    {
        case DateTypeOfStart:
            self.start_time.text = date;
            [self.delegate onGetDate:[self timeFormat:pickdate] type:type];
            
            break;
            
        case DateTypeOfEnd:
            self.end_times.text = date;
            [self.delegate onGetDate:[self timeFormat:pickdate] type:type];
            
            break;
            
        default:
            break;
    }
}

- (NSString *)timeFormat:(NSDate*)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *currentOlderOneDateStr = [dateFormatter stringFromDate:date];
    return currentOlderOneDateStr;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.tag == 10) {
        [self setupDateViewdatetype:0];
        [textField resignFirstResponder];
        return;
    }
    if (textField.tag == 20) {
        [self setupDateViewdatetype:1];
        [textField resignFirstResponder];
        return;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSString *fixregex = @"[0-9]{1,6}";
    NSPredicate *fixpred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",fixregex];
    if ([fixpred evaluateWithObject:textField.text])
    {
        return YES;
    }
    textField.text = @"";
    return YES;
}
@end
