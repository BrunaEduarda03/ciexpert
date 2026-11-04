#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <inttypes.h>
#include "svdpi.h"

uint64_t refmod(uint64_t a, uint64_t b, bool en_log) {
  // a e b chegam do SV ja como uint64_t (longint unsigned), mas representam
  // operandos de 32 bits (op_a/op_b). A soma de dois valores de 32 bits pode
  // precisar de 33 bits para representar o carry (ex.: 0xFFFFFFFF + 0xFFFFFFFF
  // = 0x1FFFFFFFE). Se a soma fosse feita em uint32_t, o carry seria perdido
  // por overflow silencioso (wrap-around modulo 2^32). Como a e b ja sao
  // uint64_t, a soma abaixo e feita em aritmetica de 64 bits, preservando o
  // 33o bit (carry) sem qualquer risco de overflow.
  uint64_t r = a + b;

  if(en_log) {
    printf("\n\r");
    printf("# ---------------------------\n");
    printf("# refmod execution\n");
    printf("# ---------------------------\n");
    printf("# a = 0x%016" PRIx64 ", b = 0x%016" PRIx64 ", r = 0x%016" PRIx64 "\n", a, b, r);
  }
  return r;
}