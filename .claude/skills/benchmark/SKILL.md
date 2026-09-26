---
name: benchmark
description: Matft の PerformanceTests を Numpy と比較計測し，結果を報告する（必要なら README の速度比較表も更新する）手順。「ベンチ回して」「Numpy と速度比較して」「README の速度表を更新して」「perf 計測」「最適化の効果を測って」など，Matft の実行速度を測る・Numpy と比べる・README の Performance 節を更新する話が出たら，明示的に "skill" と言われなくても必ずこのスキルを使うこと。
---

# Matft vs Numpy ベンチマーク

計測はすべて `scripts/benchmark.py` 1 本で行う。

- Matft 側：`swift test -c release` で `Tests/PerformanceTests` を実行し，XCTest `measure {}` の出力をパースする
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
- 電源接続と，重い処理（ビルドやブラウザの動画など）を止めてもらうことを一言伝える。

## 2. 計測

```sh
cp benchmarks/results/latest.json /tmp/matft-bench-baseline.json   # 前回と比べたいとき（存在すれば）
python3 scripts/benchmark.py [--baseline /tmp/matft-bench-baseline.json] [--filter Bool]
```

- release ビルドを含むので数分かかる。timeout は長め（10 分）にする。
- `--filter <regex>`：ケース ID で絞り込む。例 `Bool`，`Sin`。
- `--skip-swift` / `--skip-numpy`：前回の JSON を再利用する。例えば Numpy だけ測り直すとき。
- `--repeat` / `--number`：Numpy の timeit のサンプル数と，1 サンプルあたりの呼び出し回数。

## 3. 報告

`benchmarks/results/latest.md` と `latest.json` の `summary` を読み，次の点を簡潔にまとめる。

- Matft が Numpy より遅いケース（倍率が太字のもの）。倍率が大きい順に並べる。
- `--baseline` を付けたときは，前回からの改善・悪化（±10% 以上のもの）。
- `summary.*.rsd` が大きいケース（目安 30% 以上）。その数値はばらつきが大きく信頼度が低いことを注記する。

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

1. `Tests/PerformanceTests/*PefTests.swift` にテストメソッドを追加する。入力は `PerfFixtures.swift` を使う。
2. `scripts/benchmark.py` の `CASES` に `Case("<Class>.<method>", "<Category>", "<Swift 式>", "<numpy 式>")` を追加する。新しい入力が必要なら `SETUP` と `PerfFixtures` の両方に追加する。
3. README の Performance 節冒頭にある Swift / Python のセットアップ例も，入力を変えたなら合わせて更新する。

`scripts/benchmark.py` のパーサーや描画を変えたときは，先に `scripts/test_benchmark.py` にテストを追加し（TDD），`python3 -m unittest scripts/test_benchmark.py` で確認する。
