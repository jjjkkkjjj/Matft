---
name: docs
description: Procedure for writing and updating Matft's documentation (the Docusaurus site in website/ and the doc comments on the public API that become the Swift-DocC API reference). Use it to keep docs in sync when adding or changing functions or types, to add or fix guide pages and the NumPy mapping tables, to rewrite /// or /** */ comments, to fix DocC warnings, and to check that the site builds. Use this skill whenever the conversation is about Matft's documentation or comments — e.g. "write docs", "update the docs", "fix the API comments", "add it to the NumPy mapping table", "add a guide page", "get rid of the DocC warnings", "reflect it on the site", or in Japanese「ドキュメント書いて」「docs 更新して」「API コメント直して」「NumPy 対応表に追加して」「ガイドにページ追加」「DocC の警告消して」「サイトに反映して」— even if the word "skill" is never mentioned. Also use it when updating docs in a PR that implements a new feature.
---

# Writing Matft documentation

Matft's documentation has two layers.

| Layer | Location | Role |
|---|---|---|
| Site (Docusaurus) | `website/docs/` | Prose: guides, NumPy mapping tables, performance, contributing |
| API reference (Swift-DocC) | Doc comments in `Sources/Matft/**/*.swift` + `Sources/Matft/Matft.docc/Matft.md` | Spec of every public symbol |

