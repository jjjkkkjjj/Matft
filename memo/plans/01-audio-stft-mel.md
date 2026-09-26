# Plan 1: 音声前処理（窓関数・STFT・mel・log-mel）

> **実装済み（branch `feature/audio-stft-mel`）**: `Matft.hanning/hamming/blackman/bartlett/kaiser`，`Matft.audio.get_window/frame/stft/mel_filters/melspectrogram/power_to_db/pad_or_trim/whisper_log_mel`．
> 参照値: `python/gen_audio_fixtures.py`（librosa 0.11 / transformers 5.17 の WhisperFeatureExtractor と差 3.4e-6 を確認）→ `Tests/MatftTests/files/audio/`．
> 速度（M系 Mac, release, 30 秒音声）: whisper_log_mel 7.8ms（transformers numpy 11.4ms），stft 6.5ms（librosa 1.9ms，主に pocketFFT 部分 3.4ms）．
> 未実装: `istft`，多次元（バッチ）入力の stft，`frame` の view 返却（現状コピー），callable な `ref`（`np.max`）．

## 目的
Swift エコシステムに存在しない（mlx-swift-lm も `ProcessedAudio(features:)` の器のみ）音声特徴量計算を Matft で提供する．
ゴールは **Whisper の log-mel spectrogram を Python（openai-whisper / transformers WhisperFeatureExtractor）と数値一致で出せる** こと．

## 前提・依存
- Plan 4-A の `Matft.pad(mode: .reflect)` が必要（STFT の `center=True`）．
- 既存 `Matft.fft.rfft`（pocketFFT，任意長対応．n_fft=400 など非 2 冪を扱うので `vDSP: false` 経路を使う）．

## API 設計（案）

NumPy にある窓関数は NumPy 名・仕様に従う．NumPy に無いものは librosa の名前・引数に寄せ，新 namespace `Matft.audio` に置く．

| API | 参照実装 | 備考 |
|---|---|---|
| `Matft.hanning(M)`, `hamming`, `blackman`, `bartlett`, `kaiser(M, beta)` | `np.hanning` 等 | **対称窓** |
| `Matft.audio.get_window(_ name:, Nx:, fftbins: true)` | `scipy.signal.get_window` | `fftbins=true` で **periodic 窓**（torch.hann_window デフォルトと同じ） |
| `Matft.audio.frame(x, frame_length:, hop_length:, axis: -1)` | `librosa.util.frame` | as_strided 相当の view で返せるか検討（コピー可） |
| `Matft.audio.stft(y, n_fft:, hop_length:, win_length:, window:, center: true, pad_mode: .reflect)` | `librosa.stft` / `torch.stft(return_complex=True)` | 出力 shape `(1 + n_fft/2, n_frames)` の複素 MfArray |
| `Matft.audio.istft(...)` | `librosa.istft` | 優先度低 |
| `Matft.audio.mel_filters(sr:, n_fft:, n_mels:, fmin:, fmax:, htk: false, norm: "slaney")` | `librosa.filters.mel` | shape `(n_mels, 1 + n_fft/2)` |
| `Matft.audio.melspectrogram(y, sr:, n_fft:, hop_length:, n_mels:, power: 2.0, ...)` | `librosa.feature.melspectrogram` | |
| `Matft.audio.power_to_db(S, ref:, amin:, top_db:)` | `librosa.power_to_db` | |
| `Matft.audio.whisper_log_mel(y, n_mels: 80, padding: 0)` | `whisper.audio.log_mel_spectrogram` | 便利関数．下記レシピ |

Whisper レシピ（検証対象）:
```
window = hann_window(400, periodic)
stft = torch.stft(audio, 400, 160, window=window, return_complex=True)  # center=True, reflect
magnitudes = stft[..., :-1].abs() ** 2                                   # 最終フレームを捨てる
mel_spec = filters(80 or 128) @ magnitudes                              # librosa mel, slaney
log_spec = clamp(mel_spec, min=1e-10).log10()
log_spec = max(log_spec, log_spec.max() - 8.0)
log_spec = (log_spec + 4.0) / 4.0
```
（入力は 16kHz，30 秒 = 480000 サンプルに pad/trim する `pad_or_trim` も提供）

## TDD 手順
1. **参照データ生成** `python/gen_audio_fixtures.py`（numpy, scipy, librosa, torch or openai-whisper）:
   - 窓関数: M = 1, 2, 5, 16, 400 のリテラル．
   - 短い合成信号（sin 和 + 固定シードノイズ，長さ 1000 程度）に対する stft / mel_filters / melspectrogram / power_to_db．
   - Whisper: 1 秒の合成音（16000 サンプル）→ log-mel (80, 100)．大きい出力は `Tests/MatftTests/files/audio/*.csv`（float32）で保存．
   - スクリプト自体をコミットし，再生成手順を docstring に記載．
2. **テストファイル** `Tests/MatftTests/AudioTest.swift`（窓関数は `MathTest` か新規 `WindowTest.swift`）．
   順に Red→Green:
   1. 窓関数（対称/periodic）
   2. `frame`
   3. `stft`（center=false → true，窓指定，win_length < n_fft のゼロ詰め）— 実部/虚部を許容誤差 1e-4〜1e-5 で比較
   4. `mel_filters`（slaney / htk，norm あり/なし）
   5. `melspectrogram`, `power_to_db`
   6. `whisper_log_mel`（許容誤差 1e-4 程度．float32 前提）
3. 全テスト Green 後にリファクタ（フレーム分割をバッチ rfft 一括呼び出しにする等）．

## 実装メモ
- 実装場所: `Sources/Matft/function/static/audio+static.swift`，`Matft.swift` に `audio` namespace 追加．窓関数は `creation+static.swift` など NumPy 側の既存配置に合わせる．
- STFT は「reflect pad → frame（(n_frames, n_fft) の連続配列）→ 窓乗算（broadcast）→ `rfft(axis: -1)` → 転置」で既存部品のみで組める．
- 複素出力は Matft の real/imag 分離表現．`abs()**2` は `data_real² + data_imag²` を vDSP で直接計算すると速い．
- mel は Hz⇔mel 変換（slaney: 1000Hz 以下線形, 以上 log / htk: 2595*log10(1+f/700)）と三角フィルタ + slaney 正規化 `2/(hi-lo)`．
- 性能: 30 秒音声（3000 フレーム × 400 点 rfft）を iPhone で数十 ms 以内が目安．PerformanceTests に追加し benchmark スキルで Python と比較．

## 完了条件
- 上記 API がテスト付きで実装され，Whisper log-mel が Python と許容誤差内で一致．
- README に使用例（Plan 5）．
- WASI ビルドで少なくとも pocketFFT 経路が動く．

## 決定事項（2026-09-27）
- namespace は **`Matft.audio`**（librosa の命名・引数に寄せる）．窓関数（`hanning` 等）は NumPy に倣い `Matft` 直下．
- 前提の `Matft.pad`（reflect）は 4-A で実装済み（`feature/numpy-gaps-basic`）．

## 未決事項
- STFT の出力軸順: librosa `(freq, time)` を採用（torch も同じ）．
- `istft`・リサンプリング（`librosa.resample`）を今回スコープに含めるか → 含めない（後続）．
