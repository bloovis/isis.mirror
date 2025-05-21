#include <stdio.h>
#include <stdlib.h>

void dump_buf(const unsigned char *buf, int len, const char *prefix)
{
  int i;

  for (i = 0; i < len; i++) {
    if ((i & 0xf) == 0)
      printf("%s", prefix);
    printf("%02x", buf[i]);
    if ((i & 0xf) == 0x0f || i == len - 1)
      printf("\n");
    else
      printf(" ");
  }
}

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

/* Print a length-preceded name, and return the length of the name + 1
 */
int print_name(const unsigned char *buf)
{
  int nlen, i;

  nlen = buf[0] & 0xff;
  for (i = 0; i < nlen; i++)
    printf("%c", buf[i+1]);
  return nlen + 1;
}
  
/* Get the 16-bit word at buf.
 */
unsigned int get_word(const unsigned char *buf)
{
  return (buf[1] << 8) + buf[0];
}

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
  
void dump_content(const unsigned char *buf, int len)
{
  printf("Content\n");
  printf("  Segment %s\n", seg_name(buf[0]));
  printf("  Offset  0x%x\n", get_word(&buf[1]));
  printf("  Length  0x%x\n", len -3);
  printf("  Data:\n");
  dump_buf(&buf[3], len - 3, "    ");
}

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

void dump_reloc(const unsigned char *buf, int len)
{
  int i;
  
  printf("Relocation\n");
  printf("  Type: %s\n", lo_hi_both(buf[0]));
  printf("  Offsets:\n");
  for (i = 1; i < len; i += 2)
    printf("    0x%x\n", get_word(&buf[i]));
}

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


void dump_unknown(int rectype, const unsigned char *buf, int len)
{
  printf("Record type 0x%x, data length 0x%x\n", rectype, len);
  dump_buf(buf, len, "  ");
}

void dump(FILE *f)
{
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
      case 0x04:
	printf("Module END\n");
	dump_buf(buf, len, "  ");
	break;
      case 0x0e:
	printf("EOF\n");
	return;
      default:
        dump_unknown(rectype, buf, len);
	break;
      }
      
    printf("\n");
  }
}

int main(int argc, char *argv[])
{
  int i;
  FILE *f;

  for (i = 1; i < argc; i++) {
    const char *filename = argv[i];
    f = fopen(filename, "r");
    if (f)
      dump(f);
    else
      printf("Unable to open %s\n", filename);
  }
  return 0;
}
