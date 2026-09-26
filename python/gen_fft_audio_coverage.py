"""Generate Tests/MatftTests/FFTAudioCoverageTest.swift from numpy / scipy / librosa.

Requirements: numpy (2.x), scipy, librosa (>= 0.10)

    python python/gen_fft_audio_coverage.py

Every case is a Swift expression and the Python expression computing its expected value.
The inputs are written as literals, so the generated tests don't read files and run on WASI too
(complex results are compared by their real and imaginary parts, which works without complex arithmetic).
"""
import os

import numpy as np
import scipy.fft
import scipy.signal
import librosa

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "FFTAudioCoverageTest.swift")


def lit(v):
    v = float(v)
    if np.isnan(v):
        return ".nan"
    if np.isinf(v):
        return ".infinity" if v > 0 else "-.infinity"
    return repr(v)


def swift_array(a, mftype="Double"):
    a = np.asarray(a)
    shape = list(a.shape) if a.ndim > 0 else [1]
    values = ", ".join(lit(v) for v in a.ravel())
    return f"MfArray([{values}] as [Double], mftype: .{mftype}, shape: {shape})"


def escape(s):
    return s.replace("\\", "\\\\").replace("\"", "\\\"")


def close(swift, expected, mftype="Double", rtol=1e-9, atol=1e-9):
    return [f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: {rtol}, atol: {atol}, \"{escape(swift)}\")"]


def close_complex(swift, expected, mftype="Double", rtol=1e-9, atol=1e-9, layout=None):
    """Compare the real and imaginary parts. `layout`: the input whose layouts are iterated (the expression uses `x`)"""
    expected = np.asarray(expected)
    body = [f"let ret = {swift}",
            f"XCTAssertTrue(ret.isComplex, \"{escape(swift)}\")",
            f"XCTAssertEqual(ret.mftype, .{mftype}, \"{escape(swift)}\")",
            f"XCTAssertClose(ret.real, {swift_array(expected.real, mftype)}, rtol: {rtol}, atol: {atol}, \"{escape(swift)} real\"{' + name' if layout else ''})",
            f"XCTAssertClose(ret.imag!, {swift_array(expected.imag, mftype)}, rtol: {rtol}, atol: {atol}, \"{escape(swift)} imag\"{' + name' if layout else ''})"]
    if layout:
        return [f"for (name, x) in layoutVariants({layout}){{"] + ["    " + l for l in body] + ["}"]
    return ["do {"] + ["    " + l for l in body] + ["}"]


INPUTS = {}


def inp(name, a, mftype="Double"):
    INPUTS[name] = (np.asarray(a, dtype=np.float64), mftype)
    return np.asarray(a, dtype=np.float64)


def test_signal(n, sr):
    t = np.arange(n, dtype=np.float64) / sr
    return 0.6 * np.sin(2 * np.pi * 440.0 * t) + 0.3 * np.sin(2 * np.pi * 1250.5 * t + 0.3) + 0.05 * np.cos(2 * np.pi * 97.0 * t)


X7 = inp("X7", [1.0, -2.0, 3.5, 0.0, 4.0, -1.0, 2.0])
X8 = inp("X8", [0.5, 1.0, -1.5, 2.0, 0.0, 3.0, -2.5, 1.0])
X2 = inp("X2", [[1.0, 0.0, 5.0, 1.0, 2.0], [-1.0, 2.0, 0.5, 3.0, -2.0], [4.0, -3.0, 1.0, 0.0, 2.5]])
SIG = inp("SIG", test_signal(96, 8000))
SIGF = inp("SIGF", SIG, "Float")

TESTS = []


def test(name, lines, wasi=True):
    TESTS.append((name, lines, wasi))


NORMS = ["backward", "ortho", "forward"]

# ---------- rfft (pocketFFT) ----------
lines = []
for norm in NORMS:
    for name, x in [("X7", X7), ("X8", X8)]:
        lines += close_complex(f"Matft.fft.rfft({name}, norm: .{norm})", np.fft.rfft(x, norm=norm))
    for n in [5, 9, 12]:
        lines += close_complex(f"Matft.fft.rfft(X7, number: {n}, norm: .{norm})", np.fft.rfft(X7, n=n, norm=norm))
lines += close_complex("Matft.fft.rfft(X7.astype(.Float))", np.fft.rfft(X7), rtol=1e-6, atol=1e-6)
lines += close_complex("Matft.fft.rfft(MfArray([3, -1, 0, 2, 5] as [Int]))", np.fft.rfft([3, -1, 0, 2, 5]))
for axis in [0, 1, -1]:
    lines += close_complex(f"Matft.fft.rfft(x, axis: {axis}, norm: .ortho)", np.fft.rfft(X2, axis=axis, norm="ortho"), layout="X2")
lines += close_complex("Matft.fft.rfft(x, number: 4, axis: 0)", np.fft.rfft(X2, n=4, axis=0), layout="X2")
test("rfft", lines)

