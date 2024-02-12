//
//  kcall16.h
//  meow
//
//  Created by mizole on 2023/12/21.
//

#ifndef kcall16_h
#define kcall16_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/mach_time.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <CoreFoundation/CoreFoundation.h>
#include "libmeow.h"
#include "libkfd.h"
#include "IOSurface_Primitives.h"

bool init_kcall(bool early);
bool setup_client(void);
uint64_t early_kcall(uint64_t addr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3, uint64_t x4, uint64_t x5, uint64_t x6);
uint64_t mach_kalloc(size_t size);

#endif /* kcall16_h */
