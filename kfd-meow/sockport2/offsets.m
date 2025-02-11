#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

#import "offsets.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

int* offsets = NULL;

int kstruct_offsets_8_4[] = {
    0x0,   // KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE,      // never used
    0x0,   // KSTRUCT_OFFSET_TASK_REF_COUNT,         // never used
    0x0,   // KSTRUCT_OFFSET_TASK_ACTIVE,            // never used
    0x0,   // KSTRUCT_OFFSET_TASK_VM_MAP,            // never used
    0x30,  // KSTRUCT_OFFSET_TASK_NEXT,
    0x38,  // KSTRUCT_OFFSET_TASK_PREV,
    0x0,   // KSTRUCT_OFFSET_TASK_ITK_SELF,          // never used
    0x288, // KSTRUCT_OFFSET_TASK_ITK_SPACE
    0x2f0, // KSTRUCT_OFFSET_TASK_BSD_INFO
    
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_BITS,       // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES, // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE,     // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT,     // never used
    0x60,  // KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER
    0x68,  // KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG,     // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT,    // never used
    0x94,  // KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS     // maybe...?
    
    0x10,  // KSTRUCT_OFFSET_PROC_PID
    0xF0,  // KSTRUCT_OFFSET_PROC_P_FD
    
    0x0,   // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    
    0x8,   // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    
    0x38,  // KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    
    0x0,   // KSTRUCT_OFFSET_SOCKET_SO_PCB           //never used
    
    0x10,  // KSTRUCT_OFFSET_PIPE_BUFFER
    
    0x0,   // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE //never used
    0x20,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE
    
    0x0,   // KFREE_ADDR_OFFSET                      //never used
};

int kstruct_offsets_9_3[] = {
#ifdef __LP64__
    0x0,   // KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE,      // never used
    0x0,   // KSTRUCT_OFFSET_TASK_REF_COUNT,         // never used
    0x0,   // KSTRUCT_OFFSET_TASK_ACTIVE,            // never used
    0x0,   // KSTRUCT_OFFSET_TASK_VM_MAP,            // never used
    0x30,  // KSTRUCT_OFFSET_TASK_NEXT,
    0x38,  // KSTRUCT_OFFSET_TASK_PREV,
    0xe8,  // KSTRUCT_OFFSET_TASK_ITK_SELF,          // never used
    0x2a0, // KSTRUCT_OFFSET_TASK_ITK_SPACE,
    0x308, // KSTRUCT_OFFSET_TASK_BSD_INFO,
    
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_BITS,       // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES, // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE,     // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT,     // never used
    0x58,  // KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER,
    0x60,  // KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT,
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG,     // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT,    // never used
    0x94,  // KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS
    
    0x10,  // KSTRUCT_OFFSET_PROC_PID,
    0x120, // KSTRUCT_OFFSET_PROC_P_FD
    
    0x0,   // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    
    0x8,   // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    
    0x38,  // KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    
    0x0,   // KSTRUCT_OFFSET_SOCKET_SO_PCB           //never used
    
    0x10,  // KSTRUCT_OFFSET_PIPE_BUFFER
    
    0x0,   // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE //never used
    0x20,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE
    
    0x0,   // KFREE_ADDR_OFFSET                      //never used
#else
    0x0,   // KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE,      // never used
    0x0,   // KSTRUCT_OFFSET_TASK_REF_COUNT,         // never used
    0x0,   // KSTRUCT_OFFSET_TASK_ACTIVE,            // never used
    0x18,  // KSTRUCT_OFFSET_TASK_VM_MAP,            // never used
    0x1c,  // KSTRUCT_OFFSET_TASK_NEXT,
    0x20,  // KSTRUCT_OFFSET_TASK_PREV,
    0xa4,  // KSTRUCT_OFFSET_TASK_ITK_SELF,          // never used
    0x1b8, // KSTRUCT_OFFSET_TASK_ITK_SPACE,
    0x200, // KSTRUCT_OFFSET_TASK_BSD_INFO,
    
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_BITS,       // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES, // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE,     // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT,     // never used
    0x4c,  // KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER,
    0x50,  // KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT,
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG,     // never used
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT,    // never used
    0x70,  // KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS
    
    0x8,   // KSTRUCT_OFFSET_PROC_PID,
    0xa8,  // KSTRUCT_OFFSET_PROC_P_FD
    
    0x0,   // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    
    0x8,   // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    
    0x28,  // KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    
    0x0,   // KSTRUCT_OFFSET_SOCKET_SO_PCB           //never used
    
    0x10,  // KSTRUCT_OFFSET_PIPE_BUFFER
    
    0x0,   // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE //never used
    0x18,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE
    
    0x0,   // KFREE_ADDR_OFFSET                      //never used
#endif
};

