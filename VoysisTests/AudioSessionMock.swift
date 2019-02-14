import AVFoundation
import Foundation

class AudioSessionMock: AudioSession {

    public static let TEST_DEFAULT_SAMPLE_RATE = 16000.0

    override func requestRecordPermission(accepted: @escaping (Bool) -> Void) {
        accepted(true)
    }


    override func getNativeSampleRate() -> Double {
        return AudioSessionMock.TEST_DEFAULT_SAMPLE_RATE
    }
}
