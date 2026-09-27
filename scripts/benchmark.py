#!/usr/bin/env python3
"""Benchmark Matft (Tests/PerformanceTests) against Numpy and report the results.

Usage:
    python3 scripts/benchmark.py                  # run both, write benchmarks/results/latest.{json,md}
    python3 scripts/benchmark.py --update-docs    # also rewrite the table in website/docs/performance.md
    python3 scripts/benchmark.py --skip-swift     # reuse Swift results from the previous JSON
    python3 scripts/benchmark.py --baseline old.json

Matft is measured with `swift test -c release --filter PerformanceTests` (XCTest `measure {}`),
Numpy with `timeit`. Both report the median per-call time.

Like `timeit`, each Matft sample runs the expression several times after a warm-up
(see `measureWithWarmup` in Tests/PerformanceTests/PerfFixtures.swift): the number of calls
per sample is chosen so that one sample takes about `--sample-time` seconds.
"""
import argparse
import datetime
import json
import os
import platform
import re
import statistics
import subprocess
import sys
import timeit
from typing import NamedTuple

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RESULTS_DIR = os.path.join(ROOT, "benchmarks", "results")
LATEST_JSON = os.path.join(RESULTS_DIR, "latest.json")
LATEST_MD = os.path.join(RESULTS_DIR, "latest.md")
PERFORMANCE_DOC = os.path.join(ROOT, "website", "docs", "performance.md")

MARKER_START = "<!-- BENCHMARK:START -->"
MARKER_END = "<!-- BENCHMARK:END -->"

# Keep in sync with Tests/PerformanceTests/PerfFixtures.swift and the snippets in website/docs/performance.md.
SETUP = """\
import numpy as np
a = np.arange(10**6).reshape((10,10,10,10,10,10))
ad = a.astype(np.float64)
aneg = np.arange(0, -10**6, -1).reshape((10,10,10,10,10,10))
aT = a.T
b = a.transpose((0,3,4,2,1,5))
c = a.transpose((1,2,3,4,5,0))
posb = a > 0
idx = np.array([1, 3, 5, 7, 9])
values = a[posb]
v = np.arange(10000)
nested = np.arange(100000, dtype=np.float32).reshape(1000, 100).tolist()
m = np.fromfunction(lambda i, j: np.where(i == j, 256, (i*256 + j) % 7), (256, 256))
signal = np.arange(1024*1024, dtype=np.float32).reshape((1024,1024))
"""


class Case(NamedTuple):
    id: str        # "<XCTestCase class>.<test method>"
    category: str  # table the case belongs to
    matft: str     # Swift expression shown in the docs
    numpy: str     # Numpy statement measured by timeit (also shown in the docs)


