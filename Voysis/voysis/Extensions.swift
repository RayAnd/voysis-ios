import Foundation
import AudioToolbox

public extension AudioStreamBasicDescription {
    func getEncoding() throws -> String {
        if (mFormatFlags & kLinearPCMFormatFlagIsSignedInteger) > 0 {
            return "signed-int"
        } else if (mFormatFlags & kLinearPCMFormatFlagIsFloat) > 0 {
            return "float"
        } else {
            throw VoysisError.requestEncodingError("Pcm format error. Only signed-int, float supported")
        }
    }
}