# ---------- irfft (pocketFFT) ----------
lines = []
spec = np.array([4.0 + 0j, 1.0 - 2.0j, -0.5 + 1.5j, 3.0 + 0.25j])
inp("SPEC_RE", spec.real)
inp("SPEC_IM", spec.imag)
lines += ["let spec = MfArray(real: SPEC_RE, imag: SPEC_IM)"]
for norm in NORMS:
    lines += close("Matft.fft.irfft(spec, norm: .{})".format(norm), np.fft.irfft(spec, norm=norm))
    for n in [5, 7, 3, 10]:
        lines += close(f"Matft.fft.irfft(spec, number: {n}, norm: .{norm})", np.fft.irfft(spec, n=n, norm=norm))
# round trips of odd and even lengths
for norm in NORMS:
    lines += close(f"Matft.fft.irfft(Matft.fft.rfft(X7, norm: .{norm}), number: 7, norm: .{norm})", X7)
    lines += close(f"Matft.fft.irfft(Matft.fft.rfft(X8, norm: .{norm}), norm: .{norm})", X8)
lines += close("Matft.fft.irfft(Matft.fft.rfft(X2, axis: 0), number: 3, axis: 0)", X2)
lines += close("Matft.fft.irfft(Matft.fft.rfft(X2.T, axis: 1), number: 3, axis: 1)", X2.T)
test("irfft", lines)

# ---------- rfft (vDSP) ----------
lines = []
for norm in NORMS:
    lines += close_complex(f"Matft.fft.rfft(X8, norm: .{norm}, vDSP: true)", np.fft.rfft(X8, norm=norm))
    lines += close_complex(f"Matft.fft.rfft(X8.astype(.Float), norm: .{norm}, vDSP: true)", np.fft.rfft(X8, norm=norm), "Float", rtol=1e-5, atol=1e-5)
    lines += close_complex(f"Matft.fft.rfft(X8, number: 16, norm: .{norm}, vDSP: true)", np.fft.rfft(X8, n=16, norm=norm))
    lines += close_complex(f"Matft.fft.rfft(X8, number: 4, norm: .{norm}, vDSP: true)", np.fft.rfft(X8, n=4, norm=norm))
lines += close_complex("Matft.fft.rfft(x, number: 4, axis: 0, vDSP: true)", np.fft.rfft(X2, n=4, axis=0), layout="X2")
test("rfft_vDSP", lines, wasi=False)

# ---------- windows ----------
lines = []
for f in ["hanning", "hamming", "blackman", "bartlett"]:
    for M in [0, 1, 2, 5]:
        lines += close(f"Matft.{f}({M})", getattr(np, f)(M), rtol=1e-12, atol=1e-12) if M > 0 else [f"XCTAssertEqual(Matft.{f}(0).shape, [0])"]
for M in [0, 1, 4, 7]:
    lines += close(f"Matft.kaiser({M}, beta: 8.6)", np.kaiser(M, 8.6), rtol=1e-10, atol=1e-12) if M > 0 else ["XCTAssertEqual(Matft.kaiser(0, beta: 8.6).shape, [0])"]
test("windows", lines)

# ---------- stft ----------
lines = []
for pad_mode in ["constant", "edge", "reflect", "symmetric", "wrap"]:
    # center=True means np.pad(y, n_fft // 2, mode) as documented by librosa. librosa.stft itself rejects some modes like "wrap",
    # and pads the tail segment separately, so its last "reflect" frame differs when the segment is shorter than n_fft // 2 + 1
    ref = librosa.stft(np.pad(SIG, 8, mode=pad_mode), n_fft=16, hop_length=8, center=False)
    if pad_mode in ("constant", "edge"):
        assert np.allclose(ref, librosa.stft(SIG, n_fft=16, hop_length=8, pad_mode=pad_mode))
    lines += close_complex(f"Matft.audio.stft(SIG, n_fft: 16, hop_length: 8, pad_mode: .{pad_mode})", ref)
for window in ["hamming", "blackman", "bartlett"]:
    ref = librosa.stft(SIG, n_fft=16, hop_length=8, window=window)
    lines += close_complex(f"Matft.audio.stft(SIG, n_fft: 16, hop_length: 8, window: .{window})", ref)
# odd n_fft, win_length < n_fft (odd difference), no centering
lines += close_complex("Matft.audio.stft(SIG, n_fft: 15, hop_length: 4)", librosa.stft(SIG, n_fft=15, hop_length=4))
lines += close_complex("Matft.audio.stft(SIG, n_fft: 16, hop_length: 5, win_length: 11)", librosa.stft(SIG, n_fft=16, hop_length=5, win_length=11))
lines += close_complex("Matft.audio.stft(SIG, n_fft: 17, win_length: 12, center: false)", librosa.stft(SIG, n_fft=17, win_length=12, center=False))
lines += close_complex("Matft.audio.stft(SIGF, n_fft: 16, hop_length: 8, pad_mode: .reflect)", librosa.stft(np.pad(SIG.astype(np.float32), 8, mode="reflect"), n_fft=16, hop_length=8, center=False), "Float", rtol=1e-4, atol=1e-5)
# a view as the signal
lines += close_complex("Matft.audio.stft(SIG[Matft.reverse][Matft.reverse], n_fft: 16, hop_length: 8)", librosa.stft(SIG, n_fft=16, hop_length=8))
test("stft", lines)

