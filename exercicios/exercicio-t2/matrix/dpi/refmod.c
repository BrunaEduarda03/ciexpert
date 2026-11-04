#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <inttypes.h>
#include "svdpi.h"

/*
 * refmod_matrix: modelo de referencia da multiplicacao de matrizes 2x2
 * (rtl/matrixmult.v), chamado via DPI-C (mesmo padrao de adder2p0/dpi/refmod.c).
 *
 * a/b chegam como uint64_t (longint unsigned) do SV, mas representam apenas
 * os 32 bits de A/B do DUT, empacotados como 4 elementos de 8 bits cada:
 *   bits [31:24] = elemento [0][0]
 *   bits [23:16] = elemento [0][1]
 *   bits [15:8]  = elemento [1][0]
 *   bits [7:0]   = elemento [1][1]
 *
 * O RTL guarda cada elemento do resultado em um registrador de 8 bits
 * (reg [7:0] Res1[0:1][0:1]), entao a soma de dois produtos de 8 bits
 * (ate 255*255 + 255*255 = 130050, que precisa de 17 bits) e TRUNCADA para
 * os 8 bits menos significativos na atribuicao -- exatamente a semantica
 * de truncamento de Verilog ao atribuir um valor largo a um reg estreito.
 * Este modelo reproduz esse truncamento explicitamente (& 0xFF), em vez de
 * saturar ou arredondar, para bater bit-a-bit com o comportamento real do
 * RTL (que nao foi alterado).
 */
uint64_t refmod_matrix(uint64_t a, uint64_t b, bool en_log) {
  uint8_t a00 = (uint8_t)((a >> 24) & 0xFF);
  uint8_t a01 = (uint8_t)((a >> 16) & 0xFF);
  uint8_t a10 = (uint8_t)((a >> 8)  & 0xFF);
  uint8_t a11 = (uint8_t)((a >> 0)  & 0xFF);

  uint8_t b00 = (uint8_t)((b >> 24) & 0xFF);
  uint8_t b01 = (uint8_t)((b >> 16) & 0xFF);
  uint8_t b10 = (uint8_t)((b >> 8)  & 0xFF);
  uint8_t b11 = (uint8_t)((b >> 0)  & 0xFF);

  uint32_t p00 = (uint32_t)a00 * b00 + (uint32_t)a01 * b10;
  uint32_t p01 = (uint32_t)a00 * b01 + (uint32_t)a01 * b11;
  uint32_t p10 = (uint32_t)a10 * b00 + (uint32_t)a11 * b10;
  uint32_t p11 = (uint32_t)a10 * b01 + (uint32_t)a11 * b11;

  uint8_t r00 = (uint8_t)(p00 & 0xFF); /* truncamento p/ 8 bits, igual ao RTL */
  uint8_t r01 = (uint8_t)(p01 & 0xFF);
  uint8_t r10 = (uint8_t)(p10 & 0xFF);
  uint8_t r11 = (uint8_t)(p11 & 0xFF);

  uint32_t res = ((uint32_t)r00 << 24) | ((uint32_t)r01 << 16) |
                 ((uint32_t)r10 << 8)  | (uint32_t)r11;

  if (en_log) {
    printf("\n\r");
    printf("# ---------------------------\n");
    printf("# refmod_matrix execution\n");
    printf("# ---------------------------\n");
    printf("# A = 0x%08" PRIx32 ", B = 0x%08" PRIx32 ", Res = 0x%08" PRIx32 "\n",
           (uint32_t)a, (uint32_t)b, res);
    printf("# p00=%u p01=%u p10=%u p11=%u (overflow se >255)\n", p00, p01, p10, p11);
  }

  return (uint64_t)res;
}
