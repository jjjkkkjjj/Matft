#!/usr/bin/env python3
"""Compare Matft's image-processing outputs with OpenCV for visual check.

Usage:
    MATFT_IMAGE_SNAPSHOT=1 swift test --filter MatftTests.ImageTest   # writes files/images/matft/<case>.png
    python3 scripts/image_compare.py [--filter <regex>]                 # writes opencv/ and compare/

For each case in `CASES`, the input fixture is processed by OpenCV and saved to
`Tests/MatftTests/files/images/opencv/<case>.png`. Then the side-by-side sheet
(input | Matft | OpenCV | |diff|) is saved to `compare/<case>.png`, and the diff metrics are printed.

All arrays handled here are RGBA (Matft's channel order) or gray, uint8.
"""
import argparse
import math
import os
import re
import sys
from typing import Callable, Dict, List, NamedTuple, Optional

import cv2
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
IMAGES_DIR = os.path.join(ROOT, "Tests", "MatftTests", "files", "images")

DIFF_GAIN = 8        # amplify |diff| so that small errors are visible
MIN_PANEL_HEIGHT = 200
HEADER_HEIGHT = 24


class Case(NamedTuple):
    input: str                                  # fixture filename in IMAGES_DIR
    op: Callable[[np.ndarray], np.ndarray]      # RGBA (or gray) uint8 -> uint8, or float in [0, 1]
    description: str


# Key = the name passed to `ImageSnapshot.save(_:as:)` in Tests/MatftTests/ImageTest.swift.
# `op` must do the same conversion as the Matft test with OpenCV, e.g.
#   "resize_300x300": Case("rena.png", lambda x: cv2.resize(x, (300, 300), interpolation=cv2.INTER_LINEAR),
#                          "Matft.image.resize(width: 300, height: 300) vs cv2.resize"),
def _pil_resize_rgb(x: np.ndarray, width: int, height: int) -> np.ndarray:
    """Resize the RGB channels with PIL (BICUBIC) and restore the opaque alpha, same as ImagePreprocessTest.swift."""
    from PIL import Image

    rgb = np.array(Image.fromarray(np.ascontiguousarray(x[..., :3])).resize((width, height), Image.Resampling.BICUBIC))
    return np.dstack([rgb, np.full(rgb.shape[:2], 255, np.uint8)])


def _alpha_ramp(x: np.ndarray) -> np.ndarray:
    """Same as `withAlphaRamp` in ImageTest.swift: alpha[y, x] = x / (w - 1) (uint8)."""
    x = x.copy()
    w = x.shape[1]
    x[:, :, 3] = np.rint(np.arange(w) / (w - 1) * 255).astype(np.uint8)[None, :]
    return x


def _composite_white(x: np.ndarray) -> np.ndarray:
    """RGBA uint8 -> RGB float in [0, 255] composited on white."""
    a = x[:, :, 3:4].astype(np.float64) / 255
    return x[:, :, :3].astype(np.float64) * a + 255 * (1 - a)


def _rgb2gray(rgb: np.ndarray) -> np.ndarray:
    return np.rint(rgb @ np.array([0.299, 0.587, 0.114])).astype(np.uint8)


