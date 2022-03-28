//
//  EncipherHandler.m
//  USBDemo
//
//  Created by golfy on 2022/2/21.
//

#import "EncipherHandler.h"
#import "AES_Encipher.h"

#define  ENCIPHER_KEY_VALUE0                'B'
#define  ENCIPHER_KEY_VALUE1                'U'
#define  ENCIPHER_KEY_VALUE2                'L'
#define  ENCIPHER_KEY_VALUE3                'K'
#define  ENCIPHER_KEY_VALUE4                '_'
#define  ENCIPHER_KEY_VALUE5                'B'
#define  ENCIPHER_KEY_VALUE6                'L'
#define  ENCIPHER_KEY_VALUE7                'E'
#define  ENCIPHER_KEY_VALUE8                '_'
#define  ENCIPHER_KEY_VALUE9                'E'
#define  ENCIPHER_KEY_VALUE10               'C'
#define  ENCIPHER_KEY_VALUE11               'H'
#define  ENCIPHER_KEY_VALUE12               'O'
#define  ENCIPHER_KEY_VALUE13               '_'
#define  ENCIPHER_KEY_VALUE14               'E'
#define  ENCIPHER_KEY_VALUE15               'N'
//---------------------------------------------------


unsigned char CheckCnt = ENCIPHER_CHECK_CNT;

unsigned char CommunicateEncipherKey[EVERY_ENCIPHER_CNT_BYTE];
unsigned char InteractiveBuffer[COMMUNICATE_INTERACTIVE_BUF_LEN];
unsigned char FixSerialNumBuf[EVERY_ENCIPHER_CNT_BYTE];

unsigned char DefaultEncipherKey[EVERY_ENCIPHER_CNT_BYTE] =
{
   ENCIPHER_KEY_VALUE0,ENCIPHER_KEY_VALUE1,ENCIPHER_KEY_VALUE2,ENCIPHER_KEY_VALUE3,
   ENCIPHER_KEY_VALUE4,ENCIPHER_KEY_VALUE5,ENCIPHER_KEY_VALUE6,ENCIPHER_KEY_VALUE7,
   ENCIPHER_KEY_VALUE8,ENCIPHER_KEY_VALUE9,ENCIPHER_KEY_VALUE10,ENCIPHER_KEY_VALUE11,
   ENCIPHER_KEY_VALUE12,ENCIPHER_KEY_VALUE13,ENCIPHER_KEY_VALUE14,ENCIPHER_KEY_VALUE15,
};


#define FIX_SERIAL_BIT_CNT               96
#define SINGLE_SERIAL_BIT_CNT            32
#define FIX_SERIAL_ADDR_HIGH             (0x1FFF7A10)
#define FIX_SERIAL_ADDR_MID              (0x1FFF7A14)
#define FIX_SERIAL_ADDR_LOW              (0x1FFF7A18)
#define FIX_SERIAL_ADDR_CHECK_VAL        (FIX_SERIAL_ADDR_HIGH + FIX_SERIAL_ADDR_MID + FIX_SERIAL_ADDR_LOW)

@implementation EncipherHandler

- (unsigned char)checkCnt {
    return CheckCnt;
}
- (unsigned char *)communicateEncipherKey {
    return CommunicateEncipherKey;
}
- (unsigned char *)interactiveBuffer {
    return InteractiveBuffer;
}
- (unsigned char *)fixSerialNumBuf {
    return FixSerialNumBuf;
}
- (unsigned char *)defaultEncipherKey {
    return DefaultEncipherKey;
}