int kstruct_offsets_10_x[] = {
#ifdef __LP64__
    0xb,   // KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE,
    0x10,  // KSTRUCT_OFFSET_TASK_REF_COUNT,
    0x14,  // KSTRUCT_OFFSET_TASK_ACTIVE,
    0x20,  // KSTRUCT_OFFSET_TASK_VM_MAP,
    0x28,  // KSTRUCT_OFFSET_TASK_NEXT,
    0x30,  // KSTRUCT_OFFSET_TASK_PREV,
    0xd8,  // KSTRUCT_OFFSET_TASK_ITK_SELF,
    0x300, // KSTRUCT_OFFSET_TASK_ITK_SPACE,
    0x360, // KSTRUCT_OFFSET_TASK_BSD_INFO,
    
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_BITS,
    0x4,   // KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES,
    0x40,  // KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE,
    0x50,  // KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT,
    0x60,  // KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER,
    0x68,  // KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT,
    0x88,  // KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG,
    0x90,  // KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT,
    0xa0,  // KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS,
    
    0x10,  // KSTRUCT_OFFSET_PROC_PID,
    0x108, // KSTRUCT_OFFSET_PROC_P_FD
    
    0x0,   // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    
    0x8,   // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    
    0x38,  // KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    
    0x10,  // KSTRUCT_OFFSET_SOCKET_SO_PCB
    
    0x10,  // KSTRUCT_OFFSET_PIPE_BUFFER
    
    0x14,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE
    0x20,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE
    
    0x6c,  // KFREE_ADDR_OFFSET
#else
    0x7,   // KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE,
    0x8,   // KSTRUCT_OFFSET_TASK_REF_COUNT,
    0xc,   // KSTRUCT_OFFSET_TASK_ACTIVE,
    0x14,  // KSTRUCT_OFFSET_TASK_VM_MAP,
    0x18,  // KSTRUCT_OFFSET_TASK_NEXT,
    0x1c,  // KSTRUCT_OFFSET_TASK_PREV,
    0x9c,  // KSTRUCT_OFFSET_TASK_ITK_SELF,
    0x1e8, // KSTRUCT_OFFSET_TASK_ITK_SPACE,
    0x22c, // KSTRUCT_OFFSET_TASK_BSD_INFO,
    
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_BITS,
    0x4,   // KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES,
    0x30,  // KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE,
    0x3c,  // KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT,
    0x44,  // KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER,
    0x48,  // KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT,
    0x58,  // KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG,
    0x5c,  // KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT,
    0x6c,  // KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS,
    
    0x8,   // KSTRUCT_OFFSET_PROC_PID,
    0x9c,  // KSTRUCT_OFFSET_PROC_P_FD
    
    0x0,   // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    
    0x8,   // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    
    0x28,  // KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    
    0x10,  // KSTRUCT_OFFSET_SOCKET_SO_PCB
    
    0x10,  // KSTRUCT_OFFSET_PIPE_BUFFER
    
    0xc,   // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE
    0x14,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE
    
    0x0,   // KFREE_ADDR_OFFSET
    
    0x00,  // KFREE_ADDR_OFFSET
#endif
};

int kstruct_offsets_11_0[] = {
    0xb,   // KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE,
    0x10,  // KSTRUCT_OFFSET_TASK_REF_COUNT,
    0x14,  // KSTRUCT_OFFSET_TASK_ACTIVE,
    0x20,  // KSTRUCT_OFFSET_TASK_VM_MAP,
    0x28,  // KSTRUCT_OFFSET_TASK_NEXT,
    0x30,  // KSTRUCT_OFFSET_TASK_PREV,
    0xd8,  // KSTRUCT_OFFSET_TASK_ITK_SELF,
    0x308, // KSTRUCT_OFFSET_TASK_ITK_SPACE,
    0x368, // KSTRUCT_OFFSET_TASK_BSD_INFO,
    
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_BITS,
    0x4,   // KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES,
    0x40,  // KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE,
    0x50,  // KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT,
    0x60,  // KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER,
    0x68,  // KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT,
    0x88,  // KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG,
    0x90,  // KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT,
    0xa0,  // KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS,
    
    0x10,  // KSTRUCT_OFFSET_PROC_PID,
    0x108, // KSTRUCT_OFFSET_PROC_P_FD
    
    0x0,   // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    
    0x8,   // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    
    0x38,  // KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    
    0x10,  // KSTRUCT_OFFSET_SOCKET_SO_PCB
    
    0x10,  // KSTRUCT_OFFSET_PIPE_BUFFER
    
    0x14,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE
    0x20,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE
    
    0x6c,  // KFREE_ADDR_OFFSET
};

