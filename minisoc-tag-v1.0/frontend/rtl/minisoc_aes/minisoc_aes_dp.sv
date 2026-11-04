/**
 * MiniSoC AES-128 single-block datapath.
 *
 * Adapted from the original AES IP datapath. The AMBA-facing control/register
 * logic is intentionally not part of this module. This block only performs one
 * AES-128 block operation when start_AES is held high until valid_AES.
 */

module minisoc_aes_dp (input  logic clk,        // clock

  input  logic rst_n,       // asynchronous reset active low

  input  logic start_AES,     // start calcul AES when in high level

  input  logic decrypt,     // define operation decrypt in high level else encrypt

  input  logic [127:0] key,   // key 

  input  logic [127:0] busB,    // input block to encrypt or decrypt

  output logic valid_AES,   // when 1 the busAES reponse is valid 

  output logic expanding,     // 1: Key_expansion executing. 0: Key_expansion ready

  output logic [127:0] busAES   // operation reponse

);



logic [7:0] in_state  [4][4];       // State before clock transformations

logic [7:0] aux_state [3][4][4];    // Intermediary state (between transformations)

logic [7:0] out_state [4][4];       // State after clock transformations

logic [7:0] w [4][44];          // Expanded key

logic [3:0] round;            // Round of cipher or inverse cipher (inv round = 10 - round)

logic [1:0] state_key_exp;        // State of key expansion

logic aux;                  // aux: First round must have the block as in_state



/** @math functions

  * @brief

  * functios to calcul Galois field

  */



// multiplication by x

function  logic[7:0] xtime;

  input logic[7:0] valor;

  xtime = (valor[7]) ? (valor << 1) ^ 8'h1b : valor << 1;

endfunction



// multiplication by 04h

function logic [7:0] GF_04;

  input logic[7:0] in;

  GF_04 = xtime(xtime(in));

endfunction



// multiplication by 08h

function  logic [7:0] GF_08;

  input logic [7:0] in;     

  GF_08 = xtime(GF_04(in));

endfunction



// multiplication by 09h

function  logic [7:0] GF_09;

  input logic [7:0] in;   

  GF_09 = GF_08(in)^in;

endfunction



// multiplication by 0bh

function  logic [7:0] GF_0b;

  input logic [7:0] in;   

  GF_0b = GF_08(in)^xtime(in)^in;

endfunction



// multiplication by 0dh

function  logic [7:0] GF_0d;

  input logic [7:0] in;   

  GF_0d = GF_08(in)^GF_04(in)^in;

endfunction



// multiplication by 0eh

function  logic [7:0] GF_0e;

  input logic [7:0] in;   

  GF_0e = GF_08(in)^GF_04(in)^xtime(in);

endfunction



/** @cipher functions

  * @brief

  * functions to use in algorithm aes

  */



// Substitution Box

localparam logic[7:0] S_box [16][16] = 

