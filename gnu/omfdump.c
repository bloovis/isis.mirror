#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* OMF-80 dumper */

/* External functions.
 */
extern void disasm(const char *prefix, int offset, const unsigned char *buf, int len);

/* Global variables.
 */
int doption = 0;

/* Print a buffer as hex bytes.  Return a non-zero value if the buffer
 * appears to contain machine code.
 */
int dump_buf(const char *prefix, int offset, const unsigned char *buf, int len)
{
  int i;
  int has_code = 0;

  for (i = 0; i < len; i++) {
    if ((i & 0xf) == 0)
      printf("%s%04x: ", prefix, i + offset);
    printf("%02x", buf[i]);

    /* Cheap heuristic for determining if the buffer contains code
     * that we can disassemble.
     */
    if (buf[i] >= 0x7f)
      has_code = 1;

    /* After dumping 16 bytes, or we reached the end of the buffer,
     * print those bytes again in ASCII format.
     */
    if ((i & 0xf) == 0x0f || i == len - 1) {
      int start, end;

      start = i & 0xfff0;
      for (end = i; end < start + 0x10; end++)
	printf("   ");
      while (start <= i) {
	unsigned char ch = buf[start];
	if (ch <= 0x20 || ch >= 0x7f)
	  ch = '.';
	putchar(ch);
        start++;
      }
      printf("\n");
    } else {
      if ((i & 0x3) == 0x03)
	putchar('-');
      else
	printf(" ");
    }
  }
  return has_code;
}

/* Return a segment id in string form.
 */
const char *seg_name(unsigned int segid)
{
  static char name[40];

  switch (segid)
  {
    case 0: return("Absolute");
    case 1: return("Code");
    case 2: return("Data");
    case 3: return("Stack");
    case 4: return("Memory");
    default:
      snprintf(name, sizeof(name), "Segment %d", segid);
      return name;
  }
}

/* Print a length-preceded name, and return the length of the name + 1.
 */
int print_name(const unsigned char *buf)
{
  int nlen, i;

  nlen = buf[0] & 0xff;
  for (i = 0; i < nlen; i++)
    putchar(buf[i+1]);
  return nlen + 1;
}
  
/* Return the little-endian 16-bit word at buf.
 */
unsigned int get_word(const unsigned char *buf)
{
  return (buf[1] << 8) + buf[0];
}

/* Dump a module header record.
 */
void dump_modhdr(const unsigned char *buf, int len)
{
  int i;

  printf("Module Header\n");
  printf("  name: ");
  i = print_name(buf);
  printf("\n");
  printf("  trnid: %d\n", buf[i]);
  printf("  trnvn: %d\n", buf[i+1]);
  i = i + 2;
  while (i <= len - 4) {
    printf("  segment %s, length 0x%x, alignment type %d\n",
	   seg_name(buf[i]), get_word(&buf[i+1]), buf[i+3]);
    i += 4;
  }
}

/* Dump an external names record.
 */
void dump_extnames(const unsigned char *buf, int len)
{
  int i = 0, index = 0;

  printf("External Names\n");
  while (i < len) {
    printf("  [%d] ", index);
    i += print_name(&buf[i]) + 1;	/* skip reserved byte after name */
    printf("\n");
    index++;
  }
}
  
/* Dump a content record.
 */
void dump_content(const unsigned char *buf, int len)
{
  int offset, has_code;

  printf("Content\n");
  printf("  Segment %s\n", seg_name(buf[0]));
  offset = get_word(&buf[1]);
  printf("  Offset  0x%x\n", offset);
  printf("  Length  0x%x\n", len -3);
  printf("  Data:\n");
  has_code = dump_buf("    ", offset, &buf[3], len - 3);
  if (has_code && doption) {
    printf("\n");
    disasm("    ", offset, &buf[3], len - 3);
  }
}

/* Return a low/high/both relocation type in string form.
 */
const char *lo_hi_both(unsigned char n)
{
  switch (n)
  {
    case 1: return "Low-order byte";
    case 2: return "High-order byte";
    case 3: return "Both bytes";
    default: return "Unknown";
  }
}

/* Dump a relocation record.
 */
void dump_reloc(const unsigned char *buf, int len)
{
  int i;
  
  printf("Relocation\n");
  printf("  Type: %s\n", lo_hi_both(buf[0]));
  printf("  Offsets:\n");
  for (i = 1; i < len; i += 2)
    printf("    0x%x\n", get_word(&buf[i]));
}

/* Dump an external references record.
 */
void dump_extrefs(const unsigned char *buf, int len)
{
  int i;

  printf("External References\n");
  printf("  Type: %s\n", lo_hi_both(buf[0]));
  i = 1;
  while (i < len) {
    printf("  Index: %d, Offset: 0x%x\n", get_word(&buf[i]), get_word(&buf[i+2]));
    i += 4;
  }
}

/* Dump an inter-segment references record.
 */
void dump_inter_seg_refs(const unsigned char *buf, int len)
{
  int i;
  
  printf("Inter-segment References\n");
  printf("  Segment %s\n", seg_name(buf[0]));
  printf("  Type %s\n", lo_hi_both(buf[1]));
  i = 2;
  while (i < len) {
    printf("    Offset: 0x%x\n", get_word(&buf[i]));
    i += 2;
  }
}

/* Dump a public declarations record.
 */
void dump_pubdecs(const unsigned char *buf, int len)
{
  int i;

  printf("Public Declarations\n");
  printf("  Segment %s\n", seg_name(buf[0]));
  i = 1;
  while (i < len) {
    printf("    Offset: 0x%x, Name: ", get_word(&buf[i]));
    i += 2;
    i += print_name(&buf[i]) + 1;	/* skip reserved byte after name */
    printf("\n");
  }
}

