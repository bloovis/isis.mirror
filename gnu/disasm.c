#include <stdio.h>
#include <string.h>

struct optab {
  const char *name;	/* name of instruction */
  int len;		/* length of instruction */
} ops[256] = {
  {"nop", 1}, {"lxi b", 3},		/* 0,1 */
  {"stax b", 1}, {"inx b", 1},		/* 2,3 */
  {"inr b", 1}, {"dcr b", 1},		/* 4,5 */
  {"mvi b", 2}, {"rlc", 1},		/* 6,7 */
  {"halt", 1}, {"dad b", 1},		/* 8,9 */
  {"ldax b", 1}, {"dcx b", 1},		/* a,b */
  {"inr c", 1}, {"dcr c", 1},		/* c,d */
  {"mvi c", 2}, {"rrc", 1},		/* e,f */

  {"halt", 1}, {"lxi d", 3},		/* 10,11 */
  {"stax d", 1}, {"inx d", 1},		/* 12,13 */
  {"inr d", 1}, {"dcr d", 1},		/* 14,15 */
  {"mvi d", 2}, {"ral", 1},		/* 16,17 */
  {"halt", 1}, {"dad d", 1},		/* 18,19 */
  {"ldax d", 1}, {"dcx d", 1},		/* 1a,1b */
  {"inr e", 1}, {"dcr e", 1},		/* 1c,1d */
  {"mvi e", 2}, {"rar", 1},		/* 1e,1f */

  {"halt", 1}, {"lxi h", 3},		/* 20,21 */
  {"shld x", 3}, {"inx h", 1},		/* 22,23 */
  {"inr h", 1}, {"dcr h", 1},		/* 24,25 */
  {"mvi h", 2}, {"daa", 1},		/* 26,27 */
  {"halt", 1}, {"dad h", 1},		/* 28,29 */
  {"lhld", 3}, {"dcx h", 1},		/* 2a,2b */
  {"inr l", 1}, {"dcr l", 1},		/* 2c,2d */
  {"mvi l", 2}, {"cma", 1},		/* 2e,2f */

  {"halt", 1}, {"lxi sp", 3}, 		/* 30,31 */
  {"sta", 3}, {"inx sp", 1}, 		/* 32,33 */
  {"inr m", 1}, {"dcr m", 1},		/* 34,35 */
  {"mvi m", 2}, {"stc", 1},		/* 36,37 */
  {"halt", 1}, {"dad sp", 1}, 		/* 38,39 */
  {"lda", 3}, {"dcx sp", 1}, 		/* 3a,3b */
  {"inra", 1}, {"dcr a", 1},		/* 3c,3d */
  {"mvi a", 2}, {"cmc", 1},		/* 3e,3f */

  {"mov b,b", 1}, {"mov b,c", 1}, 	/* 40,41 */
  {"mov b,d", 1}, {"mov b,e", 1}, 	/* 42,43 */
  {"mov b,h", 1}, {"mov b,l", 1}, 	/* 44,45 */
  {"mov b,m", 1}, {"mov b,a", 1}, 	/* 46,47 */
  {"mov c,b", 1}, {"mov c,c", 1}, 	/* 48,49 */
  {"mov c,d", 1}, {"mov c,e", 1}, 	/* 4a,4b */
  {"mov c,h", 1}, {"mov c,l", 1}, 	/* 4c,4d */
  {"mov c,m", 1}, {"mov c,a", 1}, 	/* 4e,4f */

  {"mov d,b", 1}, {"mov d,c", 1}, 	/* 50,51 */
  {"mov d,d", 1}, {"mov d,e", 1}, 	/* 52,53 */
  {"mov d,h", 1}, {"mov d,l", 1}, 	/* 54,55 */
  {"mov d,m", 1}, {"mov d,a", 1}, 	/* 56,57 */
  {"mov e,b", 1}, {"mov e,c", 1}, 	/* 58,59 */
  {"mov e,d", 1}, {"mov e,e", 1}, 	/* 5a,5b */
  {"mov e,h", 1}, {"mov e,l", 1}, 	/* 5c,5d */
  {"mov e,m", 1}, {"mov e,a", 1}, 	/* 5e,5f */

  {"mov h,b", 1}, {"mov h,c", 1}, 	/* 60,61 */
  {"mov h,d", 1}, {"mov h,e", 1}, 	/* 62,63 */
  {"mov h,h", 1}, {"mov h,l", 1}, 	/* 64,65 */
  {"mov h,m", 1}, {"mov h,a", 1}, 	/* 66,67 */
  {"mov l,b", 1}, {"mov l,c", 1}, 	/* 68,69 */
  {"mov l,d", 1}, {"mov l,e", 1}, 	/* 6a,6b */
  {"mov l,h", 1}, {"mov l,l", 1}, 	/* 6c,6d */
  {"mov l,m", 1}, {"mov l,a", 1}, 	/* 6e,6f */

  {"mov m,b", 1}, {"mov m,c", 1}, 	/* 70,71 */
  {"mov m,d", 1}, {"mov m,e", 1}, 	/* 72,73 */
  {"mov m,h", 1}, {"mov m,l", 1}, 	/* 74,75 */
  {"hlt", 1},     {"mov m,a", 1}, 	/* 76,77 */
  {"mov a,b", 1}, {"mov a,c", 1}, 	/* 78,79 */
  {"mov a,d", 1}, {"mov a,e", 1}, 	/* 7a,7b */
  {"mov a,h", 1}, {"mov a,l", 1}, 	/* 7c,7d */
  {"mov a,m", 1}, {"mov a,a", 1}, 	/* 7e,7f */

  {"add b", 1}, {"add c", 1},		/* 80,81 */
  {"add d", 1}, {"add e", 1},		/* 82,83 */
  {"add h", 1}, {"add l", 1},		/* 84,85 */
  {"add m", 1}, {"add a", 1},		/* 86,87 */
  {"adc b", 1}, {"adc c", 1},		/* 88,89 */
  {"adc d", 1}, {"adc e", 1},		/* 8a,8b */
  {"adc h", 1}, {"adc l", 1},		/* 8c,8d */
  {"adc m", 1}, {"adc a", 1},		/* 8e,8f */

  {"sub b", 1}, {"sub c", 1},		/* 90,91 */
  {"sub d", 1}, {"sub e", 1},		/* 92,93 */
  {"sub h", 1}, {"sub l", 1},		/* 94,95 */
  {"sub m", 1}, {"sub a", 1},		/* 96,97 */
  {"sbb b", 1}, {"sbb c", 1},		/* 98,99 */
  {"sbb d", 1}, {"sbb e", 1},		/* 9a,9b */
  {"sbb h", 1}, {"sbb l", 1},		/* 9c,9d */
  {"sbb m", 1}, {"sbb a", 1},		/* 9e,9f */

  {"ana b", 1}, {"ana c", 1},		/* a0,a1 */
  {"ana d", 1}, {"ana e", 1},		/* a2,a3 */
  {"ana h", 1}, {"ana l", 1},		/* a4,a5 */
  {"ana m", 1}, {"ana a", 1},		/* a6,a7 */
  {"xra b", 1}, {"xra c", 1},		/* a8,a9 */
  {"xra d", 1}, {"xra e", 1},		/* aa,ab */
  {"xra h", 1}, {"xra l", 1},		/* ac,ad */
  {"xra m", 1}, {"xra a", 1},		/* ae,af */

  {"ora b", 1}, {"ora c", 1},		/* b0,b1 */
  {"ora d", 1}, {"ora e", 1},		/* b2,b3 */
  {"ora h", 1}, {"ora l", 1},		/* b4,b5 */
  {"ora m", 1}, {"ora a", 1},		/* b6,b7 */
  {"cmp b", 1}, {"cmp c", 1},		/* b8,b9 */
  {"cmp d", 1}, {"cmp e", 1},		/* ba,bb */
  {"cmp h", 1}, {"cmp l", 1},		/* bc,bd */
  {"cmp m", 1}, {"cmp a", 1},		/* be,bf */

  {"rnz", 1}, {"pop b", 1},		/* c0,c1 */
  {"jnz", 3}, {"jmp", 3},		/* c2,c3 */
  {"cnz", 3}, {"push b", 1},		/* c4,c5 */
  {"adi", 2}, {"rst 0", 1},		/* c6,c7 */
  {"rz", 1}, {"ret", 1},		/* c8,c9 */
  {"jz", 3}, {"*jmp", 3},		/* ca,cb */
  {"cz", 3}, {"call", 3},		/* cc,cd */
  {"aci", 2}, {"rst 1", 1},		/* ce,cf */

  {"rnc", 1}, {"pop d", 1},		/* d0,d1 */
  {"jnc", 3}, {"out", 2},		/* d2,d3 */
  {"cnc", 3}, {"push d", 1},		/* d4,d5 */
  {"sui", 2}, {"rst 2", 1},		/* d6,d7 */
  {"rc", 1}, {"*ret", 1},		/* d8,d9 */
  {"jc", 3}, {"in", 2},			/* da,db */
  {"cc", 3}, {"*call", 3},		/* dc,dd */
  {"sbi", 2}, {"rst 3", 1},		/* de,df */

  {"rpo", 1}, {"pop h", 1},		/* e0,e1 */
  {"jpo", 3}, {"xthl", 1},		/* e2,e3 */
  {"cpo", 3}, {"push h", 1},		/* e4,e5 */
  {"ani", 2}, {"rst 4", 1},		/* e6,e7 */
  {"rpe", 1}, {"pchl", 1},		/* e8,e9 */
  {"jpe", 3}, {"xchg", 1},		/* ea,eb */
  {"cpe", 3}, {"*call", 3},		/* ec,ed */
  {"xri", 2}, {"rst 5", 1},		/* ee,ef */

  {"rp", 1}, {"pop psw", 1},   		/* f0,f1 */
  {"jpx", 3}, {"di", 1},		/* f2,f3 */
  {"cp", 3}, {"push psw", 1},    	/* f4,f5 */
  {"ori", 2}, {"rst 5", 1},		/* f6,f7 */
  {"rm", 1}, {"sphl", 1},		/* f8,f9 */
  {"jm", 3}, {"ei", 1},		/* fa,fb */
  {"cm", 3}, {"*call", 3},		/* fc,fd */
  {"cpi", 2}, {"rst 7", 1},		/* fe,ff */
};

void disasm(const char *prefix, int offset, const unsigned char *buf, int len)
{
  int i = 0;
  int j;
  unsigned char opcode;
  struct optab *op;

  while (i < len) {
    /* Fetch the description of this instruction. */
    opcode = buf[i] & 0xff;
    op = &ops[opcode];

    /* Print the instruction address. */
    printf("%s%04x:", prefix, i + offset);

    /* Print the instruction in hex. */
    for (j = i; j < i + 3; j++) {
      if (j >= i + op->len || j >= len)
	printf("   ");
      else
	printf(" %02x", buf[j]);
    }

    /* Print the disassembly of the instruction. */
    printf("  %s", op->name);
    if (op->len > 1) {
      unsigned int operand = 0;
      if (op->len == 2)
	operand = buf[i+1] & 0xff;
      else if (op->len == 3)
	operand = ((buf[i+2] & 0xff) << 8) + (buf[i+1] & 0xff);
      else
	printf("Illegal instruction size %d for %s!\n", op->len, op->name);
      if (strchr(op->name, ' ') != NULL)
	printf(",");
      else
	printf(" ");
      printf("%xH", operand);
    }
    printf("\n");
    i += op->len;
  }
}
