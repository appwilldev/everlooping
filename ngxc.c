#include<stdio.h>
typedef unsigned char u_char;

u_char *ngx_hex_dump(u_char * dst, u_char * src, size_t len){
  static u_char hex[] = "0123456789abcdef";

  while(len--){
    *dst++ = hex[*src >> 4];
    *dst++ = hex[*src++ & 0xf];
  }

  return dst;
}
