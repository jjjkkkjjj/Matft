"""Generate Tests/MatftTests/ImageCoverageTest.swift from OpenCV / PIL / numpy.

Requirements: numpy (2.x), opencv-python, Pillow

    python python/gen_image_coverage.py

Every case is a Swift expression and the Python expression computing its expected value on small literal inputs.
It covers the parameters of Matft.image that the hand-written ImageTest.swift doesn't (ksize / scale / delta of Sobel,
apertureSize of Canny, border modes of remap, norm types, morphology ops, ...), and re-derives the OpenCV values
whose literals in ImageTest.swift have no script (Sobel, Laplacian, HSV, warpPerspective, remap, Canny).
"""
import os

import cv2
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "ImageCoverageTest.swift")


def lit(v):
    v = float(v)
    if np.isnan(v):
        return ".nan"
    if np.isinf(v):
        return ".infinity" if v > 0 else "-.infinity"
    return repr(v)


def swift_array(a, mftype):
    a = np.asarray(a)
    shape = list(a.shape) if a.ndim > 0 else [1]
    if mftype in ("UInt8", "Int"):
        values = ", ".join(str(int(v)) for v in a.ravel())
        return f"MfArray([{values}] as [Int], mftype: .{mftype}, shape: {shape})"
    values = ", ".join(lit(v) for v in a.ravel())
    return f"MfArray([{values}] as [Double], mftype: .{mftype}, shape: {shape})"


def escape(s):
    return s.replace("\\", "\\\\").replace("\"", "\\\"")


def close(swift, expected, mftype, rtol=1e-5, atol=1e-4, layout=None, check_type=True):
    exp = swift_array(expected, mftype)
    msg = f"\"{escape(swift)}\"" + (" + name" if layout else "")
    line = f"XCTAssertClose({swift}, {exp}, rtol: {rtol}, atol: {atol}, checkType: {str(check_type).lower()}, {msg})"
    if layout:
        return [f"for (name, x) in layoutVariants({layout}){{", "    " + line, "}"]
    return [line]


INPUTS = {}


def inp(name, a, mftype):
    INPUTS[name] = (np.asarray(a), mftype)
    return np.asarray(a)


rng = np.random.default_rng(20260927)
F = inp("F", (rng.random((7, 9)) * 10 - 3).astype(np.float32), "Float")                  # Float gray
U = inp("U", rng.integers(0, 256, (7, 9), dtype=np.uint8), "UInt8")                        # UInt8 gray
RGBA = inp("RGBA", rng.integers(0, 256, (5, 6, 4), dtype=np.uint8), "UInt8")              # UInt8 RGBA
# a square with a diagonal edge for Canny
sq = np.zeros((16, 16), np.uint8)
sq[3:12, 4:13] = 180
sq[np.tril_indices(16, -6)] = 90
SQ = inp("SQ", sq, "UInt8")

TESTS = []


def test(name, lines):
    TESTS.append((name, lines))


# ---------- filters ----------
lines = []
for dx, dy, ksize in [(1, 0, 1), (0, 1, 1), (1, 0, 5), (0, 2, 5), (1, 1, 7), (2, 0, 3)]:
    ref = cv2.Sobel(F, cv2.CV_32F, dx, dy, ksize=ksize, scale=2, delta=0.5, borderType=cv2.BORDER_REPLICATE)
    lines += close(f"Matft.image.Sobel(x, dx: {dx}, dy: {dy}, ksize: {ksize}, scale: 2, delta: 0.5)", ref, "Float", layout="F")
    ref = cv2.Sobel(U, cv2.CV_32F, dx, dy, ksize=ksize, borderType=cv2.BORDER_CONSTANT)
    lines += close(f"Matft.image.Sobel(U, ddepth: .Float, dx: {dx}, dy: {dy}, ksize: {ksize}, borderType: .Constant)", ref, "Float")
for ksize in [1, 3, 5]:
    ref = cv2.Laplacian(F, cv2.CV_32F, ksize=ksize, scale=0.5, delta=-1, borderType=cv2.BORDER_REPLICATE)
    lines += close(f"Matft.image.Laplacian(x, ksize: {ksize}, scale: 0.5, delta: -1)", ref, "Float", layout="F")