'{

  '{8'h63,8'h7c,8'h77,8'h7b,8'hf2,8'h6b,8'h6f,8'hc5,8'h30,8'h01,8'h67,8'h2b,8'hfe,8'hd7,8'hab,8'h76},

  '{8'hca,8'h82,8'hc9,8'h7d,8'hfa,8'h59,8'h47,8'hf0,8'had,8'hd4,8'ha2,8'haf,8'h9c,8'ha4,8'h72,8'hc0},

  '{8'hb7,8'hfd,8'h93,8'h26,8'h36,8'h3f,8'hf7,8'hcc,8'h34,8'ha5,8'he5,8'hf1,8'h71,8'hd8,8'h31,8'h15},

  '{8'h04,8'hc7,8'h23,8'hc3,8'h18,8'h96,8'h05,8'h9a,8'h07,8'h12,8'h80,8'he2,8'heb,8'h27,8'hb2,8'h75},

  '{8'h09,8'h83,8'h2c,8'h1a,8'h1b,8'h6e,8'h5a,8'ha0,8'h52,8'h3b,8'hd6,8'hb3,8'h29,8'he3,8'h2f,8'h84},

  '{8'h53,8'hd1,8'h00,8'hed,8'h20,8'hfc,8'hb1,8'h5b,8'h6a,8'hcb,8'hbe,8'h39,8'h4a,8'h4c,8'h58,8'hcf},

  '{8'hd0,8'hef,8'haa,8'hfb,8'h43,8'h4d,8'h33,8'h85,8'h45,8'hf9,8'h02,8'h7f,8'h50,8'h3c,8'h9f,8'ha8},

  '{8'h51,8'ha3,8'h40,8'h8f,8'h92,8'h9d,8'h38,8'hf5,8'hbc,8'hb6,8'hda,8'h21,8'h10,8'hff,8'hf3,8'hd2},

  '{8'hcd,8'h0c,8'h13,8'hec,8'h5f,8'h97,8'h44,8'h17,8'hc4,8'ha7,8'h7e,8'h3d,8'h64,8'h5d,8'h19,8'h73},

  '{8'h60,8'h81,8'h4f,8'hdc,8'h22,8'h2a,8'h90,8'h88,8'h46,8'hee,8'hb8,8'h14,8'hde,8'h5e,8'h0b,8'hdb},

  '{8'he0,8'h32,8'h3a,8'h0a,8'h49,8'h06,8'h24,8'h5c,8'hc2,8'hd3,8'hac,8'h62,8'h91,8'h95,8'he4,8'h79},

  '{8'he7,8'hc8,8'h37,8'h6d,8'h8d,8'hd5,8'h4e,8'ha9,8'h6c,8'h56,8'hf4,8'hea,8'h65,8'h7a,8'hae,8'h08},

  '{8'hba,8'h78,8'h25,8'h2e,8'h1c,8'ha6,8'hb4,8'hc6,8'he8,8'hdd,8'h74,8'h1f,8'h4b,8'hbd,8'h8b,8'h8a},

  '{8'h70,8'h3e,8'hb5,8'h66,8'h48,8'h03,8'hf6,8'h0e,8'h61,8'h35,8'h57,8'hb9,8'h86,8'hc1,8'h1d,8'h9e},

  '{8'he1,8'hf8,8'h98,8'h11,8'h69,8'hd9,8'h8e,8'h94,8'h9b,8'h1e,8'h87,8'he9,8'hce,8'h55,8'h28,8'hdf},

  '{8'h8c,8'ha1,8'h89,8'h0d,8'hbf,8'he6,8'h42,8'h68,8'h41,8'h99,8'h2d,8'h0f,8'hb0,8'h54,8'hbb,8'h16}

};



// Substitute Bytes Transformation

function void SubBytes;

  input  logic [7:0] funct_in_state [4][4];

  output logic [7:0] funct_out_state[4][4];



  funct_out_state[0][0] = S_box[(funct_in_state[0][0] & 8'hf0) >> 4][(funct_in_state[0][0] & 8'h0f)];

  funct_out_state[0][1] = S_box[(funct_in_state[0][1] & 8'hf0) >> 4][(funct_in_state[0][1] & 8'h0f)];

  funct_out_state[0][2] = S_box[(funct_in_state[0][2] & 8'hf0) >> 4][(funct_in_state[0][2] & 8'h0f)];

  funct_out_state[0][3] = S_box[(funct_in_state[0][3] & 8'hf0) >> 4][(funct_in_state[0][3] & 8'h0f)];



  funct_out_state[1][0] = S_box[(funct_in_state[1][0] & 8'hf0) >> 4][(funct_in_state[1][0] & 8'h0f)];

  funct_out_state[1][1] = S_box[(funct_in_state[1][1] & 8'hf0) >> 4][(funct_in_state[1][1] & 8'h0f)];

  funct_out_state[1][2] = S_box[(funct_in_state[1][2] & 8'hf0) >> 4][(funct_in_state[1][2] & 8'h0f)];

  funct_out_state[1][3] = S_box[(funct_in_state[1][3] & 8'hf0) >> 4][(funct_in_state[1][3] & 8'h0f)];



  funct_out_state[2][0] = S_box[(funct_in_state[2][0] & 8'hf0) >> 4][(funct_in_state[2][0] & 8'h0f)];

  funct_out_state[2][1] = S_box[(funct_in_state[2][1] & 8'hf0) >> 4][(funct_in_state[2][1] & 8'h0f)];

  funct_out_state[2][2] = S_box[(funct_in_state[2][2] & 8'hf0) >> 4][(funct_in_state[2][2] & 8'h0f)];

  funct_out_state[2][3] = S_box[(funct_in_state[2][3] & 8'hf0) >> 4][(funct_in_state[2][3] & 8'h0f)];



  funct_out_state[3][0] = S_box[(funct_in_state[3][0] & 8'hf0) >> 4][(funct_in_state[3][0] & 8'h0f)];

  funct_out_state[3][1] = S_box[(funct_in_state[3][1] & 8'hf0) >> 4][(funct_in_state[3][1] & 8'h0f)];

  funct_out_state[3][2] = S_box[(funct_in_state[3][2] & 8'hf0) >> 4][(funct_in_state[3][2] & 8'h0f)];

  funct_out_state[3][3] = S_box[(funct_in_state[3][3] & 8'hf0) >> 4][(funct_in_state[3][3] & 8'h0f)];

