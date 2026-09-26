---
title: Image
---

# Image

See [Image Processing](../guide/image.md) for the usage and the visual comparison with OpenCV.

## Conversion

| Matft | Numpy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.image.cgimage2mfarray` | n/a |  |  |
| `Matft.image.mfarray2cgimage` | n/a |  |  |

## OpenCV

Filters use `MfBorderType.Replicate` by default, because OpenCV's default border (`BORDER_REFLECT_101`) is not supported by vImage.

| Matft | OpenCV | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.image.color` | `cv2.cvtColor` |  |  |
| `Matft.image.cvtColor` | `cv2.cvtColor` |  |  |
| `Matft.image.threshold` | `cv2.threshold` |  |  |
| `Matft.image.adaptiveThreshold` | `cv2.adaptiveThreshold` |  |  |
| `Matft.image.calcHist` | `cv2.calcHist` |  |  |
| `Matft.image.equalizeHist` | `cv2.equalizeHist` |  |  |
| `Matft.image.LUT` | `cv2.LUT` |  |  |
| `Matft.image.normalize` | `cv2.normalize` |  |  |
| `Matft.image.convertScaleAbs` | `cv2.convertScaleAbs` |  |  |
| `Matft.image.filter2D` | `cv2.filter2D` |  |  |
| `Matft.image.sepFilter2D` | `cv2.sepFilter2D` |  |  |
| `Matft.image.boxFilter` | `cv2.boxFilter` |  |  |
| `Matft.image.blur` | `cv2.blur` |  |  |
| `Matft.image.getGaussianKernel` | `cv2.getGaussianKernel` |  |  |
| `Matft.image.GaussianBlur` | `cv2.GaussianBlur` |  |  |
| `Matft.image.getDerivKernels` | `cv2.getDerivKernels` |  |  |
| `Matft.image.Sobel` | `cv2.Sobel` |  |  |
| `Matft.image.Laplacian` | `cv2.Laplacian` |  |  |
| `Matft.image.Canny` | `cv2.Canny` |  |  |
| `Matft.image.getStructuringElement` | `cv2.getStructuringElement` |  |  |
| `Matft.image.erode` | `cv2.erode` |  |  |
| `Matft.image.dilate` | `cv2.dilate` |  |  |
| `Matft.image.morphologyEx` | `cv2.morphologyEx` |  |  |
| `Matft.image.resize` | `cv2.resize` |  |  |
| `Matft.image.flip` | `cv2.flip` |  |  |
| `Matft.image.rotate` | `cv2.rotate` |  |  |
| `Matft.image.getRotationMatrix2D` | `cv2.getRotationMatrix2D` |  |  |
| `Matft.image.getAffineTransform` | `cv2.getAffineTransform` |  |  |
| `Matft.image.getPerspectiveTransform` | `cv2.getPerspectiveTransform` |  |  |
| `Matft.image.warpAffine` | `cv2.warpAffine` |  |  |
| `Matft.image.warpPerspective` | `cv2.warpPerspective` |  |  |
| `Matft.image.remap` | `cv2.remap` |  |  |

## PIL / transformers

| Matft | PIL / transformers | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.image.resize(_:width:height:resample:)` | `PIL.Image.resize` |  |  |
| `Matft.image.center_crop` | `transformers.image_transforms.center_crop` |  |  |
| `Matft.image.rescale` | `transformers.image_transforms.rescale` |  |  |
| `Matft.image.normalize_meanstd` | `transformers.image_transforms.normalize` |  |  |
| `Matft.image.clip_preprocess` | `CLIPImageProcessor` |  |  |
| `Matft.image.smart_resize` | `transformers.models.qwen2_vl.image_processing_qwen2_vl.smart_resize` |  |  |
| `Matft.image.qwen2vl_patchify` | `Qwen2VLImageProcessor (patchify)` |  |  |
| `Matft.image.qwen2vl_preprocess` | `Qwen2VLImageProcessor` |  |  |
