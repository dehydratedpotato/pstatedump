//
//    main.swift
//    pstatedump
//
//    MIT License
//
//    Copyright (c) 2023 BitesPotatoBacks
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

import Foundation

struct PerformanceState {
    let id: Int
    let frequency: Int
    let type: StateType?
    
    enum StateType: String {
        case boostType = "Boost"
        case baseType = "Nominal"
    }
}

class PerformanceStates {
    var cpuPstates: [PerformanceState] = []
    var maximumLimitedState: Int = 0
    
    lazy var nominalFrequency: Int = {
        var size: Int = 0
        var ptr: Int = 0
        if sysctlbyname("hw.cpufrequency_max", nil, &size, nil, 0) != -1 {
            sysctlbyname("hw.cpufrequency_max", &ptr, &size, nil, 0)
        }
        
        return ptr / 1_000_000
    }()

    lazy var cpuModelString: String = {
        var size: Int = 0
        var string: String = ""
        if sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) != -1 {
            var ptr = [CChar](repeating: 0,  count: size)

            sysctlbyname("machdep.cpu.brand_string", &ptr, &size, nil, 0)
            
            string = String(cString: ptr)
        }
        
        if let range = string.range(of: "@") {
            string.removeSubrange(range.lowerBound..<string.endIndex)
        }

        return string
    }()
    
    init() {
        var entry: io_registry_entry_t = 0
        
        if #available(macOS 12.0, *) {
            entry = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/AppleACPIPlatformExpert/CPU0/AppleACPICPU/X86PlatformPlugin")
        } else {
            entry = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/AppleACPIPlatformExpert/CPU0/AppleACPICPU/X86PlatformPlugin")
        }
        
        guard entry != 0 else {
            print("Failed to access X86PlatformPlugin")
            exit(-1)
        }

        if let property = IORegistryEntryCreateCFProperty(entry, "IOPPFDiagDict" as CFString, kCFAllocatorDefault, 0) {
            let dict: Dictionary<String, Any> = property.takeRetainedValue() as! Dictionary
            
            for (key, _) in dict where key == "CPUPLimitDict" {
                if let limitDict: [String: Int] = dict[key] as? Dictionary, let limit: Int = limitDict["currentLimit"]  {
                    self.maximumLimitedState = limit
                    
                    break
                }
            }
        }
            
        if let property = IORegistryEntryCreateCFProperty(entry, "CPUPStates" as CFString, kCFAllocatorDefault, 0) {
            let array: Array<Dictionary<String, Int>> = property.takeRetainedValue() as! Array
            
            for item in array {
                guard let freq: Int = item["Frequency"], let id: Int = item["PState"] else {
                    print("Failed to access pstates from X86PlatformPlugin")
                    exit(-1)
                }
                
                var type: PerformanceState.StateType?
                
                if freq > self.nominalFrequency {
                    type = .boostType
                } else if freq == self.nominalFrequency {
                    type = .baseType
                }
                
                let state = PerformanceState(id: id, frequency: freq, type: type)
                self.cpuPstates.append(state)
            }
        }
    }
}

func help() {
    print("usage:")
    print(String(format: "  %s", getprogname()))
    print(String(format: "  %s [-c|-n|-m|-b|-a]", getprogname()))

    print("\n  -c, --count         print pstate count")
    print("  -n, --max           print maximum nominal freq only")
    print("  -m, --min           print minimum nominal freq only")
    print("  -b, --boost         print maximum boost freq only")
    print("  -a, --avail-boost   print maximum available boost freq only")
    print("  -h, --help          print this help menu")

    print("\n  Default: prints P-State table for the CPU")
    exit(0)
}

let pstates = PerformanceStates()

if CommandLine.arguments.count == 2 {
    switch CommandLine.arguments[1] {
    case "-c", "--count":
        print("\(pstates.cpuPstates.count) P-States")
    case "-n", "--max":
        print("Maximum Nominal: \(pstates.nominalFrequency) MHz")
    case "-m", "--min":
        if let state = pstates.cpuPstates.last {
            print("Minimum Nominal: \(state.frequency) MHz")
        }
    case "-b", "--boost":
        if let state = pstates.cpuPstates.first {
            print("Maximum Nominal: \(state.frequency) MHz")
        }
    case "-a", "--avail-boost":
        if let state = pstates.cpuPstates.first(where: { $0.id == pstates.maximumLimitedState }) {
            print("Maximum Available Boost: \(state.frequency) MHz")
        }
    case "-h", "--help":
        help()
    default:
        print("Invalid argument")
        exit(-1)
    }
} else {
    print("\(pstates.cpuModelString)\n")

    print("***** \(pstates.cpuPstates.count) P-States *****\n")
    
    for pstate in pstates.cpuPstates {
        print(String(format: "%2d %6d MHz", pstate.id, pstate.frequency), separator: "", terminator: "")
        
        if let type = pstate.type {
            print("   (\(type.rawValue))", separator: "", terminator: "")
        }
        
        print("")
    }
}
