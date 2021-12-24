//
//  SCRegFormSaveInfo.m
//  USBDemo
//
//  Created by golfy on 2021/12/23.
//

#import "SCRegFormSaveInfo.h"

@implementation SCRegFormSaveInfo

- (NSString *)description
{
    return [NSString stringWithFormat:@"dbId = %d, operating_time = %@, operating_type = %d, name = %@, gender = %d, age = %d, height = %d, weight = %d, phone = %@, serial_number = %@, start_date = %@, end_date = %@, block_count = %d, operating_time = %@, operating_type = %d", _dbId, _operating_time, _operating_type, _name, _gender, _age,_height, _weight, _phone, _serial_number, _start_date, _end_date, _block_count, _operating_time, _operating_type];
}

@end