def _gray(x: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(x, cv2.COLOR_RGBA2GRAY)


def _rotation30(x: np.ndarray) -> np.ndarray:
    return cv2.getRotationMatrix2D((112, 112), 30, 1)


CASES: Dict[str, Case] = {
    # resize: vImage uses Lanczos (kvImageHighQualityResampling)
    "resize_300x150": Case("rena.png",
                           lambda x: cv2.resize(x, (300, 150), interpolation=cv2.INTER_LANCZOS4),
                           "Matft.image.resize(width: 300, height: 150) vs cv2.resize(LANCZOS4)"),
    "resize_gray_300x150": Case("rena.png",
                                lambda x: cv2.resize(cv2.cvtColor(x, cv2.COLOR_RGBA2GRAY), (300, 150), interpolation=cv2.INTER_LANCZOS4),
                                "resize(gray) vs cv2.resize(cvtColor(RGBA2GRAY), LANCZOS4)"),
    "resize_colmajor_300x150": Case("rena.png",
                                    lambda x: cv2.resize(x, (300, 150), interpolation=cv2.INTER_LANCZOS4),
                                    "resize(column major RGBA) vs cv2.resize(LANCZOS4)"),
    # warpAffine: the matrix has the same meaning as cv2
    "warpAffine_translate": Case("rena.png",
                                 lambda x: cv2.warpAffine(x, np.float32([[1, 0, 20], [0, 1, 10]]), (225, 225),
                                                          flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0)),
                                 "warpAffine(tx=20, ty=10) vs cv2.warpAffine(LINEAR, CONSTANT)"),
    "warpAffine_rotate30_colorFill": Case("rena.png",
                                          lambda x: cv2.warpAffine(x, _rotation30(x), (225, 225), flags=cv2.INTER_LINEAR,
                                                                   borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 255)),
                                          "warpAffine(getRotationMatrix2D((112,112), 30, 1), .ColorFill) vs cv2(LINEAR, CONSTANT)"),
    "warpAffine_rotate30_edgeExtend": Case("rena.png",
                                           lambda x: cv2.warpAffine(x, _rotation30(x), (225, 225), flags=cv2.INTER_LINEAR,
                                                                    borderMode=cv2.BORDER_REPLICATE),
                                           "warpAffine(getRotationMatrix2D((112,112), 30, 1), .EdgeExtend) vs cv2(LINEAR, REPLICATE)"),
    # color
    "color_rgba2gray": Case("rena.png",
                            lambda x: cv2.cvtColor(x, cv2.COLOR_RGBA2GRAY),
                            "color(.RGBA2GRAY) vs cv2.cvtColor(RGBA2GRAY)"),
    "color_rgba2gray_alpha_white": Case("rena.png",
                                        lambda x: _rgb2gray(_composite_white(_alpha_ramp(x))),
                                        "color(.RGBA2GRAY, exclude_alpha: false) with alpha ramp vs composite on white + gray"),
    "color_rgba2rgb_uint8": Case("rena.png",
                                 lambda x: cv2.cvtColor(np.rint(_composite_white(_alpha_ramp(x))).astype(np.uint8), cv2.COLOR_RGB2RGBA),
                                 "color(.RGBA2RGB) -> (.RGB2RGBA) on UInt8 with alpha ramp vs composite on white"),
    # cvtColor
    "cvtColor_rgba2bgra": Case("rena.png",
                               lambda x: cv2.cvtColor(x, cv2.COLOR_RGBA2BGRA),
                               "cvtColor(.RGBA2BGRA) vs cv2.cvtColor(RGBA2BGRA)"),
    "cvtColor_rgb2hsv_h": Case("rena.png",
                               lambda x: cv2.cvtColor(np.ascontiguousarray(x[:, :, :3]), cv2.COLOR_RGB2HSV)[:, :, 0],
                               "cvtColor(.RGB2HSV)[H] (UInt8, H in [0, 180)) vs cv2.cvtColor(RGB2HSV)"),
    # threshold / histogram
    "threshold_binary_127": Case("rena.png",
                                 lambda x: cv2.threshold(_gray(x), 127, 255, cv2.THRESH_BINARY)[1],
                                 "threshold(127, 255, .Binary) vs cv2.threshold(THRESH_BINARY)"),
    "threshold_otsu": Case("rena.png",
                           lambda x: cv2.threshold(_gray(x), 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1],
                           "threshold(.Binary, otsu: true) vs cv2.threshold(THRESH_BINARY + THRESH_OTSU)"),
    "equalizeHist": Case("rena.png",
                         lambda x: cv2.equalizeHist(_gray(x)),
                         "equalizeHist vs cv2.equalizeHist"),
    "LUT_gamma05": Case("rena.png",
                        lambda x: cv2.LUT(x, np.rint(np.sqrt(np.arange(256) / 255) * 255).astype(np.uint8)),
                        "LUT(gamma 0.5) vs cv2.LUT"),
    # filter (Matft's default border is Replicate)
    "filter2D_sharpen": Case("rena.png",
                             lambda x: cv2.filter2D(x, -1, np.float32([[0, -1, 0], [-1, 5, -1], [0, -1, 0]]), borderType=cv2.BORDER_REPLICATE),
                             "filter2D(sharpen) vs cv2.filter2D(BORDER_REPLICATE)"),
    "blur_5x5": Case("rena.png",
                     lambda x: cv2.blur(x, (5, 5), borderType=cv2.BORDER_REPLICATE),
                     "blur((5, 5)) vs cv2.blur(BORDER_REPLICATE)"),
    "GaussianBlur_k9": Case("rena.png",
                            lambda x: cv2.GaussianBlur(x, (9, 9), 0, borderType=cv2.BORDER_REPLICATE),
                            "GaussianBlur((9, 9), 0) vs cv2.GaussianBlur(BORDER_REPLICATE)"),
    "Sobel_dx": Case("rena.png",
                     lambda x: cv2.convertScaleAbs(cv2.Sobel(_gray(x), cv2.CV_32F, 1, 0, ksize=3, borderType=cv2.BORDER_REPLICATE)),
                     "convertScaleAbs(Sobel(gray, dx=1)) vs cv2"),
    "Laplacian_k3": Case("rena.png",
                         lambda x: cv2.convertScaleAbs(cv2.Laplacian(_gray(x), cv2.CV_32F, ksize=3, borderType=cv2.BORDER_REPLICATE)),
                         "convertScaleAbs(Laplacian(gray, ksize=3)) vs cv2"),
    "adaptiveThreshold_mean": Case("rena.png",
                                   lambda x: cv2.adaptiveThreshold(_gray(x), 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, 11, 2),
                                   "adaptiveThreshold(.Mean, .Binary, 11, 2) vs cv2"),
    "adaptiveThreshold_gaussian_inv": Case("rena.png",
                                           lambda x: cv2.adaptiveThreshold(_gray(x), 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 11, 2),
                                           "adaptiveThreshold(.Gaussian, .BinaryInv, 11, 2) vs cv2"),
    # morphology (default border)
    "erode_rect5": Case("rena.png",
                        lambda x: cv2.erode(x, cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))),
                        "erode(rect 5x5) vs cv2.erode"),
    "dilate_ellipse7": Case("rena.png",
                            lambda x: cv2.dilate(x, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))),
                            "dilate(ellipse 7x7) vs cv2.dilate"),
    "morphologyEx_open_ellipse5": Case("rena.png",
                                       lambda x: cv2.morphologyEx(cv2.threshold(_gray(x), 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1],
                                                                  cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))),
                                       "morphologyEx(.Open, ellipse 5x5) of Otsu binary vs cv2"),
    "morphologyEx_gradient_cross3": Case("rena.png",
                                         lambda x: cv2.morphologyEx(_gray(x), cv2.MORPH_GRADIENT, cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))),
                                         "morphologyEx(.Gradient, cross 3x3) vs cv2"),
    # geometry
    "flip_horizontal": Case("rena.png",
                            lambda x: cv2.flip(x, 1),
                            "flip(flipCode: 1) vs cv2.flip"),
    "rotate_90cw": Case("rena.png",
                        lambda x: cv2.rotate(np.ascontiguousarray(x[:150]), cv2.ROTATE_90_CLOCKWISE),
                        "rotate(image[0~<150], .Rotate90Clockwise) vs cv2.rotate"),
    "warpPerspective": Case("rena.png",
                            lambda x: cv2.warpPerspective(x, cv2.getPerspectiveTransform(np.float32([[0, 0], [224, 0], [224, 224], [0, 224]]),
                                                                                         np.float32([[30, 10], [200, 40], [224, 200], [0, 224]])),
                                                          (225, 225), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 255)),
                            "warpPerspective(getPerspectiveTransform) vs cv2(LINEAR, CONSTANT)"),
    "warpAffine_getRotationMatrix2D_45": Case("rena.png",
                                              lambda x: cv2.warpAffine(x, cv2.getRotationMatrix2D((112, 112), 45, 0.8), (225, 225),
                                                                       flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 255)),
                                              "warpAffine(getRotationMatrix2D((112,112), 45, 0.8)) vs cv2(LINEAR, CONSTANT)"),
    "resize_linear_300x150": Case("rena.png",
                                  lambda x: cv2.resize(x, (300, 150), interpolation=cv2.INTER_LINEAR),
                                  "resize(300x150, .Linear) vs cv2.resize(INTER_LINEAR)"),
    "resize_nearest_100x60": Case("rena.png",
                                  lambda x: cv2.resize(x, (100, 60), interpolation=cv2.INTER_NEAREST),
                                  "resize(100x60, .Nearest) vs cv2.resize(INTER_NEAREST)"),
    # PIL compatible resize (the reference is PIL, not OpenCV)
    "resize_pil_bicubic_100x60": Case("rena.png",
                                      lambda x: _pil_resize_rgb(x, 100, 60),
                                      "resize(RGB, 100x60, resample: .bicubic) vs PIL.Image.resize(BICUBIC)"),
    "resize_pil_bicubic_300x400": Case("rena.png",
                                       lambda x: _pil_resize_rgb(x, 300, 400),
                                       "resize(RGB, 300x400, resample: .bicubic) vs PIL.Image.resize(BICUBIC)"),
    # edge
    "Canny_100_200": Case("rena.png",
                          lambda x: cv2.Canny(_gray(x), 100, 200),
                          "Canny(100, 200) vs cv2.Canny"),
    "Canny_50_150_L2": Case("rena.png",
                            lambda x: cv2.Canny(_gray(x), 50, 150, L2gradient=True),
                            "Canny(50, 150, L2gradient: true) vs cv2.Canny"),
}


