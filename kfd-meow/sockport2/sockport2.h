//
//  common.h
//  kfd-meow
//
//  Created by mizole on 2024/03/13.
//

#ifndef sockport2_h
#define sockport2_h

#include <stdio.h>

typedef volatile struct {
    uint32_t ip_bits;
    uint32_t ip_references;
    struct {
        uint64_t data;
        uint64_t type;
    } ip_lock; // spinlock
    struct {
        struct {
            struct {
                uint32_t flags;
                uint32_t waitq_interlock;
                uint64_t waitq_set_id;
                uint64_t waitq_prepost_id;
                struct {
                    uint64_t next;
                    uint64_t prev;
                } waitq_queue;
            } waitq;
            uint64_t messages;
            uint32_t seqno;
            uint32_t receiver_name;
            uint16_t msgcount;
            uint16_t qlimit;
            uint32_t pad;
        } port;
        uint64_t klist;
    } ip_messages;
    uint64_t ip_receiver;
    uint64_t ip_kobject;
    uint64_t ip_nsrequest;
    uint64_t ip_pdrequest;
    uint64_t ip_requests;
    uint64_t ip_premsg;
    uint64_t ip_context;
    uint32_t ip_flags;
    uint32_t ip_mscount;
    uint32_t ip_srights;
    uint32_t ip_sorights;
} kport10_t;

typedef struct {
    struct {
        uint64_t data;
        uint32_t reserved : 24,
        type     :  8;
        uint32_t pad;
    } lock; // mutex lock
    uint32_t ref_count;
    uint32_t active;
    uint32_t halting;
    uint32_t pad;
    uint64_t map;
} ktask10_t;

typedef struct __attribute__((__packed__))
{
    uint32_t ip_bits;
    uint32_t ip_references;
    struct __attribute__((__packed__))
    {
        uintptr_t data;
        uint32_t pad;
        uint32_t type;
    } ip_lock; // spinlock
    struct __attribute__((__packed__))
    {
        struct __attribute__((__packed__))
        {
            struct __attribute__((__packed__))
            {
                uint32_t flags;
                uint32_t waitq_interlock;
                uint64_t waitq_set_id;
                uint64_t waitq_prepost_id;
                struct __attribute__((__packed__))
                {
                    uintptr_t next;
                    uintptr_t prev;
                } waitq_queue;
            } waitq;
            uintptr_t messages;
            natural_t seqno;
            natural_t receiver_name;
            uint16_t msgcount;
            uint16_t qlimit;
        } port;
    } ip_messages;
    natural_t ip_flags;
    uintptr_t ip_receiver;
    uintptr_t ip_kobject;
    uintptr_t ip_nsrequest;
    uintptr_t ip_pdrequest;
    uintptr_t ip_requests;
    uintptr_t ip_premsg;
    uint64_t  ip_context;
    natural_t ip_mscount;
    natural_t ip_srights;
    natural_t ip_sorights;
} kport64_t;

typedef struct
{
    struct
    {
        uintptr_t data;
        uintptr_t pad;
        uintptr_t type;
    } lock; // mutex lock
    uint32_t ref_count;
    int active;
    char pad[0x308 /* TASK_BSDINFO */ - sizeof(int) - sizeof(uint32_t) - (3 * sizeof(uintptr_t))];
    uintptr_t bsd_info;
} ktask64_t;

typedef struct __attribute__((__packed__))
{
    uint32_t ip_bits;
    uint32_t ip_references;
    struct __attribute__((__packed__))
    {
        uint32_t data;
        uint32_t pad;
        uint32_t type;
    } ip_lock;
    struct __attribute__((__packed__))
    {
        struct __attribute__((__packed__))
        {
            struct __attribute__((__packed__))
            {
                uint32_t flags;
                uintptr_t waitq_interlock;
                uint64_t waitq_set_id;
                uint64_t waitq_prepost_id;
                struct __attribute__((__packed__))
                {
                    uintptr_t next;
                    uintptr_t prev;
                } waitq_queue;
            } waitq;
            uintptr_t messages;
            natural_t seqno;
            natural_t receiver_name;
            uint16_t msgcount;
            uint16_t qlimit;
        } port;
        uintptr_t imq_klist;
    } ip_messages;
    natural_t ip_flags;
    uintptr_t ip_receiver;
    uintptr_t ip_kobject;
    uintptr_t ip_nsrequest;
    uintptr_t ip_pdrequest;
    uintptr_t ip_requests;
    uintptr_t ip_premsg;
    uint64_t  ip_context;
    natural_t ip_mscount;
    natural_t ip_srights;
    natural_t ip_sorights;
} kport32_t;

typedef struct
{
    struct
    {
        uintptr_t data;
        uintptr_t pad;
        uintptr_t type;
    } lock; // mutex lock
    uint32_t ref_count;
    int active;
    char pad[0x200 /* TASK_BSDINFO */ - sizeof(int) - sizeof(uint32_t) - (3 * sizeof(uintptr_t))];
    uintptr_t bsd_info;
} ktask32_t;

#ifdef __LP64__
#   define ADDR "0x%016llx"
#   define KERNEL_BASE_ADDRESS9 0xffffff8004004000
#   define MACH_MAGIC MH_MAGIC_64
    typedef uint64_t addr_t;
    typedef kport64_t kport_t;
    typedef ktask64_t ktask_t;
#else
#   define ADDR "0x%08x"
#   define KERNEL_BASE_ADDRESS9 0x80001000
#   define MACH_MAGIC MH_MAGIC
    typedef uint32_t addr_t;
    typedef kport32_t kport_t;
    typedef ktask32_t ktask_t;
#endif /* __LP64__ */

mach_port_t get_tfp0(void);
addr_t get_kslide_anchor(void);
addr_t get_kslide_new(void);

void kreadbuf_sp(uint64_t va, void *ua, size_t size);
uint64_t kread64_sp(addr_t va);
uint32_t kread32_sp(addr_t va);
uint16_t kread16_sp(addr_t va);
uint8_t kread8_sp(addr_t va);
addr_t kreadptr_sp(addr_t va);

void kwritebuf_sp(addr_t va, const void *ua, size_t size);
void kwrite64_sp(addr_t va, uint64_t val);
void kwrite32_sp(addr_t va, uint32_t val);
void kwrite16_sp(addr_t va, uint16_t val);
void kwrite8_sp(addr_t va, uint8_t val);
void kwriteptr_sp(addr_t va, addr_t val);

#endif /* sockport2_h */
