@testable import Voysis
import Foundation

/*
* Mock AudioRecordManager class. when start recording is called onDataResponse calls with isRecording true.
* When stop recording called, onDataResponse called with isRecording false
*/
class AudioRecordManagerMock: AudioRecorder {
    var onDataResponse: ((Data) -> Void)?
    var stopWithData: Bool = false

    var data: Data?

    public func start(onDataResponse: @escaping ((Data) -> Void)) {
        if (self.onDataResponse != nil) {
            self.onDataResponse = onDataResponse
        }
        onDataResponse(data ?? Data([1, 2]))
    }

    public func stop() {
        if stopWithData {
            onDataResponse?(Data([4]))
        } else {
            onDataResponse?(Data())
        }

    }

    func getMimeType() throws -> MimeType {
        return MimeType(encoding: "signed-int",
                bigEndian: false,
                bitsPerSample: 16,
                channels: 1,
                sampleRate: 16000)
    }
}