CASES = [
    Case("ArithmeticPefTests.testPeformanceAdd1", "Arithmetic", "let _ = a+aneg", "a+aneg"),
    Case("ArithmeticPefTests.testPeformanceAdd2", "Arithmetic", "let _ = b+aT", "b+aT"),
    Case("ArithmeticPefTests.testPeformanceAdd3", "Arithmetic", "let _ = c+aT", "c+aT"),
    Case("ArithmeticPefTests.testPeformanceAddScalar1", "Arithmetic", "let _ = a + Float(0.5)", "a + np.float32(0.5)"),
    Case("MathPefTests.testPeformanceSin1", "Math", "let _ = Matft.math.sin(a)", "np.sin(a)"),
    Case("MathPefTests.testPeformanceSin2", "Math", "let _ = Matft.math.sin(b)", "np.sin(b)"),
    Case("MathPefTests.testPeformanceSign1", "Math", "let _ = Matft.math.sign(a)", "np.sign(a)"),
    Case("MathPefTests.testPeformanceSign2", "Math", "let _ = Matft.math.sign(b)", "np.sign(b)"),
    Case("MathPefTests.testPeformancePower1", "Math", "let _ = Matft.math.power(bases: ad, exponents: 2)", "np.power(ad, 2)"),
    Case("MathPefTests.testPeformanceArctan2", "Math", "let _ = Matft.math.arctan2(x1: ad, x2: ad)", "np.arctan2(ad, ad)"),
    Case("StatsPefTests.testPeformanceMean1", "Stats", "let _ = a.mean()", "a.mean()"),
    Case("StatsPefTests.testPeformanceCumsum1", "Stats", "let _ = Matft.stats.cumsum(a, axis: 0)", "np.cumsum(a, axis=0)"),
    Case("StatsPefTests.testPeformanceCumsum2", "Stats", "let _ = Matft.stats.cumsum(a, axis: 5)", "np.cumsum(a, axis=5)"),
    Case("StatsPefTests.testPeformanceCumsum3", "Stats", "let _ = Matft.stats.cumsum(v)", "np.cumsum(v)"),
    Case("StatsPefTests.testPeformanceMax1", "Stats", "let _ = a.max(axis: 5)", "np.max(a, axis=5)"),
    Case("StatsPefTests.testPeformanceMax2", "Stats", "let _ = a.max()", "np.max(a)"),
    Case("StatsPefTests.testPeformanceMaximum1", "Stats", "let _ = Matft.stats.maximum(a, aneg)", "np.maximum(a, aneg)"),
    Case("StatsPefTests.testPeformanceArgmax1", "Stats", "let _ = a.argmax(axis: 5)", "np.argmax(a, axis=5)"),
    Case("StatsPefTests.testPeformanceArgmax2", "Stats", "let _ = a.argmax(axis: 0)", "np.argmax(a, axis=0)"),
    Case("ConversionPefTests.testPeformanceArgsort1", "Conversion", "let _ = aneg.argsort(axis: -1)", "np.argsort(aneg, axis=-1)"),
    Case("CreationPefTests.testPeformanceNested1", "Creation", "let _ = MfArray(nested)", "np.array(nested, dtype=np.float32)"),
    Case("CreationPefTests.testPeformanceNums1", "Creation", "let _ = Matft.nums(Float(1), shape: [1000, 1000])", "np.full((1000, 1000), 1, dtype=np.float32)"),
    Case("LinAlgPefTests.testPeformanceInv1", "LinAlg", "let _ = try! Matft.linalg.inv(m)", "np.linalg.inv(m)"),
    Case("BoolPefTests.testPeformanceGreater1", "Bool", "let _ = a > 0", "a > 0"),
    Case("BoolPefTests.testPeformanceGreaterDouble1", "Bool", "let _ = ad > 0", "ad > 0"),
    Case("BoolPefTests.testPeformanceGreater2", "Bool", "let _ = a > b", "a > b"),
    Case("BoolPefTests.testPeformanceEqual1", "Bool", "let _ = a === 0", "a == 0"),
    Case("BoolPefTests.testPeformanceEqual2", "Bool", "let _ = a === b", "a == b"),
    Case("BoolPefTests.testPeformanceEqual3", "Bool", "let _ = a === 5", "a == 5"),
    Case("BoolPefTests.testPeformanceNotEqual1", "Bool", "let _ = a !== 0", "a != 0"),
    Case("BoolPefTests.testPeformanceLogicalNot1", "Bool", "let _ = Matft.logical_not(posb)", "np.logical_not(posb)"),
    Case("BoolPefTests.testPeformanceAllEqual1", "Bool", "let _ = a == a", "np.array_equal(a, a)"),
    Case("ConversionPefTests.testPeformanceAstype1", "Conversion", "let _ = a.astype(.Double)", "a.astype(np.float64)"),
    Case("ConversionPefTests.testPeformanceDeepcopy1", "Conversion", "let _ = Matft.deepcopy(a)", "a.copy()"),
    Case("ConversionPefTests.testPeformanceReshape1", "Conversion", "let _ = a.reshape([1000, 1000])", "a.reshape((1000, 1000)).copy()"),
    Case("FFTPefTests.testPeformanceRfft1", "FFT", "let _ = Matft.fft.rfft(signal)", "np.fft.rfft(signal)"),
    Case("FFTPefTests.testPeformanceRfftVDSP1", "FFT", "let _ = Matft.fft.rfft(signal, vDSP: true)", "np.fft.rfft(signal)"),
    Case("IndexingPefTests.testPeformanceBooleanIndexing1", "Indexing", "let _ = a[posb]", "a[posb]"),
    Case("IndexingPefTests.testPeformanceBooleanIndexing2", "Indexing", "let _ = a[a > 0]", "a[a > 0]"),
    Case("IndexingPefTests.testPeformanceBooleanIndexing3", "Indexing", "let _ = aT[aT > 0]", "aT[aT > 0]"),
    Case("IndexingPefTests.testPeformanceFancyIndexing1", "Indexing", "let _ = a[idx]", "a[idx]"),
    Case("IndexingPefTests.testPeformanceBoolSetter1", "Indexing", "let x = Matft.deepcopy(a); x[x > 0] = MfArray([0])", "x = a.copy(); x[x > 0] = 0"),
    Case("IndexingPefTests.testPeformanceBoolSetter2", "Indexing", "let x = Matft.deepcopy(a); x[posb] = values", "x = a.copy(); x[posb] = values"),
    Case("IndexingPefTests.testPeformanceBoolSetter3", "Indexing", "let x = Matft.deepcopy(a).T; x[x > 0] = MfArray([0])", "x = a.copy().T; x[x > 0] = 0"),
]

