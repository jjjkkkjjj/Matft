---
title: Image Processing
---

# Image Processing

`Matft.image` provides image processing compatible with OpenCV (`cv2`), and preprocessing compatible with PIL / Hugging Face transformers.
See [NumPy Mapping › Image](../numpy-mapping/image.md) for the list of functions.

## CGImage ⇄ MfArray

Convert a `CGImage` to an `MfArray` of shape `(height, width, 4)` (RGBA), process it with indexing or image functions, and convert it back.
See the [demo app](https://github.com/jjjkkkjjj/Matft/blob/main/MatftDemo/MatftDemo/ViewController.swift) for the complete example.

```swift
@IBOutlet weak var originalImageView: UIImageView!
@IBOutlet weak var reverseImageView: UIImageView!
@IBOutlet weak var swapImageView: UIImageView!

func reverse(){
    var image = Matft.image.cgimage2mfarray(self.reverseImageView.image!.cgImage!)

    // reverse
    image = image[Matft.reverse] // same as image[~<<-1]
    self.reverseImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
}

func swapchannel(){
    var image = Matft.image.cgimage2mfarray(self.swapImageView.image!.cgImage!)

    // swap channel
    image = image[Matft.all, Matft.all, MfArray([1,0,2,3])] // same as image[0~<, 0~<, MfArray([1,0,2,3])]
    self.swapImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
}
```

<img width="513" alt="Demo app" src="https://user-images.githubusercontent.com/16914891/179746856-c4e8048d-3e7c-4835-b39c-ddf6af5b5fd7.png" />

For more complex conversion, see OpenCV's [code](https://github.com/opencv/opencv/blob/4.x/modules/imgcodecs/src/apple_conversions.mm).

## Preprocessing for vision models

`Matft.image.resize(_:width:height:resample:)` reproduces `PIL.Image.resize` (Pillow's fixed-point arithmetic), so a `UInt8` image is resized to **exactly the same pixels as PIL**.
On top of it, the preprocessing of Hugging Face transformers' image processors is available, e.g. to feed the same input as Python to a VLM running on Core ML or MLX.

```swift
let rgba = Matft.image.cgimage2mfarray(cgimage, mftype: .UInt8)     // (h, w, 4), 0...255
let rgb = rgba[Matft.all, Matft.all, 0~<3].to_contiguous(mforder: .Row)

let resized = Matft.image.resize(rgb, width: 224, height: 224, resample: .bicubic) // == PIL.Image.resize(BICUBIC)

let pixel_values = Matft.image.clip_preprocess(rgb)                       // (1, 3, 224, 224), same as CLIPImageProcessor
let (patches, grid_thw) = Matft.image.qwen2vl_preprocess(rgb)             // same as Qwen2VLImageProcessor
```

:::note
Unlike PIL, an RGBA image is not premultiplied by alpha. Convert it to RGB first as transformers does.
:::

## Visual check against OpenCV

Each image function is tested in [ImageTest.swift](https://github.com/jjjkkkjjj/Matft/blob/main/Tests/MatftTests/ImageTest.swift),
and its output is compared with OpenCV's one (**input | Matft | OpenCV | |diff| x8**) by [scripts/image_compare.py](https://github.com/jjjkkkjjj/Matft/blob/main/scripts/image_compare.py).

```sh
MATFT_IMAGE_SNAPSHOT=1 swift test --filter MatftTests.ImageTest
python3 scripts/image_compare.py
```

:::note
- `Matft.image.warpAffine`'s matrix has the same meaning as `cv2.warpAffine`'s one after v0.3.3 (v0.3.3 and earlier swapped the off-diagonal elements and used a bottom-left origin).
- Interpolations differ from OpenCV's ones (vImage), so the small differences along the edges are expected.
- Filters use `MfBorderType.Replicate` by default, because OpenCV's default border (`BORDER_REFLECT_101`) is not supported by vImage.
:::

#### `resize(width: 300, height: 150)`

![resize](/img/compare/resize_300x150.png)

#### `resize` (gray)

![resize gray](/img/compare/resize_gray_300x150.png)

#### `resize` (column major)

![resize column major](/img/compare/resize_colmajor_300x150.png)

#### `warpAffine` (translation)

![warpAffine translate](/img/compare/warpAffine_translate.png)

#### `warpAffine` (rotation, `.ColorFill`)

![warpAffine rotate colorFill](/img/compare/warpAffine_rotate30_colorFill.png)

#### `warpAffine` (rotation, `.EdgeExtend`)

![warpAffine rotate edgeExtend](/img/compare/warpAffine_rotate30_edgeExtend.png)

#### `color(.RGBA2GRAY)`

![RGBA2GRAY](/img/compare/color_rgba2gray.png)

#### `color(.RGBA2GRAY, exclude_alpha: false)`

![RGBA2GRAY alpha](/img/compare/color_rgba2gray_alpha_white.png)

#### `color(.RGBA2RGB)` (UInt8)

![RGBA2RGB UInt8](/img/compare/color_rgba2rgb_uint8.png)

#### `cvtColor(.RGBA2BGRA)`

![RGBA2BGRA](/img/compare/cvtColor_rgba2bgra.png)

#### `cvtColor(.RGB2HSV)` (H channel)

![RGB2HSV](/img/compare/cvtColor_rgb2hsv_h.png)

#### `threshold(.Binary)`

![threshold](/img/compare/threshold_binary_127.png)

#### `threshold(otsu: true)`

![threshold otsu](/img/compare/threshold_otsu.png)

#### `adaptiveThreshold(.Mean)`

![adaptiveThreshold mean](/img/compare/adaptiveThreshold_mean.png)

#### `adaptiveThreshold(.Gaussian, .BinaryInv)`

![adaptiveThreshold gaussian](/img/compare/adaptiveThreshold_gaussian_inv.png)

#### `equalizeHist`

![equalizeHist](/img/compare/equalizeHist.png)

#### `LUT` (gamma 0.5)

![LUT](/img/compare/LUT_gamma05.png)

#### `filter2D` (sharpen)

![filter2D](/img/compare/filter2D_sharpen.png)

#### `blur((5, 5))`

![blur](/img/compare/blur_5x5.png)

#### `GaussianBlur((9, 9))`

![GaussianBlur](/img/compare/GaussianBlur_k9.png)

#### `Sobel(dx: 1)`

![Sobel](/img/compare/Sobel_dx.png)

#### `Laplacian(ksize: 3)`

![Laplacian](/img/compare/Laplacian_k3.png)

#### `Canny(100, 200)`

![Canny](/img/compare/Canny_100_200.png)

#### `Canny(50, 150, L2gradient: true)`

![Canny L2](/img/compare/Canny_50_150_L2.png)

#### `erode` (rect 5x5)

![erode](/img/compare/erode_rect5.png)

#### `dilate` (ellipse 7x7)

![dilate](/img/compare/dilate_ellipse7.png)

#### `morphologyEx(.Open)`

![morphologyEx open](/img/compare/morphologyEx_open_ellipse5.png)

#### `morphologyEx(.Gradient)`

![morphologyEx gradient](/img/compare/morphologyEx_gradient_cross3.png)

#### `flip(flipCode: 1)`

![flip](/img/compare/flip_horizontal.png)

#### `rotate(.Rotate90Clockwise)`

![rotate](/img/compare/rotate_90cw.png)

#### `warpAffine(getRotationMatrix2D)`

![warpAffine rotation matrix](/img/compare/warpAffine_getRotationMatrix2D_45.png)

#### `warpPerspective(getPerspectiveTransform)`

![warpPerspective](/img/compare/warpPerspective.png)

#### `resize(.Linear)`

![resize linear](/img/compare/resize_linear_300x150.png)

#### `resize(.Nearest)`

![resize nearest](/img/compare/resize_nearest_100x60.png)

