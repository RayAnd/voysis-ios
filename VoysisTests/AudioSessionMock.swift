import AVFoundation
import Foundation

class AudioSessionMock: AudioSession {

    public static let TEST_DEFAULT_SAMPLE_RATE = 16000.0
    var hasShutDown = false

    override func requestRecordPermission(accepted: @escaping (Bool) -> Void) {
        accepted(true)
    }


    override func getNativeSampleRate() -> Double {
        return AudioSessionMock.TEST_DEFAULT_SAMPLE_RATE
    }

    override func shutDown() throws {
        hasShutDown = true
    }
}
