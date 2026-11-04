// bloco8
//  ├── [0]  → 8 bits
//  ├── [1]  → 8 bits
//  ├── ...
//  └── [15] → 8 bits
typedef byte unsigned bloco8[16];

//bloco32
// ├── [0] → 32 bits
// ├── [1] → 32 bits
// ├── [2] → 32 bits
// └── [3] → 32 bits
typedef bit[31:0] bloco32[4];

import "DPI-C" context function void ecbEncrypt      (input bloco8 PT,    input bloco8 key,    output bloco8 cypher);
import "DPI-C" context function void cbcPcbcEncrypt  (input bloco8 IV,    input bloco8 PT,     input  bloco8 key,       output bloco8 cypher);
import "DPI-C" context function void cfbOfbCtrEncrypt(input bloco8 IV,    input bloco8 PT,     input  bloco8 key,       output bloco8 cypher);
import "DPI-C" context function void ecbDecrypt      (input bloco8 cypher,input bloco8 key,    output bloco8 decrypted);
import "DPI-C" context function void cbcPcbcDecrypt  (input bloco8 IV,    input bloco8 cypher, input  bloco8 key,       output bloco8 decrypted);
import "DPI-C" context function void cfbOfbCtrDecrypt(input bloco8 IV,    input bloco8 cypher, input  bloco8 key,       output bloco8 decrypted);

// Little-endian
// spec v1.0, p. 7, section 4.1 "Introduction":
// "Todos as palavras binárias dos registradores são organizados como Little-Endian,
//  ou seja, extremidade menor primeiro."

function bloco32 byte2int(bloco8 bloco);
	for(int i = 0; i<4; i++)
		byte2int[i] = {bloco[i*4+3],bloco[i*4+2],bloco[i*4+1],bloco[i*4]};
endfunction: byte2int

function bloco8 int2byte(bloco32 bloco);
	for(int i = 0; i < 4 ;i++)
		{int2byte[4*i+3], int2byte[4*i+2], int2byte[4*i+1], int2byte[4*i]} = bloco[i];
endfunction: int2byte

function void ecbEncrypt32(input bloco32 PT, input bloco32 key, output bloco32 cypher);
	bloco8 pt_8 , key_8 ,cypher_8;
	pt_8  = int2byte(PT);
	key_8 = int2byte(key);
	ecbEncrypt(pt_8, key_8, cypher_8);
	cypher = byte2int(cypher_8);
endfunction: ecbEncrypt32

function void cbcPcbcEncrypt32(input bloco32 IV, input bloco32 PT, input  bloco32 key, output bloco32 cypher);
	bloco8 pt_8, key_8, cypher_8, iv_8;
	pt_8  = int2byte(PT);
	key_8 = int2byte(key);
	iv_8  = int2byte(IV);
	cbcPcbcEncrypt(iv_8, pt_8, key_8, cypher_8);
	cypher = byte2int(cypher_8);
endfunction: cbcPcbcEncrypt32

function void cfbOfbCtrEncrypt32(input bloco32 IV, input bloco32 PT, input  bloco32 key, output bloco32 cypher);
	bloco8 pt_8, key_8, cypher_8, iv_8;
	pt_8  = int2byte(PT);
	key_8 = int2byte(key);
	iv_8  = int2byte(IV);
	cfbOfbCtrEncrypt(iv_8, pt_8, key_8, cypher_8);
	cypher = byte2int(cypher_8);
endfunction: cfbOfbCtrEncrypt32

function void ecbDecrypt32(input bloco32 cypher, input bloco32 key, output bloco32 decrypted);
	bloco8 cypher_8, key_8, decrypted_8;
	cypher_8 = int2byte(cypher);
	key_8    = int2byte(key);
	ecbDecrypt(cypher_8, key_8, decrypted_8);
	decrypted = byte2int(decrypted_8);
endfunction: ecbDecrypt32

function void cbcPcbcDecrypt32(input bloco32 IV, input bloco32 cypher, input bloco32 key, output bloco32 decrypted);
	bloco8 cypher_8, key_8, decrypted_8, iv_8;
	cypher_8 = int2byte(cypher);
	key_8    = int2byte(key);
	iv_8     = int2byte(IV);
	cbcPcbcDecrypt(iv_8, cypher_8, key_8, decrypted_8);
	decrypted = byte2int(decrypted_8);
endfunction: cbcPcbcDecrypt32

function void cfbOfbCtrDecrypt32(input bloco32 IV, input bloco32 cypher, input bloco32 key, output bloco32 decrypted);
	bloco8 cypher_8, key_8, decrypted_8, iv_8;
	cypher_8 = int2byte(cypher);
	key_8 = int2byte(key);
	iv_8  = int2byte(IV);
	cfbOfbCtrDecrypt(iv_8, cypher_8, key_8, decrypted_8);
	decrypted = byte2int(decrypted_8);
endfunction: cfbOfbCtrDecrypt32
