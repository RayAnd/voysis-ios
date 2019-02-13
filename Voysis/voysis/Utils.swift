import Foundation

class Utils {
    static func generateAudioRecordParams(_ config: Config, _ session: AudioSession) -> AudioRecordParams {
        var sampleRate = session.getNativeSampleRate()
        var readBufferSize = 4096.0
        if let rate = config.audioRecordParams?.sampleRate {
            sampleRate = rate
        }
        if let size = config.audioRecordParams?.readBufferSize {
            readBufferSize = size
        }
        return AudioRecordParams(sampleRate: sampleRate, readBufferSize: readBufferSize)
    }
}
