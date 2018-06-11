import Foundation

internal class CallbackDispatcher: Callback {
    private let dispatchQueue: DispatchQueue
    private weak var callback: Callback?

    init(_ dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
    }

    func setCallback(callback: Callback) {
        self.callback = callback
    }

    func success(response: ApiResponse) {
        dispatchQueue.async {
            self.callback?.success(response: response)
        }
    }

    func failure(error: VoysisError) {
        dispatchQueue.async {
            self.callback?.failure(error: error)
        }
    }

    func recordingStarted() {
        dispatchQueue.async {
            self.callback?.recordingStarted()
        }
    }

    func queryResponse(queryResponse: QueryResponse) {
        dispatchQueue.async {
            self.callback?.queryResponse(queryResponse: queryResponse)
        }
    }

    func recordingFinished(reason: FinishedReason) {
        dispatchQueue.async {
            self.callback?.recordingFinished(reason: reason)
        }
    }

    func audioData(data: Data) {
        dispatchQueue.async {
            self.callback?.audioData(data: data)
        }
    }
}