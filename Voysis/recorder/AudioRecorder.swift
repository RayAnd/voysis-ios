import Foundation

public protocol AudioRecorder {

    /**
     Parameter onDataResponse: called when audio buffer fills.
     */
    func start(onDataResponse: @escaping ((Data) -> Void))

    ///stop recording audio
    func stop()

    /**
      @return valid AudioInfo object.
    */
    func getMimeType() -> MimeType
}
