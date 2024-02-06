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
    
    init_kcall(true);
    
    usleep(5000);
    printf("access(%s) : %d\n", "/var/root/Library", access("/var/root/Library", R_OK));
    proc_set_svuid(our_proc, 0);
    proc_set_svgid(our_proc, 0);
    proc_set_ucred(our_proc, kern_ucred);
    setuid(0);
    
    printf("getuid() : %d\n", getuid());
    printf("access(%s) : %d\n", "/var/root/Library", access("/var/root/Library", R_OK));
    
    NSString *tips = find_tips();
    NSLog(@"%@", tips);
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", tips, @"/Tips"] toPath:[NSString stringWithFormat:@"%@%@", tips, @"/Tips_TROLLSTORE_BACKUP"] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", tips, @"/Tips"] error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/PersistenceHelper_Embedded"] toPath:[NSString stringWithFormat:@"%@%@", tips, @"/Tips"] error:nil];
    chmod([NSString stringWithFormat:@"%@%@", tips, @"/Tips"].UTF8String, 755);
    
    proc_set_svuid(our_proc, 501);
    proc_set_svgid(our_proc, 501);
    proc_set_ucred(our_proc, our_ucred);
    setuid(501);
}
