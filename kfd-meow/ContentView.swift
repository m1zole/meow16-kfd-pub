/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

import SwiftUI
import KernelPatchfinder

struct ContentView: View {
    
    @State private var result: UInt64 = 0
    private var puaf_method_options = ["physpuppet", "smith", "landa"]
    @State private var puaf_method = 2
    private var pplrw_options = ["on", "off"]
    @State private var debug_toggle = 1
    @State private var message = ""
    @State private var action = "overwrite"
    @State private var overwritten = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextEditor(text: $message)
                        .disabled(true)
                        .font(Font(UIFont.monospacedSystemFont(ofSize: 11.0, weight: .regular)))
                        .frame(height: 180)
                    Picker(selection: $puaf_method, label: Text("puaf method:")) {
                        ForEach(0 ..< puaf_method_options.count, id: \.self) {
                            Text(self.puaf_method_options[$0])
                        }
                    }.disabled(result != 0).pickerStyle(SegmentedPickerStyle())
                    Picker(selection: $debug_toggle, label: Text("pplrw:")) {
                        ForEach(0 ..< pplrw_options.count, id: \.self) {
                            Text(self.pplrw_options[$0])
                        }
                    }.disabled(result != 0).pickerStyle(SegmentedPickerStyle())
                }
                Section {
                    HStack {
                        Button("kopen") {
                            message = ""
                            result = kopen_bridge(UInt64(puaf_method), UInt64(debug_toggle))
                            if (result != 0) {
                                sleep(1)
                                message = "[*] kopening\n[*] kslide: " + String(get_kernel_slide(), radix:16) + "\n"
                                if(debug_toggle == 0) {
                                    result = kclose_bridge(result)
                                    if (result == 0) {
                                        message = message + "[*] kclosed\n"
                                        print("done!")
                                    }
                                }
                            }
                        }.disabled(result != 0).frame(minWidth: 0, maxWidth: .infinity)
                        Button("kclose") {
                            result = kclose_bridge(result)
                            if (result == 0) {
                                message = message + "[*] kclosed"
                            }
                        }.disabled(result == 0).frame(minWidth: 0, maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                }.listRowBackground(Color.clear)
                Section {
                    HStack {
                        Button("finder") {
                            print(String(KernelPatchfinder.running?.baseAddress ?? 0x0, radix: 16))
                            print(String(KernelPatchfinder.running?.ptov_data?.table ?? 0x0, radix: 16))
                            print(String(KernelPatchfinder.running?.ptov_data?.physBase ?? 0x0, radix: 16))
                            print(String(UInt64(KernelPatchfinder.running?.ptov_data?.physBase ?? 0x0) + 0x8, radix: 16))
                            print(String(KernelPatchfinder.running?.ptov_data?.virtBase ?? 0x0, radix: 16))
                            print(String(KernelPatchfinder.running?.pmap_image4_trust_caches ?? 0x0, radix: 16))
                            print(String(KernelPatchfinder.running?.ml_phys_write_data ?? 0x0, radix: 16))
                            print(String(KernelPatchfinder.running?.ml_phys_read_data ?? 0x0, radix: 16))
                        }.disabled(result != 0 || overwritten).frame(minWidth: 0, maxWidth: .infinity)
                        Button(action) {
                        }.disabled(result == 0 && !overwritten).frame(minWidth: 0, maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                }.listRowBackground(Color.clear)
            }
        }
    }
}

#Preview {
    ContentView()
}