endfunction



// Shift Rows Transformation

function void ShiftRows;

  input  logic [7:0] funct_in_state [4][4];

  output logic [7:0] funct_out_state[4][4];



  funct_out_state[0][0] = funct_in_state[0][0];

  funct_out_state[0][1] = funct_in_state[0][1];

  funct_out_state[0][2] = funct_in_state[0][2];

  funct_out_state[0][3] = funct_in_state[0][3];



  funct_out_state[1][0] = funct_in_state[1][1];

  funct_out_state[1][1] = funct_in_state[1][2];

  funct_out_state[1][2] = funct_in_state[1][3];

  funct_out_state[1][3] = funct_in_state[1][0];



  funct_out_state[2][0] = funct_in_state[2][2];

  funct_out_state[2][1] = funct_in_state[2][3];

  funct_out_state[2][2] = funct_in_state[2][0];

  funct_out_state[2][3] = funct_in_state[2][1];



  funct_out_state[3][0] = funct_in_state[3][3];

  funct_out_state[3][1] = funct_in_state[3][0];

  funct_out_state[3][2] = funct_in_state[3][1];

  funct_out_state[3][3] = funct_in_state[3][2];

endfunction



// Mix Columns Transformation

function void MixColumns;

  input  logic [7:0] funct_in_state [4][4]; 

  output logic [7:0] funct_out_state[4][4];



  funct_out_state[0][0] = xtime(funct_in_state[0][0])^(funct_in_state[1][0]^xtime(funct_in_state[1][0]))^funct_in_state[2][0]^funct_in_state[3][0];

  funct_out_state[0][1] = xtime(funct_in_state[0][1])^(funct_in_state[1][1]^xtime(funct_in_state[1][1]))^funct_in_state[2][1]^funct_in_state[3][1];

  funct_out_state[0][2] = xtime(funct_in_state[0][2])^(funct_in_state[1][2]^xtime(funct_in_state[1][2]))^funct_in_state[2][2]^funct_in_state[3][2];

  funct_out_state[0][3] = xtime(funct_in_state[0][3])^(funct_in_state[1][3]^xtime(funct_in_state[1][3]))^funct_in_state[2][3]^funct_in_state[3][3];



  funct_out_state[1][0] = xtime(funct_in_state[1][0])^(funct_in_state[2][0]^xtime(funct_in_state[2][0]))^funct_in_state[3][0]^funct_in_state[0][0];

  funct_out_state[1][1] = xtime(funct_in_state[1][1])^(funct_in_state[2][1]^xtime(funct_in_state[2][1]))^funct_in_state[3][1]^funct_in_state[0][1];

  funct_out_state[1][2] = xtime(funct_in_state[1][2])^(funct_in_state[2][2]^xtime(funct_in_state[2][2]))^funct_in_state[3][2]^funct_in_state[0][2];

  funct_out_state[1][3] = xtime(funct_in_state[1][3])^(funct_in_state[2][3]^xtime(funct_in_state[2][3]))^funct_in_state[3][3]^funct_in_state[0][3];



  funct_out_state[2][0] = xtime(funct_in_state[2][0])^(funct_in_state[3][0]^xtime(funct_in_state[3][0]))^funct_in_state[0][0]^funct_in_state[1][0];

  funct_out_state[2][1] = xtime(funct_in_state[2][1])^(funct_in_state[3][1]^xtime(funct_in_state[3][1]))^funct_in_state[0][1]^funct_in_state[1][1];

  funct_out_state[2][2] = xtime(funct_in_state[2][2])^(funct_in_state[3][2]^xtime(funct_in_state[3][2]))^funct_in_state[0][2]^funct_in_state[1][2];

  funct_out_state[2][3] = xtime(funct_in_state[2][3])^(funct_in_state[3][3]^xtime(funct_in_state[3][3]))^funct_in_state[0][3]^funct_in_state[1][3];

  funct_out_state[3][0] = xtime(funct_in_state[3][0])^(funct_in_state[0][0]^xtime(funct_in_state[0][0]))^funct_in_state[1][0]^funct_in_state[2][0];

  funct_out_state[3][1] = xtime(funct_in_state[3][1])^(funct_in_state[0][1]^xtime(funct_in_state[0][1]))^funct_in_state[1][1]^funct_in_state[2][1];

  funct_out_state[3][2] = xtime(funct_in_state[3][2])^(funct_in_state[0][2]^xtime(funct_in_state[0][2]))^funct_in_state[1][2]^funct_in_state[2][2];

  funct_out_state[3][3] = xtime(funct_in_state[3][3])^(funct_in_state[0][3]^xtime(funct_in_state[0][3]))^funct_in_state[1][3]^funct_in_state[2][3];

