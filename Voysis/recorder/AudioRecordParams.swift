import Foundation
/**
 Used for setting parameters on the iOS audio recording object. Configurable via Config interface.
*/
public struct AudioRecordParams {
    public var sampleRate: Double? = nil
    public var readBufferSize:  UInt32? = nil
}
