import Foundation
import AVFoundation

internal class AudioSession {
    private let session = AVAudioSession.sharedInstance()

    func requestRecordPermission(accepted: @escaping (Bool) -> Void) throws {
        do {
            try session.setCategory(AVAudioSession.Category.record, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            session.requestRecordPermission { granted in
                if granted {
                    accepted(true)
                } else {
                    accepted(false)
                }
            }
        } catch {
            throw error
        }
    }

    func getNativeSampleRate() -> Double {
        return session.sampleRate
    }

    func shutDown() throws {
        do {
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            throw error
        }
    }
}