class Metrics(NamedTuple):
    shape_match: bool
    max_abs: Optional[int]
    mean_abs: Optional[float]
    psnr: Optional[float]


class Result(NamedTuple):
    name: str
    status: str                 # ok / missing-matft / missing-case
    metrics: Optional[Metrics]
    matft_shape: Optional[tuple]
    opencv_shape: Optional[tuple]


def read_png(path: str) -> np.ndarray:
    a = cv2.imread(path, cv2.IMREAD_UNCHANGED)
    if a is None:
        raise FileNotFoundError(path)
    if a.ndim == 2:
        return a
    if a.shape[2] == 3:
        return cv2.cvtColor(a, cv2.COLOR_BGR2RGBA)  # Matft always loads color images as RGBA
    return cv2.cvtColor(a, cv2.COLOR_BGRA2RGBA)


def write_png(path: str, a: np.ndarray) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if a.ndim == 3:
        a = cv2.cvtColor(a, cv2.COLOR_RGBA2BGRA if a.shape[2] == 4 else cv2.COLOR_RGB2BGR)
    cv2.imwrite(path, a)


def to_uint8(a: np.ndarray) -> np.ndarray:
    if a.dtype == np.uint8:
        return a
    if np.issubdtype(a.dtype, np.floating):
        return np.clip(np.rint(a * 255), 0, 255).astype(np.uint8)
    return np.clip(a, 0, 255).astype(np.uint8)


