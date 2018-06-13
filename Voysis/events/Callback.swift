import Foundation

public protocol Callback: class {

    associatedtype C : Context
    associatedtype E : Entities

    /**
     Called when a successful response has been returned from server.
      -Parameter response: object representation of successful json response.
     */
    func success(response: StreamResponse<C,E>)

    /**
     See VoysisError for different possible error responses.
      -Parameter error: provides VoysisError.
     */
    func failure(error: VoysisError)

    /**
     Called when microphone is turned on and recording begins.
     */
    func recordingStarted()

    /**
     Called when successful connection is made to server.
      -Parameter queryResponse: contains information about the connection.
    */
    func queryResponse(queryResponse: QueryResponse)

    /**
     Called when recording finishes.
      -Parameter reason: enum explaining why recording finished.
     */
    func recordingFinished(reason: FinishedReason)

    /**
     Audio data recorded from microphone.
      -Parameter buffer: containing audio data.
     */
    func audioData(data: Data)
}

public extension Callback {

    func audioData(data: Data) {
        //no implementation
    }

    func recordingStarted() {
        //no implementation
    }

    func queryResponse(queryResponse: QueryResponse) {
        //no implementation
    }

    func recordingFinished(reason: FinishedReason) {
        //no implementation
    }
}