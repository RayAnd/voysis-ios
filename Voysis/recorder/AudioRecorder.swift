import Foundation

public protocol AudioRecorder {

    /**
     Parameter onDataResponse: called when audio buffer fills.
     */
    func start(onDataResponse: @escaping ((Data, FinishedReason?) -> Void))

    ///stop recording audio
    func stop(reason : FinishedReason)
}
