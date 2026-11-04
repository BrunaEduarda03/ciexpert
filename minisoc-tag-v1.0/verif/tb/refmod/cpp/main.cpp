#include <iomanip>
#include <iostream>
#include <string.h>
#include <type_traits>

#include "cryptopp/modes.h"
#include "cryptopp/aes.h"
#include "cryptopp/filters.h"
#include "cryptopp/hex.h"

using CryptoPP::byte;
using CryptoPP::HexEncoder;
using namespace std;

#include "aux_aes.cpp"
#include "refmod.cpp"

void dump_data(byte data[],string text){
        HexEncoder hex;
        string r1;

	hex.Attach(new CryptoPP::StringSink(r1));
        hex.Put(data, 16);
        hex.MessageEnd();      

        cout << text;
        cout <<" : ";
        cout << r1 << endl;
}

int main(void)
{	
    int k;
	//byte data1[] = {0x26, 0x18, 0xe1, 0xbb, 0xf0, 0xf0, 0x98, 0xbd, 0x2e, 0x38, 0xd9, 0x27, 0xf4, 0x2a, 0x01, 0xff};
    //byte data2[] = {0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA, 0x99, 0x88, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x00};
    //byte data3[] = {0xFF, 0x23, 0xAC, 0x45, 0x00, 0xFF, 0xAA, 0xBC, 0x88, 0x99, 0xAe, 0xeb, 0xce, 0xdF, 0xff, 0xee};  
    //byte key[]   = {0x5e, 0x03, 0x98, 0xef, 0x40, 0xd4, 0xff, 0xb4, 0x2d, 0x70, 0x0b, 0x01, 0x27, 0x7e, 0x09, 0xa6};
    //byte IV[]    = {0xCC, 0xCC, 0xCC, 0xCC, 0xAA, 0xAA, 0xAA, 0xAA, 0xFF, 0xFF, 0xFF, 0xFF, 0xEE, 0xEE, 0xEE, 0xEE};

    byte data1[] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};
    byte data2[] = {0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA, 0x99, 0x88, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x00};
    byte data3[] = {0xFF, 0x23, 0xAC, 0x45, 0x00, 0xFF, 0xAA, 0xBC, 0x88, 0x99, 0xAe, 0xeb, 0xce, 0xdF, 0xff, 0xee};  
    byte key[]   = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F};
    byte IV[]    = {0xCC, 0xCC, 0xCC, 0xCC, 0xAA, 0xAA, 0xAA, 0xAA, 0xFF, 0xFF, 0xFF, 0xFF, 0xEE, 0xEE, 0xEE, 0xEE};

    byte *newIV      = new byte[CryptoPP::AES::BLOCKSIZE];
    byte *encrypted1 = new byte[CryptoPP::AES::BLOCKSIZE];
    byte *encrypted2 = new byte[CryptoPP::AES::BLOCKSIZE];
    byte *encrypted3 = new byte[CryptoPP::AES::BLOCKSIZE];
    byte *decrypted1 = new byte[CryptoPP::AES::BLOCKSIZE];
    byte *decrypted2 = new byte[CryptoPP::AES::BLOCKSIZE];
    byte *decrypted3 = new byte[CryptoPP::AES::BLOCKSIZE];

    cout << endl;
    dump_data(data1, "data1");
    dump_data(data2, "data2");
    dump_data(key, "  key");
    dump_data(IV, "   IV");
    cout << endl;

    /* ECB mode */
    cout<<"ECB MODE"<<endl;
    //encrypt cbc mode
    encrypted1 = ecbEncrypt(data1, key);
    dump_data(encrypted1, "first cipher block    ");
    encrypted2 = ecbEncrypt(data2, key);
    dump_data(encrypted2, "second cipher block   ");

    //decrypt cbc mode 
    decrypted1 = ecbDecrypt(encrypted1, key);
    dump_data(decrypted1, "first decrypted block ");
    decrypted2 = ecbDecrypt(encrypted2, key);
    dump_data(decrypted2, "second decrypted block");
    cout<<endl;  

    /* CBC mode */
    cout<<"CBC MODE"<<endl;
    //encrypt cbc mode
    encrypted1 = cbcPcbcEncrypt(IV, data1, key);
    dump_data(encrypted1, "first cipher block    ");
    newIV = encrypted1;

    encrypted2 = cbcPcbcEncrypt(newIV, data2, key);
    dump_data(encrypted2, "second cipher block   ");

    //decrypt cbc mode 
    decrypted1 = cbcPcbcDecrypt(IV, encrypted1, key);
    dump_data(decrypted1, "first decrypted block ");
    newIV = encrypted1;
    decrypted2 = cbcPcbcDecrypt(newIV, encrypted2, key);
    dump_data(decrypted2, "second decrypted block");
    cout<<endl;

    /* PCBC mode */
    cout<<"PCBC MODE"<<endl;
    //encrypt pcbc mode
    encrypted1 = cbcPcbcEncrypt(IV, data1, key);
    dump_data(encrypted1, "first cipher block    ");
    for (k=0; k < CryptoPP::AES::BLOCKSIZE; k++){
        newIV[k] = data1[k] ^ encrypted1[k];
    }
    encrypted2 = cbcPcbcEncrypt(newIV, data2, key);
    dump_data(encrypted2, "second cipher block   ");

    //decrypt pcbc mode 
    decrypted1 = cbcPcbcDecrypt(IV, encrypted1, key);
    dump_data(decrypted1, "first decrypted block ");
    for (k=0; k < CryptoPP::AES::BLOCKSIZE; k++){
        newIV[k] = decrypted1[k] ^ encrypted1[k];
    }
    decrypted2 = cbcPcbcDecrypt(newIV, encrypted2, key);
    dump_data(decrypted2, "second decrypted block");
    cout<<endl;

    /* CFB mode */
    cout<<"CFB MODE"<<endl;
    //encrypt cfb mode
    encrypted1 = cfbOfbCtrEncrypt(IV, data1, key);
    dump_data(encrypted1, "first cipher block    ");
    newIV = encrypted1;
    encrypted2 = cfbOfbCtrEncrypt(newIV, data2, key);
    dump_data(encrypted2, "second cipher block   ");

    //decrypt cfb mode 
    decrypted1 = cfbOfbCtrDecrypt(IV, encrypted1, key);
    dump_data(decrypted1, "first decrypted block ");
    newIV = encrypted1;
    decrypted2 = cfbOfbCtrDecrypt(newIV, encrypted2, key);
    dump_data(decrypted2, "second decrypted block");
    cout<<endl;
    
    /* OFB mode */
    cout<<"OFB MODE"<<endl;
    //encrypt ofb mode
    encrypted1 = cfbOfbCtrEncrypt(IV, data1, key);
    dump_data(encrypted1, "first cipher block    ");
    for (k=0; k < CryptoPP::AES::BLOCKSIZE; k++){
        newIV[k] = data1[k] ^ encrypted1[k];
    }
    encrypted2 = cfbOfbCtrEncrypt(newIV, data2, key);
    dump_data(encrypted2, "second cipher block   ");

    //decrypt ofb mode 
    decrypted1 = cfbOfbCtrDecrypt(IV, encrypted1, key);
    dump_data(decrypted1, "first decrypted block ");
    for (k=0; k < CryptoPP::AES::BLOCKSIZE; k++) {
        newIV[k] = decrypted1[k] ^ encrypted1[k];
    }
    decrypted2 = cfbOfbCtrDecrypt(newIV, encrypted2, key);
    dump_data(decrypted2, "second decrypted block");
    cout<<endl;

    /* CTR mode */
    cout<<"CTR MODE"<<endl;

    //encrypt ctr mode
    encrypted1 = cfbOfbCtrEncrypt(IV, data1, key);

    for(int i = 0; i < 16; i++) {
        if(i != 15)
            newIV[i] = IV[i];
        else
            newIV[i] = IV[i] ^ 0x01;
    }

    dump_data(encrypted1, "first cipher block    ");
    encrypted2 = cfbOfbCtrEncrypt(newIV, data2, key);
    dump_data(encrypted2, "second cipher block   ");
    newIV[15] = IV[15] ^ 0x02;
    encrypted3 = cfbOfbCtrEncrypt(newIV, data3, key);
    dump_data(encrypted3, "third cipher block    ");

    //decrypt ctr mode 
    decrypted1 = cfbOfbCtrDecrypt(IV, encrypted1, key);
    dump_data(decrypted1, "first decrypted block ");
    
    for(int i = 0; i < 16; i++) {
        if(i != 15)
            newIV[i] = IV[i];
        else
            newIV[i] = IV[i] ^ 0x01;
    }

    decrypted2 = cfbOfbCtrDecrypt(newIV, encrypted2, key);
    dump_data(decrypted2, "second decrypted block");
    newIV[15] = IV[15] ^ 0x02;
    decrypted3 = cfbOfbCtrDecrypt(newIV, encrypted3, key);
    dump_data(decrypted3, "third decrypted block ");
	
	return 0;
}