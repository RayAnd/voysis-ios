import Foundation

public struct MimeType {
    var encoding: String = "signed-int"
    let bigEndian: Bool = false
    var bitsPerSample: Int
    var channels: Int
    var sampleRate: Int

    public var description: String {
        return "audio/pcm;" +
                "encoding=\(encoding);" +
                "rate=\(sampleRate);" +
                "bits=\(bitsPerSample);" +
                "channels=\(channels);" +
                "big-endian=\(bigEndian)"
    }
}