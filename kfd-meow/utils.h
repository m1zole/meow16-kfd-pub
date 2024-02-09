//
//  utils.h
//  kfd-meow13
//
//  Created by mizole on 2024/01/21.
//  Copyright © 2024 coolstar. All rights reserved.
//

#ifndef utils_h
#define utils_h

#include <stdio.h>
void util_printf(const char *fmt, ...);
void util_hexprint(void *data, size_t len, const char *desc);
void hexdump(void *mem, unsigned int len);

#endif /* utils_h */
