//
//  audio+static.swift
//  Matft
//

import Foundation

extension Matft.audio{
    /**
       Return a window of a given length and type. Same as `scipy.signal.get_window`
       - parameters:
            - window: The window type
            - Nx: The number of samples in the window
            - fftbins: (Optional) If true (default), create a periodic window for spectral analysis. If false, create a symmetric window
       - Returns: The window (Double)
    */
    public static func get_window(_ window: MfWindowType, Nx: Int, fftbins: Bool = true) -> MfArray{
        if window == .boxcar{
            return Matft.nums(Double(1), shape: [Nx], mftype: .Double)
        }
        // periodic window is the symmetric window of Nx + 1 points without the last point
        let M = fftbins ? Nx + 1 : Nx
        let ret: MfArray
        switch window {
        case .hann:
            ret = Matft.hanning(M)
        case .hamming:
            ret = Matft.hamming(M)
        case .blackman:
            ret = Matft.blackman(M)
        case .bartlett:
            ret = Matft.bartlett(M)
        case .boxcar:
            preconditionFailure("unreachable")
        }
        return fftbins ? ret[MfSlice(to: Nx)].to_contiguous(mforder: .Row) : ret
    }

    /**
       Slice a signal into overlapping frames along the last axis. Same as `librosa.util.frame` with `axis=-1`
       - parameters:
            - x: The signal (..., n)
            - frame_length: The length of each frame
            - hop_length: The number of steps to advance between frames
       - Returns: The framed signal (..., frame_length, n_frames). Unlike librosa, it is a copy
    */
    public static func frame(_ x: MfArray, frame_length: Int, hop_length: Int) -> MfArray{
        precondition(frame_length >= 1 && hop_length >= 1, "frame_length and hop_length must be positive")
        let n = x.shape[x.ndim - 1]
        precondition(n >= frame_length, "Input is too short (n=\(n)) for frame_length=\(frame_length)")
        let n_frames = 1 + (n - frame_length) / hop_length

        let x = x.to_contiguous(mforder: .Row)
        let last = x.strides[x.ndim - 1]
        let structure = MfStructure(shape: Array(x.shape.dropLast()) + [frame_length, n_frames],
                                    strides: Array(x.strides.dropLast()) + [last, hop_length * last])
        return MfArray(base: x, mfstructure: structure, offset: 0).to_contiguous(mforder: .Row)
    }

    /**
       Short-time Fourier transform. Same as `librosa.stft`
       - parameters:
            - y: The 1d real signal
            - n_fft: (Optional) The length of the windowed signal after padding with zeros, by default 2048
            - hop_length: (Optional) The number of samples between adjacent frames, by default `win_length / 4`
            - win_length: (Optional) The window length (<= n_fft). The window is zero-padded at center to n_fft. By default n_fft
            - window: (Optional) The window type (periodic), by default hann
            - center: (Optional) Whether to pad the signal so that the t-th frame is centered at `y[t * hop_length]`, by default true
            - pad_mode: (Optional) The padding mode used when center is true, by default constant (zero)
       - Returns: The complex STFT matrix (1 + n_fft/2, n_frames)
    */
    public static func stft(_ y: MfArray, n_fft: Int = 2048, hop_length: Int? = nil, win_length: Int? = nil, window: MfWindowType = .hann, center: Bool = true, pad_mode: MfPadMode = .constant) -> MfArray{
        unsupport_complex(y)
        precondition(y.ndim == 1, "Only 1d signal is supported")
        let win_length = win_length ?? n_fft
        let hop_length = hop_length ?? win_length / 4
        precondition(0 < win_length && win_length <= n_fft, "win_length must be in (0, n_fft]")

        var y = y.storedType == .Float ? y.astype(.Float) : y.astype(.Double)

        var win = Matft.audio.get_window(window, Nx: win_length, fftbins: true)
        if win_length < n_fft{
            let lpad = (n_fft - win_length) / 2
            win = Matft.pad(win, pad_width: [(lpad, n_fft - win_length - lpad)])
        }
        win = win.astype(y.mftype)

        if center{
            y = Matft.pad(y, pad_width: [(n_fft / 2, n_fft / 2)], mode: pad_mode)
        }

        // (n_frames, n_fft)
        let frames = Matft.audio.frame(y, frame_length: n_fft, hop_length: hop_length).T * win
        // (n_frames, 1 + n_fft/2) -> (1 + n_fft/2, n_frames)
        // pocketFFT returns Double, so cast back to the input type (as librosa returns complex64 for float32)
        return Matft.fft.rfft(frames, axis: -1).T.astype(y.mftype, mforder: .Row)
    }

