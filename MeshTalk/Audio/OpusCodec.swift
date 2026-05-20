import Foundation

/// Placeholder Opus codec wrapper.
/// Currently passes through raw PCM16. When libopus SPM package is available,
/// this will wrap opus_encoder/decoder for compressed audio.
final class OpusCodec: Sendable {

    enum CodecError: Error {
        case encodeFailed
        case decodeFailed
        case notImplemented
    }

    /// Encode PCM16 data. Currently returns raw PCM16 (passthrough).
    func encode(pcm16: Data) -> Data {
        // TODO: Integrate libopus via SPM for real Opus encoding
        // For now, send raw PCM16 which the bridge supports
        return pcm16
    }

    /// Decode audio data. Currently returns raw PCM16 (passthrough).
    func decode(data: Data) -> Data {
        // TODO: Integrate libopus via SPM for real Opus decoding
        return data
    }
}