int kstruct_offsets_11_3[] = {
    0xb,   // KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE,
    0x10,  // KSTRUCT_OFFSET_TASK_REF_COUNT,
    0x14,  // KSTRUCT_OFFSET_TASK_ACTIVE,
    0x20,  // KSTRUCT_OFFSET_TASK_VM_MAP,
    0x28,  // KSTRUCT_OFFSET_TASK_NEXT,
    0x30,  // KSTRUCT_OFFSET_TASK_PREV,
    0xd8,  // KSTRUCT_OFFSET_TASK_ITK_SELF,
    0x308, // KSTRUCT_OFFSET_TASK_ITK_SPACE,
    0x368, // KSTRUCT_OFFSET_TASK_BSD_INFO,
    
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_BITS,
    0x4,   // KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES,
    0x40,  // KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE,
    0x50,  // KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT,
    0x60,  // KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER,
    0x68,  // KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT,
    0x88,  // KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG,
    0x90,  // KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT,
    0xa0,  // KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS,
    
    0x10,  // KSTRUCT_OFFSET_PROC_PID,
    0x108, // KSTRUCT_OFFSET_PROC_P_FD
    
    0x0,   // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    
    0x8,   // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    
    0x38,  // KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    
    0x10,  // KSTRUCT_OFFSET_SOCKET_SO_PCB
    
    0x10,  // KSTRUCT_OFFSET_PIPE_BUFFER
    
    0x14,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE
    0x20,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE
};

int kstruct_offsets_12_0[] = {
    0xb,   // KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE,
    0x10,  // KSTRUCT_OFFSET_TASK_REF_COUNT,
    0x14,  // KSTRUCT_OFFSET_TASK_ACTIVE,
    0x20,  // KSTRUCT_OFFSET_TASK_VM_MAP,
    0x28,  // KSTRUCT_OFFSET_TASK_NEXT,
    0x30,  // KSTRUCT_OFFSET_TASK_PREV,
    0xd8,  // KSTRUCT_OFFSET_TASK_ITK_SELF,
    0x300, // KSTRUCT_OFFSET_TASK_ITK_SPACE,
#if __arm64e__
    0x368, // KSTRUCT_OFFSET_TASK_BSD_INFO,
#else
    0x358, // KSTRUCT_OFFSET_TASK_BSD_INFO,
#endif
    
    0x0,   // KSTRUCT_OFFSET_IPC_PORT_IO_BITS,
    0x4,   // KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES,
    0x40,  // KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE,
    0x50,  // KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT,
    0x60,  // KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER,
    0x68,  // KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT,
    0x88,  // KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG,
    0x90,  // KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT,
    0xa0,  // KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS,
    
    0x60,  // KSTRUCT_OFFSET_PROC_PID,
    0x100, // KSTRUCT_OFFSET_PROC_P_FD
    
    0x0,   // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    
    0x8,   // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    
    0x38,  // KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    
    0x10,  // KSTRUCT_OFFSET_SOCKET_SO_PCB
    
    0x10,  // KSTRUCT_OFFSET_PIPE_BUFFER
    
    0x14,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE
    0x20,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE
    
    0x7c,  // KFREE_ADDR_OFFSET
};

int koffset(enum kstruct_offset offset) {
    if (offsets == NULL) {
        printf("need to call offsets_init() prior to querying offsets\n");
        return 0;
    }
    return offsets[offset];
}

uint32_t create_outsize;

void offsets_init(void) {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.0")) {
        printf("[i] offsets selected for iOS 12.0 or above\n");
        offsets = kstruct_offsets_12_0;
        
#if __arm64e__
        offsets[8] = 0x368;
#endif
        create_outsize = 0xdd0;
    }
    
    else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.3")) {
        printf("[i] offsets selected for iOS 11.3 or above\n");
        offsets = kstruct_offsets_11_3;
        create_outsize = 0xbc8;
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.1")) {
        printf("[i] offsets selected for iOS 11.1 or above\n");
        offsets = kstruct_offsets_11_3;
        create_outsize = 0xbc8;
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
        printf("[i] offsets selected for iOS 11.0 to 11.0.3\n");
        offsets = kstruct_offsets_11_0;
        create_outsize = 0x6c8;
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        printf("[i] offsets selected for iOS 10.x\n");
        offsets = kstruct_offsets_10_x;
        create_outsize = 0x3c8;
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.3")) {
        printf("[i] offsets selected for iOS 9.3.x\n");
        offsets = kstruct_offsets_9_3;
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        printf("[i] offsets selected for iOS 8.4.x\n");
        offsets = kstruct_offsets_8_4;
    } else {
        printf("[-] iOS version too low, 10.0 required\n");
        exit(EXIT_FAILURE);
    }
}
