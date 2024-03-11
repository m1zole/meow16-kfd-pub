/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef thread_h
#define thread_h

#include <stdint.h>

struct thread {
    uint64_t task_threads_next;
    uint64_t task_threads_prev;
    uint64_t map;
    uint64_t thread_id;
    uint64_t object_size;
};

static const struct thread thread_versions[] = {
    // Note: sizes below here are wrong idc
    {
        .task_threads_next = 0x420,
        .task_threads_prev = 0x428,
        .map               = 0x438,
        .thread_id         = 0x578,
        .object_size       = 0x610
    }, // iOS 12.0 - 12.5 arm64/arm64e
    
    {
        .task_threads_next = 0x420,
        .task_threads_prev = 0x428,
        .map               = 0x438,
        .thread_id         = 0x578,
        .object_size       = 0x610
    }, // iOS 13.0 - 13.7 arm64/arm64e
    
    {
        .task_threads_next = 0x420,
        .task_threads_prev = 0x428,
        .map               = 0x438,
        .thread_id         = 0x578,
        .object_size       = 0x610
    }, // iOS 14.0 - 14.4 arm64/arm64e
    
    {
        .task_threads_next = 0x420,
        .task_threads_prev = 0x428,
        .map               = 0x438,
        .thread_id         = 0x578,
        .object_size       = 0x610
    }, // iOS 14.5 - 14.8 arm64/arm64e

    {
        .task_threads_next = 0x420,
        .task_threads_prev = 0x428,
        .map               = 0x438,
        .thread_id         = 0x578,
        .object_size       = 0x610
    }, // iOS 15.0 - 15.1 arm64
    
    {
        .task_threads_next = 0x400,
        .task_threads_prev = 0x408,
        .map               = 0x418,
        .thread_id         = 0x560,
        .object_size       = 0x610
    }, // iOS 15.0 - 15.1 arm64e
    
    {
        .task_threads_next = 0x3b0,
        .task_threads_prev = 0x3b8,
        .map               = 0x3c8,
        .thread_id         = 0x460,
        .object_size       = 0x610
    }, // iOS 15.2 - 15.3 arm64
    
    {
        .task_threads_next = 0x388,
        .task_threads_prev = 0x390,
        .map               = 0x3a0,
        .thread_id         = 0x438,
        .object_size       = 0x610
    }, // iOS 15.2 - 15.3 arm64e
    
    {
        .task_threads_next = 0x3a8,
        .task_threads_prev = 0x3b0,
        .map               = 0x3c0,
        .thread_id         = 0x458,
        .object_size       = 0x610
    }, // iOS 15.4 - 15.7 arm64
    
    {
        .task_threads_next = 0x388,
        .task_threads_prev = 0x390,
        .map               = 0x3a0,
        .thread_id         = 0x440,
        .object_size       = 0x610
    }, // iOS 15.4 - 15.7 arm64e
    
    {
        .task_threads_next = 0x340,
        .task_threads_prev = 0x348,
        .map               = 0x358,
        .thread_id         = 0x3f0,
        .object_size       = 0x498
    }, // iOS 16.0 - 16.1 arm64
    
    {
        .task_threads_next = 0x368,
        .task_threads_prev = 0x370,
        .map               = 0x380,
        .thread_id         = 0x420,
        .object_size       = 0x4c8
    }, // iOS 16.0 - 16.1 arm64e
    
    {
        .task_threads_next = 0x368,
        .task_threads_prev = 0x370,
        .map               = 0x380,
        .thread_id         = 0x3f0,
        .object_size       = 0x498
    }, // iOS 16.2 - 16.3 arm64
    
    {
        .task_threads_next = 0x368,
        .task_threads_prev = 0x370,
        .map               = 0x380,
        .thread_id         = 0x420,
        .object_size       = 0x4c8
    }, // iOS 16.2 - 16.3 arm64e
    
    {
        .task_threads_next = 0x368,
        .task_threads_prev = 0x370,
        .map               = 0x380,
        .thread_id         = 0x3f0,
        .object_size       = 0x498
    }, // iOS 16.4 - 16.6 arm64
    
    {
        .task_threads_next = 0x368,
        .task_threads_prev = 0x370,
        .map               = 0x380,
        .thread_id         = 0x418,
        .object_size       = 0x4c0
    }, // iOS 16.4 - 16.6 arm64e
    
    {
        .task_threads_next = 0x378,
        .task_threads_prev = 0x380,
        .map               = 0x390,
        .thread_id         = 0x430,
        .object_size       = 0x4c8
    }, // iOS 17.0 beta 1 arm64
};

typedef uint64_t thread_task_threads_next_t;
typedef uint64_t thread_task_threads_prev_t;
typedef uint64_t thread_map_t;
typedef uint64_t thread_thread_id_t;

#endif /* thread_h */
