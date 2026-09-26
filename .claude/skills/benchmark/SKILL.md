---
name: benchmark
description: Procedure for benchmarking Matft's PerformanceTests against Numpy and reporting the results (and, when asked, updating the speed comparison table on the docs site, website/docs/performance.md). Use this skill whenever the conversation is about measuring Matft's speed, comparing it with Numpy, or updating the Performance section of the docs (formerly the README) — e.g. "run the benchmarks", "compare speed with Numpy", "update the perf table", "measure the effect of this optimization", or in Japanese「ベンチ回して」「Numpy と速度比較して」「README / ドキュメントの速度表を更新して」「perf 計測」「最適化の効果を測って」— even if the word "skill" is never mentioned.
---

# Matft vs Numpy benchmark

All measurement is done by a single script, `scripts/benchmark.py`.

- Matft side: runs `Tests/PerformanceTests` with `swift test -c release` and parses the output of XCTest `measure {}`.
  - Each test is measured with `measureWithWarmup {}` (`Tests/PerformanceTests/PerfFixtures.swift`), which works in two stages:
    1. Spin the block for `--warmup` seconds (default 0.5 s).
    2. Choose the number of calls per sample, N, so that one sample takes about `--sample-time` seconds (default 20 ms), then run `measure {}` (the same idea as `number` in `timeit`).
  - N is printed as a line `MatftBench: -[<Class> <method>] number=N`. The script divides each sample by N to get the time per call.
  - With one call per sample, XCTest's own per-iteration overhead dominates fast cases. For example, an operation that really takes 0.14 ms is reported as about 0.5 ms.
- Numpy side: measures the same expression with `timeit`.
- Result: compares the medians of both and writes `benchmarks/results/latest.{json,md}`.

On the docs site's Performance page (`website/docs/performance.md`), everything between `<!-- BENCHMARK:START -->` and `<!-- BENCHMARK:END -->` is generated. Do not edit it by hand.

Measure on a local Mac only. CI runners are too noisy, so never use their numbers in the docs.

## 1. Pre-checks

```sh
git status --porcelain
python3 -c "import numpy; print(numpy.__version__)"
```

- You can measure with uncommitted changes, but the report's commit field becomes `-dirty`. If the numbers are going into the docs, tell the user to run it after committing.
- If numpy is missing, suggest `pip3 install numpy`. Do not install it yourself.
- Ask the user to plug in the power and stop heavy work (builds, video in the browser, VMs, etc.). You can check the load with the load average from `uptime` and `ps -Ao pcpu,comm -r | head`.

## 2. Measure

```sh
cp benchmarks/results/latest.json /tmp/matft-bench-baseline.json   # to compare with the previous run (if it exists)
python3 scripts/benchmark.py [--baseline /tmp/matft-bench-baseline.json] [--filter Bool]
```

- It includes a release build, so it takes several minutes. Use a long timeout (10 minutes).
- `--filter <regex>`: narrow down by case ID, e.g. `Bool`, `Sin`.
- `--skip-swift` / `--skip-numpy`: reuse the previous JSON, e.g. to re-measure only Numpy.
- `--warmup` / `--sample-time`: warm-up seconds and target seconds per sample on the Matft side.
- `--repeat` / `--number`: number of samples and calls per sample for Numpy's timeit.
- `--configuration debug`: measure Matft in a debug build. SwiftPM builds dependencies with the same configuration as the app, so this is the speed seen by an app built without optimization. Generic loops such as `initialize(repeating:)` become orders of magnitude slower at -Onone, so when you change allocation or per-element loops, measure both release and debug. Cannot be combined with `--update-readme`.

### Measuring the effect of an optimization (A/B comparison)

Using a previously saved JSON as the baseline compares against values taken at a different time under different load, which is very noisy — background load has shifted results by ±100% or more. Measure the effect of an optimization by alternating runs of the pre-change commit with the same measurement harness.

```sh
git worktree add /tmp/matft-before <commit before the change>
cp -R Tests/PerformanceTests/. /tmp/matft-before/Tests/PerformanceTests/   # align the harness and cases
cp scripts/benchmark.py /tmp/matft-before/scripts/
# Alternate before → after → before → after (--skip-numpy if only Matft matters)
(cd /tmp/matft-before && python3 scripts/benchmark.py --skip-numpy && cp benchmarks/results/latest.json /tmp/before-1.json)
python3 scripts/benchmark.py --skip-numpy && cp benchmarks/results/latest.json /tmp/after-1.json
# ...repeat for the second round. When done: git worktree remove /tmp/matft-before
```

- If the cases you did not change stay within a few percent, that round is trustworthy. Use them as a noise control.
- Finally, re-measure Numpy alone with `--skip-swift` so the Numpy ratios are taken under the same conditions.

## 3. Report

Read `benchmarks/results/latest.md` and the `summary` in `latest.json`, and briefly summarize:

- Cases where Matft is slower than Numpy (the ratios in bold), sorted by ratio, largest first.
- With `--baseline`, improvements and regressions from the previous run (only those of ±10% or more).
- Cases with a large `summary.swift.*.rsd_steady` (roughly 10% or more). Note that those numbers are noisy and less reliable.
  - Do not use `rsd`. Even after the warm-up, the first 2–3 samples of XCTest `measure {}` are 1.3–2× slower, so `rsd` is always inflated to 20–30%.
  - `rsd_steady` is the spread excluding the first 3 samples. The median itself is barely affected.

No need to paste the whole table. Show only the key points and the numbers that stand out.

## 4. Update the docs (only when the user agrees)

```sh
python3 scripts/benchmark.py --skip-swift --skip-numpy --update-docs   # write the last results into website/docs/performance.md as-is
git diff website/docs/performance.md
```

- `--update-docs` (formerly `--update-readme`) cannot be combined with `--filter` (it needs all cases).
- Confirm and show that the diff stays between the markers.
- Commit only when the user tells you to.

## 5. Adding or changing cases

A case must be kept in sync in three places:

1. Add a test method to `Tests/PerformanceTests/*PefTests.swift`, using inputs from `PerfFixtures.swift`. Always measure with `self.measureWithWarmup {}`, not `self.measure {}`. `self.measure {}` has no warm-up and does not print the call-count line (it is treated as N=1).
2. Add `Case("<Class>.<method>", "<Category>", "<Swift expr>", "<numpy expr>")` to `CASES` in `scripts/benchmark.py`. If it needs a new input, add it to both `SETUP` and `PerfFixtures`.
3. If you changed inputs, also update the Swift / Python setup examples at the top of `website/docs/performance.md`.

When you change the parser or the rendering in `scripts/benchmark.py`, add a test to `scripts/test_benchmark.py` first (TDD) and check with `python3 -m unittest scripts/test_benchmark.py`.