for dx, dy, ksize in [(1, 0, 5), (2, 1, 7), (0, 1, 3)]:
    kx, ky = cv2.getDerivKernels(dx, dy, ksize, normalize=True, ktype=cv2.CV_32F)
    lines += [f"do {{", f"    let (kx, ky) = Matft.image.getDerivKernels(dx: {dx}, dy: {dy}, ksize: {ksize}, normalize: true)"]
    lines += ["    " + l for l in close("kx", kx, "Float", check_type=False)]
    lines += ["    " + l for l in close("ky", ky, "Float", check_type=False)]
    lines += ["}"]
ref = cv2.GaussianBlur(F, (5, 3), sigmaX=1.2, sigmaY=0.7, borderType=cv2.BORDER_REPLICATE)
lines += close("Matft.image.GaussianBlur(x, ksize: (width: 5, height: 3), sigmaX: 1.2, sigmaY: 0.7)", ref, "Float", layout="F")
ref = cv2.GaussianBlur(F, (3, 7), sigmaX=0.9, sigmaY=2.0, borderType=cv2.BORDER_CONSTANT)
lines += close("Matft.image.GaussianBlur(F, ksize: (width: 3, height: 7), sigmaX: 0.9, sigmaY: 2.0, borderType: .Constant)", ref, "Float")
kx = np.float32([1, -2, 0.5])
ky = np.float32([0.25, 1, 0.25, -0.5, 2])
ref = cv2.sepFilter2D(F, -1, kx, ky, delta=1.5, borderType=cv2.BORDER_REPLICATE)
lines += close("Matft.image.sepFilter2D(x, kernelX: MfArray([1, -2, 0.5] as [Float]), kernelY: MfArray([0.25, 1, 0.25, -0.5, 2] as [Float]), delta: 1.5)", ref, "Float", layout="F")
ref = cv2.sepFilter2D(F, -1, kx, ky, anchor=(0, 1), borderType=cv2.BORDER_CONSTANT)
lines += close("Matft.image.sepFilter2D(F, kernelX: MfArray([1, -2, 0.5] as [Float]), kernelY: MfArray([0.25, 1, 0.25, -0.5, 2] as [Float]), anchor: (x: 0, y: 1), borderType: .Constant)", ref, "Float")
k = np.float32([[1, 0, -1], [2, 0, -2], [0.5, 1, 0.25]])
ref = cv2.filter2D(U, cv2.CV_32F, k, delta=3, borderType=cv2.BORDER_REPLICATE)
lines += close("Matft.image.filter2D(U, ddepth: .Float, kernel: MfArray([[1, 0, -1], [2, 0, -2], [0.5, 1, 0.25]] as [[Float]]), delta: 3)", ref, "Float")
ref = cv2.boxFilter(U, cv2.CV_32F, (3, 2), normalize=False, borderType=cv2.BORDER_REPLICATE)
lines += close("Matft.image.boxFilter(U, ddepth: .Float, ksize: (width: 3, height: 2), normalize: false)", ref, "Float")
test("filters", lines)

# ---------- color ----------
lines = []
lines += close("Matft.image.cvtColor(RGBA, code: .BGRA2GRAY)", cv2.cvtColor(RGBA, cv2.COLOR_BGRA2GRAY), "UInt8", rtol=0, atol=1)
lines += close("Matft.image.cvtColor(RGBA, code: .RGBA2GRAY)", cv2.cvtColor(RGBA, cv2.COLOR_RGBA2GRAY), "UInt8", rtol=0, atol=1)
rgb = np.ascontiguousarray(RGBA[:, :, :3])
lines += close("Matft.image.cvtColor(RGBA[Matft.all, Matft.all, 0~<3], code: .RGB2HSV)", cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV), "UInt8", rtol=0, atol=1)
rgbf = rgb.astype(np.float32) / 255
lines += close("Matft.image.cvtColor(RGBA[Matft.all, Matft.all, 0~<3].astype(.Float) / 255, code: .RGB2HSV)", cv2.cvtColor(rgbf, cv2.COLOR_RGB2HSV), "Float", rtol=1e-5, atol=1e-3)
hsv = cv2.cvtColor(rgbf, cv2.COLOR_RGB2HSV)
inp("HSV", hsv, "Float")
lines += close("Matft.image.cvtColor(HSV, code: .HSV2RGB)", cv2.cvtColor(hsv, cv2.COLOR_HSV2RGB), "Float", rtol=1e-5, atol=1e-4)
for norm, cvnorm in [("Inf", cv2.NORM_INF), ("L1", cv2.NORM_L1), ("L2", cv2.NORM_L2)]:
    lines += close(f"Matft.image.normalize(x, alpha: 3, normType: .{norm})", cv2.normalize(F, None, 3, 0, cvnorm), "Float", layout="F")
