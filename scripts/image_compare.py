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
CASES: Dict[str, Case] = {
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