    /**
       Create a mel filter bank. Same as `librosa.filters.mel`
       - parameters:
            - sr: The sampling rate
            - n_fft: The number of FFT components
            - n_mels: (Optional) The number of mel bands, by default 128
            - fmin: (Optional) The lowest frequency (Hz), by default 0
            - fmax: (Optional) The highest frequency (Hz), by default sr / 2
            - htk: (Optional) Use HTK formula instead of Slaney, by default false
            - norm: (Optional) The normalization. If nil, leave all the triangles aiming for a peak value of 1.0. By default slaney
            - mftype: (Optional) The type of the returned mfarray, by default Float
       - Returns: The mel transform matrix (n_mels, 1 + n_fft/2)
    */
    public static func mel_filters(sr: Double, n_fft: Int, n_mels: Int = 128, fmin: Double = 0, fmax: Double? = nil, htk: Bool = false, norm: MfMelNorm? = .slaney, mftype: MfType = .Float) -> MfArray{
        let fmax = fmax ?? sr / 2
        let n_freqs = 1 + n_fft / 2
        let fftfreqs = (0..<n_freqs).map{ Double($0) * sr / Double(n_fft) }

        // center frequencies of mel bands
        let min_mel = _hz_to_mel(fmin, htk: htk)
        let max_mel = _hz_to_mel(fmax, htk: htk)
        let mel_f = _linspace(min_mel, max_mel, num: n_mels + 2).map{ _mel_to_hz($0, htk: htk) }

        var weights = [Double](repeating: 0, count: n_mels * n_freqs)
        for i in 0..<n_mels{
            let fdiff_lower = mel_f[i + 1] - mel_f[i]
            let fdiff_upper = mel_f[i + 2] - mel_f[i + 1]
            let enorm = norm == .slaney ? 2 / (mel_f[i + 2] - mel_f[i]) : 1
            for k in 0..<n_freqs{
                let lower = (fftfreqs[k] - mel_f[i]) / fdiff_lower
                let upper = (mel_f[i + 2] - fftfreqs[k]) / fdiff_upper
                weights[i * n_freqs + k] = Swift.max(0, Swift.min(lower, upper)) * enorm
            }
        }

        return MfArray(weights, mftype: .Double, shape: [n_mels, n_freqs]).astype(mftype)
    }

    /**
       Compute a mel-scaled power spectrogram. Same as `librosa.feature.melspectrogram`
       - parameters:
            - y: The 1d real signal
            - sr: (Optional) The sampling rate, by default 22050
            - n_fft: (Optional) See `stft`, by default 2048
            - hop_length: (Optional) See `stft`, by default 512
            - win_length: (Optional) See `stft`
            - window: (Optional) See `stft`
            - center: (Optional) See `stft`
            - pad_mode: (Optional) See `stft`
            - power: (Optional) Exponent for the magnitude spectrogram, by default 2 (power)
            - n_mels: (Optional) See `mel_filters`
            - fmin: (Optional) See `mel_filters`
            - fmax: (Optional) See `mel_filters`
            - htk: (Optional) See `mel_filters`
            - norm: (Optional) See `mel_filters`
       - Returns: The mel spectrogram (n_mels, n_frames)
    */
    public static func melspectrogram(_ y: MfArray, sr: Double = 22050, n_fft: Int = 2048, hop_length: Int = 512, win_length: Int? = nil, window: MfWindowType = .hann, center: Bool = true, pad_mode: MfPadMode = .constant, power: Double = 2.0, n_mels: Int = 128, fmin: Double = 0, fmax: Double? = nil, htk: Bool = false, norm: MfMelNorm? = .slaney) -> MfArray{
        let spec = Matft.audio.stft(y, n_fft: n_fft, hop_length: hop_length, win_length: win_length, window: window, center: center, pad_mode: pad_mode)
        let S = _power_spectrum(spec, power: power)
        let mel_basis = Matft.audio.mel_filters(sr: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax, htk: htk, norm: norm, mftype: S.mftype)
        return mel_basis *& S
    }

    /**
       Convert a power spectrogram to decibel units. Same as `librosa.power_to_db` with a scalar ref
       - parameters:
            - S: The power spectrogram
            - ref: (Optional) The reference power, by default 1.0
            - amin: (Optional) The minimum threshold of S and ref, by default 1e-10
            - top_db: (Optional) Threshold the output at `max - top_db`, by default 80. If nil, no threshold
       - Returns: `10 * log10(S / ref)`
    */
    public static func power_to_db(_ S: MfArray, ref: Double = 1.0, amin: Double = 1e-10, top_db: Double? = 80.0) -> MfArray{
        unsupport_complex(S)
        precondition(amin > 0, "amin must be strictly positive")
        let S = S.storedType == .Float ? S.astype(.Float) : S.astype(.Double)

        var log_spec = Matft.math.log10(Matft.clip(S, min: amin)) * 10 - 10 * Foundation.log10(Swift.max(amin, ref))
        if let top_db = top_db{
            precondition(top_db >= 0, "top_db must be non-negative")
            log_spec = Matft.clip(log_spec, min: _max_scalar(log_spec) - top_db)
        }
        // Double scalar operations promote Float to Double
        return log_spec.astype(S.mftype)
    }

