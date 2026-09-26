---
name: release
description: Matft の新バージョンをリリースする手順（バージョン決定 → テスト確認 → リリースノート作成 → annotated tag 付与・push → GitHub Releases 公開）。「バージョンアップして」「リリースして」「0.3.4 を出して」「タグ打って」「Releases 作って」「新しいバージョン公開」など，Matft のバージョンを上げる・タグを付ける・GitHub Release を作る/更新する話が出たら，明示的に "skill" と言われなくても必ずこのスキルを使うこと。
---

# Matft リリース手順

Matft は SwiftPM で配布しており，利用者は **`x.x.x` 形式の git タグ** でバージョンを解決する（`v` 接頭辞は付けない。SwiftPM がセマンティックバージョンとして認識できなくなるため）。
そのため「タグを正しいコミットに付けて push し，それに紐づく GitHub Release を公開する」ことがリリースの本体になる。
CocoaPods（`Matft.podspec`）と Carthage はこのスキルの対象外なので触らない。

タグの push と Release の公開は外部に公開される操作で，利用者の `Package.resolved` に即座に影響する。やり直しが効きにくいので，**公開系コマンドを実行する前に必ずユーザーの確認を取る**。

## 1. 事前チェックとタグ対象コミットの決定

リリースの基準は「作業ツリー」ではなく **タグを付ける 1 つのコミット（以下 `<commit>`）** である。以降のログ・テスト・CI 確認はすべてこの `<commit>` に対して行う。こうしておけば，手元に無関係な作業中の変更や運用だけの未 push コミットがあってもリリースは進められる。

```sh
git fetch origin --tags
git branch --show-current
git status --porcelain
git rev-list --left-right --count origin/main...HEAD   # "<origin だけにある数> <ローカルだけにある数>"
gh auth status
```

- `<commit>` は通常 `origin/main` の先頭（`git rev-parse origin/main`）。ブランチ名ではなくコミットハッシュで指定する（後でブランチが動いても指す先が変わらないように）。
- ローカルに未 push のコミットがある場合：その中にリリースに含めるべきコード変更があるかを見る。CLAUDE.md 追加など運用だけの変更なら無視して `origin/main` を対象にしてよい。コード変更なら，先に push するか（ユーザー確認後）ユーザーに聞く。
- 未コミットの変更があっても，`<commit>` を明示してタグを付けるならリリース内容には入らない。ただし確認時に「作業ツリーの変更は含まれない」ことを一言添える。
- 止まるべきなのは `gh` 未認証，origin 側に取り込んでいないコミットがあってどれを出すか不明，など対象が決められないときだけ。

## 2. バージョン決定

```sh
git tag --sort=-v:refname | head -5                   # 直近のタグ
git log --oneline <最新タグ>..<commit>                # 前回リリース以降の変更
```

- ユーザーがバージョンを指定していればそれを使う。`x.x.x` 形式か，既存タグと重複していないか，最新タグより大きいかを検証する。
- 指定がなければ変更内容から提案する：破壊的変更（Numpy 挙動に合わせた仕様変更など）や新機能 → minor，バグ修正のみ → patch。0.x 系なので最終判断はユーザーに委ねる。

## 3. テスト・CI の確認

CLAUDE.md の方針どおり，全テストが通っていないものはリリースしない。作業ツリーで `swift test` すると未コミットの TDD 途中の変更（Red 状態のテストなど）まで巻き込んで失敗しうるので，`<commit>` をクリーンに取り出してテストする。

```sh
git worktree add <scratchpad>/matft-release <commit>
(cd <scratchpad>/matft-release && swift test)
git worktree remove <scratchpad>/matft-release

gh run list --commit <commit>      # Swift / wasm ワークフローが両方 success か
```

作業ツリーがクリーンで HEAD が `<commit>` と同じなら，その場で `swift test` してよい。テストか CI が失敗していればリリースを中断し，原因を報告する。

## 4. 既存 Draft Release の確認

GitHub 上に同名の Draft Release（タグ未設定のことが多い）が作られていて，事前にリリースノートが書かれていることがある。これを捨てずに流用する。

```sh
gh api repos/jjjkkkjjj/Matft/releases \
  --jq '.[] | select(.draft and .name=="<version>") | {id, name, tag_name, body}'
```

見つかればその `id` と `body` を控える。

## 5. リリースノート作成

`git log <最新タグ>..<commit> --pretty='%h %s'` を元に作る。Draft の本文があればそれをベースにし，漏れている変更を追記する（Draft 作成後にマージされたものが漏れがち）。

コミット件名は `fixed #47` のように番号しか書かれていないことが多い。その場合はタイトルを引いて中身を把握する：

```sh
gh api repos/jjjkkkjjj/Matft/issues/<n> --jq '{title, pull_request: (.pull_request != null)}'
```

既存リリースに合わせてこの形式で書く（該当なしのセクションは `N/A`）：

```markdown
- New Features
  - Add `Matft.foo` (#100)
- Improvement
  - N/A
- Bug fixed
  - `Matft.bar` returns wrong shape for negative axis (#101)
```

- 英語で簡潔に。関数名などはバッククォートで囲む。
- 載せるのはライブラリ利用者に影響する変更（`Sources/` の機能・挙動・公開 API・警告など）。CI/workflow の変更，テストだけの変更，README・CLAUDE.md などドキュメントや運用の変更，merge コミットは載せない。
- 関連する PR/Issue 番号を末尾に付ける（複数なら `(#57, #58)`）。

## 6. ユーザー確認

ここまでの結果を提示して，明示的な OK をもらう：

- バージョン番号
- タグを付けるコミット（ハッシュと件名）
- テスト / CI 結果
- リリースノート全文
- Draft を流用するか新規作成か

## 7. タグ付けと push

```sh
git tag -a <version> -m "<version>" <commit>
git push origin <version>
```

`git push --tags` ではなくタグ名を指定して push する。ローカルに残っている古い/試しのタグまで一緒に公開してしまうのを防ぐため。

## 8. GitHub Release 公開

リリースノートは一時ファイル（スクラッチパッド）に書き出してから渡す。改行やバッククォートのエスケープ事故を避けるため。

**Draft がある場合**（タグ未設定の Draft は `gh release edit` でタグ名から引けないので API で更新する）：

```sh
gh api -X PATCH repos/jjjkkkjjj/Matft/releases/<draft-id> \
  -f tag_name=<version> -f name=<version> \
  -f body="$(cat <notes-file>)" \
  -F draft=false -f make_latest=true
```

**Draft がない場合**：

```sh
gh release create <version> --verify-tag --title <version> --notes-file <notes-file> --latest
```

`--verify-tag` は push 済みタグが存在しないと失敗させるオプションで，gh が勝手に別コミットへタグを作るのを防ぐ。

## 9. 確認と報告

```sh
gh release view <version>
gh release list --limit 3        # 新バージョンが Latest になっていること
git ls-remote --tags origin <version>
```

Release の URL と，SwiftPM 利用者は `File > Packages > Update to Latest Package Versions` で取得できる旨を報告する。

## やり直しが必要になったとき

公開後に誤りが見つかった場合は，ユーザーの確認を取ったうえで：

```sh
gh release delete <version> --yes        # Release を消す（必要なら）
git tag --delete <version>
git push origin :refs/tags/<version>
```

一度公開したタグは利用者側でキャッシュされている可能性があるため，同じ番号の付け直しより次のパッチ番号で出し直す方が安全なことも伝える。
