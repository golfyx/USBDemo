//
//  SCUserInfoModel.h
//  SAIAppUser
//
//  Created by golfy on 2019/4/8.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    GenderType_male = 1,
    GenderType_female = 0,
    GenderType_unknow = 1,
} GenderType;


@interface SCUserInfoModel : NSObject

@property (nonatomic, assign) int userID;
@property (nonatomic, assign) int memberID;
@property (nonatomic, copy) NSString *phoneNum;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) GenderType genderType;
@property (nonatomic, copy) NSString *birthday;
@property (nonatomic, copy) NSString *height;
@property (nonatomic, copy) NSString *weight;

@end

NS_ASSUME_NONNULL_END
