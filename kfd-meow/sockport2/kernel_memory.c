//
//  kernel_memory.c
//  sock_port
//
//  Created by Jake James on 7/18/19.
//  Copyright © 2019 Jake James. All rights reserved.
//

#include "kernel_memory.h"

static mach_port_t tfpzero;
static uint64_t task_self;

void init_kernel_memory(mach_port_t tfp0, addr_t our_port_addr) {
    tfpzero = tfp0;
    task_self = our_port_addr;
}

uint64_t kalloc(vm_size_t size) {
    mach_vm_address_t address = 0;
    mach_vm_allocate(tfpzero, (mach_vm_address_t *)&address, size, VM_FLAGS_ANYWHERE);
    return address;
}

void kfree(mach_vm_address_t address, vm_size_t size) {
    mach_vm_deallocate(tfpzero, address, size);
}

kern_return_t copyin_sp(void* to, addr_t from, size_t size)
{
    kern_return_t r = KERN_SUCCESS;
    
    mach_vm_size_t outsize = size;
    size_t szt = size;
    if (size > 0x800)
    {
        size = 0x800;
    }
    size_t off = 0;
    while (1)
    {
        r = mach_vm_read_overwrite(tfpzero, off+from, size, (mach_vm_offset_t)(off+to), &outsize);
        szt -= size;
        off += size;
        if (szt == 0)
        {
            break;
        }
        size = szt;
        if (size > 0x800)
        {
            size = 0x800;
        }
    }
    return r;
}

kern_return_t copyout_sp(addr_t to, void* from, size_t size)
{
    return mach_vm_write(tfpzero, to, (vm_offset_t)from, (mach_msg_type_number_t)size);
}

void kreadbuf_sp(addr_t va, void *ua, size_t size)
{
    uint32_t *v16 = (uint32_t*) ua;
    
    while (size) {
        size_t bytesToRead = (size > 4) ? 4 : size;
        uint32_t value = kread32_sp(va);
        va += 4;
        
        if (bytesToRead == 4) {
            *v16++ = value;
        } else {
            memcpy(ua, &value, bytesToRead);
        }
        
        size -= bytesToRead;
    }
}

uint64_t kread64_sp(addr_t va)
{
    uint64_t val = 0;
    if(copyin_sp(&val, va, 8) == KERN_SUCCESS)
    {
        return val;
    }
    return 0;
}

uint32_t kread32_sp(addr_t va)
{
    uint32_t val = 0;
    if(copyin_sp(&val, va, 4) == KERN_SUCCESS)
    {
        return val;
    }
    return 0;
}

uint16_t kread16_sp(addr_t va)
{
    uint16_t val = 0;
    if(copyin_sp(&val, va, 2) == KERN_SUCCESS)
    {
        return val;
    }
    return 0;
}

uint8_t kread8_sp(addr_t va)
{
    uint8_t val = 0;
    if(copyin_sp(&val, va, 1) == KERN_SUCCESS)
    {
        return val;
    }
    return 0;
}

addr_t kreadptr_sp(addr_t va)
{
#ifdef __LP64__
    return kread64_sp(va);
#else
    return kread32_sp(va);
#endif
}

void kwritebuf_sp(addr_t va, const void *ua, size_t size)
{
    uint8_t *v8 = (uint8_t*) ua;
    
    while (size >= 4) {
        kwrite32_sp(va, *(uint32_t*)v8);
        size -= 4;
        v8 += 4;
        va += 4;
    }
    
    if (size) {
        uint32_t val = kread32_sp(va);
        memcpy(&val, v8, size);
        kwrite32_sp(va, val);
    }
}

void kwrite64_sp(addr_t va, uint64_t val)
{
    copyout_sp(va, &val, 8);
}

void kwrite32_sp(addr_t va, uint32_t val)
{
    copyout_sp(va, &val, 4);
}

void kwrite16_sp(addr_t va, uint16_t val)
{
    copyout_sp(va, &val, 2);
}

void kwrite8_sp(addr_t va, uint8_t val)
{
    copyout_sp(va, &val, 1);
}

void kwriteptr_sp(addr_t va, addr_t val)
{
#ifdef __LP64__
    return kwrite64_sp(va, val);
#else
    return kwrite32_sp(va, val);
#endif
}

uint64_t find_port(mach_port_name_t port) {
    uint64_t task_addr = kread64_sp(task_self + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
    uint64_t itk_space = kread64_sp(task_addr + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t is_table = kread64_sp(itk_space + koffset(KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE));
    
    uint32_t port_index = port >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    
    uint64_t port_addr = kread64_sp(is_table + (port_index * sizeof_ipc_entry_t));
    
    return port_addr;
}