endfunction



/** @inverse cipher functions

  * @brief

  * functions to use in algorithm aes

  */



// Inverse Substitution Box

localparam logic [7:0]Inv_S_box [16][16] =

'{

    '{8'h52,8'h09,8'h6a,8'hd5,8'h30,8'h36,8'ha5,8'h38,8'hbf,8'h40,8'ha3,8'h9e,8'h81,8'hf3,8'hd7,8'hfb},

    '{8'h7c,8'he3,8'h39,8'h82,8'h9b,8'h2f,8'hff,8'h87,8'h34,8'h8e,8'h43,8'h44,8'hc4,8'hde,8'he9,8'hcb},

    '{8'h54,8'h7b,8'h94,8'h32,8'ha6,8'hc2,8'h23,8'h3d,8'hee,8'h4c,8'h95,8'h0b,8'h42,8'hfa,8'hc3,8'h4e},

    '{8'h08,8'h2e,8'ha1,8'h66,8'h28,8'hd9,8'h24,8'hb2,8'h76,8'h5b,8'ha2,8'h49,8'h6d,8'h8b,8'hd1,8'h25},

    '{8'h72,8'hf8,8'hf6,8'h64,8'h86,8'h68,8'h98,8'h16,8'hd4,8'ha4,8'h5c,8'hcc,8'h5d,8'h65,8'hb6,8'h92},

    '{8'h6c,8'h70,8'h48,8'h50,8'hfd,8'hed,8'hb9,8'hda,8'h5e,8'h15,8'h46,8'h57,8'ha7,8'h8d,8'h9d,8'h84},

    '{8'h90,8'hd8,8'hab,8'h00,8'h8c,8'hbc,8'hd3,8'h0a,8'hf7,8'he4,8'h58,8'h05,8'hb8,8'hb3,8'h45,8'h06},

    '{8'hd0,8'h2c,8'h1e,8'h8f,8'hca,8'h3f,8'h0f,8'h02,8'hc1,8'haf,8'hbd,8'h03,8'h01,8'h13,8'h8a,8'h6b},

    '{8'h3a,8'h91,8'h11,8'h41,8'h4f,8'h67,8'hdc,8'hea,8'h97,8'hf2,8'hcf,8'hce,8'hf0,8'hb4,8'he6,8'h73},

    '{8'h96,8'hac,8'h74,8'h22,8'he7,8'had,8'h35,8'h85,8'he2,8'hf9,8'h37,8'he8,8'h1c,8'h75,8'hdf,8'h6e},

    '{8'h47,8'hf1,8'h1a,8'h71,8'h1d,8'h29,8'hc5,8'h89,8'h6f,8'hb7,8'h62,8'h0e,8'haa,8'h18,8'hbe,8'h1b},

    '{8'hfc,8'h56,8'h3e,8'h4b,8'hc6,8'hd2,8'h79,8'h20,8'h9a,8'hdb,8'hc0,8'hfe,8'h78,8'hcd,8'h5a,8'hf4},

    '{8'h1f,8'hdd,8'ha8,8'h33,8'h88,8'h07,8'hc7,8'h31,8'hb1,8'h12,8'h10,8'h59,8'h27,8'h80,8'hec,8'h5f},

    '{8'h60,8'h51,8'h7f,8'ha9,8'h19,8'hb5,8'h4a,8'h0d,8'h2d,8'he5,8'h7a,8'h9f,8'h93,8'hc9,8'h9c,8'hef},

    '{8'ha0,8'he0,8'h3b,8'h4d,8'hae,8'h2a,8'hf5,8'hb0,8'hc8,8'heb,8'hbb,8'h3c,8'h83,8'h53,8'h99,8'h61},

    '{8'h17,8'h2b,8'h04,8'h7e,8'hba,8'h77,8'hd6,8'h26,8'he1,8'h69,8'h14,8'h63,8'h55,8'h21,8'h0c,8'h7d}

};



