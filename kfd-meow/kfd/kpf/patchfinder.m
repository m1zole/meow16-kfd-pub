//
//  patchfinder.m
//  kfd
//
//  Created by Seo Hyun-gyu on 1/8/24.
//

#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import <sys/mount.h>
#import "patchfinder.h"
#import "libdimentio.h"
#import "../libkfd.h"

bool did_patchfinder = false;

int do_dynamic_patchfinder(struct kfd* kfd, uint64_t kbase) {
    uint64_t kslide = kbase - 0xFFFFFFF007004000;
    set_kbase(kbase);
    set_kfd(kfd);
    pfinder_t pfinder;
    if(pfinder_init(&pfinder) == KERN_SUCCESS) {
        printf("pfinder_init: success!\n");
        
        uint64_t gPhysBase = pfinder_gPhysBase(pfinder);
        if(gPhysBase) kaddr_gPhysBase = gPhysBase - kslide;
        printf("gPhysBase: 0x%llx\n", kaddr_gPhysBase);
        
        uint64_t gPhysSize = pfinder_gPhysSize(pfinder);
        if(gPhysSize) kaddr_gPhysSize = gPhysSize - kslide;
        printf("gPhysSize: 0x%llx\n", kaddr_gPhysSize);
        
        uint64_t gVirtBase = pfinder_gVirtBase(pfinder);
        if(gVirtBase) kaddr_gVirtBase = gVirtBase - kslide;
        printf("gVirtBase: 0x%llx\n", kaddr_gVirtBase);
        
        uint64_t ptov_table = pfinder_ptov_table(pfinder);
        if(ptov_table) kaddr_ptov_table = ptov_table - kslide;
        printf("ptov_table: 0x%llx\n", kaddr_ptov_table);
        
        if(isarm64e()){
            uint64_t cdevsw = pfinder_cdevsw(pfinder);
            if(cdevsw) kaddr_cdevsw = cdevsw - kslide;
            printf("cdevsw: 0x%llx\n", kaddr_cdevsw);
            
            uint64_t perfmon_dev_open = pfinder_perfmon_dev_open(pfinder);
            if(perfmon_dev_open) kaddr_perfmon_dev_open = perfmon_dev_open - kslide;
            printf("perfmon_dev_open: 0x%llx\n", kaddr_perfmon_dev_open);
            
            uint64_t perfmon_devices = pfinder_perfmon_devices(pfinder);
            if(perfmon_devices) kaddr_perfmon_devices = perfmon_devices - kslide;
            printf("perfmon_devices: 0x%llx\n", kaddr_perfmon_devices);
        }
        
    } else {
        printf("failed to init patchfinder\n");
    }
    save_kfd_offsets();
    pfinder_term(&pfinder);
    return 0;
}

const char* get_kernversion(void) {
    char kern_version[512] = {};
    size_t size = sizeof(kern_version);
    sysctlbyname("kern.version", &kern_version, &size, NULL, 0);

    return strdup(kern_version);;
}

int import_kfd_offsets(void) {
    NSString* save_path = [NSString stringWithFormat:@"%@/Documents/kfund_offsets.plist", NSHomeDirectory()];
    if(access(save_path.UTF8String, F_OK) == -1)
        return -1;

    NSDictionary *offsets = [NSDictionary dictionaryWithContentsOfFile:save_path];
    NSString *saved_kern_version = [offsets objectForKey:@"kern_version"];
    if(strcmp(get_kernversion(), saved_kern_version.UTF8String) != 0)
        return -1;

    kaddr_gPhysBase = [offsets[@"off_gPhysBase"] unsignedLongLongValue];
    kaddr_gPhysSize = [offsets[@"off_gPhysSize"] unsignedLongLongValue];
    kaddr_gVirtBase = [offsets[@"off_gVirtBase"] unsignedLongLongValue];
    kaddr_ptov_table = [offsets[@"off_ptov_table"] unsignedLongLongValue];
    if(isarm64e()) {
        kaddr_cdevsw = [offsets[@"off_cdevsw"] unsignedLongLongValue];
        kaddr_perfmon_dev_open = [offsets[@"off_perfmon_dev_open"] unsignedLongLongValue];
        kaddr_perfmon_devices = [offsets[@"off_perfmon_devices"] unsignedLongLongValue];
    }

    return 0;
}

int save_kfd_offsets(void) {
    NSString* save_path = [NSString stringWithFormat:@"%@/Documents/kfund_offsets.plist", NSHomeDirectory()];
    remove(save_path.UTF8String);

    NSDictionary *offsets = @{};
    if(isarm64e()) {
        offsets = @{
            @"kern_version": @(get_kernversion()),
            @"off_cdevsw": @(kaddr_cdevsw),
            @"off_gPhysBase": @(kaddr_gPhysBase),
            @"off_gPhysSize": @(kaddr_gPhysSize),
            @"off_gVirtBase": @(kaddr_gVirtBase),
            @"off_perfmon_dev_open": @(kaddr_perfmon_dev_open),
            @"off_perfmon_devices": @(kaddr_perfmon_devices),
            @"off_ptov_table": @(kaddr_ptov_table),
        };
    } else {
        offsets = @{
            @"kern_version": @(get_kernversion()),
            @"off_gPhysBase": @(kaddr_gPhysBase),
            @"off_gPhysSize": @(kaddr_gPhysSize),
            @"off_gVirtBase": @(kaddr_gVirtBase),
            @"off_ptov_table": @(kaddr_ptov_table),
        };
    }

    BOOL success = [offsets writeToFile:save_path atomically:YES];
    if (!success) {
        printf("failed to saved offsets: %s\n", save_path.UTF8String);
        return -1;
    }
    printf("saved offsets for kfd: %s\n", save_path.UTF8String);

    return 0;
}
