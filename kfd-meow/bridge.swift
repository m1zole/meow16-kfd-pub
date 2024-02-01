//
//  fugufinder.swift
//  kfd-meow
//
//  Created by mizole on 2024/01/05.
//

import Foundation
import KernelPatchfinder

@objc class objcbridge: NSObject {
    
    @objc public func find_base() -> UInt64 {
        return KernelPatchfinder.running?.baseAddress ?? 0x0
    }
    @objc public func find_ptov_table() -> UInt64 {
        return KernelPatchfinder.running?.ptov_data?.table ?? 0x0
    }
    @objc public func find_gPhysBase() -> UInt64 {
        return KernelPatchfinder.running?.ptov_data?.physBase ?? 0x0
    }
    @objc public func find_gPhysSize() -> UInt64 {
        return UInt64(KernelPatchfinder.running?.ptov_data?.physBase ?? 0x0) + 0x8
    }
    @objc public func find_gVirtBase() -> UInt64 {
        return KernelPatchfinder.running?.ptov_data?.virtBase ?? 0x0
    }
    @objc public func find_vn_kqfilter () -> UInt64 {
        return KernelPatchfinder.running?.vn_kqfilter ?? 0x0
    }
    @objc public func find_perfmon_devices() -> UInt64 {
        return KernelPatchfinder.running?.perfmon_devices ?? 0x0
    }
    @objc public func find_perfmon_dev_open() -> UInt64 {
        return KernelPatchfinder.running?.perfmon_dev_open ?? 0x0
    }
    @objc public func find_cdevsw() -> UInt64 {
        return KernelPatchfinder.running?.cdevsw ?? 0x0
    }
    @objc public func find_vm_pages() -> UInt64 {
        return KernelPatchfinder.running?.vm_pages ?? 0x0
    }
    @objc public func find_vm_page_array_beginning() -> UInt64 {
        return KernelPatchfinder.running?.vm_page_array.beginning ?? 0x0
    }
    @objc public func find_vm_page_array_ending() -> UInt64 {
        return KernelPatchfinder.running?.vm_page_array.ending ?? 0x0
    }
    @objc public func find_vm_first_phys_ppnum() -> UInt64 {
        return UInt64(KernelPatchfinder.running?.vm_page_array.ending ?? 0x0) + 0x8
    }
    @objc public func find_kalloc_data_external() -> UInt64 {
        return KernelPatchfinder.running?.kalloc_data_external ?? 0
    }
    @objc public func find_kfree_data_external() -> UInt64 {
        return KernelPatchfinder.running?.kfree_data_external ?? 0
    }
    @objc public func find_ml_phys_read_data() -> UInt64 {
        return KernelPatchfinder.running?.ml_phys_read_data ?? 0
    }
    @objc public func find_ml_phys_write_data() -> UInt64 {
        return KernelPatchfinder.running?.ml_phys_write_data ?? 0
    }
    @objc public func find_mach_vm_allocate() -> UInt64 {
        return KernelPatchfinder.running?.mach_vm_allocate ?? 0
    }
    @objc public func find_pmap_image4_trust_caches() -> UInt64 {
        return KernelPatchfinder.running?.pmap_image4_trust_caches ?? 0x0
    }
    @objc public func find_ITK_SPACE() -> UInt64 {
        return KernelPatchfinder.running?.ITK_SPACE ?? 0x0
    }
    @objc public func find_ktrr() -> UInt64 {
        return KernelPatchfinder.running?.ktrr ?? 0x0
    }
}
