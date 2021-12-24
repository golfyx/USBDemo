//
//  SCRegFormDataBaseOptHandle.m
//  USBDemo
//
//  Created by golfy on 2021/12/23.
//

#import "SCRegFormDataBaseOptHandle.h"
#import "WDLog.h"

@implementation SCRegFormDataBaseOptHandle

// 创建表
static NSString *const CREATE_REG_FORM_SQL =
@"create table if not exists regFormInfo ( \
dbId integer primary key autoincrement, \
name text, \
gender integer, \
age integer, \
height integer, \
weight integer, \
phone text, \
serial_number text, \
start_date text, \
end_date text, \
block_count integer, \
operating_time text, \
operating_type integer) \
";
/// 销毁表
static NSString *const DROP_REG_FORM_SQL = @"drop table if exists regFormInfo";
/// 清空表
static NSString *const DELETE_REG_FORM_SQL = @"delete from regFormInfo where 1";

/// 获取所有的记录
static NSString *const GET_REG_FORM_INFO_SQL = @"select * from regFormInfo order by dbId desc";
/// 获取指定phone对应的记录
static NSString *const SELECT_REG_FORM_ITEM_WITH_PHONE_SQL = @"select * from regFormInfo where phone = ?";
/// 获取指定日期对应的所有记录
static NSString *const SELECT_REG_FORM_ITEM_WITH_TIME_TYPE_SQL = @"select * from regFormInfo where operating_time = ? and  operating_type = ?";
/// 添加一条记录
static NSString *const INSERT_REG_FORM_ITEM_SQL = @"insert into regFormInfo(name,gender,age,height,weight,phone,serial_number,start_date,end_date,block_count,operating_time,operating_type) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

#pragma mark - 表操作公共方法(子类重写实现)
/**
 *  创建表
 */
- (void)createTable
{
    [self.dateBaseQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        BOOL result = [db executeUpdate:CREATE_REG_FORM_SQL withErrorAndBindings:&error];
        if (!result)
        {
            WDLog(LOG_MODUL_DATABASE,@"创建信息表失败:error = %@",[error localizedDescription]);
        }
    }];
}

/**
 *  销毁表
 */
- (void)dropTable
{
    [self.dateBaseQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        BOOL result = [db executeUpdate:DROP_REG_FORM_SQL withErrorAndBindings:&error];
        if (!result)
        {
            WDLog(LOG_MODUL_DATABASE,@"销毁信息表失败:error = %@",[error localizedDescription]);
        }
    }];
}

/**
 *  清空表
 */
- (void)clearTable
{
    [self.dateBaseQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        BOOL result = [db executeUpdate:DELETE_REG_FORM_SQL withErrorAndBindings:&error];
        if (!result)
        {
            WDLog(LOG_MODUL_DATABASE,@"清空信息表失败:error = %@",[error localizedDescription]);
        }
    }];
}

#pragma mark - public method
/**
 获取一条指定手机号的记录
 @param phone 手机号
 @return 一条记录信息
 */
- (SCRegFormSaveInfo *)acceptRegFormItemDataWithPhone:(NSString *)phone
{
    __block SCRegFormSaveInfo *info = nil;
    
    [self.dateBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        FMResultSet *rs = [db executeQuery:SELECT_REG_FORM_ITEM_WITH_PHONE_SQL, phone];
        if ([rs next])
        {
            info = [self getRegFormInfoFromrs:rs];
        }
        [rs close];
    }];
    
    return info;
}

/**
 获取指定日期的所有记录
 @param operating_time 操作时间
 @param operating_type 操作类型
 @return N条记录信息
 */
- (NSArray<SCRegFormSaveInfo *> *)acceptRegFormItemDataWithOperatingTime:(NSString *)operating_time operatingType:(int)operating_type
{
    __block NSMutableArray<SCRegFormSaveInfo *> *tmpInfoArray = @[].mutableCopy;
    __block SCRegFormSaveInfo *info = nil;
    
    [self.dateBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        FMResultSet *rs = [db executeQuery:SELECT_REG_FORM_ITEM_WITH_TIME_TYPE_SQL, operating_time, @(operating_type)];
        while ([rs next])
        {
            info = [self getRegFormInfoFromrs:rs];
            [tmpInfoArray addObject:info];
        }
        [rs close];
    }];
    
    return tmpInfoArray;
}

/**
 保存一条记录

 @param saveInfo info
 @return YES/NO
 */
- (BOOL)saveRegFormDataWithInfo:(SCRegFormSaveInfo *)saveInfo
{
    __block BOOL result = NO;
    
    [self.dateBaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        
        NSError *error = nil;
        result = [db executeUpdate:INSERT_REG_FORM_ITEM_SQL withErrorAndBindings:&error, saveInfo.name, @(saveInfo.gender), @(saveInfo.age), @(saveInfo.height), @(saveInfo.weight), saveInfo.phone, saveInfo.serial_number, saveInfo.start_date, saveInfo.end_date, @(saveInfo.block_count), saveInfo.operating_time, @(saveInfo.operating_type)];
        if (result)
        {
            FMResultSet *rs = [db executeQuery:GET_REG_FORM_INFO_SQL];
            if ([rs next])
            {
                saveInfo.dbId = [rs intForColumn:@"dbId"];
            }
            [rs close];
        }
        else
        {
            WDLog(LOG_MODUL_DATABASE, @"添加注册信息失败:error = %@",[error localizedDescription]);
        }
    }];
    
    return result;
}

#pragma mark - private method
- (SCRegFormSaveInfo *)getRegFormInfoFromrs:(FMResultSet *)rs
{
    if (rs == nil)
    {
        return nil;
    }
    SCRegFormSaveInfo *saveInfo = [[SCRegFormSaveInfo alloc] init];
    saveInfo.dbId = [rs intForColumn:@"dbId"];
    saveInfo.name = [rs stringForColumn:@"name"];
    saveInfo.gender = [rs intForColumn:@"gender"];
    saveInfo.age = [rs intForColumn:@"age"];
    saveInfo.height = [rs intForColumn:@"height"];
    saveInfo.weight = [rs intForColumn:@"weight"];
    saveInfo.phone = [rs stringForColumn:@"phone"];
    saveInfo.serial_number = [rs stringForColumn:@"serial_number"];
    saveInfo.start_date = [rs stringForColumn:@"start_date"];
    saveInfo.end_date = [rs stringForColumn:@"end_date"];
    saveInfo.block_count = [rs intForColumn:@"block_count"];
    saveInfo.operating_time = [rs stringForColumn:@"operating_time"];
    saveInfo.operating_type = [rs intForColumn:@"operating_type"];
    
    return saveInfo;
}

@end
