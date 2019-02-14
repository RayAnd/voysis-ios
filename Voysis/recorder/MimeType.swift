import Foundation

public struct MimeType {
    let sampleRate: Int
    let bitsPerSample: Int

    public var description: String {
        return "audio/pcm;bits=\(bitsPerSample);rate=\(sampleRate)"
    }
}