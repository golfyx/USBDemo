//
//  Crc32Check.h
//  USBDemo
//
//  Created by golfy on 2021/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Crc32Check : NSObject

void MakeCrc32Table(void);
unsigned int CalcCrc32(unsigned char *data, unsigned int size);
unsigned int CalcCrc32_buf(unsigned char *data, unsigned int size,unsigned int crcTmp);

@end

NS_ASSUME_NONNULL_END
