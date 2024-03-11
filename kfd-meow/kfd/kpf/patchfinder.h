//
//  patchfinder.h
//  kfd
//
//  Created by Seo Hyun-gyu on 1/8/24.
//

#ifndef patchfinder_h
#define patchfinder_h

#include "../libkfd.h"
#include "../libkfd/perf.h"

int do_dynamic_patchfinder(struct kfd* kfd, uint64_t kbase);

int import_kfd_offsets(void);
int save_kfd_offsets(void);

#endif /* patchfinder_h */
