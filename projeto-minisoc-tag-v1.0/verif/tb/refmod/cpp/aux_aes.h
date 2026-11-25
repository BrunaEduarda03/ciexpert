#ifndef aux_aes_H
#define aux_aes_H

#include <iomanip>
#include <iostream>
#include <string.h>

#include "cryptopp/modes.h"
#include "cryptopp/aes.h"
#include "cryptopp/filters.h"
#include "cryptopp/hex.h"

using CryptoPP::byte;

class aux_aes {
private:
	byte* data;
	byte* key;
	byte* cipher;
	byte* decrypted;

public:
	aux_aes();
	~aux_aes();
	void setKey(byte *);
	void setPlainText(byte *);
	void setCipher(byte *);
	void encrypt();
	void decrypt();
	byte* getKey();
	byte* getPlainText();
	byte* getCipher();
	byte* getDecrypted();
};
#endif
