//
//  iokit.h
//  kfd-meow
//
//  Created by mizole on 2024/02/16.
//

#ifndef iokit_h
#define iokit_h

#include <CoreFoundation/CoreFoundation.h>
#include <device/device_types.h>
#include <stdint.h>

#define VM_KERN_MEMORY_BSD 2
#ifndef IO_OBJECT_NULL
#define IO_OBJECT_NULL 0
#endif

#define kOSSerializeBinarySignature        0x000000D3
#define kOSSerializeIndexedBinarySignature 0x000000D4

enum {
    kOSSerializeDictionary          = 0x01000000U,
    kOSSerializeArray               = 0x02000000U,
    kOSSerializeSet                 = 0x03000000U,
    kOSSerializeNumber              = 0x04000000U,
    kOSSerializeSymbol              = 0x08000000U,
    kOSSerializeString              = 0x09000000U,
    kOSSerializeData                = 0x0a000000U,
    kOSSerializeBoolean             = 0x0b000000U,
    kOSSerializeObject              = 0x0c000000U,
    
    kOSSerializeTypeMask            = 0x7F000000U,
    kOSSerializeDataMask            = 0x00FFFFFFU,
    
    kOSSerializeEndCollection       = 0x80000000U,
    
    kOSSerializeMagic               = 0x000000d3U,
};

typedef mach_port_t io_connect_t;
typedef mach_port_t io_service_t;
typedef mach_port_t io_iterator_t;
typedef mach_port_t io_object_t;
typedef mach_port_t io_registry_entry_t;
typedef mach_port_t io_master_t;
typedef char io_string_t[512];
typedef UInt32 IOOptionBits;

extern const mach_port_t kIOMasterPortDefault;
kern_return_t IOConnectCallMethod(mach_port_t connection, uint32_t selector, const uint64_t *input, uint32_t inputCnt, const void *inputStruct, size_t inputStructCnt, uint64_t *output, uint32_t *outputCnt, void *outputStruct, size_t *outputStructCnt);
kern_return_t IOConnectTrap6(io_connect_t connect, uint32_t index, uintptr_t p1, uintptr_t p2, uintptr_t p3, uintptr_t p4, uintptr_t p5, uintptr_t p6);
io_service_t IOServiceGetMatchingService(mach_port_t mainPort, CFDictionaryRef matching CF_RELEASES_ARGUMENT);
CFMutableDictionaryRef IOServiceMatching(const char *name);
kern_return_t IOServiceOpen(io_service_t service, task_port_t owningTask, uint32_t type,io_connect_t *connect);
kern_return_t IOServiceClose(io_connect_t connect);
kern_return_t IOObjectRelease(io_object_t object);
io_registry_entry_t IORegistryEntryFromPath(mach_port_t mainPort, const io_string_t path);
CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);
kern_return_t IORegistryEntryGetChildIterator(io_registry_entry_t entry, const io_name_t plane, io_iterator_t * iterator);
kern_return_t IORegistryEntryGetProperty(io_registry_entry_t entry, const io_name_t propertyName, io_struct_inband_t buffer, uint32_t * size);
io_object_t IOIteratorNext(io_iterator_t iterator);

#endif /* iokit_h */
