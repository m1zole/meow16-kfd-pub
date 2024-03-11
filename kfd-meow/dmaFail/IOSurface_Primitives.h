//
//  IOSurface_Permissive.h
//  kfd-meow
//
//  Created by mizole on 2024/01/08.
//

#ifndef IOSurface_Permissive_h
#define IOSurface_Permissive_h

#import <Foundation/Foundation.h>
#import <IOSurface/IOSurfaceRef.h>
#import <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <os/log.h>
#include "IOSurface_Primitives.h"
#include "../kfd/libkfd.h"

uint64_t ipc_find_port(mach_port_t port_name);
uint64_t ipc_entry_lookup(mach_port_name_t port_name);
void *IOSurface_map(uint64_t phys, uint64_t size);
uint64_t IOSurface_kalloc(uint64_t size, bool leak);

#endif /* IOSurface_Permissive_h */
