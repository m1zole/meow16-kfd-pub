/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef uthread_h
#define uthread_h

#include <stdint.h>

struct uthread {
    uint64_t object_size;
};

static const struct uthread uthread_versions[] = {
    // Note: sizes below here are wrong idc
    { }, // iOS 13.0 - 13.4 arm64/arm64e
    { }, // iOS 13.5 - 13.7 arm64/arm64e
    { .object_size = 0x1b0 }, // iOS 14.0 - 14.4 arm64/arm64e
    { .object_size = 0x1b0 }, // iOS 14.5 - 14.8 arm64/arm64e
    { .object_size = 0x1b0 }, // iOS 15.0 - 15.1 arm64
    { .object_size = 0x1b0 }, // iOS 15.0 - 15.1 arm64e
    { .object_size = 0x1b0 }, // iOS 15.2 - 15.3 arm64
    { .object_size = 0x1b0 }, // iOS 15.2 - 15.3 arm64e
    { .object_size = 0x1b0 }, // iOS 15.4 - 15.7 arm64
    { .object_size = 0x1b0 }, // iOS 15.4 - 15.7 arm64e
    { .object_size = 0x200 }, // iOS 16.0 - 16.1 arm64
    { .object_size = 0x200 }, // iOS 16.0 - 16.1 arm64e
    { .object_size = 0x1b0 }, // iOS 16.2 - 16.3 arm64
    { .object_size = 0x200 }, // iOS 16.2 - 16.3 arm64e
    { .object_size = 0x1b0 }, // iOS 16.4 - 16.6 arm64
    { .object_size = 0x200 }, // iOS 16.4 - 16.6 arm64e
    { .object_size = 0x200 }, // iOS 17.0 beta 1 arm64
};

#endif /* uthread_h */
