import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import benchmark  # noqa: E402

XCTEST_OUTPUT = """\
Test Suite 'ArithmeticPefTests' started at 2026-09-26 12:00:00.000.
Test Case '-[PerformanceTests.ArithmeticPefTests testPeformanceAdd1]' started.
/Users/x/Matft/Tests/PerformanceTests/ArithmeticPefTests.swift:12: Test Case '-[PerformanceTests.ArithmeticPefTests testPeformanceAdd1]' measured [Time, seconds] average: 0.001, relative standard deviation: 51.245%, values: [0.002205, 0.000989, 0.000802], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[PerformanceTests.ArithmeticPefTests testPeformanceAdd1]' passed (0.320 seconds).
/Users/x/Matft/Tests/PerformanceTests/MathPefTests.swift:18: Test Case '-[PerformanceTests.MathPefTests testPeformanceSin1]' measured [Time, seconds] average: 0.002, relative standard deviation: 21.210%, values: [0.002137, 0.002056], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime
"""


class ParseXCTestOutputTest(unittest.TestCase):
    def test_parse_measured_lines(self):
        got = benchmark.parse_xctest_output(XCTEST_OUTPUT)
        self.assertEqual(got, {
            "ArithmeticPefTests.testPeformanceAdd1": [0.002205, 0.000989, 0.000802],
            "MathPefTests.testPeformanceSin1": [0.002137, 0.002056],
        })

    def test_parse_empty(self):
        self.assertEqual(benchmark.parse_xctest_output("no measurements"), {})


class ParseCallsPerSampleTest(unittest.TestCase):
    def test_values_are_divided_by_calls_per_sample(self):
        text = (
            "MatftBench: -[PerformanceTests.BoolPefTests testPeformanceGreater1] number=100 warmup=0.5\n"
            "Test Case '-[PerformanceTests.BoolPefTests testPeformanceGreater1]' measured [Time, seconds] "
            "average: 0.015, relative standard deviation: 1.0%, values: [0.020000, 0.010000]\n"
        )
        got = benchmark.parse_xctest_output(text)
        self.assertEqual(list(got), ["BoolPefTests.testPeformanceGreater1"])
        for v, want in zip(got["BoolPefTests.testPeformanceGreater1"], [0.0002, 0.0001]):
            self.assertAlmostEqual(v, want)

    def test_parse_calls_per_sample_without_module(self):
        # XCTestCase.name on macOS has no module prefix
        text = "MatftBench: -[BoolPefTests testPeformanceGreater1] number=131 warmup=0.5\n"
        self.assertEqual(benchmark.parse_calls_per_sample(text), {"BoolPefTests.testPeformanceGreater1": 131})

    def test_parse_calls_per_sample(self):
        text = "MatftBench: -[PerformanceTests.MathPefTests testPeformanceSin1] number=7 warmup=0.5\n"
        self.assertEqual(benchmark.parse_calls_per_sample(text), {"MathPefTests.testPeformanceSin1": 7})


class SwiftTestEnvTest(unittest.TestCase):
    def test_env_contains_warmup_and_sample_time(self):
        env = benchmark.swift_test_env(warmup=0.3, sample_time=0.05, base={"PATH": "/bin"})
        self.assertEqual(env["PATH"], "/bin")
        self.assertEqual(env["MATFT_BENCH_WARMUP"], "0.3")
        self.assertEqual(env["MATFT_BENCH_SAMPLE_TIME"], "0.05")


class FormatTimeTest(unittest.TestCase):
    def test_micro(self):
        self.assertEqual(benchmark.format_time(0.000596), "596μs")

    def test_milli(self):
        self.assertEqual(benchmark.format_time(0.00104), "1.04ms")
        self.assertEqual(benchmark.format_time(0.0178), "17.8ms")
        self.assertEqual(benchmark.format_time(0.1234), "123ms")

    def test_seconds(self):
        self.assertEqual(benchmark.format_time(1.5), "1.50s")


class StatsTest(unittest.TestCase):
    def test_summarize(self):
        s = benchmark.summarize([0.004, 0.001, 0.002, 0.003])
        self.assertAlmostEqual(s["median"], 0.0025)
        self.assertAlmostEqual(s["mean"], 0.0025)
        self.assertEqual(s["n"], 4)

    def test_rsd_steady_ignores_leading_samples(self):
        # XCTest `measure {}` reports slow first samples even after the warm-up
        s = benchmark.summarize([0.004, 0.003, 0.002, 0.001, 0.001, 0.001])
        self.assertGreater(s["rsd"], 0.5)
        self.assertAlmostEqual(s["rsd_steady"], 0.0)

    def test_rsd_steady_with_few_samples_falls_back_to_rsd(self):
        s = benchmark.summarize([0.002, 0.001])
        self.assertAlmostEqual(s["rsd_steady"], s["rsd"])


class ReplaceReadmeTest(unittest.TestCase):
    def test_replace_between_markers(self):
        text = "head\n<!-- BENCHMARK:START -->\nold\n<!-- BENCHMARK:END -->\ntail\n"
        got = benchmark.replace_between_markers(text, "new table")
        self.assertEqual(got, "head\n<!-- BENCHMARK:START -->\nnew table\n<!-- BENCHMARK:END -->\ntail\n")

    def test_missing_markers_raises(self):
        with self.assertRaises(ValueError):
            benchmark.replace_between_markers("no markers here", "x")


class RenderTest(unittest.TestCase):
    def test_render_contains_ratio_and_expressions(self):
        cases = [benchmark.Case("ArithmeticPefTests.testPeformanceAdd1", "Arithmetic",
                                "let _ = a+aneg", "a+aneg")]
        results = {
            "swift": {"ArithmeticPefTests.testPeformanceAdd1": [0.002, 0.002, 0.002]},
            "numpy": {"ArithmeticPefTests.testPeformanceAdd1": [0.001, 0.001, 0.001]},
        }
        md = benchmark.render_tables(cases, results)
        self.assertIn("- Arithmetic", md)
        self.assertIn("`let _ = a+aneg`", md)
        self.assertIn("`a+aneg`", md)
        self.assertIn("2.00ms", md)
        self.assertIn("1.00ms", md)
        self.assertIn("2.00x", md)

    def test_report_mentions_warmup_and_calls_per_sample(self):
        cases = [benchmark.Case("X.testY", "Math", "let _ = y", "y")]
        env = {"cpu": "c", "macos": "m", "swift": "s", "python": "p", "numpy": "n", "commit": "x", "date": "d"}
        md = benchmark.render_report(cases, {"swift": {}, "numpy": {}}, env)
        self.assertIn("warm-up", md)
        self.assertIn("calls per sample", md)

    def test_render_missing_value(self):
        cases = [benchmark.Case("X.testY", "Math", "let _ = y", "y")]
        md = benchmark.render_tables(cases, {"swift": {}, "numpy": {"X.testY": [0.001]}})
        self.assertIn("n/a", md)


if __name__ == "__main__":
    unittest.main()
