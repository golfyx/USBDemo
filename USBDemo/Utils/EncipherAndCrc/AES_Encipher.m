//
//  AES_Encipher.m
//  USBDemo
//
//  Created by golfy on 2022/2/21.
//

#import "AES_Encipher.h"

@implementation AES_Encipher

#define EXPANDED_KEY_SIZE (BLOCKSIZE * (ROUNDS+1))       //!< 176, 208 or 240 bytes.
//---------------------------------------------------------------------------------
unsigned char AES_Key_Table[KEYLENGTH];
unsigned char block1[256]; //!< Workspace 1.
unsigned char block2[256]; //!< Worksapce 2.
unsigned char tempbuf[256];
unsigned char ChainCipherBlock[KEYLENGTH];
//---------------------------------------
unsigned char *powTbl; //!< Final location of exponentiation lookup table.
unsigned char *logTbl; //!< Final location of logarithm lookup table.
unsigned char *sBox; //!< Final location of s-box.
unsigned char *sBoxInv; //!< Final location of inverse s-box.
unsigned char *expandedKey; //!< Final location of expanded key.
//-----------------------------------------------------------------------
void CalcPowLog(unsigned char *powTbl, unsigned char *logTbl);
void CalcSBox( unsigned char * sBox );
void CalcSBoxInv( unsigned char * sBox, unsigned char * sBoxInv );
void CycleLeft( unsigned char * row );
void InvMixColumn( unsigned char * column );
void SubBytes( unsigned char * bytes, unsigned char count );
void InvSubBytesAndXOR( unsigned char * bytes, unsigned char * key, unsigned char count );
void InvShiftRows( unsigned char * state );
void InvMixColumns( unsigned char * state );
void XORBytes( unsigned char * bytes1, unsigned char * bytes2, unsigned char count );
void CopyBytes( unsigned char * to, unsigned char * from, unsigned char count );
void KeyExpansion( unsigned char * expandedKey );
void InvCipher( unsigned char * block, unsigned char * expandedKey );
void aesDecInit(void);
void aesDecrypt( unsigned char * buffer, unsigned char * chainBlock );
unsigned char Multiply( unsigned char num, unsigned char factor );
unsigned char DotProduct( unsigned char * vector1, unsigned char * vector2 );
void MixColumn( unsigned char * column );
void MixColumns( unsigned char * state );
void ShiftRows( unsigned char * state );
void Cipher( unsigned char * block, unsigned char * expandedKey );
void aesEncInit(void);
void aesEncrypt( unsigned char * buffer, unsigned char * chainBlock );
//-----------------------------------------------------------------------
//
// calc pow log
//
void CalcPowLog(unsigned char *powTbl, unsigned char *logTbl)
{
    unsigned char i = 0;
    unsigned char t = 1;
    
    do {
        // Use 0x03 as root for exponentiation and logarithms.
        powTbl[i] = t;
        logTbl[t] = i;
        i++;
        
        // Muliply t by 3 in GF(2^8).
        t ^= (t << 1) ^ (t & 0x80 ? BPOLY : 0);
    }while( t != 1 ); // Cyclic properties ensure that i < 255.
    
    powTbl[255] = powTbl[0]; // 255 = '-0', 254 = -1, etc.
}

void CalcSBox( unsigned char * sBox )
{
    unsigned char i, rot;
    unsigned char temp;
    unsigned char result;
    
    // Fill all entries of sBox[].
    i = 0;
    do {
        //Inverse in GF(2^8).
        if( i > 0 )
        {
            temp = powTbl[ 255 - logTbl[i] ];
        }
        else
        {
            temp = 0;
        }
        
        // Affine transformation in GF(2).
        result = temp ^ 0x63; // Start with adding a vector in GF(2).
        for( rot = 0; rot < 4; rot++ )
        {
            // Rotate left.
            temp = (temp<<1) | (temp>>7);
            
            // Add rotated byte in GF(2).
            result ^= temp;
        }
        
        // Put result in table.
        sBox[i] = result;
    } while( ++i != 0 );
}

