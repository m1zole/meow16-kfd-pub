//
//  kcall16.h
//  meow
//
//  Created by mizole on 2023/12/21.
//

#ifndef kcall16_h
#define kcall16_h

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/mach_time.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <CoreFoundation/CoreFoundation.h>
#include "libmeow.h"
#include "libkfd.h"
#include "IOSurface_Primitives.h"

//#include "IOKit/IOKitLib.h"

#define VM_KERN_MEMORY_BSD 2
#ifndef IO_OBJECT_NULL
#define IO_OBJECT_NULL 0
#endif

typedef mach_port_t io_connect_t;
typedef mach_port_t io_service_t;
typedef mach_port_t io_iterator_t;
typedef mach_port_t io_object_t;
typedef mach_port_t io_registry_entry_t;

extern const mach_port_t kIOMasterPortDefault;
kern_return_t IOConnectTrap6(io_connect_t connect, uint32_t index, uintptr_t p1, uintptr_t p2, uintptr_t p3, uintptr_t p4, uintptr_t p5, uintptr_t p6);
io_service_t IOServiceGetMatchingService(mach_port_t mainPort, CFDictionaryRef matching CF_RELEASES_ARGUMENT);
CFMutableDictionaryRef IOServiceMatching(const char *name);
kern_return_t IOServiceOpen(io_service_t service, task_port_t owningTask, uint32_t type,io_connect_t *connect);
kern_return_t IOObjectRelease(io_object_t object);

bool init_kcall(void);
bool setup_client(void);
uint64_t eary_kcall(uint64_t addr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3, uint64_t x4, uint64_t x5, uint64_t x6);
uint64_t mach_kalloc(size_t size);

#endif /* kcall16_h */
