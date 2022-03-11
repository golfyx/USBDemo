//
//  SCMultiDeviceInfo.m
//  USBDemo
//
//  Created by golfy on 2021/11/22.
//

#import "SCMultiDeviceInfo.h"

static const int responsePageDataLen = 4194304; ///4M 的长度
static const int responsePageIntervalDataLen = 11; ///11 的长度

@implementation SCMultiDeviceInfo

- (instancetype)init
{
    if (self = [super init])
    {
        _allBlockInfo = [[SCDeviceAllBlockInfo alloc] init];
        _curBlockIndex = 0;
        
        _responsePageDataArray = [[NSMutableArray alloc] init];
        // 开辟一个4M 大小的内存空间
        for (int i = 0; i < responsePageDataLen; i++) {
            NSMutableArray *responsePageIntervalDataArray = [[NSMutableArray alloc] init];
            for (int j = 0; j < responsePageIntervalDataLen; j++) {
                [responsePageIntervalDataArray addObject:@0];
            }
            [_responsePageDataArray addObject:responsePageIntervalDataArray];
        }
        _rawDataHexadecimalStr = [NSMutableString string];
        _curUploadBlockIndex = 1;
        
        _filePathDataDecimalismArray = [NSMutableArray array];
        _filePathDataHexadecimalArray = [NSMutableArray array];
        _filePathBaiHuiDataHexadecimalArray = [NSMutableArray array];
    }
    return self;
}

/// 初始化file数组
- (void)clearFileCache {
    _filePathDataDecimalismArray = [NSMutableArray array];
    _filePathDataHexadecimalArray = [NSMutableArray array];
}

@end
