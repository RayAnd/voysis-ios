import AVFoundation
import Foundation

class AudioSessionMock: AudioSession {
 
    override func requestRecordPermission(accepted: @escaping (Bool) -> Void)  {
        accepted(true)
    }
    
}
