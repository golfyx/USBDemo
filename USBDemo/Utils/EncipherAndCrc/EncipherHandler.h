//
//  EncipherHandler.h
//  USBDemo
//
//  Created by golfy on 2022/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define ENCIPHER_CHECK_CNT                         10
//----------------------------------------------------
#define EVERY_ENCIPHER_CNT_BYTE                    16
#define COMMUNICATE_INTERACTIVE_BUF_LEN            (EVERY_ENCIPHER_CNT_BYTE * 4)

@interface EncipherHandler : NSObject

@property (nonatomic, assign) unsigned char checkCnt;
@property (nonatomic, assign) unsigned char *communicateEncipherKey;
@property (nonatomic, assign) unsigned char *interactiveBuffer;
@property (nonatomic, assign) unsigned char *fixSerialNumBuf;
@property (nonatomic, assign) unsigned char *defaultEncipherKey;

//------------------------------
void UseDefaultCommunicateEncipherKey(void);
void SetCommunicateEncipherKey(unsigned char *keyTab);
void SetRandomCommunicateEncipherKey(void);

void GetEncipherSerialNumAddr(void);           //32
void CheckBulkSerialNumValidtyCmd(void);

void GetFixSerialNumBuffer(unsigned char *buffer);
void GetSingleUint32_tData(uint32_t keyValue, uint8_t *keyTab);


unsigned char ByteToAscii(unsigned char changedata);
unsigned char AsciiToByte(unsigned char changedata);



@end

NS_ASSUME_NONNULL_END
