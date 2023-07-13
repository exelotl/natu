#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <setjmp.h>
#include <acsl.h>
#include <math.h>
#include <stdint.h>

/* This is just a compilation test, not intended to be run */

typedef struct {int a;} s;

void output(char c) {}
char buf1[8], buf2[8];

int main()
{
  system("k"); // call the last unimplemented function to check it's correct

  void *p = malloc(1);
  if (rand()) p = calloc(1,1);
  if (rand()) p = realloc(0,0);
  free(p);
  int i = offsetof(s,a);
  fopen(0, 0);
  i = strlen(malloc(1));
  fwrite(0, 0, 0, 0);
  jmp_buf j;
  setjmp(j);
  srand(0);

  memcpy(malloc(1),malloc(1),99);
  memmove(buf1,buf1+1,99);
  strcpy(malloc(1),malloc(1));
  strncpy(malloc(1),malloc(1),99);
  strcat(malloc(1),malloc(1));
  strncat(malloc(1),malloc(1),99);
  if (memcmp(malloc(1),malloc(1),99)) p = malloc(1);
  if (strcmp(malloc(1),malloc(1))) p = malloc(1);
  if (strcoll(malloc(1),malloc(1))) p = malloc(1);
  if (strncmp(malloc(1),malloc(1),99)) p = malloc(1);
  strxfrm(malloc(1),malloc(1),99);
  if (memchr(malloc(1),99,99)) p = malloc(1);
  if (strchr(malloc(1),99)) p = malloc(1);
  memset(malloc(1),99,99);

  if (fabs(rand()) == 0) p = malloc(1);
  if (fabsf(rand()) == 0) p = malloc(1);
  perror("blah");
  if (getenv("abc")) system("dir");

  free(p); // without this, gcc plays smart and doesn't link the functions
  // longjmp is noreturn; place last
  longjmp(j,0);
}
