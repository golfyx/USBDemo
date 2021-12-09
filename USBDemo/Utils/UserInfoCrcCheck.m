//
//  UserInfoCrcCheck.m
//  USBDemo
//
//  Created by golfy on 2021/11/24.
//

#import "UserInfoCrcCheck.h"

@implementation UserInfoCrcCheck


////////////////////////////////////////////////////////////////////
// Uses CRC-32 (Ethernet) polynomial: 0x4C11DB7
// X32 + X26 + X23 + X22 + X16 + X12 + X10 + X11 +X8 + X7 + X5 + X4 + X2+ X +1
// The reverse poly is 0xEDB88320
////////////////////////////////////////////////////////////////////
unsigned int Crc32Table[256];
#define     CRC32_MASK    ((unsigned long)0xFFFFFFFF)
//
//  make crc 32 table
//
void MakeCrc32Table(void)
{
   unsigned int i,j;
   unsigned int crc;
   for(i = 0; i < 256; i++)
   {
      crc = i<<24;
      for(j = 0; j < 8; j++)
      {
         if(crc & 0x80000000)
         {
            crc = (crc << 1) ^ 0x4C11DB7;
         }
         else
         {
            crc <<= 1;
         }
      }
      Crc32Table[i] = crc&CRC32_MASK;
   }
}
//
// calc crc 32
//
unsigned int CalcCrc32(unsigned char *data, unsigned int size)
{
   unsigned int crc = CRC32_MASK;
   while(size--)
   {
      crc = (crc << 8) ^ Crc32Table[ ((crc >> (32-8)) & 0xFF) ^ *data++];
   }
   crc ^= CRC32_MASK;
   return crc;
}
//
// calc crc 32
//
unsigned int CalcCrc32_buf(unsigned char *data, unsigned int size,unsigned int crcTmp)
{
   unsigned int crc = crcTmp;
   while(size--)
   {
      crc = (crc << 8) ^ Crc32Table[ ((crc >> (32-8)) & 0xFF) ^ *data++];
   }
   return crc;
}

@end
