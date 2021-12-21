//
//  SCUserInfoModel.m
//  SAIAppUser
//
//  Created by golfy on 2019/4/8.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCUserInfoModel.h"

@implementation SCUserInfoModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _userID = 0;
        _phoneNum = @"0";
        _iconUrl = @"";
        _name = @"";
        _genderType = GenderType_male;
        _birthday = @"";
        _height = @"170";
        _weight = @"60";
    }
    return self;
}

@end
