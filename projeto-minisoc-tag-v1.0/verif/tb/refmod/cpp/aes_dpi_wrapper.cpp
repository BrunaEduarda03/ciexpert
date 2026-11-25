#include <iostream>          // I/O operations on the console (std::cout, std::endl)
#include <iomanip>           // Text/hexadecimal formatting in the console (std::setw, std::setfill, std::hex, std::dec)
#include "svdpi.h"           // SystemVerilog DPI-C interface (svBitVecVal definitions, etc.)
#include "cryptopp/modes.h"
#include "cryptopp/aes.h"

using CryptoPP::byte;

#include "aux_aes.h"
#include "refmod.cpp"

//---------------------------------------------------------------------
// SV to C
//---------------------------------------------------------------------
// Auxiliary function to convert the SV bit vector (svBitVecVal) into a C byte array
void bitvec_to_bytes(const svBitVecVal* sv_vec, byte* c_bytes) {
    // svBitVecVal stores data in 32-bit little-endian words in memory.
    for (int i = 0; i < 16; i++) {
        int word_idx = (15 - i) / 4;
        int byte_shift = ((15 - i) % 4) * 8;
        c_bytes[i] = (sv_vec[word_idx] >> byte_shift) & 0xFF;
    }
}

//---------------------------------------------------------------------
// C to SV
//---------------------------------------------------------------------
// Helper function to convert C byte array back to svBitVecVal (output)
void bytes_to_bitvec(const byte* c_bytes, svBitVecVal* sv_vec) {
    sv_vec[0] = 0; sv_vec[1] = 0; sv_vec[2] = 0; sv_vec[3] = 0;
    for (int i = 0; i < 16; i++) {
        int word_idx = (15 - i) / 4;
        int byte_shift = ((15 - i) % 4) * 8;
        sv_vec[word_idx] |= ((uint32_t)c_bytes[i]) << byte_shift;
    }
}

//---------------------------------------------------------------------
// Debug Function: Print Inputs
//---------------------------------------------------------------------
void print_debug_inputs(
    int is_decrypt, 
    int mode, 
    const byte* key, 
    const byte* block_in, 
    const byte* iv
) {
    std::cout << "\n[DPI-C DEBUG] Operations: " 
              << (is_decrypt ? "DECRYPT" : "ENCRYPT") 
              << " | Mode: " << mode << std::endl;

    std::cout << "[DPI-C DEBUG] Input Key:   0x";
    for (int i = 0; i < 16; i++) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)key[i];
    }
    std::cout << std::endl;

    std::cout << "[DPI-C DEBUG] Input Block: 0x";
    for (int i = 0; i < 16; i++) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)block_in[i];
    }
    std::cout << std::endl;

    std::cout << "[DPI-C DEBUG] Input IV:    0x";
    for (int i = 0; i < 16; i++) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)iv[i];
    }
    std::cout << std::endl;
}

//---------------------------------------------------------------------
// Debug Function: Print Output
//---------------------------------------------------------------------
void print_debug_output(const byte* block_out) {
    std::cout << "[DPI-C DEBUG] Output Block: 0x";
    for (int i = 0; i < 16; i++) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)block_out[i];
    }
    std::cout << std::dec << std::endl << std::endl;
}

//---------------------------------------------------------------------
// c_aes_process
//---------------------------------------------------------------------
extern "C" {
    void c_aes_process(
        const svBitVecVal* key,      // SystemVerilog bit vector
        const svBitVecVal* iv,       // SystemVerilog bit vector
        const svBitVecVal* block_in, // SystemVerilog bit vector
        svBitVecVal* block_out,      // SystemVerilog bit vector
        int mode,
        int is_decrypt
    ) {
        byte key_bytes[16];
        byte iv_bytes[16];
        byte block_in_bytes[16];
        byte block_out_bytes[16];

        // Converts 128-bit DPI vectors to C++ readable byte arrays
        bitvec_to_bytes(key, key_bytes);
        bitvec_to_bytes(iv, iv_bytes);
        bitvec_to_bytes(block_in, block_in_bytes);

        byte* result = nullptr;

        if (is_decrypt == 0) {
        // ENCRYPT
            switch (mode) {
                case 0: result = ecbEncrypt(block_in_bytes, key_bytes); break;                 // ECB
                case 1: result = cbcPcbcEncrypt(iv_bytes, block_in_bytes, key_bytes); break;   // CBC
                case 2: result = cbcPcbcEncrypt(iv_bytes, block_in_bytes, key_bytes); break;   // PCBC
                case 3: result = cfbOfbCtrEncrypt(iv_bytes, block_in_bytes, key_bytes); break; // CFB
                case 4: result = cfbOfbCtrEncrypt(iv_bytes, block_in_bytes, key_bytes); break; // OFB
                case 5: result = cfbOfbCtrEncrypt(iv_bytes, block_in_bytes, key_bytes); break; // CTR
                case 6: result = cbcPcbcEncrypt(iv_bytes, block_in_bytes, key_bytes); break;   // PCBC
                case 7: result = cfbOfbCtrEncrypt(iv_bytes, block_in_bytes, key_bytes); break; // CFB
            }
        } else {
        // DECRYPT
            switch (mode) {
                case 0: result = ecbDecrypt(block_in_bytes, key_bytes); break;                 // ECB
                case 1: result = cbcPcbcDecrypt(iv_bytes, block_in_bytes, key_bytes); break;   // CBC
                case 2: result = cbcPcbcDecrypt(iv_bytes, block_in_bytes, key_bytes); break;   // PCBC
                case 3: result = cfbOfbCtrDecrypt(iv_bytes, block_in_bytes, key_bytes); break; // CFB
                case 4: result = cfbOfbCtrDecrypt(iv_bytes, block_in_bytes, key_bytes); break; // OFB
                case 5: result = cfbOfbCtrDecrypt(iv_bytes, block_in_bytes, key_bytes); break; // CTR
                case 6: result = cbcPcbcDecrypt(iv_bytes, block_in_bytes, key_bytes); break;   // PCBC
                case 7: result = cfbOfbCtrDecrypt(iv_bytes, block_in_bytes, key_bytes); break; // CFB
            }
        }

        // DEBUG: Printout of Inputs
        //print_debug_inputs(is_decrypt, mode, key_bytes, block_in_bytes, iv_bytes);

        if (result != nullptr) {
            for (int i = 0; i < 16; i++) {
                block_out_bytes[i] = result[i];
            }

            // Exports the result back to the svBitVecVal vector of SystemVerilog
            bytes_to_bitvec(block_out_bytes, block_out);

            // DEBUG: Printout of Outputs
            //print_debug_output(block_out_bytes);
            
        } else {
            std::cout << "[DPI-C ERROR] Result pointer returned NULL!" << std::endl;
        }
    }
}