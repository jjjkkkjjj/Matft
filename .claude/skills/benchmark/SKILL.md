---
name: benchmark
description: Matft の PerformanceTests を Numpy と比較計測し，結果を報告する（必要なら README の速度比較表も更新する）手順。「ベンチ回して」「Numpy と速度比較して」「README の速度表を更新して」「perf 計測」「最適化の効果を測って」など，Matft の実行速度を測る・Numpy と比べる・README の Performance 節を更新する話が出たら，明示的に "skill" と言われなくても必ずこのスキルを使うこと。
---

# Matft vs Numpy ベンチマーク

計測はすべて `scripts/benchmark.py` 1 本で行う。

- Matft 側：`swift test -c release` で `Tests/PerformanceTests` を実行し，XCTest `measure {}` の出力をパースする
  - 各テストは `measureWithWarmup {}`（`Tests/PerformanceTests/PerfFixtures.swift`）で計測する。次の 2 段階で動く。
    1. `--warmup` 秒（既定 0.5 秒）ブロックを空回しする。
    2. 1 サンプルが `--sample-time` 秒（既定 20ms）程度になるよう，1 サンプルあたりの呼び出し回数 N を決めて `measure {}` する（`timeit` の `number` と同じ考え方）。
  - N は `MatftBench: -[<Class> <method>] number=N` という行で出力される。スクリプトはサンプル値を N で割って 1 回あたりの時間にする。
  - 1 サンプル 1 回だと，XCTest 自身の反復ごとのオーバーヘッドが速いケースを支配してしまう。例えば実測 0.14ms の処理が 0.5ms 前後と報告される。
- Numpy 側：同じ式を `timeit` で計測する
- 結果：両者の median を比較して `benchmarks/results/latest.{json,md}` に書き出す

README の Performance 節は `<!-- BENCHMARK:START -->` 〜 `<!-- BENCHMARK:END -->` の間が自動生成になっている。手で編集しないこと。

計測はローカルの Mac 専用。CI ランナーは計測のばらつきが大きいので，README の数値には使わない。

## 1. 事前確認

```sh
git status --porcelain
python3 -c "import numpy; print(numpy.__version__)"
```

- 未コミットの変更があっても計測はできる。ただしレポートのコミット欄が `-dirty` になる。README に載せる計測なら，コミット後に回すようユーザーに一言添える。
- numpy が無ければ `pip3 install numpy` を提案する。勝手にインストールしない。
- 電源接続と，重い処理（ビルドやブラウザの動画，VM など）を止めてもらうことを一言伝える。`uptime` の load average と `ps -Ao pcpu,comm -r | head` で負荷を確認できる。

## 2. 計測

```sh
cp benchmarks/results/latest.json /tmp/matft-bench-baseline.json   # 前回と比べたいとき（存在すれば）
python3 scripts/benchmark.py [--baseline /tmp/matft-bench-baseline.json] [--filter Bool]
```

- release ビルドを含むので数分かかる。timeout は長め（10 分）にする。
- `--filter <regex>`：ケース ID で絞り込む。例 `Bool`，`Sin`。
- `--skip-swift` / `--skip-numpy`：前回の JSON を再利用する。例えば Numpy だけ測り直すとき。
- `--warmup` / `--sample-time`：Matft 側のウォームアップ秒数と，1 サンプルの目標秒数。
- `--repeat` / `--number`：Numpy の timeit のサンプル数と，1 サンプルあたりの呼び出し回数。
- `--configuration debug`：Matft を debug ビルドで測る。SwiftPM は依存パッケージをアプリと同じ構成でビルドするため，最適化なしでビルドしたアプリでの速度になる。`initialize(repeating:)` のようなジェネリックなループは -Onone で桁違いに遅くなるので，割り当てや要素ごとのループを変えたときは release と両方測る。`--update-readme` とは併用できない。

### 最適化の効果を測るとき（A/B 比較）

以前に保存した JSON を baseline にすると，別の時刻・別の負荷状況の値と比べることになり，誤差が大きい。背景負荷で ±100% 以上ずれた例もある。最適化の効果は，変更前のコミットを同じ計測方法で交互に測って比べる。

```sh
git worktree add /tmp/matft-before <変更前のコミット>
cp -R Tests/PerformanceTests/. /tmp/matft-before/Tests/PerformanceTests/   # 計測方法（ハーネスとケース）を揃える
cp scripts/benchmark.py /tmp/matft-before/scripts/
# before → after → before → after の順に交互に回す（Matft のみなら --skip-numpy）
(cd /tmp/matft-before && python3 scripts/benchmark.py --skip-numpy && cp benchmarks/results/latest.json /tmp/before-1.json)
python3 scripts/benchmark.py --skip-numpy && cp benchmarks/results/latest.json /tmp/after-1.json
# ...2 回目も同様。終わったら git worktree remove /tmp/matft-before
```

- 変更していないケースが ±数% に収まっていれば，その回の計測は信頼できる。ノイズの対照として使う。
- 最後に `--skip-swift` で Numpy だけ測り直すと，Numpy との倍率も同じ条件で揃う。

## 3. 報告

`benchmarks/results/latest.md` と `latest.json` の `summary` を読み，次の点を簡潔にまとめる。

- Matft が Numpy より遅いケース（倍率が太字のもの）。倍率が大きい順に並べる。
- `--baseline` を付けたときは，前回からの改善・悪化（±10% 以上のもの）。
- `summary.swift.*.rsd_steady` が大きいケース（目安 10% 以上）。その数値はばらつきが大きく信頼度が低いことを注記する。
  - `rsd` は使わない。XCTest `measure {}` は，ウォームアップ後でも最初の 2〜3 サンプルが 1.3〜2 倍遅い。そのため `rsd` は常に 20〜30% に膨らむ。
  - `rsd_steady` は先頭 3 サンプルを除いたばらつき。median 自体はこの影響をほぼ受けない。

表の全文を貼る必要はない。要点と，気になる数値だけを示す。

## 4. README 更新（ユーザーが了承したときだけ）

```sh
python3 scripts/benchmark.py --skip-swift --skip-numpy --update-readme   # 直前の計測結果をそのまま README に反映
git diff README.md
```

- `--update-readme` は `--filter` と併用できない（全ケースが必要）。
- 差分がマーカーの間だけに収まっていることを確認して見せる。
- コミットはユーザーの指示があるときだけ行う。

## 5. ケースを追加・変更するとき

ケースは次の 3 か所で揃えておく必要がある。

1. `Tests/PerformanceTests/*PefTests.swift` にテストメソッドを追加する。入力は `PerfFixtures.swift` を使う。計測は `self.measure {}` ではなく必ず `self.measureWithWarmup {}` で書く。`self.measure {}` だとウォームアップされず，呼び出し回数の行も出ない（N=1 として扱われる）。
2. `scripts/benchmark.py` の `CASES` に `Case("<Class>.<method>", "<Category>", "<Swift 式>", "<numpy 式>")` を追加する。新しい入力が必要なら `SETUP` と `PerfFixtures` の両方に追加する。
3. README の Performance 節冒頭にある Swift / Python のセットアップ例も，入力を変えたなら合わせて更新する。

`scripts/benchmark.py` のパーサーや描画を変えたときは，先に `scripts/test_benchmark.py` にテストを追加し（TDD），`python3 -m unittest scripts/test_benchmark.py` で確認する。