def diff_metrics(matft: np.ndarray, ref: np.ndarray) -> Metrics:
    if matft.shape != ref.shape:
        return Metrics(False, None, None, None)
    d = np.abs(matft.astype(np.int32) - ref.astype(np.int32))
    mse = float((d.astype(np.float64) ** 2).mean())
    psnr = math.inf if mse == 0 else 10 * math.log10(255 ** 2 / mse)
    return Metrics(True, int(d.max()), float(d.mean()), psnr)


def to_display_rgb(a: np.ndarray) -> np.ndarray:
    """Gray -> RGB, RGBA -> RGB composited on white."""
    if a.ndim == 2:
        return np.repeat(a[:, :, None], 3, axis=2)
    if a.shape[2] == 1:
        return np.repeat(a, 3, axis=2)
    if a.shape[2] == 3:
        return a
    alpha = a[:, :, 3:4].astype(np.float64) / 255
    rgb = a[:, :, :3].astype(np.float64) * alpha + 255 * (1 - alpha)
    return np.rint(rgb).astype(np.uint8)


def diff_image(matft: np.ndarray, ref: np.ndarray) -> np.ndarray:
    d = np.abs(to_display_rgb(matft).astype(np.int32) - to_display_rgb(ref).astype(np.int32)).max(axis=2)
    d = np.clip(d * DIFF_GAIN, 0, 255).astype(np.uint8)
    return cv2.cvtColor(cv2.applyColorMap(d, cv2.COLORMAP_INFERNO), cv2.COLOR_BGR2RGB)