void CalcSBoxInv( unsigned char * sBox, unsigned char * sBoxInv )
{
    unsigned char i = 0;
    unsigned char j = 0;
    
    // Iterate through all elements in sBoxInv using  i.
    do {
    // Search through sBox using j.
        do {
            // Check if current j is the inverse of current i.
            if( sBox[ j ] == i )
            {
                // If so, set sBoxInc and indicate search finished.
                sBoxInv[ i ] = j;
                j = 255;
            }
        } while( ++j != 0 );
    } while( ++i != 0 );
}

void CycleLeft( unsigned char * row )
{
    // Cycle 4 bytes in an array left once.
    unsigned char temp = row[0];
    
    row[0] = row[1];
    row[1] = row[2];
    row[2] = row[3];
    row[3] = temp;
}

void InvMixColumn( unsigned char * column )
{
    unsigned char r0, r1, r2, r3;
    
    r0 = column[1] ^ column[2] ^ column[3];
    r1 = column[0] ^ column[2] ^ column[3];
    r2 = column[0] ^ column[1] ^ column[3];
    r3 = column[0] ^ column[1] ^ column[2];
    
    column[0] = (column[0] << 1) ^ (column[0] & 0x80 ? BPOLY : 0);
    column[1] = (column[1] << 1) ^ (column[1] & 0x80 ? BPOLY : 0);
    column[2] = (column[2] << 1) ^ (column[2] & 0x80 ? BPOLY : 0);
    column[3] = (column[3] << 1) ^ (column[3] & 0x80 ? BPOLY : 0);
    
    r0 ^= column[0] ^ column[1];
    r1 ^= column[1] ^ column[2];
    r2 ^= column[2] ^ column[3];
    r3 ^= column[0] ^ column[3];
    
    column[0] = (column[0] << 1) ^ (column[0] & 0x80 ? BPOLY : 0);
    column[1] = (column[1] << 1) ^ (column[1] & 0x80 ? BPOLY : 0);
    column[2] = (column[2] << 1) ^ (column[2] & 0x80 ? BPOLY : 0);
    column[3] = (column[3] << 1) ^ (column[3] & 0x80 ? BPOLY : 0);
    
    r0 ^= column[0] ^ column[2];
    r1 ^= column[1] ^ column[3];
    r2 ^= column[0] ^ column[2];
    r3 ^= column[1] ^ column[3];
    
    column[0] = (column[0] << 1) ^ (column[0] & 0x80 ? BPOLY : 0);
    column[1] = (column[1] << 1) ^ (column[1] & 0x80 ? BPOLY : 0);
    column[2] = (column[2] << 1) ^ (column[2] & 0x80 ? BPOLY : 0);
    column[3] = (column[3] << 1) ^ (column[3] & 0x80 ? BPOLY : 0);
    
    column[0] ^= column[1] ^ column[2] ^ column[3];
    r0 ^= column[0];
    r1 ^= column[0];
    r2 ^= column[0];
    r3 ^= column[0];
    
    column[0] = r0;
    column[1] = r1;
    column[2] = r2;
    column[3] = r3;
}

void SubBytes( unsigned char * bytes, unsigned char count )
{
    do {
        *bytes = sBox[ *bytes ]; // Substitute every byte in state.
        bytes++;
    } while( --count );
}

void InvSubBytesAndXOR( unsigned char * bytes, unsigned char * key, unsigned char count )
{
    do {
        // *bytes = sBoxInv[ *bytes ] ^ *key; // Inverse substitute every byte in state and add key.
        *bytes = block2[ *bytes ] ^ *key; // Use block2 directly. Increases speed.
        bytes++;
        key++;
    } while( --count );
}

void InvShiftRows( unsigned char * state )
{
    unsigned char temp;
    
    // Note: State is arranged column by column.
    
    // Cycle second row right one time.
    temp = state[ 1 + 3*4 ];
    state[ 1 + 3*4 ] = state[ 1 + 2*4 ];
    state[ 1 + 2*4 ] = state[ 1 + 1*4 ];
    state[ 1 + 1*4 ] = state[ 1 + 0*4 ];
    state[ 1 + 0*4 ] = temp;
    
    // Cycle third row right two times.
    temp = state[ 2 + 0*4 ];
    state[ 2 + 0*4 ] = state[ 2 + 2*4 ];
    state[ 2 + 2*4 ] = temp;
    temp = state[ 2 + 1*4 ];
    state[ 2 + 1*4 ] = state[ 2 + 3*4 ];
    state[ 2 + 3*4 ] = temp;
    
    // Cycle fourth row right three times, ie. left once.
    temp = state[ 3 + 0*4 ];
    state[ 3 + 0*4 ] = state[ 3 + 1*4 ];
    state[ 3 + 1*4 ] = state[ 3 + 2*4 ];
    state[ 3 + 2*4 ] = state[ 3 + 3*4 ];
    state[ 3 + 3*4 ] = temp;
}

