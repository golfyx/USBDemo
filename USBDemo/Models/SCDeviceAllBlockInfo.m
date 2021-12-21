//
//  SCDeviceAllBlockInfo.m
//  SAIAppUser
//
//  Created by He Kerous on 2019/12/31.
//  Copyright © 2019 golfy.xiong. All rights reserved.
//

#import "SCDeviceAllBlockInfo.h"

@implementation SCDeviceBlockInfo

+ (instancetype)infoWithBlockIndex:(UInt16)blockIndex start_timestamp:(long long)start_timestamp end_timestamp:(long long)end_timestamp saved_datalen:(int)saved_datalen startpageIndex:(int)startpageIndex endpageIndex:(int)endpageIndex
{
    return [[[self class] alloc] initWithBlockIndex:blockIndex start_timestamp:start_timestamp end_timestamp:end_timestamp saved_datalen:saved_datalen startpageIndex:startpageIndex endpageIndex:endpageIndex];
}

- (instancetype)initWithBlockIndex:(UInt16)blockIndex start_timestamp:(long long)start_timestamp end_timestamp:(long long)end_timestamp saved_datalen:(int)saved_datalen startpageIndex:(int)startpageIndex endpageIndex:(int)endpageIndex
{
    self = [super init];
    if (self)
    {
        _blockIndex = blockIndex;
        _start_timestamp = start_timestamp;
        _end_timestamp = end_timestamp;
        _saved_datalen = saved_datalen;
        _startpageIndex = startpageIndex;
        _endpageIndex = endpageIndex;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"blockIndex = %d, start_timestamp = %lld, saved_datalen = %d, startpageIndex = %d, endpageIndex = %d", _blockIndex, _start_timestamp, _saved_datalen, _startpageIndex, _endpageIndex];
}

@end

@implementation SCDeviceAllBlockInfo

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _allBlockInfoArray = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
