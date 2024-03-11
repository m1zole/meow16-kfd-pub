/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef kwrite_sem_open_h
#define kwrite_sem_open_h

#include "../../../libkfd.h"
#include "../../info.h"
#include "../../info/static_types/fileproc.h"
#include "../../info/static_types/fileproc_guard.h"
#include "../kread/kread_sem_open.h"
#include "kwrite_dup.h"

void kwrite_sem_open_init(struct kfd* kfd);
void kwrite_sem_open_allocate(struct kfd* kfd, uint64_t id);
bool kwrite_sem_open_search(struct kfd* kfd, uint64_t object_uaddr);
void kwrite_sem_open_kwrite(struct kfd* kfd, void* uaddr, uint64_t kaddr, uint64_t size);
void kwrite_sem_open_find_proc(struct kfd* kfd);
void kwrite_sem_open_deallocate(struct kfd* kfd, uint64_t id);
void kwrite_sem_open_free(struct kfd* kfd);

#endif /* kwrite_sem_open_h */