# ---------- mel / power_to_db ----------
lines = []
for power in [1.0, 2.0]:
    for htk in [False, True]:
        for norm in ["slaney", None]:
            ref = librosa.feature.melspectrogram(y=SIG, sr=8000, n_fft=32, hop_length=16, power=power, n_mels=6, htk=htk, norm=norm, fmin=100, fmax=3500, dtype=np.float64)
            sw_norm = ".slaney" if norm else "nil"
            lines += close(f"Matft.audio.melspectrogram(SIG, sr: 8000, n_fft: 32, hop_length: 16, power: {power}, n_mels: 6, fmin: 100, fmax: 3500, htk: {str(htk).lower()}, norm: {sw_norm})", ref, rtol=1e-8, atol=1e-10)
lines += close("Matft.audio.melspectrogram(SIGF, sr: 8000, n_fft: 32, hop_length: 16, n_mels: 6)", librosa.feature.melspectrogram(y=SIG.astype(np.float32), sr=8000, n_fft=32, hop_length=16, n_mels=6), "Float", rtol=1e-4, atol=1e-5)
S = np.array([[0.0, 1e-12, 3.0, 20.0], [0.5, 100.0, 1e-3, 7.0], [2.5e-6, 0.0, 1e4, 1.0]])
inp("S", S)
for kwargs, sw in [({}, ""), ({"top_db": None}, ", top_db: nil"), ({"ref": 0.5}, ", ref: 0.5"), ({"amin": 1e-5, "top_db": 20.0}, ", amin: 1e-5, top_db: 20"), ({"ref": 1e3, "top_db": None}, ", ref: 1000, top_db: nil")]:
    lines += close(f"Matft.audio.power_to_db(S{sw})", librosa.power_to_db(S, **kwargs), rtol=1e-9, atol=1e-9)
    lines += close(f"Matft.audio.power_to_db(S.astype(.Float){sw})", librosa.power_to_db(S.astype(np.float32), **kwargs), "Float", rtol=1e-5, atol=1e-4)
test("mel_power_to_db", lines)

# ---------- pad_or_trim ----------
lines = []
P = np.arange(12, dtype=np.float64).reshape(3, 4) - 5
inp("P", P)
for length, axis in [(6, -1), (2, -1), (4, -1), (5, 0), (1, 0)]:
    ax = axis % 2
    if P.shape[ax] >= length:
        ref = np.take(P, np.arange(length), axis=ax)
    else:
        pad = [(0, 0), (0, 0)]
        pad[ax] = (0, length - P.shape[ax])
        ref = np.pad(P, pad)
    lines += close(f"Matft.audio.pad_or_trim(P, length: {length}, axis: {axis})", ref, rtol=0, atol=0)
    lines += close(f"Matft.audio.pad_or_trim(P.T.T, length: {length}, axis: {axis})", ref, rtol=0, atol=0)
test("pad_or_trim", lines)

# ---------- whisper_log_mel with padding ----------
lines = []
W = inp("W", test_signal(1600, 16000))
for padding in [0, 320, 150]:
    y = np.pad(W, (0, padding))
    stft = librosa.stft(y, n_fft=400, hop_length=160, window="hann", center=True, pad_mode="reflect")
    mag = np.abs(stft[:, :-1]) ** 2
    filters = librosa.filters.mel(sr=16000, n_fft=400, n_mels=8)
    log_spec = np.log10(np.clip(filters @ mag, 1e-10, None))
    log_spec = np.maximum(log_spec, log_spec.max() - 8.0)
    ref = (log_spec + 4.0) / 4.0
    lines += close(f"Matft.audio.whisper_log_mel(W, n_mels: 8, padding: {padding})", ref, rtol=1e-8, atol=1e-8)
test("whisper_log_mel_padding", lines)


def swift_input(name):
    a, mftype = INPUTS[name]
    return f"    private let {name} = {swift_array(a, mftype)}"


with open(OUT, "w") as f:
    f.write(f"// Generated by python/gen_fft_audio_coverage.py (numpy {np.__version__}, scipy {scipy.__version__}, librosa {librosa.__version__}). Do not edit by hand.\n")
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write("/// FFT (pocketFFT / vDSP), windows and audio functions over norms, lengths, pad modes and windows. Expected values are numpy / librosa outputs.\n")
    f.write("/// The inputs are literals, so the tests except vDSP ones run on WASI too\n")
    f.write("final class FFTAudioCoverageTests: XCTestCase {\n")
    for name in INPUTS:
        f.write(swift_input(name) + "\n")
    for name, lines, wasi in TESTS:
        f.write("\n")
        if not wasi:
            f.write("    #if canImport(Accelerate)\n")
        f.write(f"    func test_{name}() {{\n")
        for line in lines:
            f.write("        " + line + "\n")
        f.write("    }\n")
        if not wasi:
            f.write("    #endif\n")
    f.write("}\n")
print("wrote", OUT)
