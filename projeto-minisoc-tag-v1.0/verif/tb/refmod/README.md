# AES-128 reference model

Software, writting in c++ language, with the purpose of encryption and decryption using the AES-128 specification. The project makes use of the CryptoPP library, for the stantard encryption in ECB mode, combined with original functions for other modes. Encryption and decryption is fully functional in the ECB, CBC, PCBC,CFB, OFB and CTR modes.

## ⚠️[DEPRECATED] Installing / Getting started
To run the software the GCC GNU compiler 6.1 or above is recomended but any C++ compiler can make use of this code. The cryptoPP library is also necessary.
```shell
yum search  crypto++
sudo yum install cryptopp cryptopp-devel
sudo yum install cryptopp cryptopp-progs 
```

A Makefile is already avaible, it makes use of the GCC to build the software.   

```shell
make all
./prog
```
After executing the "prog" file you will be met with the input data that was used for encryption, and the results for each mode(ECB, CBC, PCBC, CFB, OFB, CTR). Each mode shows the ciphers produced and result of their decryption.  

## 🚀[NEW] Installing / Getting started

**1.** Go back to your home folder.
```shell
cd ~
```

**2.** Clone the official Crypto++ repository.
```shell
git clone https://github.com/weidai11/cryptopp.git
cd cryptopp
```

**3.** Compiles the library using multiple cores.
```shell
make -j4
```

**4.** Install the library within a local directory in your account.
```shell
make install PREFIX=$HOME/cryptopp_local
```

**5.** Confirm that the header files and libraries have been generated in your user directory. If these two commands display the files without errors, the local compilation was completed successfully.
```shell
ls -l $HOME/cryptopp_local/include/cryptopp/modes.h
ls -l $HOME/cryptopp_local/lib/libcryptopp.a
```

## 📄 Features

What's all the bells and whistles this project can perform?
* What's the main functionality
* You can also do another thing
* If you get really randy, you can even do this

## ⚙️ Configuration
In order to use this software you will need to modify the input values in the main.cpp file.

#### Argument 1
Input: `data1`  
Default: `'3243F6A8885A308D313198A2E0370734'`

Input `data2`
Default :`'00112233445566778899AABBCCDDEEFF'`


The 'data1' is the first 16 bytes block to be encrypted, and 'data2' is the secound 16 bytes block to be encrypted. There is the possibility to add more blocks by following the logic already implemented for each mode.

Example:
```c++

   //encrypt cbc mode
    encrypted1 = ecbEncrypt(data1, key);
    dump_data(encrypted1, "first cipher block    ");
    encrypted2 = ecbEncrypt(data2, key);
    dump_data(encrypted2, "second cipher block   ");
    encrypted3 = ecbEncrypt(data3, key);
    dump_data(encrypted3, "third cipher block	");

```

#### Argument 2
Input: `Key`  
Default: `2B7E151628AED2A6ABF7158809CF4F3C`

The Key is a 16 bytes block.

#### Argument 3
Input: `IV`  
Default: `070A111FAE9A364F0F94275F3E91B9CA`

The IV is a 16 bytes block.

## ✅ Results Validation

### ECB MODE
Data            	        | Key				 | IV				  | Cipher 			    
--------------------------------|--------------------------------|--------------------------------|--------------------------------
3243F6A8885A308D313198A2E0370734|2B7E151628AED2A6ABF7158809CF4F3C|070A111FAE9A364F0F94275F3E91B9CA|3925841D02DC09FBDC118597196A0B32 
### CBC MODE

Data            	        | Key				 | IV				  | Cipher 			    
--------------------------------|--------------------------------|--------------------------------|--------------------------------
3243F6A8885A308D313198A2E0370734|2B7E151628AED2A6ABF7158809CF4F3C|070A111FAE9A364F0F94275F3E91B9CA|BDFA585368EFB3F422031EDC0B6BAA40
 
### PCBC MODE

Data            	        | Key				 | IV				  | Cipher 			    
--------------------------------|--------------------------------|--------------------------------|--------------------------------
3243F6A8885A308D313198A2E0370734|2B7E151628AED2A6ABF7158809CF4F3C|070A111FAE9A364F0F94275F3E91B9CA|BDFA585368EFB3F422031EDC0B6BAA40
 
### CFB MODE

Data            	        | Key				 | IV				  | Cipher 			    
--------------------------------|--------------------------------|--------------------------------|--------------------------------
3243F6A8885A308D313198A2E0370734|2B7E151628AED2A6ABF7158809CF4F3C|070A111FAE9A364F0F94275F3E91B9CA|7AA5C17E1E2027CE1FE77E2E9D293506
 
### OFB MODE

Data            	        | Key				 | IV				  | Cipher 			    
--------------------------------|--------------------------------|--------------------------------|-------------------------------
3243F6A8885A308D313198A2E0370734|2B7E151628AED2A6ABF7158809CF4F3C|070A111FAE9A364F0F94275F3E91B9CA|7AA5C17E1E2027CE1FE77E2E9D293506
 
### CTR MODE
Data            	        | Key				 | IV				  | Cipher 			    
--------------------------------|--------------------------------|--------------------------------|--------------------------------
3243F6A8885A308D313198A2E0370734|2B7E151628AED2A6ABF7158809CF4F3C|070A111FAE9A364F0F94275F3E91B9CA| 7AA5C17E1E2027CE1FE77E2E9D293506
 
