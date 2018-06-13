import Foundation

internal class CallbackDispatcher<T: Callback> {
    private let dispatchQueue: DispatchQueue
    private weak var callback: T?

    init(_ dispatchQueue: DispatchQueue, _ callback: T) {
        self.dispatchQueue = dispatchQueue
        self.callback = callback
    }

    func success(_ response: StreamResponse<T.C, T.E>) {
        dispatchQueue.async {
            self.callback?.success(response: response)
        }
    }

    func failure(_ error: VoysisError) {
        dispatchQueue.async {
            self.callback?.failure(error: error)
        }
    }

    func recordingStarted() {
        dispatchQueue.async {
            self.callback?.recordingStarted()
        }
    }

    func queryResponse(_ queryResponse: QueryResponse) {
        dispatchQueue.async {
            self.callback?.queryResponse(queryResponse: queryResponse)
        }
    }

    func recordingFinished(_ reason: FinishedReason) {
        dispatchQueue.async {
            self.callback?.recordingFinished(reason: reason)
        }
    }

    func audioData(_ data: Data) {
        dispatchQueue.async {
            self.callback?.audioData(data: data)
        }
    }
}