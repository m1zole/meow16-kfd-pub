#include <stdio.h>
#include <ctype.h>
#include <CoreFoundation/CoreFoundation.h>
 
//taken from https://gist.github.com/richinseattle/c527a3acb6f152796a580401057c78b4
#ifndef HEXDUMP_COLS
#define HEXDUMP_COLS 8
#endif

void (*log_UI)(const char *text) = NULL;

static void util_vprintf(const char *fmt, va_list ap)
{
    vfprintf(stdout, fmt, ap);
    if (log_UI) {
        char ui_text[512];
        vsnprintf(ui_text, sizeof(ui_text), fmt, ap);
        log_UI(ui_text);
    }
}

void util_printf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    util_vprintf(fmt, ap);
    va_end(ap);
}

void util_hexprint(void *data, size_t len, const char *desc)
{
    uint8_t *ptr = (uint8_t *)data;
    size_t i;

    if (desc) {
        util_printf("%s\n", desc);
    }
    for (i = 0; i < len; i++) {
        if (i % 16 == 0) {
            util_printf("%04x: ", (uint16_t)i);
        }
        util_printf("%02x ", ptr[i]);
        if (i % 16 == 7) {
            util_printf(" ");
        }
        if (i % 16 == 15) {
            util_printf("\n");
        }
    }
    if (i % 16 != 0) {
        util_printf("\n");
    }
}

void hexdump(void *mem, unsigned int len)
{
        unsigned int i, j;
        
        for(i = 0; i < len + ((len % HEXDUMP_COLS) ? (HEXDUMP_COLS - len % HEXDUMP_COLS) : 0); i++)
        {
                /* print offset */
                if(i % HEXDUMP_COLS == 0)
                {
                        printf("0x%06x: ", i);
                }
 
                /* print hex data */
                if(i < len)
                {
                        printf("%02x ", 0xFF & ((char*)mem)[i]);
                }
                else /* end of block, just aligning for ASCII dump */
                {
                        printf("   ");
                }
                
                /* print ASCII dump */
                if(i % HEXDUMP_COLS == (HEXDUMP_COLS - 1))
                {
                        for(j = i - (HEXDUMP_COLS - 1); j <= i; j++)
                        {
                                if(j >= len) /* end of block, not really printing */
                                {
                                        putchar(' ');
                                }
                                else if(isprint(((char*)mem)[j])) /* printable char */
                                {
                                        putchar(0xFF & ((char*)mem)[j]);
                                }
                                else /* other char */
                                {
                                        putchar('.');
                                }
                        }
                        putchar('\n');
                }
        }
}
