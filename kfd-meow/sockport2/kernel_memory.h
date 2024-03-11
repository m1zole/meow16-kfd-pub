//
//  kernel_memory.h
//  sock_port
//
//  Created by Jake James on 7/18/19.
//  Copyright © 2019 Jake James. All rights reserved.
//

#ifndef kernel_memory_h
#define kernel_memory_h

#include <stdio.h>
#include <mach/mach.h>
#include "offsets.h"
#include "sockport2.h"

kern_return_t mach_vm_allocate(vm_map_t target, mach_vm_address_t *address, mach_vm_size_t size, int flags);
kern_return_t mach_vm_read_overwrite(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, mach_vm_address_t data, mach_vm_size_t *outsize);
kern_return_t mach_vm_write(vm_map_t target_task, mach_vm_address_t address, vm_offset_t data, mach_msg_type_number_t dataCnt);
kern_return_t mach_vm_deallocate(vm_map_t target, mach_vm_address_t address, mach_vm_size_t size);;
kern_return_t mach_vm_read(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt);

void init_kernel_memory(mach_port_t tfp0, addr_t our_port_addr);

void kfree(mach_vm_address_t address, vm_size_t size);
uint64_t kalloc(vm_size_t size);

uint64_t find_port(mach_port_name_t port);

#endif /* kernel_memory_h */