void InvMixColumns( unsigned char * state )
{
    InvMixColumn( state + 0*4 );
    InvMixColumn( state + 1*4 );
    InvMixColumn( state + 2*4 );
    InvMixColumn( state + 3*4 );
}

void XORBytes( unsigned char * bytes1, unsigned char * bytes2, unsigned char count )
{
    do {
        *bytes1 ^= *bytes2; // Add in GF(2), ie. XOR.
        bytes1++;
        bytes2++;
    } while( --count );
}

void CopyBytes( unsigned char * to, unsigned char * from, unsigned char count )
{
    do {
        *to = *from;
        to++;
        from++;
    } while( --count );
}

void KeyExpansion( unsigned char * expandedKey )
{
    unsigned char temp[4];
    unsigned char i;
    unsigned char Rcon[4] = { 0x01, 0x00, 0x00, 0x00 }; // Round constant.
    
    unsigned char * key = AES_Key_Table;
    
    // Copy key to start of expanded key.
    i = KEYLENGTH;
    do {
        *expandedKey = *key;
        expandedKey++;
        key++;
    } while( --i );
    
    // Prepare last 4 bytes of key in temp.
    expandedKey -= 4;
    temp[0] = *(expandedKey++);
    temp[1] = *(expandedKey++);
    temp[2] = *(expandedKey++);
    temp[3] = *(expandedKey++);
    
    // Expand key.
    i = KEYLENGTH;
    while( i < BLOCKSIZE*(ROUNDS+1) )
    {
        // Are we at the start of a multiple of the key size?
        if( (i % KEYLENGTH) == 0 )
        {
            CycleLeft( temp ); // Cycle left once.
            SubBytes( temp, 4 ); // Substitute each byte.
            XORBytes( temp, Rcon, 4 ); // Add constant in GF(2).
            *Rcon = (*Rcon << 1) ^ (*Rcon & 0x80 ? BPOLY : 0);
        }
        
        // Keysize larger than 24 bytes, ie. larger that 192 bits?
        #if KEYLENGTH > 24
        // Are we right past a block size?
        else if( (i % KEYLENGTH) == BLOCKSIZE ) {
        SubBytes( temp, 4 ); // Substitute each byte.
        }
        #endif
        
        // Add bytes in GF(2) one KEYLENGTH away.
        XORBytes( temp, expandedKey - KEYLENGTH, 4 );
        
        // Copy result to current 4 bytes.
        *(expandedKey++) = temp[ 0 ];
        *(expandedKey++) = temp[ 1 ];
        *(expandedKey++) = temp[ 2 ];
        *(expandedKey++) = temp[ 3 ];
        
        i += 4; // Next 4 bytes.
    }
}