lines += close("Matft.image.normalize(x, alpha: -1, beta: 2, normType: .MinMax)", cv2.normalize(F, None, -1, 2, cv2.NORM_MINMAX), "Float", layout="F")
lines += close("Matft.image.convertScaleAbs(F, alpha: 12, beta: -7)", cv2.convertScaleAbs(F, alpha=12, beta=-7), "UInt8", rtol=0, atol=0)
for t, ct in [("Binary", cv2.THRESH_BINARY), ("BinaryInv", cv2.THRESH_BINARY_INV), ("Trunc", cv2.THRESH_TRUNC), ("ToZero", cv2.THRESH_TOZERO), ("ToZeroInv", cv2.THRESH_TOZERO_INV)]:
    lines += close(f"Matft.image.threshold(x, thresh: 1.5, maxval: 4, type: .{t}).dst", cv2.threshold(F, 1.5, 4, ct)[1], "Float", layout="F")
# OpenCV 4 returns (5, 1) and OpenCV 5 returns (5,), so the values are compared
h = cv2.calcHist([F], [0], None, [5], [-1, 4]).ravel()
lines += close("Matft.image.calcHist(F, histSize: 5, range: (-1, 4)).flatten()", h, "Float", check_type=False)
test("color", lines)

# ---------- morphology ----------
lines = []
cross = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))
ell = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 3))
inp("CROSS", cross, "UInt8")
inp("ELL", ell, "UInt8")
for op, cop in [("Erode", cv2.MORPH_ERODE), ("Dilate", cv2.MORPH_DILATE), ("Open", cv2.MORPH_OPEN), ("Close", cv2.MORPH_CLOSE),
                ("Gradient", cv2.MORPH_GRADIENT), ("TopHat", cv2.MORPH_TOPHAT), ("BlackHat", cv2.MORPH_BLACKHAT)]:
    lines += close(f"Matft.image.morphologyEx(x, op: .{op}, kernel: ELL)", cv2.morphologyEx(U, cop, ell), "UInt8", rtol=0, atol=0, layout="U")
    lines += close(f"Matft.image.morphologyEx(U, op: .{op}, kernel: CROSS, iterations: 2)", cv2.morphologyEx(U, cop, cross, iterations=2), "UInt8", rtol=0, atol=0)
lines += close("Matft.image.erode(U, kernel: ELL, anchor: (x: 0, y: 2))", cv2.erode(U, ell, anchor=(0, 2)), "UInt8", rtol=0, atol=0)
lines += close("Matft.image.dilate(U, kernel: ELL, anchor: (x: 4, y: 0), iterations: 2)", cv2.dilate(U, ell, anchor=(4, 0), iterations=2), "UInt8", rtol=0, atol=0)
lines += close("Matft.image.dilate(RGBA, kernel: CROSS)", cv2.dilate(RGBA, cross), "UInt8", rtol=0, atol=0)
test("morphology", lines)

