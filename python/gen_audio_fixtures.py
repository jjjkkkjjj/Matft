"""Generate reference values for Tests/MatftTests/AudioTest.swift.

Requirements: numpy, scipy, librosa (>=0.10), transformers (numpy backend is enough)

    python python/gen_audio_fixtures.py

Small values are printed as Swift literals (paste them into the tests),
large arrays are saved as CSV files into Tests/MatftTests/files/audio/.
The test signal is defined by `test_signal` and must be identical to `_test_signal` in AudioTest.swift.
"""
import os

import numpy as np
import scipy.signal
import librosa
from transformers import WhisperFeatureExtractor

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "files", "audio")


def test_signal(n, sr):
    t = np.arange(n, dtype=np.float64) / sr
    return (0.6 * np.sin(2 * np.pi * 440.0 * t)
            + 0.3 * np.sin(2 * np.pi * 1250.5 * t + 0.3)
            + 0.1 * np.cos(2 * np.pi * 3.7 * t) * np.sin(2 * np.pi * 3000.0 * t))


def save(name, arr):
    arr = np.asarray(arr, dtype=np.float64)
    if arr.ndim == 1:
        arr = arr[None, :]
    np.savetxt(os.path.join(OUT_DIR, name), arr, delimiter=",", fmt="%.12g")
    print(f"saved {name} shape={arr.shape}")


def literal(name, arr):
    print(f"{name}: {np.asarray(arr, dtype=np.float64).round(10).tolist()}")


def whisper_log_mel(audio, n_mels):
    """Same as whisper.audio.log_mel_spectrogram (float64)"""
    stft = librosa.stft(audio, n_fft=400, hop_length=160, window="hann", center=True, pad_mode="reflect")
    magnitudes = np.abs(stft[:, :-1]) ** 2
    filters = librosa.filters.mel(sr=16000, n_fft=400, n_mels=n_mels, dtype=np.float64)
    mel_spec = filters @ magnitudes
    log_spec = np.log10(np.clip(mel_spec, 1e-10, None))
    log_spec = np.maximum(log_spec, log_spec.max() - 8.0)
    return (log_spec + 4.0) / 4.0


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # windows (numpy: symmetric)
    for m in [1, 2, 5, 8]:
        literal(f"hanning({m})", np.hanning(m))
        literal(f"hamming({m})", np.hamming(m))
        literal(f"blackman({m})", np.blackman(m))
        literal(f"bartlett({m})", np.bartlett(m))
        literal(f"kaiser({m}, 5.0)", np.kaiser(m, 5.0))
    # scipy get_window (fftbins=True -> periodic)
    for name in ["hann", "hamming", "blackman", "bartlett", "boxcar"]:
        literal(f"get_window({name}, 8)", scipy.signal.get_window(name, 8))
        literal(f"get_window({name}, 5, fftbins=False)", scipy.signal.get_window(name, 5, fftbins=False))

    # frame
    x = np.arange(10, dtype=np.float64)
    literal("frame(arange(10), 4, 2)", librosa.util.frame(x, frame_length=4, hop_length=2))
    literal("frame(arange(10), 3, 3)", librosa.util.frame(x, frame_length=3, hop_length=3))

    # stft
    y = test_signal(1000, 8000)
    for tag, kwargs in [
        ("center_constant", dict(center=True, pad_mode="constant")),
        ("center_reflect", dict(center=True, pad_mode="reflect")),
        ("nocenter", dict(center=False)),
        ("win200_reflect", dict(center=True, pad_mode="reflect", win_length=200)),
    ]:
        s = librosa.stft(y, n_fft=256, hop_length=64, window="hann", **kwargs)
        save(f"stft_{tag}_real.csv", s.real)
        save(f"stft_{tag}_imag.csv", s.imag)

    # mel filters
    save("mel_slaney.csv", librosa.filters.mel(sr=8000, n_fft=256, n_mels=20, dtype=np.float64))
    save("mel_htk_nonorm.csv", librosa.filters.mel(sr=8000, n_fft=256, n_mels=20, fmin=100.0, fmax=3000.0,
                                                   htk=True, norm=None, dtype=np.float64))

    # melspectrogram / power_to_db
    mel = librosa.feature.melspectrogram(y=y, sr=8000, n_fft=256, hop_length=64, n_mels=20)
    save("melspectrogram.csv", mel)
    save("power_to_db.csv", librosa.power_to_db(mel, ref=1.0, amin=1e-10, top_db=80.0))

    # whisper log-mel (1 sec, 16kHz)
    audio = test_signal(16000, 16000)
    ref = whisper_log_mel(audio, 80)
    # cross check with transformers (pads to 30 sec, so compare on the unpadded region is not possible;
    # compare using the same length input instead)
    fe = WhisperFeatureExtractor(feature_size=80, n_samples=16000)
    hf = fe._np_extract_fbank_features(audio[None, :].astype(np.float32), "cpu")[0]
    print("max |ref - transformers| =", np.abs(ref - hf).max())
    save("whisper_log_mel80.csv", ref)


if __name__ == "__main__":
    main()