_MEASURED_RE = re.compile(
    r"Test Case '-\[\w+\.(\w+) (\w+)\]' measured \[Time, seconds\].*?values: \[([^\]]*)\]"
)
# Printed by `measureWithWarmup` before `measure {}` starts
_CALLS_RE = re.compile(r"MatftBench: -\[(?:\w+\.)?(\w+) (\w+)\] number=(\d+)")


# ---------------------------------------------------------------- pure helpers

def parse_calls_per_sample(text):
    """Extract `{ "<Class>.<method>": calls per sample }` printed by `measureWithWarmup`."""
    return {f"{cls}.{method}": int(n) for cls, method, n in _CALLS_RE.findall(text)}


def parse_xctest_output(text):
    """Extract `{ "<Class>.<method>": [seconds per call, ...] }` from XCTest output."""
    calls = parse_calls_per_sample(text)
    results = {}
    for cls, method, values in _MEASURED_RE.findall(text):
        case_id = f"{cls}.{method}"
        number = calls.get(case_id, 1)
        results[case_id] = [float(v) / number for v in values.split(",") if v.strip()]
    return results


def swift_test_env(warmup, sample_time, base=None):
    """Environment for `swift test`, read by `PerfFixtures` in Tests/PerformanceTests."""
    env = dict(os.environ if base is None else base)
    env["MATFT_BENCH_WARMUP"] = str(warmup)
    env["MATFT_BENCH_SAMPLE_TIME"] = str(sample_time)
    return env


def format_time(sec):
    """Format seconds like `596μs`, `1.04ms`, `17.8ms` (3 significant digits)."""
    for unit, scale in (("s", 1.0), ("ms", 1e-3), ("μs", 1e-6), ("ns", 1e-9)):
        if sec >= scale or unit == "ns":
            v = sec / scale
            if v >= 100:
                return f"{v:.0f}{unit}"
            if v >= 10:
                return f"{v:.1f}{unit}"
            return f"{v:.2f}{unit}"


# XCTest `measure {}` reports systematically slow first samples even after the warm-up
STEADY_SKIP = 3


def _rsd(values):
    mean = statistics.fmean(values)
    return statistics.pstdev(values) / mean if mean else 0.0


