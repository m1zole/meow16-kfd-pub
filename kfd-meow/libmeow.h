//
//  libmeow.h
//  kfd-meow
//
//  Created by doraaa on 2023/12/17.
//

#ifndef libmeow_h
#define libmeow_h

#include <CoreFoundation/CoreFoundation.h>

#include "kcall.h"
#include "troll.h"
#include "pplrw.h"
#include "libkfd.h"
#include "utils.h"
#include "meowfinder.h"

extern uint64_t kernel_base;
extern uint64_t kernel_slide;

extern bool has_physrw;

extern uint64_t our_task;
extern uint64_t our_proc;
extern uint64_t kern_task;
extern uint64_t kernproc;
extern uint64_t our_ucred;
extern uint64_t kern_ucred;

extern uint64_t gCpuTTEP;
extern uint64_t gPhysBase;
extern uint64_t gPhysSize;
extern uint64_t gVirtBase;

extern uint64_t data__gCpuTTEP;
extern uint64_t data__gVirtBase;
extern uint64_t data__gPhysBase;

extern uint64_t add_x0_x0_0x40;
extern uint64_t container_init;
extern uint64_t iogettargetand;
extern uint64_t empty_kdata;
extern uint64_t mach_vm_alloc;
extern uint64_t trust_caches;
extern uint64_t ml_phys_read;
extern uint64_t ml_phys_write;
extern uint64_t pmap_enter_options;
extern uint64_t pmap_remove_options;


#define VM_KERN_MEMORY_BSD 2
#ifndef IO_OBJECT_NULL
#define IO_OBJECT_NULL 0
#endif

typedef mach_port_t io_connect_t;
typedef mach_port_t io_service_t;
typedef mach_port_t io_iterator_t;
typedef mach_port_t io_object_t;
typedef mach_port_t io_registry_entry_t;
typedef char io_string_t[512];
typedef UInt32 IOOptionBits;

extern const mach_port_t kIOMasterPortDefault;
kern_return_t IOConnectTrap6(io_connect_t connect, uint32_t index, uintptr_t p1, uintptr_t p2, uintptr_t p3, uintptr_t p4, uintptr_t p5, uintptr_t p6);
io_service_t IOServiceGetMatchingService(mach_port_t mainPort, CFDictionaryRef matching CF_RELEASES_ARGUMENT);
CFMutableDictionaryRef IOServiceMatching(const char *name);
kern_return_t IOServiceOpen(io_service_t service, task_port_t owningTask, uint32_t type,io_connect_t *connect);
kern_return_t IOServiceClose(io_connect_t connect);
kern_return_t IOObjectRelease(io_object_t object);
io_registry_entry_t IORegistryEntryFromPath(mach_port_t mainPort, const io_string_t path);
CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);

void set_offsets(void);

uint64_t proc_of_pid(pid_t target);
uint64_t proc_get_proc_ro(uint64_t proc_ptr);
uint64_t proc_ro_get_ucred(uint64_t proc_ro_ptr);
uint64_t proc_get_ucred(uint64_t proc_ptr);
void proc_ro_set_ucred(uint64_t proc_ro_ptr, uint64_t ucred_ptr);
uint64_t proc_get_ucred(uint64_t proc_ptr);
void proc_set_ucred(uint64_t proc_ptr, uint64_t ucred_ptr);
uint32_t proc_get_csflags(uint64_t proc);
void proc_set_csflags(uint64_t proc, uint32_t csflags);
uint32_t proc_get_uid(uint64_t proc_ptr);
void proc_set_uid(uint64_t proc_ptr, uid_t uid);
uint32_t proc_get_ruid(uint64_t proc_ptr);
void proc_set_ruid(uint64_t proc_ptr, uid_t ruid);
uint32_t proc_get_gid(uint64_t proc_ptr);
void proc_set_gid(uint64_t proc_ptr, uid_t uid);
uint32_t proc_get_rgid(uint64_t proc_ptr);
void proc_set_rgid(uint64_t proc_ptr, uid_t ruid);
uint32_t proc_get_svuid(uint64_t proc_ptr);
void proc_set_svuid(uint64_t proc_ptr, uid_t svuid);
uint32_t proc_get_svgid(uint64_t proc_ptr);
void proc_set_svgid(uint64_t proc_ptr, uid_t svgid);
uint32_t proc_get_p_flag(uint64_t proc_ptr);
void proc_set_p_flag(uint64_t proc_ptr, uint32_t p_flag);
uint32_t ucred_get_uid(uint64_t ucred_ptr);
void ucred_set_uid(uint64_t ucred_ptr, uint32_t uid);
uint32_t ucred_get_svuid(uint64_t ucred_ptr);
void ucred_set_svuid(uint64_t ucred_ptr, uint32_t svuid);
uint32_t ucred_get_cr_groups(uint64_t ucred_ptr);
void ucred_set_cr_groups(uint64_t ucred_ptr, uint32_t cr_groups);
uint32_t ucred_get_svgid(uint64_t ucred_ptr);
void ucred_set_svgid(uint64_t ucred_ptr, uint32_t svgid);
uint64_t ucred_get_cr_label(uint64_t ucred_ptr);

uint64_t physread64(uint64_t pa);
void physwrite64(uint64_t pa, uint64_t val);
void physreadbuf(uint64_t pa, void* ua, size_t size);
void physwritebuf(uint64_t pa, const void* ua, size_t size);

uint64_t kread64(uint64_t va);
uint32_t kread32(uint64_t va);
uint16_t kread16(uint64_t va);
uint8_t kread8(uint64_t va);
void kwrite64(uint64_t va, uint64_t val);
void kwrite32(uint64_t va, uint32_t val);
void kwrite16(uint64_t va, uint16_t val);
void kwrite8(uint64_t va, uint8_t val);

void kreadbuf(uint64_t va, void* ua, size_t size);
void kwritebuf(uint64_t va, const void* ua, size_t size);

uint64_t kreadptr(uint64_t va);

#endif /* libmeow_h */