// Inverse Shift Rows Transformation

function void InvShiftRows;

  input  logic[7:0] funct_in_state [4][4];

  output logic[7:0] funct_out_state[4][4];



  funct_out_state[0][0] = funct_in_state[0][0];

  funct_out_state[0][1] = funct_in_state[0][1];

  funct_out_state[0][2] = funct_in_state[0][2];

  funct_out_state[0][3] = funct_in_state[0][3];



  funct_out_state[1][0] = funct_in_state[1][3];

  funct_out_state[1][1] = funct_in_state[1][0];

  funct_out_state[1][2] = funct_in_state[1][1];

  funct_out_state[1][3] = funct_in_state[1][2];



  funct_out_state[2][0] = funct_in_state[2][2];

  funct_out_state[2][1] = funct_in_state[2][3];

  funct_out_state[2][2] = funct_in_state[2][0];

  funct_out_state[2][3] = funct_in_state[2][1];



  funct_out_state[3][0] = funct_in_state[3][1];

  funct_out_state[3][1] = funct_in_state[3][2];

  funct_out_state[3][2] = funct_in_state[3][3];

  funct_out_state[3][3] = funct_in_state[3][0];

endfunction



// Inverse Substitute Bytes Transformation

function void InvSubBytes;

  input  logic [7:0] funct_in_state [4][4];

  output logic [7:0] funct_out_state[4][4];



  funct_out_state[0][0] = Inv_S_box[(funct_in_state[0][0] & 8'hf0) >> 4][(funct_in_state[0][0] & 8'h0f)];

  funct_out_state[0][1] = Inv_S_box[(funct_in_state[0][1] & 8'hf0) >> 4][(funct_in_state[0][1] & 8'h0f)];

  funct_out_state[0][2] = Inv_S_box[(funct_in_state[0][2] & 8'hf0) >> 4][(funct_in_state[0][2] & 8'h0f)];

  funct_out_state[0][3] = Inv_S_box[(funct_in_state[0][3] & 8'hf0) >> 4][(funct_in_state[0][3] & 8'h0f)];



  funct_out_state[1][0] = Inv_S_box[(funct_in_state[1][0] & 8'hf0) >> 4][(funct_in_state[1][0] & 8'h0f)];

  funct_out_state[1][1] = Inv_S_box[(funct_in_state[1][1] & 8'hf0) >> 4][(funct_in_state[1][1] & 8'h0f)];

  funct_out_state[1][2] = Inv_S_box[(funct_in_state[1][2] & 8'hf0) >> 4][(funct_in_state[1][2] & 8'h0f)];

  funct_out_state[1][3] = Inv_S_box[(funct_in_state[1][3] & 8'hf0) >> 4][(funct_in_state[1][3] & 8'h0f)];



  funct_out_state[2][0] = Inv_S_box[(funct_in_state[2][0] & 8'hf0) >> 4][(funct_in_state[2][0] & 8'h0f)];

  funct_out_state[2][1] = Inv_S_box[(funct_in_state[2][1] & 8'hf0) >> 4][(funct_in_state[2][1] & 8'h0f)];

  funct_out_state[2][2] = Inv_S_box[(funct_in_state[2][2] & 8'hf0) >> 4][(funct_in_state[2][2] & 8'h0f)];

  funct_out_state[2][3] = Inv_S_box[(funct_in_state[2][3] & 8'hf0) >> 4][(funct_in_state[2][3] & 8'h0f)];



  funct_out_state[3][0] = Inv_S_box[(funct_in_state[3][0] & 8'hf0) >> 4][(funct_in_state[3][0] & 8'h0f)];

  funct_out_state[3][1] = Inv_S_box[(funct_in_state[3][1] & 8'hf0) >> 4][(funct_in_state[3][1] & 8'h0f)];

  funct_out_state[3][2] = Inv_S_box[(funct_in_state[3][2] & 8'hf0) >> 4][(funct_in_state[3][2] & 8'h0f)];

  funct_out_state[3][3] = Inv_S_box[(funct_in_state[3][3] & 8'hf0) >> 4][(funct_in_state[3][3] & 8'h0f)];