def summarize(values):
    mean = statistics.fmean(values)
    std = statistics.pstdev(values)
    steady = values[STEADY_SKIP:] if len(values) > STEADY_SKIP + 1 else values
    return {
        "median": statistics.median(values),
        "mean": mean,
        "std": std,
        "rsd": std / mean if mean else 0.0,
        "rsd_steady": _rsd(steady),  # variation after the leading samples; use this to judge reliability
        "n": len(values),
    }


def replace_between_markers(text, content):
    start = text.find(MARKER_START)
    end = text.find(MARKER_END)
    if start < 0 or end < 0 or end < start:
        raise ValueError(f"markers {MARKER_START} / {MARKER_END} not found")
    return text[:start + len(MARKER_START)] + "\n" + content + "\n" + text[end:]


def _median(results, side, case_id):
    values = results.get(side, {}).get(case_id)
    return statistics.median(values) if values else None


def render_tables(cases, results, baseline=None):
    """Render Markdown tables grouped by category."""
    out = []
    categories = list(dict.fromkeys(c.category for c in cases))
    for category in categories:
        header = "| Matft | time | Numpy | time | Matft / Numpy |"
        sep = "| --- | --- | --- | --- | --- |"
        if baseline is not None:
            header += " Matft vs baseline |"
            sep += " --- |"
        out += [f"- {category}", "", header, sep]
        for c in (c for c in cases if c.category == category):
            m = _median(results, "swift", c.id)
            n = _median(results, "numpy", c.id)
            m_s = format_time(m) if m is not None else "n/a"
            n_s = format_time(n) if n is not None else "n/a"
            if m is not None and n:
                ratio = f"{m / n:.2f}x"
                ratio = f"**{ratio}**" if m > n else ratio
            else:
                ratio = "n/a"
            row = f"| `{c.matft}` | `{m_s}` | `{c.numpy}` | `{n_s}` | {ratio} |"
            if baseline is not None:
                b = _median(baseline, "swift", c.id)
                row += f" {(m / b - 1) * 100:+.1f}% |" if m is not None and b else " n/a |"
            out.append(row)
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def render_env(env):
    return (f"Measured on {env['cpu']}, macOS {env['macos']}, {env['swift']}, "
            f"Python {env['python']}, numpy {env['numpy']} "
            f"(Matft `{env['commit']}`, {env['date']}).")


def render_report(cases, results, env, baseline=None):
    configuration = env.get("configuration", "release")
    return "\n".join([
        render_tables(cases, results, baseline),
        render_env(env),
        "",
        f"Matft: median of XCTest `measure {{}}` in {configuration} build (`swift test -c {configuration}`), "
        "after a warm-up and with several calls per sample (like `timeit`). "
        "Numpy: median of `timeit`. Ratios > 1 (Matft slower) are shown in bold.",
        "",
        "Regenerate with `python3 scripts/benchmark.py --update-docs`.",
    ])


# ---------------------------------------------------------------- side effects

def _run(cmd):
    try:
        return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True).stdout.strip()
    except OSError:
        return "unknown"


def collect_env():
    import numpy as np
    swift = _run(["swift", "--version"]).splitlines()
    swift = next((l for l in swift if "Swift version" in l), "unknown")
    swift = re.sub(r"^.*?(Swift version [\d.]+).*$", r"\1", swift)
    return {
        "cpu": _run(["sysctl", "-n", "machdep.cpu.brand_string"]),
        "macos": _run(["sw_vers", "-productVersion"]),
        "swift": swift,
        "python": platform.python_version(),
        "numpy": np.__version__,
        "commit": _run(["git", "describe", "--always", "--dirty"]),
        "date": datetime.date.today().isoformat(),
    }


def swift_test_command(cases, configuration="release"):
    # SwiftPM matches --filter against "<Target>.<Class>/<method>"
    ids = "|".join(re.escape(c.id).replace("\\.", "/") for c in cases)
    return ["swift", "test", "-c", configuration, "--filter", f"^PerformanceTests\\.({ids})$"]