void UseDefaultCommunicateEncipherKey(void)
{
   int i;
   for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
   {
      CommunicateEncipherKey[i] = DefaultEncipherKey[i];
   }
}
//
//
void SetCommunicateEncipherKey(unsigned char *keyTab)
{
    int i;
    for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
    {
        CommunicateEncipherKey[i] = keyTab[i];
    }
}
//
//
void SetRandomCommunicateEncipherKey(void)
{
    int i;
    unsigned char temp;
//-------------------------------------------------
    srand((unsigned)time(NULL));
    for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
    {
        temp = (unsigned char)(rand());
        CommunicateEncipherKey[i] = temp;
//        keyTab[i] = temp;
    }
//--------------------------------------------------
}
//
//
void GetEncipherSerialNumAddr(void)
{
//----------------------------------------------------------------
   SetRandomCommunicateEncipherKey();                // set key
   GetEncryptionAesKeyTable(CommunicateEncipherKey);        // Get aes key
   
//   bufData = new unsigned char[EVERY_ENCIPHER_CNT_BYTE];    // get clear code
    unsigned char bufData[EVERY_ENCIPHER_CNT_BYTE] = {0x00};

   GetSingleUint32_tData(FIX_SERIAL_ADDR_HIGH, &bufData[0]);
   GetSingleUint32_tData(FIX_SERIAL_ADDR_MID, &bufData[4]);
   GetSingleUint32_tData(FIX_SERIAL_ADDR_LOW, &bufData[8]);
   GetSingleUint32_tData(FIX_SERIAL_ADDR_CHECK_VAL, &bufData[12]);

   AesEncipher(bufData, EVERY_ENCIPHER_CNT_BYTE);
//------------------------------------------------------------------
   int i;
   int index;
   index = 0;
   for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
   {
      InteractiveBuffer[index++] = ByteToAscii(CommunicateEncipherKey[i] / 16);
      InteractiveBuffer[index++] = ByteToAscii(CommunicateEncipherKey[i] % 16);
   }
   for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
   {
      InteractiveBuffer[index++] = ByteToAscii(bufData[i] / 16);
      InteractiveBuffer[index++] = ByteToAscii(bufData[i] % 16);
   }
//-------------------------------------------------------------------
//   delete[] bufData;
}
//
//
void CheckBulkSerialNumValidtyCmd(void)
{
//   unsigned char *bufData;
   int i;
   //----------------------------------------------------------------
   SetRandomCommunicateEncipherKey();                // set key
   GetEncryptionAesKeyTable(CommunicateEncipherKey);        // Get aes key

//   bufData = new unsigned char[EVERY_ENCIPHER_CNT_BYTE];    // get clear code
    unsigned char bufData[EVERY_ENCIPHER_CNT_BYTE] = {0x00};
    
   for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
   {
       bufData[i] = FixSerialNumBuf[i];
   }
   AesEncipher(bufData, EVERY_ENCIPHER_CNT_BYTE);
   //------------------------------------------------------------------
   int index;
   index = 0;
   for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
   {
      InteractiveBuffer[index++] = ByteToAscii(CommunicateEncipherKey[i] / 16);
      InteractiveBuffer[index++] = ByteToAscii(CommunicateEncipherKey[i] % 16);
   }
   for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
   {
      InteractiveBuffer[index++] = ByteToAscii(bufData[i] / 16);
      InteractiveBuffer[index++] = ByteToAscii(bufData[i] % 16);
   }
   //-------------------------------------------------------------------
//   delete[] bufData;
}
//
//
void GetSingleUint32_tData(uint32_t keyValue, uint8_t *keyTab)
{
   keyTab[0] = (uint8_t)((keyValue >> 24) & 0xFF);
   keyTab[1] = (uint8_t)((keyValue >> 16) & 0xFF);
   keyTab[2] = (uint8_t)((keyValue >> 8) & 0xFF);
   keyTab[3] = (uint8_t)(keyValue & 0xFF);
}

void GetFixSerialNumBuffer(unsigned char *buffer)
{
   int i;
   int index;
   unsigned char temp;
//   unsigned char *cipherTextBuf;
//---------------------------------------------
//   cipherTextBuf = new unsigned char[EVERY_ENCIPHER_CNT_BYTE];
    unsigned char cipherTextBuf[EVERY_ENCIPHER_CNT_BYTE] = {0x00};
   index = 0;
   for (i = 0; i <EVERY_ENCIPHER_CNT_BYTE; i++)
   {
       temp = AsciiToByte(buffer[index++]);
       temp = temp *16 + AsciiToByte(buffer[index++]);
       cipherTextBuf[i] = temp;
   }
//---------------------------------------------
   UseDefaultCommunicateEncipherKey();
   GetDecryptionAesKeyTable(CommunicateEncipherKey);        // Get aes key
   AesDecipher(cipherTextBuf, EVERY_ENCIPHER_CNT_BYTE);

   for (i = 0; i < EVERY_ENCIPHER_CNT_BYTE; i++)
   {
       FixSerialNumBuf[i] = cipherTextBuf[i];
   }
//   delete[] cipherTextBuf;
}
//
//
unsigned char ByteToAscii(unsigned char changedata)
{
   if (changedata<10)
      changedata = changedata + '0';
   else if (changedata >= 10 && changedata<16)
      changedata = changedata + 'A' - 10;
   else
      return 0xff;

   return  changedata;
}
//
//
unsigned char AsciiToByte(unsigned char changedata)
{
   if (changedata >= '0' && changedata <= '9')
      changedata = changedata - '0';
   else if (changedata >= 'a' && changedata <= 'z')
      changedata = changedata - 'a' + 10;
   else if (changedata >= 'A' && changedata <= 'Z')
      changedata = changedata - 'A' + 10;
   else
      changedata = 0xff;

   return changedata;
}

@end
