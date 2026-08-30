import Foundation
import AVFoundation

public final class SoundSentinel: @unchecked Sendable {
    public static let shared = SoundSentinel()
    private var audioPlayer: AVAudioPlayer?
    private var cachedDropletData: Data?
    private let lock = NSLock()

    private init() {
        self.cachedDropletData = generateWaterDropletWAV()
    }

    /// Play a delicate, crystal-clear 0.35s pure water droplet chime (soft, non-piercing)
    public func playWaterDropletChime() {
        lock.lock()
        defer { lock.unlock() }

        guard let wavData = cachedDropletData else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            do {
                self.audioPlayer = try AVAudioPlayer(data: wavData)
                self.audioPlayer?.volume = 0.55
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } catch {
                // Fail silently without crashing
            }
        }
    }

    /// Generate an in-memory 0.35-second pure water ripple sound wave (Zero asset disk bloat)
    private func generateWaterDropletWAV() -> Data? {
        let sampleRate: Double = 44100.0
        let duration: Double = 0.35
        let totalSamples = Int(sampleRate * duration)

        var pcmSamples = [Int16](repeating: 0, count: totalSamples)

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let progress = t / duration

            // Frequency envelope: smooth water droplet upward-downward glide (820Hz -> 1350Hz -> 680Hz)
            let baseFreq: Double
            if progress < 0.25 {
                baseFreq = 820.0 + (progress / 0.25) * 530.0
            } else {
                baseFreq = 1350.0 - ((progress - 0.25) / 0.75) * 670.0
            }

            // Exponential damping envelope (crisp start, gentle water ripple decay)
            let envelope = exp(-8.5 * progress) * sin(Double.pi * min(1.0, progress * 20.0))

            // Primary water droplet tone + gentle subtle 2nd harmonic
            let wave1 = sin(2.0 * Double.pi * baseFreq * t)
            let wave2 = 0.22 * sin(4.0 * Double.pi * baseFreq * t)
            let sampleVal = (wave1 + wave2) * envelope * 0.75

            let clamped = max(-1.0, min(1.0, sampleVal))
            pcmSamples[i] = Int16(clamped * 32767.0)
        }

        // Build standard 44-byte WAV header
        var wavData = Data()
        let byteRate = Int32(sampleRate * 2)
        let dataSize = Int32(totalSamples * 2)
        let chunkSize = 36 + dataSize

        wavData.append(contentsOf: "RIFF".utf8)
        wavData.append(withUnsafeBytes(of: chunkSize.littleEndian) { Data($0) })
        wavData.append(contentsOf: "WAVE".utf8)
        wavData.append(contentsOf: "fmt ".utf8)
        wavData.append(withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) }) // Subchunk1Size
        wavData.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) })  // AudioFormat (PCM)
        wavData.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) })  // NumChannels (1)
        wavData.append(withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Data($0) }) // SampleRate
        wavData.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })  // ByteRate
        wavData.append(withUnsafeBytes(of: Int16(2).littleEndian) { Data($0) })  // BlockAlign
        wavData.append(withUnsafeBytes(of: Int16(16).littleEndian) { Data($0) }) // BitsPerSample
        wavData.append(contentsOf: "data".utf8)
        wavData.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })

        for sample in pcmSamples {
            var s = sample.littleEndian
            wavData.append(withUnsafeBytes(of: &s) { Data($0) })
        }

        return wavData
    }
}
