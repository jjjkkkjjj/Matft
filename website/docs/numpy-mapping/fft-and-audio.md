---
title: FFT and Audio
---

# FFT and Audio

## FFT

| Matft | Numpy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.fft.rfft` | `numpy.fft.rfft` |  |  |
| `Matft.fft.irfft` | `numpy.fft.irfft` |  |  |

## Audio

See [Audio Features](../guide/audio.md) for the usage.

| Matft | Python | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.audio.get_window` | `scipy.signal.get_window` |  |  |
| `Matft.audio.frame` | `librosa.util.frame` |  |  |
| `Matft.audio.stft` | `librosa.stft` |  |  |
| `Matft.audio.mel_filters` | `librosa.filters.mel` |  |  |
| `Matft.audio.melspectrogram` | `librosa.feature.melspectrogram` |  |  |
| `Matft.audio.power_to_db` | `librosa.power_to_db` |  |  |
| `Matft.audio.pad_or_trim` | `whisper.audio.pad_or_trim` |  |  |
| `Matft.audio.whisper_log_mel` | `whisper.audio.log_mel_spectrogram` |  |  |
