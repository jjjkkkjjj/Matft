"""Generate reference values for Tests/MatftTests/ImagePreprocessTest.swift.

Requirements: numpy, pillow, transformers (the PIL backend processors work without torch)

    python python/gen_image_preprocess_fixtures.py

Arrays are saved as CSV files (one flattened row, uint8 or float) into Tests/MatftTests/files/image_preprocess/,
and small values are printed as Swift literals.
The synthetic image is defined by `synthetic_image` and must be identical to `_synthetic_image` in the Swift test.
"""
import os

import numpy as np
from PIL import Image
from transformers.image_utils import OPENAI_CLIP_MEAN, OPENAI_CLIP_STD
from transformers.models.clip.image_processing_pil_clip import CLIPImageProcessorPil
from transformers.models.qwen2_vl.image_processing_pil_qwen2_vl import Qwen2VLImageProcessorPil, smart_resize

ROOT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "files")
OUT_DIR = os.path.join(ROOT, "image_preprocess")

RESAMPLES = {
    "nearest": Image.Resampling.NEAREST,
    "bilinear": Image.Resampling.BILINEAR,
    "bicubic": Image.Resampling.BICUBIC,
    "lanczos": Image.Resampling.LANCZOS,
}
# (width, height) of the synthetic 17x13 image: up (non-integer), down, horizontal only, vertical only
SIZES = [(31, 20), (7, 5), (9, 13), (17, 6)]


def synthetic_image(height, width, channels):
    y, x, c = np.meshgrid(np.arange(height), np.arange(width), np.arange(channels), indexing="ij")
    return ((x * 37 + y * 91 + c * 53 + (x * y) % 29) % 256).astype(np.uint8)


def save(name, arr, fmt):
    arr = np.asarray(arr)
    np.savetxt(os.path.join(OUT_DIR, name), arr.reshape(1, -1), delimiter=",", fmt=fmt)
    print(f"saved {name} shape={arr.shape}")


def rena_rgb():
    return np.array(Image.open(os.path.join(ROOT, "images", "rena.png")))[..., :3]


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # PIL resize of the synthetic image (uint8)
    rgb = synthetic_image(13, 17, 3)
    gray = synthetic_image(13, 17, 1)[..., 0]
    for name, resample in RESAMPLES.items():
        for w, h in SIZES:
            save(f"resize_rgb_{name}_{w}x{h}.csv", np.array(Image.fromarray(rgb).resize((w, h), resample)), "%d")
            save(f"resize_gray_{name}_{w}x{h}.csv", np.array(Image.fromarray(gray).resize((w, h), resample)), "%d")
    # PIL resize of the float image (mode F)
    f = gray.astype(np.float32) / 255
    for name, resample in RESAMPLES.items():
        for w, h in SIZES:
            save(f"resize_float_{name}_{w}x{h}.csv",
                 np.array(Image.fromarray(f, mode="F").resize((w, h), resample)), "%.9g")

    # PIL resize of rena (RGB)
    rena = rena_rgb()
    for name in ["bicubic", "bilinear"]:
        save(f"resize_rena_{name}_100x60.csv", np.array(Image.fromarray(rena).resize((100, 60), RESAMPLES[name])), "%d")

    # smart_resize
    for h, w, kwargs in [(225, 225, {}), (1080, 1920, {}), (30, 40, {}), (4000, 3000, {}), (100, 300, dict(factor=14)),
                         (225, 225, dict(min_pixels=28 * 28, max_pixels=28 * 28 * 4)), (50, 9000, {})]:
        print(f"smart_resize({h}, {w}, {kwargs}) = {smart_resize(h, w, **kwargs)}")

    # CLIP (small size to keep the fixture small, and default)
    clip = CLIPImageProcessorPil(size={"shortest_edge": 32}, crop_size={"height": 32, "width": 32})
    save("clip_rena_32.csv", clip(images=rena, return_tensors="np")["pixel_values"], "%.9g")
    clip_nonsq = CLIPImageProcessorPil(size={"shortest_edge": 24}, crop_size={"height": 20, "width": 28})
    save("clip_rena_24_crop20x28.csv", clip_nonsq(images=rena[:150], return_tensors="np")["pixel_values"], "%.9g")
    pv = CLIPImageProcessorPil()(images=rena, return_tensors="np")["pixel_values"]
    print("clip default:", pv.shape, "sum", float(pv.astype(np.float64).sum()), "[0,:,0,0]", pv[0, :, 0, 0].tolist(),
          "[0,:,100,150]", pv[0, :, 100, 150].tolist())

    # Qwen2-VL
    qwen = Qwen2VLImageProcessorPil(min_pixels=28 * 28, max_pixels=28 * 28 * 4)
    out = qwen(images=rena, return_tensors="np")
    print("qwen small:", out["pixel_values"].shape, out["image_grid_thw"].tolist())
    save("qwen2vl_rena_small.csv", out["pixel_values"], "%.9g")
    # pass the default explicitly because Qwen2VLImageProcessorPil(min_pixels=...) mutates the class attribute `size`
    out = Qwen2VLImageProcessorPil(min_pixels=56 * 56, max_pixels=28 * 28 * 1280)(images=rena, return_tensors="np")
    p = out["pixel_values"]
    print("qwen default:", p.shape, out["image_grid_thw"].tolist(), "sum", float(p.astype(np.float64).sum()),
          "[0,:4]", p[0, :4].tolist(), "[255,-3:]", p[255, -3:].tolist())

    # center_crop (transformers.image_transforms.center_crop), channel last
    from transformers.image_transforms import center_crop
    img = synthetic_image(5, 6, 1)
    for size in [(3, 4), (4, 3), (7, 8), (2, 9)]:
        print(f"center_crop(5x6, {size}) =", center_crop(img, size, input_data_format="channels_last")[..., 0].tolist())


if __name__ == "__main__":
    main()