endfunction



// Inverse Mix Columns Transformation

function void InvMixColumns;

  input  logic [7:0] funct_in_state [4][4];

  output logic [7:0] funct_out_state[4][4];



  //c = 0

  funct_out_state[0][0] = GF_0e(funct_in_state[0][0]) ^ GF_0b(funct_in_state[1][0]) ^ GF_0d(funct_in_state[2][0]) ^ GF_09(funct_in_state[3][0]);

  funct_out_state[1][0] = GF_09(funct_in_state[0][0]) ^ GF_0e(funct_in_state[1][0]) ^ GF_0b(funct_in_state[2][0]) ^ GF_0d(funct_in_state[3][0]);

  funct_out_state[2][0] = GF_0d(funct_in_state[0][0]) ^ GF_09(funct_in_state[1][0]) ^ GF_0e(funct_in_state[2][0]) ^ GF_0b(funct_in_state[3][0]);                                                                                      

  funct_out_state[3][0] = GF_0b(funct_in_state[0][0]) ^ GF_0d(funct_in_state[1][0]) ^ GF_09(funct_in_state[2][0]) ^ GF_0e(funct_in_state[3][0]);             



  //c = 1

  funct_out_state[0][1] = GF_0e(funct_in_state[0][1]) ^ GF_0b(funct_in_state[1][1]) ^ GF_0d(funct_in_state[2][1]) ^ GF_09(funct_in_state[3][1]);

  funct_out_state[1][1] = GF_09(funct_in_state[0][1]) ^ GF_0e(funct_in_state[1][1]) ^ GF_0b(funct_in_state[2][1]) ^ GF_0d(funct_in_state[3][1]);

  funct_out_state[2][1] = GF_0d(funct_in_state[0][1]) ^ GF_09(funct_in_state[1][1]) ^ GF_0e(funct_in_state[2][1]) ^ GF_0b(funct_in_state[3][1]);                                                                                      

  funct_out_state[3][1] = GF_0b(funct_in_state[0][1]) ^ GF_0d(funct_in_state[1][1]) ^ GF_09(funct_in_state[2][1]) ^ GF_0e(funct_in_state[3][1]); 



  //c = 2 

  funct_out_state[0][2] = GF_0e(funct_in_state[0][2]) ^ GF_0b(funct_in_state[1][2]) ^ GF_0d(funct_in_state[2][2]) ^ GF_09(funct_in_state[3][2]);

  funct_out_state[1][2] = GF_09(funct_in_state[0][2]) ^ GF_0e(funct_in_state[1][2]) ^ GF_0b(funct_in_state[2][2]) ^ GF_0d(funct_in_state[3][2]);

  funct_out_state[2][2] = GF_0d(funct_in_state[0][2]) ^ GF_09(funct_in_state[1][2]) ^ GF_0e(funct_in_state[2][2]) ^ GF_0b(funct_in_state[3][2]);                                                                                      

  funct_out_state[3][2] = GF_0b(funct_in_state[0][2]) ^ GF_0d(funct_in_state[1][2]) ^ GF_09(funct_in_state[2][2]) ^ GF_0e(funct_in_state[3][2]); 



  //c = 3

  funct_out_state[0][3] = GF_0e(funct_in_state[0][3]) ^ GF_0b(funct_in_state[1][3]) ^ GF_0d(funct_in_state[2][3]) ^ GF_09(funct_in_state[3][3]);

  funct_out_state[1][3] = GF_09(funct_in_state[0][3]) ^ GF_0e(funct_in_state[1][3]) ^ GF_0b(funct_in_state[2][3]) ^ GF_0d(funct_in_state[3][3]);

  funct_out_state[2][3] = GF_0d(funct_in_state[0][3]) ^ GF_09(funct_in_state[1][3]) ^ GF_0e(funct_in_state[2][3]) ^ GF_0b(funct_in_state[3][3]);                                                                                     

  funct_out_state[3][3] = GF_0b(funct_in_state[0][3]) ^ GF_0d(funct_in_state[1][3]) ^ GF_09(funct_in_state[2][3]) ^ GF_0e(funct_in_state[3][3]);