    /**
       Pad or trim the audio array to `length` along the axis. Same as `whisper.audio.pad_or_trim`
       - parameters:
            - array: The audio array
            - length: (Optional) The length, by default 480000 (30 seconds of 16kHz audio)
            - axis: (Optional) The axis, by default -1
       - Returns: The padded or trimmed array
    */
    public static func pad_or_trim(_ array: MfArray, length: Int = 480000, axis: Int = -1) -> MfArray{
        let axis = get_positive_axis(axis, ndim: array.ndim)
        let n = array.shape[axis]
        if n > length{
            var indices: [Any] = Array(repeating: MfSlice(), count: array.ndim)
            indices[axis] = MfSlice(to: length)
            return array._get_mfarray(indices: &indices).to_contiguous(mforder: .Row)
        }
        else if n < length{
            var pad_width = Array(repeating: (0, 0), count: array.ndim)
            pad_width[axis] = (0, length - n)
            return Matft.pad(array, pad_width: pad_width)
        }
        return array.deepcopy()
    }

    /**
       Compute the log-mel spectrogram for Whisper. Same as `whisper.audio.log_mel_spectrogram`
       - parameters:
            - audio: The 1d audio signal (16kHz)
            - n_mels: (Optional) The number of mel bands, 80 or 128. By default 80
            - padding: (Optional) The number of zero samples to pad to the right, by default 0
       - Returns: The log-mel spectrogram (n_mels, n_frames)
    */
    public static func whisper_log_mel(_ audio: MfArray, n_mels: Int = 80, padding: Int = 0) -> MfArray{
        var audio = audio
        if padding > 0{
            audio = Matft.pad(audio, pad_width: [(0, padding)])
        }
        let spec = Matft.audio.stft(audio, n_fft: 400, hop_length: 160, window: .hann, center: true, pad_mode: .reflect)
        // drop the last frame
        let magnitudes = _power_spectrum(spec[MfSlice(), MfSlice(to: -1)], power: 2.0)
        let filters = Matft.audio.mel_filters(sr: 16000, n_fft: 400, n_mels: n_mels, mftype: magnitudes.mftype)

        var log_spec = Matft.math.log10(Matft.clip(filters *& magnitudes, min: 1e-10))
        log_spec = Matft.clip(log_spec, min: _max_scalar(log_spec) - 8.0)
        // Double scalar operations promote Float to Double
        return ((log_spec + 4.0) / 4.0).astype(magnitudes.mftype)
    }
}

/// |spec| ** power
fileprivate func _power_spectrum(_ spec: MfArray, power: Double) -> MfArray{
    let re = spec.real
    let im = spec.imag!
    let power2 = re * re + im * im
    if power == 2{
        return power2
    }
    return Matft.math.power(bases: power2, exponents: Float(power / 2))
}

fileprivate func _max_scalar(_ mfarray: MfArray) -> Double{
    return Matft.stats.max(mfarray).astype(.Double).scalar(Double.self)!
}

/// Same as `np.linspace` (endpoint=True)
fileprivate func _linspace(_ start: Double, _ stop: Double, num: Int) -> [Double]{
    if num == 1{
        return [start]
    }
    let step = (stop - start) / Double(num - 1)
    var ret = (0..<num).map{ start + Double($0) * step }
    ret[num - 1] = stop
    return ret
}

/// Same as `librosa.hz_to_mel`
fileprivate func _hz_to_mel(_ freq: Double, htk: Bool) -> Double{
    if htk{
        return 2595.0 * log10(1.0 + freq / 700.0)
    }
    let f_sp = 200.0 / 3
    let min_log_hz = 1000.0
    let min_log_mel = min_log_hz / f_sp
    let logstep = log(6.4) / 27.0
    return freq >= min_log_hz ? min_log_mel + log(freq / min_log_hz) / logstep : freq / f_sp
}

/// Same as `librosa.mel_to_hz`
fileprivate func _mel_to_hz(_ mel: Double, htk: Bool) -> Double{
    if htk{
        return 700.0 * (pow(10.0, mel / 2595.0) - 1.0)
    }
    let f_sp = 200.0 / 3
    let min_log_hz = 1000.0
    let min_log_mel = min_log_hz / f_sp
    let logstep = log(6.4) / 27.0
    return mel >= min_log_mel ? min_log_hz * exp(logstep * (mel - min_log_mel)) : f_sp * mel
}
