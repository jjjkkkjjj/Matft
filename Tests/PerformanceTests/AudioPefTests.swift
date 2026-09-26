//
//  AudioPefTests.swift
//

import XCTest

import Matft

final class AudioPefTests: XCTestCase {

    /// 30 seconds of 16kHz audio (Whisper input)
    static let audio30s: MfArray = {
        let y = (0..<480000).map{ Float(sin(2 * Double.pi * 440.0 * Double($0) / 16000)) }
        return MfArray(y, mftype: .Float)
    }()

    func testPeformanceWhisperLogMel() {
        let audio = AudioPefTests.audio30s

        self.measureWithWarmup {
            let _ = Matft.audio.whisper_log_mel(audio)
        }
    }

    func testPeformanceSTFT() {
        let audio = AudioPefTests.audio30s

        self.measureWithWarmup {
            let _ = Matft.audio.stft(audio, n_fft: 400, hop_length: 160, pad_mode: .reflect)
        }
    }
}
