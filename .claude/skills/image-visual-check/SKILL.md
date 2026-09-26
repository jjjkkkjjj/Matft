---
name: image-visual-check
description: Procedure for adding tests for Matft's image processing (Matft.image.*, indexing or channel swapping on images, etc.), generating comparison images that put the result next to an OpenCV reference, and visually checking that the conversion is correct. Use this skill whenever the conversation is about adding, fixing, testing, or checking Matft features that handle images — e.g. "add an image processing test", "visually check resize / warpAffine / color", "see if the image is converted correctly", "compare with OpenCV", "check it like the images in the README / docs", or in Japanese「画像処理のテスト追加して」「resize / warpAffine / color を目視確認したい」「画像が正しく変換されてるか見て」「OpenCV と見比べたい」「README / ドキュメントの画像みたいに確認したい」— even if the word "skill" is never mentioned.
---

# Adding image processing tests and checking them visually

With numeric asserts alone, image processing bugs like vertical flips, swapped RGB, or shifted interpolation are easy to miss.
So pin down the spec with numeric tests, then build a comparison image that lays out **input | Matft | OpenCV | diff** side by side, and have both Claude and the user check it visually.
The comparison images are committed to the repository so they can be reviewed in the PR.

## How it works

| Location | Role |
|---|---|
| `Tests/MatftTests/files/images/rena.png` | Input image (225x225, RGBA). Lossless PNG, because JPEG mixes in decoder differences |
| `Tests/MatftTests/ImageSnapshot.swift` | Test helper. `loadFixture()` loads a CGImage; `check(_:as:)` compares Matft's output with the committed `opencv/<case>.png` by `tolerances[<case>]` and then saves it as PNG (`save(_:as:)`) |
| `Tests/MatftTests/ImageTest.swift` | Image processing tests (create it if missing) |
| `scripts/image_compare.py` | Runs the OpenCV version of each conversion registered in `CASES` and writes reference images, comparison images, and diff metrics |
| `files/images/matft/<case>.png` | Matft's output (committed) |
| `files/images/opencv/<case>.png` | OpenCV's output (committed) |
| `files/images/compare/<case>.png` | Comparison image (committed). This is what you look at |

`ImageSnapshot.save` writes files only when run with the environment variable `MATFT_IMAGE_SNAPSHOT=1`,
so that a regular `swift test` does not modify files in the repository.

## 0. Pre-checks

```sh
python3 -c "import cv2, numpy; print(cv2.__version__, numpy.__version__)"
```

If cv2 is missing, suggest `pip3 install --user opencv-python-headless`. Install only with the user's consent.

## 1. Write the test (Red)

Follow TDD as CLAUDE.md requires. If `ImageTest.swift` does not exist, create it in this form.
Wrap the whole file in `#if` so it still builds where Accelerate/ImageIO are unavailable (WASI, Linux).

```swift
#if canImport(Accelerate) && canImport(ImageIO)
import XCTest

@testable import Matft

final class ImageTest: XCTestCase {
    func test_resize() {
        let image = Matft.image.cgimage2mfarray(ImageSnapshot.loadFixture())   // Float [0, 1], RGBA, shape=(225, 225, 4)
        let ret = Matft.image.resize(image, width: 300, height: 150)

        XCTAssertEqual(ret.shape, [150, 300, 4])
        XCTAssertEqual(ret.mftype, .Float)
        // Assert whatever can be checked numerically, e.g. representative pixel values

        ImageSnapshot.check(ret, as: "resize_300x150")
    }
}
#endif
```

Tips for numeric asserts:

- Get expected values by computing them from `rena.png` in Python (numpy / cv2). Write the Python expression in a comment so it is clear where the embedded values come from.
- For operations involving interpolation (resize, warpAffine), vImage and OpenCV do not match pixel for pixel. So assert **algorithm-independent properties**: shape, dtype, value range, pixels in flat regions, border values (warpAffine's borderValue), etc.
- For operations that are exactly defined (flip, channel swap, grayscale), compare representative pixels with the numpy / cv2 values (divide by 255 for Float; tolerance around 1e-2).
- Give each `check` a case name that tells the operation and its conditions (e.g. `warpAffine_rotate30_edgeExtend`).
- `check` fails until the case has a tolerance in `ImageSnapshot.tolerances` and a committed reference `opencv/<case>.png` (step 4). Pick `.exact`, `.rounding(n)` or `.interpolation(meanAbs:minPSNR:)` from the metrics of step 4, with a little margin, and write the measured values in a comment.

Confirm it fails with `swift test --filter MatftTests.ImageTest`.

## 2. Register the OpenCV version

Add the OpenCV operation to `CASES` in `scripts/image_compare.py` under the same case name.

```python
"resize_300x150": Case("rena.png",
                       lambda x: cv2.resize(x, (300, 150), interpolation=cv2.INTER_LANCZOS4),
                       "Matft.image.resize(width: 300, height: 150) vs cv2.resize(LANCZOS4)"),
```

`op` receives an RGBA uint8 array. It may return either uint8 or float in [0, 1] (converted to uint8 automatically).
Differences in conventions between Matft and OpenCV often make a correct result look "off". Watch for:

- **Channel order**: Matft is RGBA, OpenCV is BGR(A). The script passes RGBA, so do not use BGR-based conversions (`COLOR_BGR2GRAY`, etc.) inside `op`.
- **Size arguments**: `cv2.resize` takes `(width, height)`; Matft's shape is `(height, width, channel)`.
- **Value range**: Matft's Float images are [0, 1]; OpenCV uses 0–255. Multiply `borderValue` and the like by 255.
- **Interpolation**: vImage's resize uses Lanczos-style interpolation, whose edges differ from `INTER_LINEAR`. Pick the closest interpolation and state in the description what it was compared against.
- **Savable channel counts**: `mfarray2cgimage` supports only 1 and 4 channels. For results with 3 channels, such as `RGBA2RGB`, convert back to 4 channels with `Matft.image.color(ret, conversion: .RGB2RGBA)` before `save`. Do the same on the OpenCV side.

## 3. Implement and pass the test (Green)

Write the minimal implementation that passes the test, and confirm all tests pass with `swift test`.
When no change to Matft itself is needed (just adding tests and a visual check to an existing feature), this step is only a check.

## 4. Generate the comparison images

```sh
MATFT_IMAGE_SNAPSHOT=1 swift test --filter MatftTests.ImageTest
python3 scripts/image_compare.py --filter '<regex of case names>'
```

Check the `status` column of the table the script prints.

- `missing-matft`: `check` was not called on the Swift side. Either `MATFT_IMAGE_SNAPSHOT=1` was forgotten or the case names do not match.
- `missing-case`: not registered in `CASES`.

## 5. Visual check (Claude)

Open `compare/<case>.png` with the Read tool and actually look at the image. Do not decide pass/fail from the metrics alone.
A high PSNR is still wrong if the image is mirrored, and a diff can be fine if only the interpolation differs.

Look in this order:

1. **Orientation and position**: do flips, rotation direction, and translation direction match the intended transform?
2. **Color**: do skin and background tones look natural compared with the input? Any R/B swap (bluish skin) or alpha mishandling (blown-out whites, crushed blacks)?
3. **Shape**: is the output size and aspect ratio the same as OpenCV's?
4. **Diff map**: look at the **shape of the diff's distribution**.
   - Faintly scattered everywhere → rounding error or different interpolation. Usually acceptable.
   - Along edges → different interpolation, or a half-pixel shift.
   - A whole region or the image border is bright → likely a real bug: coordinate system, border handling, swapped channels, etc.

Rough metric guidelines (guidelines only):

| Kind of operation | Expected |
|---|---|
| Indexing (flip, slice, channel swap) | `max|diff| = 0` |
| Color conversion | `max|diff| ≤ 2` (rounding error) |
| resize, warpAffine | No pixel match expected. Fine if PSNR is roughly 30 dB or higher and the diff is confined to edges |

When a result falls outside the guidelines, before calling it a bug, suspect the convention differences in step 2 (a mistake on the OpenCV side), and decide which is right by comparing against the input image.

## 6. Show the user and report

```sh
open Tests/MatftTests/files/images/compare/<case>.png   # pass several at once if there are multiple
```

Include in the report:

- The tests added and what they assert
- The table the script printed (metrics per case)
- What you checked visually: what looked correct, where the diff appears and why you judged it acceptable (or what is wrong)

Let the user make the final call on correctness.

## 7. Commit (only when the user tells you to)

Commit `files/images/{matft,opencv,compare}/<case>.png` together with the tests.
Check with `git status` that images of existing cases have not changed unintentionally. If they have, tell the user about that diff too.

To show a new case in the docs, add `#### <function name>` and `![alt](/img/compare/<case>.png)` to the "Visual check against OpenCV" section of `website/docs/guide/image.md`. `website/scripts/copy-assets.mjs` copies the images into static at build time, so do not commit them a second time on the website side.
