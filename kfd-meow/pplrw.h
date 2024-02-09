//
//  pplrw.h
//  kfd-meow
//
//  Created by mizole on 2024/01/08.
//

#ifndef pplrw_h
#define pplrw_h

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <sys/sysctl.h>
#include "libkfd.h"
#include "utils.h"
#include "IOSurface_Primitives.h"

int test_pplrw(void);
int test_ktrr(void);

void dma_perform(void (^block)(void));
void dma_writephys64(uint64_t pa, uint64_t val);
void dma_writephys32(uint64_t pa, uint32_t val);
void dma_writephys16(uint64_t pa, uint16_t val);
void dma_writephys8(uint64_t pa, uint8_t val);
void dma_writevirt64(uint64_t pa, uint64_t val);
void dma_writevirt32(uint64_t pa, uint32_t val);
void dma_writevirt16(uint64_t pa, uint16_t val);
void dma_writevirt8(uint64_t pa, uint8_t val);
void dma_writephysbuf(uint64_t pa, const void *input, size_t size);
void dma_writevirtbuf(uint64_t kaddr, const void* input, size_t size);


#endif /* pplrw_h */