endfunction



/** @functions used by cipher and inverse cipher

  * @brief

  * 

  */



// Add Round Key Transformation

function void AddRoundKey(input logic [7:0] funct_in_state [4][4], input logic [7:0] w[4][4], output logic [7:0] funct_out_state [4][4]);

  funct_out_state[0][0] = funct_in_state[0][0]^w[0][0];

  funct_out_state[0][1] = funct_in_state[0][1]^w[0][1];

  funct_out_state[0][2] = funct_in_state[0][2]^w[0][2];

  funct_out_state[0][3] = funct_in_state[0][3]^w[0][3];



  funct_out_state[1][0] = funct_in_state[1][0]^w[1][0];

  funct_out_state[1][1] = funct_in_state[1][1]^w[1][1];

  funct_out_state[1][2] = funct_in_state[1][2]^w[1][2];

  funct_out_state[1][3] = funct_in_state[1][3]^w[1][3];



  funct_out_state[2][0] = funct_in_state[2][0]^w[2][0];

  funct_out_state[2][1] = funct_in_state[2][1]^w[2][1];

  funct_out_state[2][2] = funct_in_state[2][2]^w[2][2];

  funct_out_state[2][3] = funct_in_state[2][3]^w[2][3];



  funct_out_state[3][0] = funct_in_state[3][0]^w[3][0];

  funct_out_state[3][1] = funct_in_state[3][1]^w[3][1];

  funct_out_state[3][2] = funct_in_state[3][2]^w[3][2];

  funct_out_state[3][3] = funct_in_state[3][3]^w[3][3];

endfunction



// Key Expansion

minisoc_aes_key_exp ke (
  .clk     (clk),
  .rst_n   (rst_n),
  .key     (key),
  .key_exp (w),
  .state   (state_key_exp),
  .start   (start_AES)
);





always_comb

