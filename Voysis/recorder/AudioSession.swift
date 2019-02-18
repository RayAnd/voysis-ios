import Foundation
import AVFoundation

class AudioSession {
    let session = AVAudioSession.sharedInstance()

    func requestRecordPermission(accepted: @escaping (Bool) -> Void) {
        session.requestRecordPermission { granted in
            if granted {
                accepted(true)
            } else {
                accepted(false)
            }
        }
    }

    func getNativeSampleRate() -> Double {
        return session.sampleRate
    }
}
