import Foundation
import XCTest
import Matft

// Shared inputs for the performance tests.
// Keep these in sync with `SETUP` in scripts/benchmark.py so that Matft and Numpy measure the same thing.
enum PerfFixtures {
    static var a: MfArray { Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10]) }
    static var ad: MfArray { a.astype(.Double) }
    static var aneg: MfArray { Matft.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10]) }
    static var idx: MfArray { MfArray([1, 3, 5, 7, 9]) }
    static var signal: MfArray { Matft.arange(start: 0, to: 1024*1024, by: 1, shape: [1024, 1024], mftype: .Float) }
}

// Measurement settings. scripts/benchmark.py passes them via environment variables (--warmup, --sample-time).
enum PerfSettings {
    /// Seconds to run the block before `measure {}` starts
    static var warmup: Double { double("MATFT_BENCH_WARMUP") ?? 0.5 }
    /// Target seconds of one measured sample. The number of calls per sample is chosen from the warm-up.
    static var sampleTime: Double { double("MATFT_BENCH_SAMPLE_TIME") ?? 0.02 }
    /// The block runs at least this many times during warm-up
    static let minWarmupIterations = 3
    
    private static func double(_ key: String) -> Double? {
        ProcessInfo.processInfo.environment[key].flatMap(Double.init)
    }
}

extension XCTestCase {
    /// `measure {}` with a warm-up and several calls per sample, like Python's `timeit`.
    ///
    /// With a single call per sample, XCTest's own per-iteration overhead and cold allocations dominate fast cases
    /// (e.g. 0.14ms operations were reported as ~0.5ms). The reported values are per sample, so the number of calls
    /// is printed as `MatftBench: <test name> number=<N>`; scripts/benchmark.py divides the values by it.
    func measureWithWarmup(_ block: () -> Void) {
        // ProcessInfo instead of DispatchTime, which is unavailable on WASI
        let start = ProcessInfo.processInfo.systemUptime
        var iterations = 0
        var elapsed = 0.0
        repeat {
            block()
            iterations += 1
            elapsed = ProcessInfo.processInfo.systemUptime - start
        } while iterations < PerfSettings.minWarmupIterations || elapsed < PerfSettings.warmup
        
        let perCall = elapsed / Double(iterations)
        let number = max(1, Int((PerfSettings.sampleTime / perCall).rounded(.up)))
        print("MatftBench: \(self.name) number=\(number) warmup=\(PerfSettings.warmup)")
        
        measure {
            for _ in 0..<number {
                block()
            }
        }
    }
}
