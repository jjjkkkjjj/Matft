---
title: Audio Features
---

# Audio Features

`Matft.audio` computes audio features compatible with [librosa](https://librosa.org/), e.g. the log-mel spectrogram for [Whisper](https://github.com/openai/whisper).

```swift
let audio = MfArray(samples, mftype: .Float) // 16kHz mono
let logmel = Matft.audio.whisper_log_mel(Matft.audio.pad_or_trim(audio), n_mels: 80)
// logmel.shape == [80, 3000]

let spec = Matft.audio.stft(audio, n_fft: 400, hop_length: 160, pad_mode: .reflect) // complex, (201, n_frames)
let mel = Matft.audio.melspectrogram(audio, sr: 16000, n_fft: 400, hop_length: 160, n_mels: 80)
let db = Matft.audio.power_to_db(mel)
```

See [NumPy Mapping › FFT and Audio](../numpy-mapping/fft-and-audio.md) for the list of functions and their Python counterparts.
