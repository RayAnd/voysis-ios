import Foundation

class Utils {
    static func generateAudioRecordParams(_ config: Config, _ session: AudioSession) -> AudioRecordParams {
        var sampleRate = session.getNativeSampleRate()
        var readBufferSize = UInt32(4096)
        if let rate = config.audioRecordParams?.sampleRate {
            sampleRate = rate
        }
        if let size = config.audioRecordParams?.readBufferSize {
            readBufferSize = size
        }
        return AudioRecordParams(sampleRate: sampleRate, readBufferSize: readBufferSize)
    }

    static func calculateMaxRecordingLength(_ sampleRate: Int) -> Int {
        //pcm 16bit encoding = two bytes per sample
        let bytesPerSample = 2
        let seconds = 10
        return sampleRate * bytesPerSample * seconds
    }
}