begin

  expanding = (state_key_exp != 2'b10 && start_AES) ? 1 : 0;



  if(start_AES) begin

    // encrypt

    if(!decrypt) begin

      if(round <= 10)

      begin

        if(round == 0)

        begin

          AddRoundKey(in_state, '{'{w[0][0], w[0][1], w[0][2], w[0][3]},

                      '{w[1][0], w[1][1], w[1][2], w[1][3]},

                      '{w[2][0], w[2][1], w[2][2], w[2][3]},

                      '{w[3][0], w[3][1], w[3][2], w[3][3]}}, out_state);

        end

        else

        begin

          SubBytes(in_state, aux_state[0]);

          ShiftRows(aux_state[0], aux_state[1]);



          if(round != 10)

          begin

            MixColumns(aux_state[1], aux_state[2]);



            AddRoundKey(aux_state[2], '{'{w[0][round*4], w[0][round*4 + 1], w[0][round*4 + 2], w[0][round*4 + 3]},

                          '{w[1][round*4], w[1][round*4 + 1], w[1][round*4 + 2], w[1][round*4 + 3]},

                          '{w[2][round*4], w[2][round*4 + 1], w[2][round*4 + 2], w[2][round*4 + 3]},

                          '{w[3][round*4], w[3][round*4 + 1], w[3][round*4 + 2], w[3][round*4 + 3]}}, out_state);

          end

          else

          begin

            AddRoundKey(aux_state[1], '{'{w[0][round*4], w[0][round*4 + 1], w[0][round*4 + 2], w[0][round*4 + 3]},

                          '{w[1][round*4], w[1][round*4 + 1], w[1][round*4 + 2], w[1][round*4 + 3]},

                          '{w[2][round*4], w[2][round*4 + 1], w[2][round*4 + 2], w[2][round*4 + 3]},

                          '{w[3][round*4], w[3][round*4 + 1], w[3][round*4 + 2], w[3][round*4 + 3]}}, out_state);

          end

        end

      end

      else

        out_state = in_state;

    end

    // decrypt

    else 

    begin

      if(round <= 10)

      begin

        if(round == 0)

        begin

          AddRoundKey(in_state, '{'{w[0][40], w[0][41], w[0][42], w[0][43]},

                      '{w[1][40], w[1][41], w[1][42], w[1][43]},

                      '{w[2][40], w[2][41], w[2][42], w[2][43]},

                      '{w[3][40], w[3][41], w[3][42], w[3][43]}}, out_state);

        end

        else

        begin

          InvShiftRows(in_state, aux_state[0]);

          InvSubBytes(aux_state[0], aux_state[1]);

          if(round != 10)

          begin

            AddRoundKey(aux_state[1], '{'{w[0][40 - round*4], w[0][41 - round*4], w[0][42 - round*4], w[0][43 - round*4]},

                          '{w[1][40 - round*4], w[1][41 - round*4], w[1][42 - round*4], w[1][43 - round*4]},

                          '{w[2][40 - round*4], w[2][41 - round*4], w[2][42 - round*4], w[2][43 - round*4]},

                          '{w[3][40 - round*4], w[3][41 - round*4], w[3][42 - round*4], w[3][43 - round*4]}}, aux_state[2]);

            InvMixColumns(aux_state[2], out_state);

          end

          else

          begin

            AddRoundKey(aux_state[1], '{'{w[0][40 - round*4], w[0][41 - round*4], w[0][42 - round*4], w[0][43 - round*4]},

                          '{w[1][40 - round*4], w[1][41 - round*4], w[1][42 - round*4], w[1][43 - round*4]},

                          '{w[2][40 - round*4], w[2][41 - round*4], w[2][42 - round*4], w[2][43 - round*4]},

                          '{w[3][40 - round*4], w[3][41 - round*4], w[3][42 - round*4], w[3][43 - round*4]}}, out_state);

          end

        end

      end

      else

        out_state = in_state;

    end

  end

  else

    out_state = in_state;

end



always_ff @(posedge clk)

begin

  if(!rst_n)

  begin

    round     <= 0;

    aux     <= 1;

    valid_AES <= 0;

    busAES    <= 0;

  end

  else

  begin

    if(start_AES)

    begin

      if(state_key_exp == 2'b10)

      begin

        if(round < 10)

        begin

          if(round == 0)

          begin

            aux <= 0;

            if(!aux)

              in_state <= out_state;

            else

            begin

              in_state[0][0] <= busB[127:120];

              in_state[1][0] <= busB[119:112];

              in_state[2][0] <= busB[111:104];

              in_state[3][0] <= busB[103: 96];



              in_state[0][1] <= busB[95 : 88];

              in_state[1][1] <= busB[87 : 80];

              in_state[2][1] <= busB[79 : 72];

              in_state[3][1] <= busB[71 : 64];



              in_state[0][2] <= busB[63 : 56];

              in_state[1][2] <= busB[55 : 48];

              in_state[2][2] <= busB[47 : 40];

              in_state[3][2] <= busB[39 : 32];



              in_state[0][3] <= busB[31 : 24];

              in_state[1][3] <= busB[23 : 16];

              in_state[2][3] <= busB[15 :  8];

              in_state[3][3] <= busB[7  :  0];

            end

          end

          else

            in_state <= out_state;

          if(!aux)

            round <= round + 1;

        end

        else

          valid_AES <= 1;



        busAES <= {out_state[0][0],out_state[1][0],out_state[2][0],out_state[3][0],

               out_state[0][1],out_state[1][1],out_state[2][1],out_state[3][1],

               out_state[0][2],out_state[1][2],out_state[2][2],out_state[3][2],

               out_state[0][3],out_state[1][3],out_state[2][3],out_state[3][3]};

      end

      if(valid_AES)

      begin

        valid_AES <= 0;

        round     <= 0;

        aux     <= 1;

      end

    end

  end

end

endmodule