# ---------- geometry ----------
lines = []
src = np.float32([[0, 0], [5, 0], [5, 4], [0, 4]])
dst = np.float32([[0.5, 0.2], [4.8, 0.6], [5.2, 3.9], [0.1, 3.5]])
M = cv2.getPerspectiveTransform(src, dst)
inp("M", M, "Double")
for interp, ci in [("Linear", cv2.INTER_LINEAR), ("Nearest", cv2.INTER_NEAREST)]:
    for border, cb in [("Constant", cv2.BORDER_CONSTANT), ("Replicate", cv2.BORDER_REPLICATE)]:
        ref = cv2.warpPerspective(F, M, (8, 6), flags=ci, borderMode=cb, borderValue=2.5)
        lines += close(f"Matft.image.warpPerspective(x, M: M, dsize: (width: 8, height: 6), interpolation: .{interp}, borderMode: .{border}, borderValue: [2.5])", ref, "Float", layout="F", atol=1e-3)
ref = cv2.warpPerspective(RGBA, M, (7, 5), flags=cv2.INTER_NEAREST, borderMode=cv2.BORDER_CONSTANT, borderValue=(10, 20, 30, 40))
lines += close("Matft.image.warpPerspective(RGBA, M: M, dsize: (width: 7, height: 5), interpolation: .Nearest, borderValue: [10, 20, 30, 40])", ref, "UInt8", rtol=0, atol=0)
my, mx = np.mgrid[0:5, 0:6].astype(np.float32)
mapx = (mx * 1.3 - 1.2 + 0.3 * my).astype(np.float32)
mapy = (my * 1.1 + 0.4 - 0.2 * mx).astype(np.float32)
inp("MAPX", mapx, "Float")
inp("MAPY", mapy, "Float")
for interp, ci in [("Linear", cv2.INTER_LINEAR), ("Nearest", cv2.INTER_NEAREST)]:
    for border, cb in [("Constant", cv2.BORDER_CONSTANT), ("Replicate", cv2.BORDER_REPLICATE)]:
        ref = cv2.remap(F, mapx, mapy, ci, borderMode=cb, borderValue=-4)
        lines += close(f"Matft.image.remap(x, map1: MAPX, map2: MAPY, interpolation: .{interp}, borderMode: .{border}, borderValue: [-4])", ref, "Float", layout="F", atol=1e-3)
for code, cc in [("Rotate90Clockwise", cv2.ROTATE_90_CLOCKWISE), ("Rotate180", cv2.ROTATE_180), ("Rotate90Counterclockwise", cv2.ROTATE_90_COUNTERCLOCKWISE)]:
    lines += close(f"Matft.image.rotate(RGBA, rotateCode: .{code})", cv2.rotate(RGBA, cc), "UInt8", rtol=0, atol=0)
for fc in [0, 1, -1]:
    lines += close(f"Matft.image.flip(x, flipCode: {fc})", cv2.flip(F, fc), "Float", layout="F", rtol=0, atol=0)