def make_sheet(panels: List[tuple], footer: str = "") -> np.ndarray:
    """Concatenate labeled panels horizontally. Returns RGB uint8."""
    imgs = [to_display_rgb(a) for _, a in panels]
    max_h = max(a.shape[0] for a in imgs)
    scale = max(1, math.ceil(MIN_PANEL_HEIGHT / max_h))  # enlarge tiny images (nearest) to be visible
    gap = 8
    cols = []
    for (label, _), a in zip(panels, imgs):
        a = cv2.resize(a, (a.shape[1] * scale, a.shape[0] * scale), interpolation=cv2.INTER_NEAREST)
        w = max(a.shape[1], 8 * len(label) + 8)
        col = np.full((HEADER_HEIGHT + max_h * scale, w, 3), 255, dtype=np.uint8)
        col[HEADER_HEIGHT:HEADER_HEIGHT + a.shape[0], :a.shape[1]] = a
        cv2.putText(col, label, (2, HEADER_HEIGHT - 7), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 0), 1, cv2.LINE_AA)
        cols.append(col)
        cols.append(np.full((col.shape[0], gap, 3), 255, dtype=np.uint8))
    sheet = np.concatenate(cols[:-1], axis=1)
    if footer:
        bar = np.full((HEADER_HEIGHT, sheet.shape[1], 3), 255, dtype=np.uint8)
        cv2.putText(bar, footer, (2, HEADER_HEIGHT - 7), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 0), 1, cv2.LINE_AA)
        sheet = np.concatenate([sheet, bar], axis=0)
    return sheet


def format_metrics(m: Optional[Metrics]) -> str:
    if m is None:
        return ""
    if not m.shape_match:
        return "shape mismatch"
    psnr = "inf" if math.isinf(m.psnr) else f"{m.psnr:.1f}dB"
    return f"max|diff|={m.max_abs} mean|diff|={m.mean_abs:.3f} PSNR={psnr}"


def run(images_dir: str, cases: Dict[str, Case], pattern: Optional[str] = None) -> List[Result]:
    matft_dir = os.path.join(images_dir, "matft")
    results = []
    for name, case in cases.items():
        if pattern and not re.search(pattern, name):
            continue
        src = read_png(os.path.join(images_dir, case.input))
        ref = to_uint8(case.op(src.copy()))
        write_png(os.path.join(images_dir, "opencv", f"{name}.png"), ref)

        matft_path = os.path.join(matft_dir, f"{name}.png")
        if not os.path.exists(matft_path):
            results.append(Result(name, "missing-matft", None, None, ref.shape))
            continue
        matft = read_png(matft_path)
        m = diff_metrics(matft, ref)
        panels = [("input", src), ("Matft", matft), ("OpenCV", ref)]
        if m.shape_match:
            panels.append((f"|diff| x{DIFF_GAIN}", diff_image(matft, ref)))
        footer = f"{name}: {case.description}  |  {format_metrics(m)}"
        if not m.shape_match:
            footer += f" Matft{matft.shape} OpenCV{ref.shape}"
        write_png(os.path.join(images_dir, "compare", f"{name}.png"), make_sheet(panels, footer))
        results.append(Result(name, "ok", m, matft.shape, ref.shape))

    if os.path.isdir(matft_dir):
        for f in sorted(os.listdir(matft_dir)):
            name, ext = os.path.splitext(f)
            if ext == ".png" and name not in cases and not (pattern and not re.search(pattern, name)):
                results.append(Result(name, "missing-case", None, None, None))
    return results


def report(results: List[Result], images_dir: str) -> str:
    lines = ["| case | status | Matft shape | OpenCV shape | metrics |", "|---|---|---|---|---|"]
    for r in results:
        lines.append(f"| {r.name} | {r.status} | {r.matft_shape or ''} | {r.opencv_shape or ''} | {format_metrics(r.metrics)} |")
    notes = []
    if any(r.status == "missing-matft" for r in results):
        notes.append("missing-matft: run `MATFT_IMAGE_SNAPSHOT=1 swift test --filter MatftTests.ImageTest` first.")
    if any(r.status == "missing-case" for r in results):
        notes.append("missing-case: add the case to CASES in scripts/image_compare.py.")
    ok = [r for r in results if r.status == "ok"]
    if ok:
        notes.append("compare sheets: " + ", ".join(
            os.path.relpath(os.path.join(images_dir, "compare", f"{r.name}.png"), ROOT) for r in ok))
    return "\n".join(lines + [""] + notes)


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--filter", help="regex to select case names")
    p.add_argument("--images-dir", default=IMAGES_DIR)
    args = p.parse_args(argv)
    results = run(args.images_dir, CASES, args.filter)
    print(report(results, args.images_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