void InvCipher( unsigned char * block, unsigned char * expandedKey )
{
    unsigned char round = ROUNDS-1;
    expandedKey += BLOCKSIZE * ROUNDS;
    
    XORBytes( block, expandedKey, 16 );
    expandedKey -= BLOCKSIZE;
    
    do {
        InvShiftRows( block );
        InvSubBytesAndXOR( block, expandedKey, 16 );
        expandedKey -= BLOCKSIZE;
        InvMixColumns( block );
    } while( --round );
    
    InvShiftRows( block );
    InvSubBytesAndXOR( block, expandedKey, 16 );
}
//------------------------------------------------------------------------
//========================================================================
//------------------------------------------------------------------------
void aesDecInit(void)
{
    powTbl = block1;
    logTbl = block2;
    CalcPowLog( powTbl, logTbl );
    
    sBox = tempbuf;
    CalcSBox( sBox );
    
    expandedKey = block1;
    KeyExpansion( expandedKey );
    
    sBoxInv = block2; // Must be block2.
    CalcSBoxInv( sBox, sBoxInv );
}
void aesDecrypt( unsigned char * buffer, unsigned char * chainBlock )
{
    unsigned char temp[ BLOCKSIZE ];
    
    CopyBytes( temp, buffer, BLOCKSIZE );
    InvCipher( buffer, expandedKey );
    XORBytes( buffer, chainBlock, BLOCKSIZE );
    //CopyBytes( chainBlock, temp, BLOCKSIZE );
}
//----------------------------------------------------------------------
unsigned char Multiply( unsigned char num, unsigned char factor )
{
    unsigned char mask = 1;
    unsigned char result = 0;
    
    while( mask != 0 )
    {
    // Check bit of factor given by mask.
        if( mask & factor )
        {
          // Add current multiple of num in GF(2).
          result ^= num;
        }
    
        // Shift mask to indicate next bit.
        mask <<= 1;
        
        // Double num.
        num = (num << 1) ^ (num & 0x80 ? BPOLY : 0);
    }
    
    return result;
}

unsigned char DotProduct( unsigned char * vector1, unsigned char * vector2 )
{
    unsigned char result = 0;
    
    result ^= Multiply( *vector1++, *vector2++ );
    result ^= Multiply( *vector1++, *vector2++ );
    result ^= Multiply( *vector1++, *vector2++ );
    result ^= Multiply( *vector1  , *vector2   );
    
    return result;
}

void MixColumn( unsigned char * column )
{
    unsigned char row[8] = {0x02, 0x03, 0x01, 0x01, 0x02, 0x03, 0x01, 0x01};
    // Prepare first row of matrix twice, to eliminate need for cycling.
    
    unsigned char result[4];
    
    // Take dot products of each matrix row and the column vector.
    result[0] = DotProduct( row+0, column );
    result[1] = DotProduct( row+3, column );
    result[2] = DotProduct( row+2, column );
    result[3] = DotProduct( row+1, column );
    
    // Copy temporary result to original column.
    column[0] = result[0];
    column[1] = result[1];
    column[2] = result[2];
    column[3] = result[3];
}

void MixColumns( unsigned char * state )
{
    MixColumn( state + 0*4 );
    MixColumn( state + 1*4 );
    MixColumn( state + 2*4 );
    MixColumn( state + 3*4 );
}

void ShiftRows( unsigned char * state )
{
    unsigned char temp;
    
    // Note: State is arranged column by column.
    
    // Cycle second row left one time.
    temp = state[ 1 + 0*4 ];
    state[ 1 + 0*4 ] = state[ 1 + 1*4 ];
    state[ 1 + 1*4 ] = state[ 1 + 2*4 ];
    state[ 1 + 2*4 ] = state[ 1 + 3*4 ];
    state[ 1 + 3*4 ] = temp;
    
    // Cycle third row left two times.
    temp = state[ 2 + 0*4 ];
    state[ 2 + 0*4 ] = state[ 2 + 2*4 ];
    state[ 2 + 2*4 ] = temp;
    temp = state[ 2 + 1*4 ];
    state[ 2 + 1*4 ] = state[ 2 + 3*4 ];
    state[ 2 + 3*4 ] = temp;
    
    // Cycle fourth row left three times, ie. right once.
    temp = state[ 3 + 3*4 ];
    state[ 3 + 3*4 ] = state[ 3 + 2*4 ];
    state[ 3 + 2*4 ] = state[ 3 + 1*4 ];
    state[ 3 + 1*4 ] = state[ 3 + 0*4 ];
    state[ 3 + 0*4 ] = temp;
}

