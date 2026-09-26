# CLAUDE.md

Matft は Swift 製の Numpy ライクな多次元配列ライブラリ．

## 開発ルール

### テスト駆動開発（必須）
実装は必ずテスト駆動（TDD）で行うこと．
1. 先に `Tests/MatftTests/` に失敗するテストを書く（期待値は可能な限り Numpy の出力に合わせる）
   - 期待値は `python/gen_*.py` で生成する（環境構築・再生成手順は `python/README.md`）
2. テストが失敗することを確認する
3. テストを通す最小限の実装を行う
4. 全テストが通ることを確認してからリファクタリングする

```sh
swift test                               # 全テスト
swift test --filter MatftTests.MathTest  # 特定のテストクラス
```

### 命名規則
関数名・引数名・挙動は Numpy に寄せること（例: `np.expand_dims` → `Matft.expand_dims`）．
