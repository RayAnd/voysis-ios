@testable import Voysis
import Foundation

/*
* Mock AudioRecordManager class. when start recording is called onDataResponse calls with isRecording true.
* When stop recording called, onDataResponse called with isRecording false
*/
class AudioRecordManagerMock: AudioRecorder {
    var onDataResponse: ((Data, FinishedReason?) -> Void)?

    var data : Data?

    public func start(onDataResponse: @escaping ((Data, FinishedReason?) -> Void)) {
        if (self.onDataResponse != nil) {
            self.onDataResponse = onDataResponse
        }
        onDataResponse(data ?? Data(), .manualStop)
    }

    public func stop(reason : FinishedReason) {
        onDataResponse?(Data(), reason)
    }
}
