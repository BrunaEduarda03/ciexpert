#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <inttypes.h>
#include "svdpi.h"

uint64_t refmod(uint64_t a, uint64_t b, bool en_log) {
  uint64_t r = 0;

  if(en_log) {
    printf("\n\r");
    printf("# ---------------------------\n");
    printf("# refmod execution\n");
    printf("# ---------------------------\n");
  }
  return r;
}