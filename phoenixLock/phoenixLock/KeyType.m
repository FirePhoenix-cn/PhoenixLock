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
    
    _keytype = 1;
    
    _effectimes.delegate = self;
    
    _start_time.delegate = self;
   
    _end_times.delegate = self;
    
    _start_time.enabled = NO;
    _end_times.enabled = NO;
    _effectimes.enabled = NO;
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
    _keytype = sender.selectedSegmentIndex + 1;
    switch (sender.selectedSegmentIndex) {
        case 0:
        {
            _start_time.enabled = NO;
            _end_times.enabled = NO;
            _effectimes.enabled = NO;
        }
            break;
            
            
        case 1:
        {
            _start_time.enabled = YES;
            _end_times.enabled = YES;
            _effectimes.enabled = NO;
        }
            break;
            
        case 2:
        {
            _start_time.enabled = NO;
            _end_times.enabled = NO;
            _effectimes.enabled = YES;
        }
            break;
            
        case 3:
        {
            _start_time.enabled = YES;
            _end_times.enabled = YES;
            _effectimes.enabled = YES;
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
            _start_time.text = date;
            [self.delegate onGetDate:[self timeFormat:pickdate] type:type];
            
            break;
            
        case DateTypeOfEnd:
            _end_times.text = date;
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
    }
    if (textField.tag == 20) {
        [self setupDateViewdatetype:1];
        [textField resignFirstResponder];
    }
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
@end
