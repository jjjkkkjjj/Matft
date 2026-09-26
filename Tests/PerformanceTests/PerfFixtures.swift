import Matft

// Shared inputs for the performance tests.
// Keep these in sync with `SETUP` in scripts/benchmark.py so that Matft and Numpy measure the same thing.
enum PerfFixtures {
    static var a: MfArray { Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10]) }
    static var aneg: MfArray { Matft.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10]) }
}