/* Dump a module end record.
 */
void dump_modend(const unsigned char *buf, int len)
{
  printf("Module End\n");
  printf("  Type: %smain program\n", buf[0] == 0 ? "not a " : "");
  printf("  Segment %s\n", seg_name(buf[1]));
  printf("  Offset  0x%x\n", get_word(&buf[2]));
}

/* Dump a library header record.
 */
void dump_libhdr(const unsigned char *buf, int len)
{
  int block, byte, offset;

  printf("Library Header\n");
  printf("  Module count: %d\n", get_word(&buf[0]));
  block = get_word(&buf[2]);
  byte = get_word(&buf[4]);
  offset = block * 128 + byte;
  printf("  Offset of Library Module Names Record: 0x%x\n", offset);
}

/* Dump a library module names record.
 */
void dump_modnames(const unsigned char *buf, int len)
{
  int i = 0;
  int index = 0;

  printf("Library Module Names\n");
  while (i < len) {
    printf("  [%d] ", index);
    i += print_name(&buf[i]);
    printf("\n");
    index++;
  }
}

/* Dump a library module locations record.
 */
void dump_modlocs(const unsigned char *buf, int len)
{
  int i = 0;
  int index = 0;
  int block, byte, offset;

  printf("Library Module Locations\n");
  while (i < len) {
    block = get_word(&buf[i]);
    byte = get_word(&buf[i+2]);
    offset = block * 128 + byte;
    printf("  [%d] offset 0x%x\n", index, offset);
    i += 4;
    index++;
  }
}

/* Dump a library dictionary record.
 */
void dump_libdict(const unsigned char *buf, int len)
{
  int i = 0;
  int index = 0;

  printf("Library Dictionary\n");
  while (i < len) {
    printf("  Module %d:\n", index);
    while (buf[i] != 0) {
      printf("    ");
      i += print_name(&buf[i]);
      printf("\n");
    }
    i++;
    index++;
  }
}

/* Dump an unknown record.
 */
void dump_unknown(int rectype, const unsigned char *buf, int len)
{
  printf("Record type 0x%x, data length 0x%x\n", rectype, len);
  dump_buf("  ", 0, buf, len);
}

/* Dump a single file.
 */
void dump(FILE *f)
{
  int offset = 0;

  while (1) {
    int rectype, reclen, byte, nread, len;
    unsigned char *buf = NULL;
    int buflen = 0;
    int i;
    unsigned char chksum;

    /* Read record type */
    rectype = fgetc(f);
    if (rectype == EOF) {
      printf("premature EOF reading record type\n");
      return;
    }
    chksum = rectype & 0xff;

    /* Read record length (little-endian 16-bit word) */
    byte = fgetc(f);
    chksum += byte;
    if (byte == EOF) {
      printf("premature EOF reading record length\n");
      return;
    }
    reclen = byte;

    byte = fgetc(f);
    chksum += byte;
    if (byte == EOF) {
      printf("premature EOF reading record length\n");
      return;
    }
    reclen = (byte << 8) + reclen;

    /* Read the data into the buffer.  The record length includes
     * the checksum byte, so don't read that into the buffer.
     */
    len = reclen - 1;
    if (len > buflen) {
      buflen = len;
      buf = realloc(buf, buflen);
      if (buf == NULL) {
	printf("Unable to allocate buffer of %d bytes\n", reclen);
        return;
      }
    }
    nread = fread(buf, 1, len, f);
    if (nread != len) {
      printf("Read %d bytes, expected %d\n", nread, len);
      return;
    }
    for (i = 0; i < len; i++) {
      chksum += buf[i];
    }

    /* Read the checksum byte and validate it. */
    byte = fgetc(f);
    if (byte == EOF) {
      printf("premature EOF reading checksum byte\n");
      return;
    }
    chksum += byte;
    if (chksum != 0) {
      printf("Checksum was 0x%x, expected 0\n", chksum);
      return;
    }

    printf("[%04x] ", offset);
    switch (rectype) {
      case 0x02:
	dump_modhdr(buf, len);
	break;
      case 0x18:
	dump_extnames(buf, len);
	break;
      case 0x06:
	dump_content(buf, len);
	break;
      case 0x22:
	dump_reloc(buf, len);
	break;
      case 0x20:
	dump_extrefs(buf, len);
	break;
      case 0x24:
	dump_inter_seg_refs(buf, len);
	break;
      case 0x16:
	dump_pubdecs(buf, len);
	break;
      case 0x04:
	dump_modend(buf, len);
	break;
      case 0x0e:
	printf("EOF\n");
	return;
      case 0x2c:
	dump_libhdr(buf, len);
	break;
      case 0x28:
	dump_modnames(buf, len);
	break;
      case 0x26:
	dump_modlocs(buf, len);
	break;
      case 0x2a:
	dump_libdict(buf, len);
	break;
      default:
        dump_unknown(rectype, buf, len);
	break;
    }
    printf("\n");
    offset += reclen + 3;
  }
}

int main(int argc, char *argv[])
{
  int i;
  FILE *f;

  if (argc == 1) {
    puts("usage: omdump [-d] file...");
    puts("-d : disassemble code contents");
    return 1;
  }
  for (i = 1; i < argc; i++) {
    const char *filename = argv[i];

    if (strcmp(filename, "-d") == 0)
      doption = 1;
    else {
      f = fopen(filename, "r");
      if (f)
	dump(f);
      else
	printf("Unable to open %s\n", filename);
    }
  }
  return 0;
}