# integer translation of UInt8 by warpAffine is exact
ref = cv2.warpAffine(RGBA, np.float32([[1, 0, 2], [0, 1, -1]]), (6, 5), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
lines += close("Matft.image.warpAffine(RGBA, matrix: MfArray([[1, 0, 2], [0, 1, -1]] as [[Float]]), width: 6, height: 5)", ref, "UInt8", rtol=0, atol=0)
# resize by factors
for interp, ci in [("Linear", cv2.INTER_LINEAR), ("Nearest", cv2.INTER_NEAREST)]:
    ref = cv2.resize(U, None, fx=1.5, fy=0.75, interpolation=ci)
    lines += close(f"Matft.image.resize(U, factor_x: 1.5, factor_y: 0.75, interpolation: .{interp})", ref, "UInt8", rtol=0, atol=1)
test("geometry", lines)

# ---------- Canny ----------
lines = []
for a in [3, 5, 7]:
    for l2 in [False, True]:
        lo, hi = {3: (40, 120), 5: (400, 1200), 7: (4000, 12000)}[a]
        ref = cv2.Canny(SQ, lo, hi, apertureSize=a, L2gradient=l2)
        lines += close(f"Matft.image.Canny(SQ, threshold1: {lo}, threshold2: {hi}, apertureSize: {a}, L2gradient: {str(l2).lower()})", ref, "UInt8", rtol=0, atol=0)
test("canny", lines)

# ---------- preprocess (PIL / transformers) ----------
lines = []
for name, resample in [("bilinear", Image.Resampling.BILINEAR), ("bicubic", Image.Resampling.BICUBIC)]:
    ref = np.array(Image.fromarray(np.ascontiguousarray(RGBA[:, :, :3])).resize((4, 7), resample))
    lines += close(f"Matft.image.resize(RGBA[Matft.all, Matft.all, 0~<3], width: 4, height: 7, resample: .{name})", ref, "UInt8", rtol=0, atol=0)
    ref = np.array(Image.fromarray(np.ascontiguousarray(U.T)).resize((5, 3), resample))
    lines += close(f"Matft.image.resize(U.T, width: 5, height: 3, resample: .{name})", ref, "UInt8", rtol=0, atol=0)
    ref = np.array(Image.fromarray(F).resize((5, 4), resample))
    lines += close(f"Matft.image.resize(F.astype(.Double), width: 5, height: 4, resample: .{name})", ref, "Float", check_type=False, rtol=1e-5, atol=1e-5)


def qwen2vl_patchify(image, patch_size, temporal_patch_size, merge_size):
    """The patchify step of transformers' Qwen2VLImageProcessor._preprocess for one image"""
    patches = np.array([image])
    if patches.shape[0] % temporal_patch_size != 0:
        repeats = np.repeat(patches[-1][np.newaxis], temporal_patch_size - 1, axis=0)
        patches = np.concatenate([patches, repeats], axis=0)
    channel = patches.shape[1]
    grid_t = patches.shape[0] // temporal_patch_size
    grid_h, grid_w = image.shape[1] // patch_size, image.shape[2] // patch_size
    patches = patches.reshape(grid_t, temporal_patch_size, channel, grid_h // merge_size, merge_size, patch_size,
                              grid_w // merge_size, merge_size, patch_size)
    patches = patches.transpose(0, 3, 6, 4, 7, 2, 1, 5, 8)
    return patches.reshape(grid_t * grid_h * grid_w, channel * temporal_patch_size * patch_size * patch_size), (grid_t, grid_h, grid_w)


CHW = inp("CHW", (np.arange(3 * 8 * 12) % 17 / 17 - 0.5).reshape(3, 8, 12).astype(np.float32), "Float")
for ps, tps, ms in [(2, 2, 2), (4, 3, 1), (1, 2, 4)]:
    ref, grid = qwen2vl_patchify(CHW, ps, tps, ms)
    lines += ["do {", f"    let (patches, grid) = Matft.image.qwen2vl_patchify(CHW, patch_size: {ps}, temporal_patch_size: {tps}, merge_size: {ms})",
              f"    XCTAssertEqual([grid.t, grid.h, grid.w], {list(grid)})"]
    lines += ["    " + l for l in close("patches", ref, "Float", rtol=0, atol=0)]
    lines += ["}"]
gray = U.astype(np.float64)
lines += close("Matft.image.normalize_meanstd(U.reshape([7, 9, 1]).astype(.Double), mean: [100], std: [50])", ((gray - 100) / 50)[..., None], "Double", check_type=False)
test("preprocess", lines)


def swift_input(name):
    a, mftype = INPUTS[name]
    return f"    private let {name} = {swift_array(a, mftype)}"


with open(OUT, "w") as f:
    f.write(f"// Generated by python/gen_image_coverage.py (numpy {np.__version__}, opencv {cv2.__version__}, Pillow {Image.__version__}). Do not edit by hand.\n")
    f.write("#if canImport(Accelerate)\nimport XCTest\n\nimport Matft\n\n")
    f.write("/// Parameters of Matft.image (ksize, scale, delta, border modes, interpolations, norm types, morphology ops, ...)\n")
    f.write("/// on small literal images. Expected values are OpenCV / PIL / numpy outputs\n")
    f.write("final class ImageCoverageTests: XCTestCase {\n")
    for name in INPUTS:
        f.write(swift_input(name) + "\n")
    for name, lines in TESTS:
        f.write(f"\n    func test_{name}() {{\n")
        for line in lines:
            f.write("        " + line + "\n")
        f.write("    }\n")
    f.write("}\n#endif\n")
print("wrote", OUT)
