#!/usr/bin/env python3
"""Benchmark Matft (Tests/PerformanceTests) against Numpy and report the results.

Usage:
    python3 scripts/benchmark.py                  # run both, write benchmarks/results/latest.{json,md}
    python3 scripts/benchmark.py --update-readme  # also rewrite the table in README.md
    python3 scripts/benchmark.py --skip-swift     # reuse Swift results from the previous JSON
    python3 scripts/benchmark.py --baseline old.json

Matft is measured with `swift test -c release --filter PerformanceTests` (XCTest `measure {}`),
Numpy with `timeit`. Both report the median per-call time.
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
README = os.path.join(ROOT, "README.md")

MARKER_START = "<!-- BENCHMARK:START -->"
MARKER_END = "<!-- BENCHMARK:END -->"

# Keep in sync with Tests/PerformanceTests/PerfFixtures.swift and the snippets in README.md.
SETUP = """\
import numpy as np
a = np.arange(10**6).reshape((10,10,10,10,10,10))
ad = a.astype(np.float64)
aneg = np.arange(0, -10**6, -1).reshape((10,10,10,10,10,10))
aT = a.T
b = a.transpose((0,3,4,2,1,5))
c = a.transpose((1,2,3,4,5,0))
posb = a > 0
"""


class Case(NamedTuple):
    id: str        # "<XCTestCase class>.<test method>"
    category: str  # table the case belongs to
    matft: str     # Swift expression shown in README
    numpy: str     # Numpy statement measured by timeit (also shown in README)


CASES = [
    Case("ArithmeticPefTests.testPeformanceAdd1", "Arithmetic", "let _ = a+aneg", "a+aneg"),
    Case("ArithmeticPefTests.testPeformanceAdd2", "Arithmetic", "let _ = b+aT", "b+aT"),
    Case("ArithmeticPefTests.testPeformanceAdd3", "Arithmetic", "let _ = c+aT", "c+aT"),
    Case("MathPefTests.testPeformanceSin1", "Math", "let _ = Matft.math.sin(a)", "np.sin(a)"),
    Case("MathPefTests.testPeformanceSin2", "Math", "let _ = Matft.math.sin(b)", "np.sin(b)"),
    Case("MathPefTests.testPeformanceSign1", "Math", "let _ = Matft.math.sign(a)", "np.sign(a)"),
    Case("MathPefTests.testPeformanceSign2", "Math", "let _ = Matft.math.sign(b)", "np.sign(b)"),
    Case("BoolPefTests.testPeformanceGreater1", "Bool", "let _ = a > 0", "a > 0"),
    Case("BoolPefTests.testPeformanceGreaterDouble1", "Bool", "let _ = ad > 0", "ad > 0"),
    Case("BoolPefTests.testPeformanceGreater2", "Bool", "let _ = a > b", "a > b"),
    Case("BoolPefTests.testPeformanceEqual1", "Bool", "let _ = a === 0", "a == 0"),
    Case("BoolPefTests.testPeformanceEqual2", "Bool", "let _ = a === b", "a == b"),
    Case("IndexingPefTests.testPeformanceBooleanIndexing1", "Indexing", "let _ = a[posb]", "a[posb]"),
    Case("IndexingPefTests.testPeformanceBooleanIndexing2", "Indexing", "let _ = a[a > 0]", "a[a > 0]"),
]

_MEASURED_RE = re.compile(
    r"Test Case '-\[\w+\.(\w+) (\w+)\]' measured \[Time, seconds\].*?values: \[([^\]]*)\]"
)


# ---------------------------------------------------------------- pure helpers

def parse_xctest_output(text):
    """Extract `{ "<Class>.<method>": [seconds, ...] }` from XCTest output."""
    results = {}
    for cls, method, values in _MEASURED_RE.findall(text):
        results[f"{cls}.{method}"] = [float(v) for v in values.split(",") if v.strip()]
    return results


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


def summarize(values):
    mean = statistics.fmean(values)
    std = statistics.pstdev(values)
    return {
        "median": statistics.median(values),
        "mean": mean,
        "std": std,
        "rsd": std / mean if mean else 0.0,
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
    """Render README-style Markdown tables grouped by category."""
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
    return "\n".join([
        render_tables(cases, results, baseline),
        render_env(env),
        "",
        "Matft: median of XCTest `measure {}` in release build (`swift test -c release`). "
        "Numpy: median of `timeit`. Ratios > 1 (Matft slower) are shown in bold.",
        "",
        "Regenerate with `python3 scripts/benchmark.py --update-readme`.",
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


def run_swift(cases):
    # SwiftPM matches --filter against "<Target>.<Class>/<method>"
    ids = "|".join(re.escape(c.id).replace("\\.", "/") for c in cases)
    cmd = ["swift", "test", "-c", "release", "--filter", f"^PerformanceTests\\.({ids})$"]
    print("$ " + " ".join(cmd), file=sys.stderr)
    proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
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
    p.add_argument("--update-readme", action="store_true", help="rewrite the table in README.md")
    p.add_argument("--repeat", type=int, default=10, help="Numpy: number of samples")
    p.add_argument("--number", type=int, default=10, help="Numpy: calls per sample")
    args = p.parse_args(argv)

    cases = [c for c in CASES if not args.filter or re.search(args.filter, c.id)]
    if not cases:
        raise SystemExit("no case matches --filter")
    if args.update_readme and len(cases) != len(CASES):
        raise SystemExit("--update-readme requires all cases (drop --filter)")

    previous = {"results": {}}
    if args.skip_swift or args.skip_numpy:
        with open(LATEST_JSON) as f:
            previous = json.load(f)

    results = {
        "swift": previous["results"]["swift"] if args.skip_swift else run_swift(cases),
        "numpy": previous["results"]["numpy"] if args.skip_numpy else run_numpy(cases, args.repeat, args.number),
    }
    baseline = None
    if args.baseline:
        with open(args.baseline) as f:
            baseline = json.load(f)["results"]

    # Nothing was re-measured: keep the environment the results were actually measured in.
    env = previous["env"] if args.skip_swift and args.skip_numpy else collect_env()
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

    if args.update_readme:
        with open(README) as f:
            text = f.read()
        with open(README, "w") as f:
            f.write(replace_between_markers(text, render_report(cases, results, env)))
        print(f"updated {os.path.relpath(README, ROOT)}", file=sys.stderr)


if __name__ == "__main__":
    main()