def run_swift(cases, warmup, sample_time, configuration="release"):
    cmd = swift_test_command(cases, configuration)
    print("$ " + " ".join(cmd), file=sys.stderr)
    proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                          env=swift_test_env(warmup, sample_time))
    output = proc.stdout + proc.stderr
    if proc.returncode != 0:
        sys.stderr.write(output)
        raise SystemExit(f"swift test failed (exit {proc.returncode})")
    results = parse_xctest_output(output)
    missing = [c.id for c in cases if c.id not in results]
    if missing:
        raise SystemExit(f"no measurement found for: {', '.join(missing)}")
    return results


def run_numpy(cases, repeat, number):
    results = {}
    for c in cases:
        timer = timeit.Timer(c.numpy, setup=SETUP)
        timer.timeit(number=1)  # warm-up
        results[c.id] = [t / number for t in timer.repeat(repeat=repeat, number=number)]
        print(f"numpy {c.numpy:<12} {format_time(statistics.median(results[c.id]))}", file=sys.stderr)
    return results


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--filter", help="regex on case id (e.g. 'Bool')")
    p.add_argument("--skip-swift", action="store_true", help="reuse Swift results from latest.json")
    p.add_argument("--skip-numpy", action="store_true", help="reuse Numpy results from latest.json")
    p.add_argument("--baseline", help="previous results JSON to compare Matft against")
    p.add_argument("--update-docs", "--update-readme", dest="update_docs", action="store_true",
                   help="rewrite the table in website/docs/performance.md (--update-readme is the old name)")
    p.add_argument("--warmup", type=float, default=0.5, help="Matft: warm-up seconds per case")
    p.add_argument("--sample-time", type=float, default=0.02, help="Matft: target seconds per sample")
    p.add_argument("--repeat", type=int, default=10, help="Numpy: number of samples")
    p.add_argument("--number", type=int, default=10, help="Numpy: calls per sample")
    p.add_argument("--configuration", choices=["release", "debug"], default="release",
                   help="Matft: build configuration (debug shows what apps built without optimization see)")
    args = p.parse_args(argv)
    if args.update_docs and args.configuration != "release":
        raise SystemExit("--update-docs requires --configuration release")

    cases = [c for c in CASES if not args.filter or re.search(args.filter, c.id)]
    if not cases:
        raise SystemExit("no case matches --filter")
    if args.update_docs and len(cases) != len(CASES):
        raise SystemExit("--update-docs requires all cases (drop --filter)")

    previous = {"results": {}}
    if args.skip_swift or args.skip_numpy:
        with open(LATEST_JSON) as f:
            previous = json.load(f)

    results = {
        "swift": previous["results"]["swift"] if args.skip_swift else run_swift(cases, args.warmup, args.sample_time, args.configuration),
        "numpy": previous["results"]["numpy"] if args.skip_numpy else run_numpy(cases, args.repeat, args.number),
    }
    baseline = None
    if args.baseline:
        with open(args.baseline) as f:
            baseline = json.load(f)["results"]

    # Nothing was re-measured: keep the environment the results were actually measured in.
    env = previous["env"] if args.skip_swift and args.skip_numpy else {**collect_env(), "configuration": args.configuration}
    report = render_report(cases, results, env, baseline)
    print(report)

    os.makedirs(RESULTS_DIR, exist_ok=True)
    with open(LATEST_JSON, "w") as f:
        json.dump({
            "env": env,
            "results": results,
            "summary": {side: {k: summarize(v) for k, v in results[side].items()} for side in results},
        }, f, indent=2, ensure_ascii=False)
        f.write("\n")
    with open(LATEST_MD, "w") as f:
        f.write(report + "\n")

    if args.update_docs:
        with open(PERFORMANCE_DOC) as f:
            text = f.read()
        with open(PERFORMANCE_DOC, "w") as f:
            f.write(replace_between_markers(text, render_report(cases, results, env)))
        print(f"updated {os.path.relpath(PERFORMANCE_DOC, ROOT)}", file=sys.stderr)


if __name__ == "__main__":
    main()