void Cipher( unsigned char * block, unsigned char * expandedKey )
{
    unsigned char round = ROUNDS-1;
    
    XORBytes( block, expandedKey, 16 );
    expandedKey += BLOCKSIZE;
    
    do {
        SubBytes( block, 16 );
        ShiftRows( block );
        MixColumns( block );
        XORBytes( block, expandedKey, 16 );
        expandedKey += BLOCKSIZE;
    } while( --round );
    
    SubBytes( block, 16 );
    ShiftRows( block );
    XORBytes( block, expandedKey, 16 );
}
//------------------------------------------------------------------------
//========================================================================
//------------------------------------------------------------------------
void aesEncInit(void)
{
    powTbl = block1;
    logTbl = tempbuf;
    CalcPowLog( powTbl, logTbl );
    
    sBox = block2;
    CalcSBox( sBox );
    
    expandedKey = block1;
    KeyExpansion( expandedKey );
}
void aesEncrypt( unsigned char * buffer, unsigned char * chainBlock )
{
    XORBytes( buffer, chainBlock, BLOCKSIZE );
    Cipher( buffer, expandedKey );
    //CopyBytes( chainBlock, buffer, BLOCKSIZE );
}
//=============================================================================
//-----------------------------------------------------------------------------
//=============================================================================
// write on 2014-05-23
// get encryption aes key table
void GetEncryptionAesKeyTable(unsigned char *aeskey)
{
   int i;

   for(i=0;i<KEYLENGTH;i++)
       AES_Key_Table[i] = aeskey[i];
    
   for(i=0;i<KEYLENGTH;i++)
       ChainCipherBlock[i] = 0x00;

   aesEncInit();      //‘⁄÷¥––º”√‹≥ı ºªØ÷Æ«∞ø…“‘Œ™AES_Key_Table∏≥÷µ”––ßµƒ√‹¬Î ˝æ›
}
/*******************************************************************************
* Function Name  : AesEncipher
* Description    : 16∏ˆ◊÷Ω⁄ AESº”√‹£¨
* Input          : æ÷≤ø±‰¡ø£∫unsigned char *result   ‰»Îµƒ√˜Œƒ
                            unsigned int length      ‰»Îµƒ√˜Œƒµƒ≥§∂»
* Output         : unsigned char *result  ∑µªÿµƒº”√‹Ω·π˚
* Return         : None
*******************************************************************************/
void AesEncipher(unsigned char *result,unsigned int length)
{
   unsigned int i;
//-----------------------------------
   i = 0;
   while(i<length)
   {
      aesEncrypt(&result[i],ChainCipherBlock);//AESº”√‹£¨ ˝◊Èdat¿Ô√Êµƒ–¬ƒ⁄»›æÕ «º”√‹∫Ûµƒ ˝æ›°£
      i = i + ENCIPHER_BLOCK_SIZE;
   }
//-----------------------------------
}

//-----------------------------------------------------------
//-----------------------------------------------------------
// Get decrypt aes key table
void GetDecryptionAesKeyTable(unsigned char *aeskey)
{
   unsigned int  i;

   for(i=0;i<KEYLENGTH;i++)
      AES_Key_Table[i] = aeskey[i];
    
   for(i=0;i<KEYLENGTH;i++)
      ChainCipherBlock[i] = 0x00;

   aesDecInit();               //‘⁄÷¥––Ω‚√‹≥ı ºªØ÷Æ«∞ø…“‘Œ™AES_Key_Table∏≥÷µ”––ßµƒ√‹¬Î ˝æ›
}
/*******************************************************************************
* Function Name  : AesDecipher
* Description    : 16∏ˆ◊÷Ω⁄ AESΩ‚√‹
* Input          : æ÷≤ø±‰¡ø£∫unsigned char *result   ‰»Îµƒ√‹Œƒ
                            unsigned int length     ‰»Îµƒ√‹Œƒµƒ≥§∂»
                 : »´æ÷±‰¡ø£∫unsigned char *AES_Key_Table   ‰»Îµƒ√‹‘ø
* Output         : unsigned char *result  ∑µªÿµƒΩ‚√‹Ω·π˚
* Return         : None
*******************************************************************************/
void AesDecipher(unsigned char *result,unsigned int length)
{
   unsigned int  i;
//-----------------------------------
   i = 0;
   while(i<length)
   {
      aesDecrypt(&result[i],ChainCipherBlock);//AESΩ‚√‹£¨√‹Œƒ ˝æ›¥Ê∑≈‘⁄dat¿Ô√Ê£¨æ≠Ω‚√‹æÕƒ‹µ√µΩ÷Æ«∞µƒ√˜Œƒ°£
      i = i + ENCIPHER_BLOCK_SIZE;
   }
//-----------------------------------
}

@end
