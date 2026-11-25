#include "aux_aes.h"

extern byte *ecbEncrypt(byte *PT, byte*key)
{

    aux_aes ecb;

    ecb.setKey(key);
    ecb.setPlainText(PT);
    ecb.encrypt();

    return ecb.getCipher();
}


extern byte *cbcPcbcEncrypt(byte *IV, byte *PT, byte*key)
{
    byte *plain = new byte[CryptoPP::AES::BLOCKSIZE];
    
    for (int k=0; k < CryptoPP::AES::BLOCKSIZE; k++){
        plain[k] = PT[k] ^ IV[k];
    }
    aux_aes ecb;

    ecb.setKey(key);
    ecb.setPlainText(plain);
    ecb.encrypt();

    return ecb.getCipher();
}


extern byte *cfbOfbCtrEncrypt(byte *IV, byte *PT, byte*key)
{
    byte *cipher = new byte[CryptoPP::AES::BLOCKSIZE];
    
   
    aux_aes ecb;
    ecb.setKey(key);
    ecb.setPlainText(IV);
    ecb.encrypt();

    for (int k=0; k < CryptoPP::AES::BLOCKSIZE; k++){
        cipher[k] = PT[k] ^ ecb.getCipher()[k];
    }

    return cipher;
}

extern byte *ecbDecrypt(byte *C, byte*key)
{

    aux_aes ecb;

    ecb.setKey(key);
    ecb.setCipher(C);
    ecb.decrypt();

    return ecb.getDecrypted();
}


extern byte *cbcPcbcDecrypt(byte *IV, byte *C, byte*key)
{
    byte *decrypted = new byte[CryptoPP::AES::BLOCKSIZE];
    
    aux_aes ecb;

    ecb.setKey(key);
    ecb.setCipher(C);
    ecb.decrypt();

    for (int k=0; k < CryptoPP::AES::BLOCKSIZE; k++){
        decrypted[k] = ecb.getDecrypted()[k] ^ IV[k];
    }

    return decrypted;
}

extern byte *cfbOfbCtrDecrypt(byte *IV, byte *C, byte*key)
{
    byte *decrypted = new byte[CryptoPP::AES::BLOCKSIZE];
    
    aux_aes ecb;

    ecb.setKey(key);
    ecb.setPlainText(IV);
    ecb.encrypt();

    for (int k=0; k < CryptoPP::AES::BLOCKSIZE; k++){
        decrypted[k] = ecb.getCipher()[k] ^ C[k];
    }

    return decrypted;
}