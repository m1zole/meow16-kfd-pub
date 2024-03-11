//
//  kread_IOSurface.c
//  kfd
//
//  Created by Lars Fröder on 29.07.23.
//

#ifndef kread_IOSurface_h
#define kread_IOSurface_h

#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <mach-o/reloc.h>

#include "../../../libkfd.h"

#include "../IOSurface_shared.h"
#include "../../info.h"
#include "../../info/dynamic_types/IOSurface.h"
#include "../kwrite/kwrite_IOSurface.h"

extern io_connect_t g_surfaceConnect;

void kread_IOSurface_init(struct kfd* kfd);
void kread_IOSurface_allocate(struct kfd* kfd, uint64_t id);
bool kread_IOSurface_search(struct kfd* kfd, uint64_t object_uaddr);
void kread_IOSurface_kread(struct kfd* kfd, uint64_t kaddr, void* uaddr, uint64_t size);
void get_kernel_section(struct kfd* kfd, uint64_t kernel_base, const char *segment, const char *section, uint64_t *addr_out, uint64_t *size_out);
uint64_t patchfind_kernproc(struct kfd* kfd, uint64_t kernel_base);
void kread_IOSurface_find_proc(struct kfd* kfd);
void kread_IOSurface_deallocate(struct kfd* kfd, uint64_t id);
void kread_IOSurface_free(struct kfd* kfd);
uint32_t kread_IOSurface_kread_u32(struct kfd* kfd, uint64_t kaddr);

#endif /* kread_IOSurface_h */