Both are built by `.github/workflows/docs.yml` and published to GitHub Pages (https://jjjkkkjjj.github.io/Matft/, API at `/Matft/api/documentation/matft`). CI treats **DocC warnings as errors** and **broken site links as errors**, so pass the same checks locally before opening a PR.

The README is only an entry point (overview, examples, installation, links). Do not add details to the README; write them on the site and link to them.

## 1. Decide what to update

Where each kind of change needs to be reflected. The NumPy mapping tables and the Topics in `Matft.md` are the ones most often missed.

| Change | Update |
|---|---|
| Public function/method added or signature changed | That symbol's doc comment (2.), one row in the table in `website/docs/numpy-mapping/<category>.md` |
| Behavior changed (types, return value, difference from Numpy) | The comment, code examples and output on the relevant guide page, Method / Complex columns of the mapping table |
| Public type (enum / struct / class) added | Comments (the type and every case), the right group under `## Topics` in `Sources/Matft/Matft.docc/Matft.md` |
| Headline feature added | A guide page or section (3.); if needed, the Features in `website/docs/intro.md` and one Features line in the README |
| Image processing case added | Create comparison images with the `image-visual-check` skill and put them in `website/docs/guide/image.md` |
| Benchmark table | The `benchmark` skill (`--update-docs`). Never edit by hand |

## 2. Doc comments (API reference)

### Read the implementation before writing

Comments describe how the implementation actually behaves. Guessing from the signature or old comments publishes a false spec on DocC. In particular, check these in the implementation:

- Supported types, and the `mftype` of the result (e.g. integer input becomes Float)
- Whether complex is supported: if it calls `unsupport_complex(...)`, it is not → write it in `- Precondition:`
- The meaning of defaults such as `axis` / `keepDims`, and the behavior when axis is omitted
- Whether the return value is a **view (shares memory with the original) or a copy**
- If it `throws`, which `MfError` cases it throws (only cases actually thrown)
- Differences from Numpy (scipy / cv2 / PIL / librosa)

When the implementation and the comment disagree and you cannot tell which is intended (i.e. a suspected bug), **do not fix the code**: make the comment match the actual behavior and report the suspicion to the user. The fix goes in a separate PR following the TDD rule in CLAUDE.md. Fixing code on the side during documentation work sneaks in untested behavior changes.

### Format

Match the existing format of each file (`/** ... */` or `///`). Do not mix them.

```swift
/**
   Return the indices of the elements that are non-zero.

   Equivalent to `numpy.nonzero`. NaN counts as non-zero. The indices are listed in row-major order.

   - Parameters:
        - mfarray: The input array.
   - Returns: One 1-d `.Int` array per dimension of `mfarray`, holding the indices of the non-zero elements along that dimension.
   - Precondition: Complex arrays are not supported.
*/
public static func nonzero(_ mfarray: MfArray) -> [MfArray]{
```

- First line: a one-sentence summary (shown in DocC listings). Details after a blank line.
- If there is a counterpart, write `Equivalent to \`numpy.xxx\`.` (likewise for cv2 / PIL / transformers / librosa / scipy).
- List every argument under `- Parameters:` (capital P). **Names must match the internal names in the signature** (a mismatch causes a DocC warning → CI failure). Do not write meaningless descriptions like `mfarray: mfarray`.
- `- Returns:` / `- Throws:` / `- Precondition:` / `- Note:` (differences from Numpy and caveats).
- For method versions, write `Method version of \`Matft.transpose(_:axes:)\`.` and repeat only the key points.
- For operators, write the Numpy counterpart (`*&` is `@`, `===` is element-wise `==`, `==` is `numpy.array_equal`).
- For internal helpers that happen to be public, write `- Note: This is an implementation detail of Matft and may change.` Do not change the access level.
- Document protocol requirements on the requirement. No need to document each conforming implementation for `Int` / `Float` etc. (DocC inherits the requirement's description).
- Use ` ``Symbol`` ` double-backquote links only when you are sure they resolve. Unresolved links become warnings, so normally write `code`.
- Write in English.

### Code examples

Add short ```` ```swift ```` examples only to major entry points (creation functions, commonly used operations, image/audio preprocessing, etc.). **If you include output, copy values straight from a test or use only results actually run as in 4.** Never guess output.

## 3. Site (website/)

### Structure

```
website/
  docs/intro.md, performance.md, contributing.md
  docs/getting-started/   installation, quick-start
  docs/guide/             mfarray, indexing, views, manipulation, arithmetic, math-and-stats, linalg, complex, image, audio, mlx
  docs/numpy-mapping/     index (legend) + mapping tables by category
  sidebars.ts             ← always register new pages here (docsSidebar / mappingSidebar)
  docusaurus.config.ts    navbar, footer, baseUrl=/Matft/
  src/pages/index.tsx     top page (Numpy vs Matft code comparison and feature cards)
  scripts/copy-assets.mjs Tests/MatftTests/files/images/compare → static/img/compare (copied at build time, not tracked by git)
```

### Rules

- `.md` is parsed as **CommonMark** (`markdown.format: 'detect'`). JSX / MDX syntax is not available (use `.mdx` for that). In exchange, `<`, `{` in tables and HTML comments (the `BENCHMARK` markers) can be written as-is.
- Use admonitions for notes: `:::note` / `:::caution` / `:::warning` / `:::info Beta` … `:::`.
- Link to other pages with relative `.md` paths (e.g. `../numpy-mapping/math.md`, `./views.md#copy`). Use file paths rather than URLs so broken links are detected at build time.
- Comparison images: `![alt](/img/compare/<case>.png)`. Do not copy images into website and commit them.
- Link to the API reference with `pathname:///api/documentation/matft` (no trailing slash, because of `trailingSlash: false`).
- Give new pages a `title:` in the front matter and add them to `sidebars.ts`.

### NumPy mapping tables

The tables in `website/docs/numpy-mapping/*.md` have these four columns.

```markdown
| Matft | Numpy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.stats.median` | `numpy.median` |  |  |
| `Matft.transpose` | `numpy.transpose` | ✓ | ✓ |
| `MfArray.toArray` | `numpy.ndarray.tolist` | only |  |
```

- Method: `✓` = a method version also exists (`a.transpose()`), `only` = method version only.
- Complex: `✓` if complex arrays are supported.
- If the counterpart is not Numpy, write its name (`cv2.GaussianBlur`, `librosa.stft`, etc.). `n/a` if there is none.
- To list a function and an operator in one cell, separate them with `<br />` (e.g. `` `Matft.matmul`<br />`*&` ``).

## 4. Verify code example output

Output shown in guides or the Quick Start must be verified by actually running it. Print it from a temporary test and copy it.

```sh
cat > Tests/MatftTests/TmpDocsSnippetTest.swift <<'EOF'
import XCTest
@testable import Matft

final class TmpDocsSnippetTest: XCTestCase {
    func testSnippets() {
        print("SNIP")
        let a = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])
        print(a.sum(axis: 0))
    }
}
EOF
swift test --filter MatftTests.TmpDocsSnippetTest 2>&1 | sed -n '/^SNIP/,/^◇/p'
rm Tests/MatftTests/TmpDocsSnippetTest.swift   # always delete it when done (never commit it)
```

- Copy tabs and spaces exactly as Matft prints them.
- If an existing example no longer matches the current implementation (e.g. after a behavior-changing PR), fix both the example and its output.

## 5. Build and check

```sh
DOCC_WARNINGS_AS_ERRORS=1 ./scripts/build-docs.sh               # API reference → website/static/api
python3 .claude/skills/docs/scripts/undocumented_symbols.py     # public symbols without comments (must be 0)

cd website
npm ci                  # first time only
npm run build           # fails on broken links
npx docusaurus serve --port 3210 --no-open    # for visual checks (http://localhost:3210/Matft/)
```

- `build-docs.sh` does not use swift-docc-plugin; it feeds the symbol graph from `swift build` to `docc convert`. Do not add DocC dependencies to Package.swift (it would add dependencies for users). For the API only, use `./scripts/build-docs.sh --preview`.
- `undocumented_symbols.py` reads the symbol graph produced by `build-docs.sh`, so run `build-docs.sh` first.
- DocC warnings are mostly `warning: Parameter 'x' is missing documentation` / `not found in ... declaration`. Making the comment's parameter list match the signature removes them.
- For the visual check, open the pages you changed and the API pages of the affected symbols. serve redirects `/api/documentation/matft/` because of `trailingSlash: false`; this is not a problem in production (GitHub Pages).

## 6. Report

- Pages and files updated, rows added to the mapping tables
- DocC warning count and undocumented symbol count (both must be 0), and the site build result
- Code examples verified by running them
- Suspicious behavior found while writing comments (file:line, what differs from Numpy / the comment). State explicitly that you did not fix it

Documentation-only changes are exempt from TDD. However, **when changing scripts** such as `scripts/benchmark.py`, **write the tests first** (`scripts/test_benchmark.py`).
